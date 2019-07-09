#!/usr/bin/env ruby

# See example.env.create-cluster for the environment variables
# which must be set before running this script.
#
# Usage:
#
#   ./create-cluster.rb [cluster-name]
#

require "fileutils"
require "open3"

MAX_CLUSTER_NAME_LENGTH = 12
CLUSTER_SUFFIX = "cloud-platform.service.justice.gov.uk"
# TODO: use the right dns flush command, depending on the architecture of the local machine
DNS_FLUSH_COMMAND = 'sudo killall -HUP mDNSResponder' # Mac OSX Mojave

REQUIRED_ENV_VARS = %w( AWS_PROFILE AUTH0_DOMAIN AUTH0_CLIENT_ID AUTH0_CLIENT_SECRET KOPS_STATE_STORE )
REQUIRED_EXECUTABLES = %w( git-crypt terraform helm aws kops )
REQUIRED_AWS_PROFILES = %w( moj-cp moj-dsd )

def main(cluster_name)
  check_prerequisites(cluster_name)

  execute "git-crypt unlock"
  get_sudo

  create_cluster(cluster_name)
  # run_kops(cluster_name)
  # install_components(cluster_name)

  # kubectl cluster-info
end

def create_cluster(cluster_name)
  FileUtils.rm_rf("terraform/cloud-platform/.terraform")
  dir = "terraform/cloud-platform"
  switch_terraform_workspace(dir, cluster_name)
  execute "cd #{dir}; terraform apply -auto-approve"
end

def switch_terraform_workspace(dir, name)
  execute "cd #{dir}; terraform init"
  # The workspace might already exist, so the workspace new is allowed to fail
  # but the workspace select must succeed
  execute "cd #{dir}; terraform workspace new #{name}", can_fail: true
  execute "cd #{dir}; terraform workspace select #{name}"
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

# https://stackoverflow.com/a/677212/794111 <-- explains 'hash' vs. 'which'
def check_software_installed
  REQUIRED_EXECUTABLES.each do |exe|
    raise "ERROR Required executable #{exe} not found." unless system("hash #{exe}")
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
  puts cmd
  result = `#{cmd}` # TODO: Use open3
  raise "Command: #{cmd} failed." unless (can_fail || $?.success?)
  result
end

def get_sudo
  execute "sudo true"
end

############################################################

main ARGV.shift
