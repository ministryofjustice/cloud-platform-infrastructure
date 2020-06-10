#!/usr/bin/env ruby

# If any namespaces exist in the cluster which are not
# listed here, the destroy script will abort.
SYSTEM_NAMESPACES = %w[
  cert-manager
  default
  docker-registry-cache
  ingress-controllers
  kiam
  kube-node-lease
  kube-public
  kube-system
  kuberos
  logging
  monitoring
  starter-pack
  opa
  velero
]

MAX_CLUSTER_NAME_LENGTH = 12
REQUIRED_ENV_VARS = %w[AWS_PROFILE AUTH0_DOMAIN AUTH0_CLIENT_ID AUTH0_CLIENT_SECRET KOPS_STATE_STORE]
REQUIRED_EXECUTABLES = %w[git-crypt terraform helm aws kops ssh-keygen]
REQUIRED_AWS_PROFILES = %w[moj-cp]
LIVE_CLUSTER_NAME_REXP = /live/

require "open3"
require "optparse"

class ClusterDeleter
  attr_reader :options

  def initialize(options)
    @options = options
  end

  def run
    puts "DRY-RUN: No changes will be made to the cluster" if dry_run?

    check_prerequisites
    target_cluster
    abort_if_user_namespaces_exist
    terraform_components
    kops_cluster
    terraform_base
    terraform_workspaces
    terraform_vpc if destroy_vpc? # Un comment to destroy the VPC
  end

  private

  def dry_run?
    !!options[:dry_run]
  end

  def destroy_vpc?
    !!options[:destroy_vpc]
  end

  def check_prerequisites
    check_options
    check_env_vars
    check_software_installed
    check_aws_profiles
    check_name_length
  end

  def check_options
    raise "No cluster name supplied" if cluster_name.nil?
    raise "You may not destroy production clusters" if LIVE_CLUSTER_NAME_REXP.match(cluster_name)
  end

  def check_env_vars
    REQUIRED_ENV_VARS.each do |var|
      value = ENV.fetch(var, "")
      raise "ERROR Required environment variable #{var} is not set." if value.empty?
    end
  end

  def check_software_installed
    REQUIRED_EXECUTABLES.each do |exe|
      raise "ERROR Required executable #{exe} not found." unless system("which #{exe}")
    end
    check_terraform_auth0
  end

  def check_terraform_auth0
    raise "ERROR Terraform auth0 provider plugin not found." \
      unless Dir["#{ENV.fetch("HOME")}/.terraform.d/plugins/**/**"].grep(/auth0/).any?
  end

  def check_aws_profiles
    creds = File.read("#{ENV.fetch("HOME")}/.aws/credentials").split("\n")
    REQUIRED_AWS_PROFILES.each do |profile|
      raise "ERROR Required AWS Profile #{profile} not found." \
        unless creds.grep(/\[#{profile}\]/).any?
    end
  end

  def check_name_length
    l = cluster_name.length
    raise "ERROR Cluster name #{cluster_name} too long (#{l} chars). Max. is #{MAX_CLUSTER_NAME_LENGTH}." \
      unless l <= MAX_CLUSTER_NAME_LENGTH
  end

  def target_cluster
    execute("kops export kubecfg #{cluster_long_name}", true)
  end

  # If someone has deployed something into this cluster, there might be
  # associated AWS resources which would be left orphaned if the cluster were
  # destroyed. So, we check for any unexpected namespaces, and abort if we find
  # any.
  def abort_if_user_namespaces_exist
    if user_namespaces.any?
      puts "\nPlease delete these namespaces, and any associated AWS resources, before destroying this cluster:"
      user_namespaces.each { |ns| puts "  * #{ns}" }
      puts
      raise
    end
  end

  def user_namespaces
    stdout, _, _ = execute("kubectl get ns -o name | sed 's/namespace.//'", true)
    namespaces = stdout.split("\n")
    namespaces - SYSTEM_NAMESPACES
  end

  def terraform_components
    dir = "terraform/cloud-platform-components"
    tf_init dir
    tf_workspace_select(dir, cluster_name)
    # prometheus_operator often fails to delete cleanly if anything has
    # happened to the open policy agent beforehand. Delete it first to
    # avoid any issues
    begin
      retries ||= 0
      puts "Retry ##{retries} to destroy prometheus due to CRDs missing and deleting prometheus resources"
      tf_destroy(dir, "module.prometheus")
      raise
    rescue
      retry if (retries += 1) < 2
    end
    tf_destroy(dir)
  end

  def kops_cluster
    execute "kops delete cluster --name #{cluster_long_name} --yes"
  end

  def terraform_base
    dir = "terraform/cloud-platform"
    tf_init dir
    tf_workspace_select(dir, cluster_name)
    execute %(cd #{dir}; terraform destroy -var vpc_name="#{vpc_name}" -auto-approve)
  end

  def terraform_workspaces
    ["terraform/cloud-platform", "terraform/cloud-platform-components", "terraform/cloud-platform-network"].each do |dir|
      execute "cd #{dir}; terraform workspace select default; terraform workspace delete #{cluster_name}"
    end
  end

  def terraform_vpc
    dir = "terraform/cloud-platform-network"
    tf_init dir
    tf_workspace_select(dir, vpc_name)
    tf_destroy(dir)
  end

  def tf_init(dir)
    execute "cd #{dir}; terraform init"
  end

  def tf_workspace_select(dir, workspace)
    execute "cd #{dir}; terraform workspace select #{workspace}"
  end

  def tf_destroy(dir, target = nil)
    tgt = target.nil? ? "" : "-target #{target}"
    execute "cd #{dir}; terraform destroy #{tgt} -auto-approve"
  end

  def vpc_name
    options[:vpc_name]
  end

  def cluster_name
    options[:cluster_name]
  end

  def cluster_long_name
    "#{cluster_name}.cloud-platform.service.justice.gov.uk"
  end

  def execute(cmd, execute_in_dry_run = false)
    if dry_run? && !execute_in_dry_run
      puts "DRY-RUN: #{cmd}"
      nil
    else
      puts "executing: #{cmd}"
      stdout, stderr, status = Open3.capture3(cmd)

      unless status.success?
        puts "Command: #{cmd} failed."
        puts stderr
        raise
      end

      puts stdout

      [stdout, stderr, status]
    end
  end
end

def parse_options
  # set defaults
  options = {
    dry_run: true,
    cluster_name: nil,
    destroy_vpc: true
  }

  OptionParser.new { |opts|
    opts.on("-n", "--name CLUSTER-NAME", "Cluster name (max. #{MAX_CLUSTER_NAME_LENGTH} chars)") do |name|
      options[:cluster_name] = name
    end

    opts.on("-v", "--vpc-name VPC-NAME", "VPC to destroy, defaults to CLUSTER-NAME") do |name|
      options[:vpc_name] = name
    end

    opts.on("-d", "--dont-destroy-vpc", "Supply this flag to leave the VPC intact") do |dont_destroy_vpc|
      options[:destroy_vpc] = !dont_destroy_vpc
    end

    opts.on("-y", "--yes", "Actually destroy the cluster") do |yes|
      options[:dry_run] = !yes
    end

    opts.on_tail("-h", "--help", "Show help message") do
      puts opts
      exit
    end
  }.parse!

  # By default, we name our VPCs the same as the cluster
  options[:vpc_name] ||= options[:cluster_name]

  options
end

############################################################

options = parse_options
ClusterDeleter.new(options).run
