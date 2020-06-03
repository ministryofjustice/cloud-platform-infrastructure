#!/usr/bin/env ruby

# Edit this to specify the cluster and VPC to destroy
CLUSTER = "cp-2503-1123"
VPC_NAME = CLUSTER

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

REQUIRED_ENV_VARS = %w[AWS_PROFILE AUTH0_DOMAIN AUTH0_CLIENT_ID AUTH0_CLIENT_SECRET KOPS_STATE_STORE]
REQUIRED_EXECUTABLES = %w[git-crypt terraform helm aws kops ssh-keygen]
REQUIRED_AWS_PROFILES = %w[moj-cp]

# copied from create-cluster.rb
MAX_CLUSTER_NAME_LENGTH = 12

require "open3"
require "optparse"

def main(options)
  check_prerequisites

  target_cluster
  abort_if_user_namespaces_exist
  terraform_components
  kops_cluster(options)
  terraform_base
  terraform_workspaces
  terraform_vpc # Un comment to destroy the VPC
end

def check_prerequisites(options)
  check_options(options)
  check_env_vars
  check_software_installed
  check_aws_profiles
  check_name_length(options[:cluster_name])
end

def check_options(options)
  abort_if_live_cluster(options)
  abort_if_vpc_name_but_no_destroy(options)
end

def check_prerequisites(cluster_name)
  # TODO: check helm version is >= 2.11
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

def check_name_length(cluster_name)
  l = cluster_name.length
  raise "ERROR Cluster name #{cluster_name} too long (#{l} chars). Max. is #{MAX_CLUSTER_NAME_LENGTH}." \
    unless l <= MAX_CLUSTER_NAME_LENGTH
end

def target_cluster(cluster)
  execute "kops export kubecfg #{cluster}"
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
  stdout, _, _ = execute("kubectl get ns -o name | sed 's/namespace.//'")
  namespaces = stdout.split("\n")
  namespaces - SYSTEM_NAMESPACES
end

def terraform_components
  dir = "terraform/cloud-platform-components"
  tf_init dir
  tf_workspace_select(dir, CLUSTER)
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

def kops_cluster(options)
  name = options.fetch(:cluster_name)
  execute "kops delete cluster --name #{cluster_long_name(name)} --yes"
end

def terraform_base
  dir = "terraform/cloud-platform"
  tf_init dir
  tf_workspace_select(dir, CLUSTER)
  execute %(cd #{dir}; terraform destroy -var vpc_name="#{VPC_NAME}" -auto-approve)
end

def terraform_workspaces
  ["terraform/cloud-platform", "terraform/cloud-platform-components"].each do |dir|
    execute "cd #{dir}; terraform workspace select default; terraform workspace delete #{CLUSTER}"
  end
end

def terraform_vpc
  dir = "terraform/cloud-platform-network"
  tf_init dir
  tf_workspace_select(dir, VPC_NAME)
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

def cluster_long_name(name)
  "#{name}.cloud-platform.service.justice.gov.uk"
end

def execute(cmd)
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

def parse_options
  # set defaults
  options = {
    dry_run: true,
    cluster_name: nil,
    vpc_name: nil,
    destroy_vpc: false,
  }

  OptionParser.new { |opts|
    opts.on("-n", "--name CLUSTER-NAME", "Cluster name (max. #{MAX_CLUSTER_NAME_LENGTH} chars)") do |name|
      options[:cluster_name] = name
    end

    opts.on("-v", "--vpc-name VPC-NAME", "VPC to destroy (if --destroy-vpc is specified, defaults to CLUSTER-NAME)") do |name|
      options[:vpc_name] = name || options[:cluster_name]
    end

    opts.on("-d", "--destroy-vpc", "Supply this flag to actually destroy the VPC") do |destroy_vpc|
      options[:destroy_vpc] = destroy_vpc
    end

    opts.on_tail("-h", "--help", "Show help message") do
      puts opts
      exit
    end
  }.parse!

  options
end

############################################################

options = parse_options
main(options)
