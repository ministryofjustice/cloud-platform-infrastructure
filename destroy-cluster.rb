#!/usr/bin/env ruby

# Edit this to specify the cluster and VPC to destroy
CLUSTER = "cp-2503-1123"
VPC_NAME = CLUSTER

require "open3"

def main
  terraform_components
  kops_cluster
  terraform_base
  terraform_workspaces
  # terraform_vpc # Un comment to destroy the VPC
end

def terraform_components
  dir = "terraform/cloud-platform-components"
  execute "kops export kubecfg #{cluster_long_name}"
  tf_init dir
  tf_workspace_select(dir, CLUSTER)
  # prometheus_operator often fails to delete cleanly if anything has
  # happened to the open policy agent beforehand. Delete it first to
  # avoid any issues
  tf_destroy(dir, "module.prometheus")
  tf_destroy(dir)
end

def kops_cluster
  execute "kops delete cluster --name #{cluster_long_name} --yes"
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

def cluster_long_name
  "#{CLUSTER}.cloud-platform.service.justice.gov.uk"
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

main
