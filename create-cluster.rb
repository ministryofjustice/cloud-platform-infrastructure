#!/usr/bin/env ruby

# See example.env.create-cluster for the environment variables
# which must be set before running this script.
#
# Usage:
#
#   ./create-cluster.rb [cluster-name]
#
require "fileutils"

MAX_CLUSTER_NAME_LENGTH = 12
CLUSTER_SUFFIX = "cloud-platform.service.justice.gov.uk"

REQUIRED_ENV_VARS = %w( AWS_PROFILE AUTH0_DOMAIN AUTH0_CLIENT_ID AUTH0_CLIENT_SECRET KOPS_STATE_STORE )
REQUIRED_EXECUTABLES = %w( git-crypt terraform helm aws kops ssh-keygen )
REQUIRED_AWS_PROFILES = %w( moj-cp moj-dsd )

def main(cluster_name)
  usage if cluster_name.nil?

  check_prerequisites(cluster_name)

  execute "git-crypt unlock"

  create_cluster(cluster_name)
  run_kops(cluster_name)
  install_components(cluster_name)

  run_and_output "kubectl cluster-info"
end

def create_cluster(cluster_name)
  FileUtils.rm_rf("terraform/cloud-platform/.terraform")
  dir = "terraform/cloud-platform"
  switch_terraform_workspace(dir, cluster_name)
  run_and_output "cd #{dir}; terraform apply -auto-approve"
end

def run_kops(cluster_name)
  run_and_output "kops create -f kops/#{cluster_name}.yaml"

  # This is a throwaway SSH key which we never need again.
  execute("rm -f /tmp/#{cluster_name} /tmp/#{cluster_name}.pub")
  execute("ssh-keygen -b 4096 -P '' -f /tmp/#{cluster_name}")

  run_and_output "kops create secret --name #{cluster_name}.#{CLUSTER_SUFFIX} sshpublickey admin -i /tmp/#{cluster_name}.pub"
  run_and_output "kops update cluster #{cluster_name}.#{CLUSTER_SUFFIX} --yes --alsologtostderr"

  wait_for_kops_validate
end

# TODO: figure out this problem, and fix it.
# For some reason, the first terraform apply sometimes fails with an error "could not find a ready tiller pod"
# This seems to be quite misleading, since adding a delay after 'helm init' makes no difference.
# A second run of the terraform apply usually works correctly.
def install_components(cluster_name)
  dir = "terraform/cloud-platform-components"
  execute "cd #{dir}; rm -rf .terraform"
  switch_terraform_workspace(dir, cluster_name)

  # Ensure we have the latest helm charts for all the required components
  execute "helm init --client-only; helm repo update"
  # Without this step, you may get errors like this:
  #
  #     helm_release.open-policy-agent: chart “opa” matching 1.3.2 not found in stable index. (try ‘helm repo update’). No chart version found for opa-1.3.2
  #


  cmd = "cd #{dir}; terraform apply -auto-approve"
  if cmd_successful?(cmd)
    log "Cluster components installed."
  else
    log "Initial components install reported errors. Sleeping and retrying..."
    sleep 120
    cmd_successful?(cmd)
  end
end

def wait_for_kops_validate
  max_tries = 30
  validated = false

  (1..max_tries).each do |attempt|
    log "Validate cluster, attempt #{attempt} of #{max_tries}..."

    if cmd_successful?("kops validate cluster")
      log "Cluster validated."
      validated = true
      break
    else
      log "Sleeping before retry..."
      sleep 60
    end
  end

  raise "ERROR Failed to validate cluster after $max_tries attempts." unless validated
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
    ENV.fetch(var) { raise "ERROR Required environment variable #{var} is not set." }
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
    unless Dir["#{ENV.fetch('HOME')}/.terraform.d/plugins/**/**"].grep(/auth0/).any?
end

# cluster is built in moj-cp, but cert-manager and external-dns need
# credentials for moj-dsd
def check_aws_profiles
  creds = File.read("#{ENV.fetch('HOME')}/.aws/credentials").split("\n")
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
  raise "Command: #{cmd} failed." unless (can_fail || $?.success?)
  result
end

def run_and_output(cmd, opts = {})
  puts execute(cmd, opts)
end

def usage
  puts "USAGE: #{$0} cluster-name"
  exit 1
end

def log(msg)
  puts [Time.now.strftime("%Y-%m-%d %H:%M:%S"), msg].join(" ")
end

def cmd_successful?(cmd)
  log cmd
  system cmd
end

############################################################

main ARGV.shift
