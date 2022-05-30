#!/usr/bin/env ruby

# If any namespaces exist in the cluster which are not
# listed here, the destroy script will abort.

EKS_SYSTEM_NAMESPACES = %w[
  cert-manager
  default
  ingress-controllers
  kube-node-lease
  kube-public
  kube-system
  kuberos
  logging
  monitoring
  opa
  velero
] + (0..9).map { |i| "starter-pack-#{i}" }

MAX_CLUSTER_NAME_LENGTH = 12
REQUIRED_ENV_VARS = %w[AWS_PROFILE AUTH0_DOMAIN AUTH0_CLIENT_ID AUTH0_CLIENT_SECRET]
REQUIRED_EXECUTABLES = %w[git-crypt terraform helm aws ssh-keygen]
REQUIRED_AWS_PROFILES = %w[moj-cp]
LIVE_CLUSTER_NAME_REXP = /live/
AWS_REGION = "eu-west-2"

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
    target_eks_cluster
    abort_if_user_namespaces_exist
    # terraform_eks_components
    # terraform_base_eks
    # terraform_vpc if destroy_vpc?
    # terraform_workspaces_eks
  end

  private

  def kind
    options[:kind]
  end

  def dry_run?
    !!options[:dry_run]
  end

  def destroy_vpc?
    !!options[:destroy_vpc]
  end

  def check_prerequisites
    running_in_docker
    check_options
    check_env_vars
    check_software_installed
    check_aws_profiles
    check_name_length
  end

  def running_in_docker
    unless running_in_docker?
      raise "This script may only be run inside a docker container"
    end
  end

  # https://stackoverflow.com/questions/20010199/how-to-determine-if-a-process-runs-inside-lxc-docker
  def running_in_docker?
    FileTest.exists?("/.dockerenv") || (
      FileTest.exists?("/proc/self/cgroup") &&
      File.read("/proc/self/cgroup").split("\n").any?
    )
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

  def target_eks_cluster
    execute("aws eks update-kubeconfig --name #{cluster_name} --region #{AWS_REGION}")
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
    namespaces - EKS_SYSTEM_NAMESPACES
  end

  def terraform_eks_components
    dir = "terraform/aws-accounts/cloud-platform-aws/vpc/eks/components"
    tf_init dir
    tf_workspace_select(dir, cluster_name)
    tf_destroy(dir)
  end

  def terraform_base_eks
    dir = "terraform/aws-accounts/cloud-platform-aws/vpc/eks"
    tf_init dir
    tf_workspace_select(dir, cluster_name)
    tf_destroy(dir)
  end

  def terraform_workspaces_eks
    ["terraform/aws-accounts/cloud-platform-aws/vpc/eks", "terraform/aws-accounts/cloud-platform-aws/vpc/eks/components", "terraform/aws-accounts/cloud-platform-aws/vpc"].each do |dir|
      execute "cd #{dir}; terraform workspace select default; terraform workspace delete #{cluster_name}"
    end
  end

  def terraform_vpc
    dir = "terraform/aws-accounts/cloud-platform-aws/vpc"
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
      options[:cluster_name] = name.sub(".cloud-platform.service.justice.gov.uk", "")
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
