#!/usr/bin/env ruby

# See example.env.create-cluster for the environment variables
# which must be set before running this script.
#
# Usage:
#
#   ./create-cluster.rb [cluster-name]
#
require "fileutils"
require "optparse"

MAX_CLUSTER_NAME_LENGTH = 12
CLUSTER_SUFFIX = "cloud-platform.service.justice.gov.uk"
AWS_REGION = "eu-west-2"

REQUIRED_ENV_VARS = %w[AWS_PROFILE AUTH0_DOMAIN AUTH0_CLIENT_ID AUTH0_CLIENT_SECRET]
REQUIRED_EXECUTABLES = %w[git-crypt terraform helm aws ssh-keygen]
REQUIRED_AWS_PROFILES = %w[moj-cp]

NONE = "none"

def main(options)
  cluster_name = options[:cluster_name]
  kind = options[:kind]
  vpc_name = options[:vpc_name]
  gitcrypt_unlock = options[:gitcrypt_unlock]
  integration_tests = options[:integration_tests]
  dockerconfig = options[:dockerconfig]
  extra_wait = options[:extra_wait]

  vpc_name = cluster_name if vpc_name.nil?
  usage if cluster_name.nil?

  check_prerequisites(cluster_name)

  execute "git-crypt unlock" if gitcrypt_unlock

  create_vpc(vpc_name)
  create_cluster_eks(cluster_name, vpc_name)
  sleep(extra_wait)
  install_components_eks(cluster_name)
  run_integration_tests(cluster_name) if integration_tests
  run_and_output "kubectl cluster-info"
end

def create_vpc(vpc_name)
  FileUtils.rm_rf("terraform/aws-accounts/cloud-platform-aws/vpc/.terraform")
  dir = "terraform/aws-accounts/cloud-platform-aws/vpc"
  switch_terraform_workspace(dir, vpc_name)

  tf_apply = [
    "terraform apply",
    "-auto-approve"
  ].join(" ")

  run_and_output "cd #{dir}; #{tf_apply}"
end

def create_cluster_eks(cluster_name, vpc_name)
  FileUtils.rm_rf("terraform/aws-accounts/cloud-platform-aws/vpc/eks/.terraform")
  dir = "terraform/aws-accounts/cloud-platform-aws/vpc/eks"
  switch_terraform_workspace(dir, cluster_name)

  tf_apply = [
    "terraform apply",
    "-auto-approve"
  ].join(" ")

  run_and_output "cd #{dir}; #{tf_apply}"
end

# This is a tactical fix to install our own pod security policies in an EKS cluster. When PSP's are deprecated and we create policies via another means, this method can be removed.
def fix_psp
  cmd_delete = "kubectl delete psp eks.privileged --ignore-not-found=true"
  if cmd_successful?(cmd_delete)
    log "Deleted eks.privileged psp."
  else
    log "Could not delete eks.privileged psp. Aborting."
    exit 1
  end

  cmd_destroy = "kubectl delete --all pods -A"
  if cmd_successful?(cmd_destroy)
    log "Recycled all pods."
  else
    log "Failed to recycle pods. Continuing."
  end
end

def install_components_eks(cluster_name)
  dir = "terraform/aws-accounts/cloud-platform-aws/vpc/eks/components"
  execute "cd #{dir}; rm -rf .terraform"
  switch_terraform_workspace(dir, cluster_name)
  disable_alerts(dir)

  cmd_update_kubeconfig = "aws eks update-kubeconfig --name #{cluster_name} --region #{AWS_REGION}"
  if cmd_successful?(cmd_update_kubeconfig)
    log "Set kubeconfig to the new cluster"
  else
    log "Could not set kubeconfig to the new cluster. Aborting."
    exit 1
  end

  fix_psp

  cmd = "cd #{dir}; terraform apply -auto-approve"
  if cmd_successful?(cmd)
    log "Cluster components installed."
  else
    log "Cluster components failed to install. Aborting."
    exit 1
  end
end

def disable_alerts(dir)
  # This will disable high-priority pagerduty alarms for your cluster by replacing the pagerduty_config token with a dummy value
  `sed -i 's/pagerduty_config\\s\\{1,\\}=\\s\\{1,\\}".*"/pagerduty_config = "dummydummy"/g' #{dir}/terraform.tfvars`
  # This will disable lower priority alerts for your cluster by replacing the alertmanager slack webhook url with a dummy value
  `sed -i 's/cloud_platform_slack_webhook\\s\\{1,\\}=\\s\\{1,\\}".*"/cloud_platform_slack_webhook = "dummydummy"/g'  #{dir}/terraform.tfvars`
  `sed -i 's/hooks.slack.com/dummy.slack.com/g'  #{dir}/terraform.tfvars`
end

def switch_terraform_workspace(dir, name)
  run_and_output "cd #{dir}; terraform init"
  # The workspace might already exist, so the workspace new is allowed to fail
  # but the workspace select must succeed
  run_and_output "cd #{dir}; terraform workspace new #{name}", can_fail: true
  run_and_output "cd #{dir}; terraform workspace select #{name}"
end

def check_prerequisites(cluster_name)
  check_env_vars
  check_software_installed
  check_aws_profiles
  check_name_length(cluster_name)
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

def execute(cmd, can_fail: false)
  log cmd
  result = `#{cmd}` # TODO: Use open3
  raise "Command: #{cmd} failed." unless can_fail || $?.success?
  result
end

def run_and_output(cmd, opts = {})
  puts execute(cmd, opts)
end

def usage
  puts
  puts "For usage instructions, run: #{$0} --help"
  puts
  exit 1
end

def log(msg)
  puts [Time.now.strftime("%Y-%m-%d %H:%M:%S"), msg].join(" ")
end

def cmd_successful?(cmd)
  log cmd
  system cmd
end

def running_in_docker_container?
  File.file?("/proc/1/cgroup") && File.read("/proc/1/cgroup") =~ /(docker|kubepods|0::\/)/
end

def run_integration_tests(cluster_name)
  dir = "smoke-tests/"
  output = "./#{cluster_name}-rspec.txt"

  cmd = [
    "cd #{dir}",
    "bundle binstubs bundler --force --path /usr/local/bin",
    "bundle binstubs rspec-core --path /usr/local/bin",
    "rspec --tag ~live-1 --tag ~eks-manager --format progress --format documentation --out #{output}"
  ].join("; ")

  run_and_output(cmd)
end

def parse_options
  options = {gitcrypt_unlock: true, integration_tests: true, extra_wait: 0, kind: "kops", dockerconfig: NONE}

  OptionParser.new { |opts|
    opts.on("-n", "--name CLUSTER-NAME", "Cluster name (max. #{MAX_CLUSTER_NAME_LENGTH} chars)") do |name|
      options[:cluster_name] = name
    end

    opts.on("-v", "--vpc-name VPC-NAME", "VPC where to deploy the test cluster") do |name|
      options[:vpc_name] = name
    end

    opts.on("-g", "--no-gitcrypt", "Avoid the execution of git-crypt unlock (example: pipeline tools might do that for you)") do |name|
      options[:gitcrypt_unlock] = false
    end

    opts.on("-i", "--no-integration-test", "Don't run integration tests after creating the cluster") do |name|
      options[:integration_tests] = false
    end

    opts.on("-t", "--extra-wait N", Float, "The time between kops validate and deploy of components. We need to wait for DNS propagation") do |n|
      options[:extra_wait] = n
    end

    opts.on("-d", "--dockerconfig DOCKER-CONFIG", "Authenticate to Docker hub using a docker config file") do |name|
      options[:dockerconfig] = name
    end

    opts.on_tail("-h", "--help", "Show help message") do
      puts opts
      exit
    end
  }.parse!

  options
end

############################################################

abort("You must run this script from within the ministryofjustice/cloud-platform-tools docker container!") unless running_in_docker_container?

options = parse_options

main(options)
