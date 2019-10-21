#!/usr/bin/env ruby

# See example.env.create-cluster for the environment variables
# which must be set before running this script.
#
# Usage:
#   Change the K8S_CLUSTER_NAME and kubectl use-context of #K8S_CLUSTER_NAME
#   ./create-cluster.rb
#

require 'json'
require "yaml"
require "pry-byebug"  # TODO remove this
require "net/http"

K8S_CLUSTER_NAME = "vij-ing-fire.cloud-platform.service.justice.gov.uk"
AWS_REGION = "eu-west-2"
KOPS_CONFIG_URL = "https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/master/kops/live-1.yaml"

def main
  number_of_workers = count_worker_nodes
  worker_instance_group_size = get_worker_instance_group_size

  unless correct_number_of_workers_running?
    raise "There should be #{worker_instance_group_size} workers, but #{number_of_workers} found. Aborting."
  end

  node = get_oldest_worker_node
  drain_node(node)
  sleep 30
  terminate_node(node)
  sleep 60

  wait_for_node_to_be_replaced
end

def correct_number_of_workers_running?
  count_worker_nodes == get_worker_instance_group_size
end

def wait_for_node_to_be_replaced
  max_tries = 30
  validated = false

  (1..max_tries).each do |attempt|
    log "Checking that node has been replaced, #{attempt} of #{max_tries}..."

    if correct_number_of_workers_running?
      log "Terminated node was replaced"
      validated = true
      break
    else
      log "Waiting for node to be replaced..."
      sleep 60
    end
  end

  raise "Terminated node was not replaced after checking #{max_tries} times." unless validated
end

def count_worker_nodes
  get_worker_nodes
    .find_all { |node| node_ready?(node) }
    .count
end

def get_nodes
  JSON.parse(`kubectl get nodes -o json`).dig("items")
end

def get_worker_nodes
  get_nodes.find_all { |node| worker_node?(node) }
end

def node_ready?(node)
  node_conditions = node.dig("status", "conditions")
  node_conditions.map { |c| c.dig("reason") }.include?("KubeletReady")
end

def worker_node?(node)
  node.dig("metadata", "labels")["kubernetes.io/role"] == "node"
end

def get_worker_instance_group_size
  docs = []
  YAML.load_stream(get_kops_config) { |doc| docs << doc }
  worker_instance_group = docs.last
  
  unless worker_instance_group.dig("metadata", "name") == "nodes"
    raise "Failed to parse kops config. Last document in YAML file is supposed to be worker instancegroup definition."
  end

  worker_instance_group.dig("spec", "minSize").to_i
end

def get_kops_config
  Net::HTTP.get(URI(KOPS_CONFIG_URL))
end

def get_oldest_worker_node
  get_worker_nodes
    .sort_by {|node| node.dig("metadata", "creationTimestamp") }
    .first
end

def drain_node(node)
  name = node.dig("metadata", "name")

  cmd = "kubectl --ignore-daemonsets --delete-local-data drain #{name}"

  if cmd_successful?(cmd)
    log "worker node #{name} drained sucessfully."
  else
    raise "worker node #{name} failed to drain. Aborting."
  end
end

def terminate_node(node)
  if cordoned?(node)
    execute "aws ec2 terminate-instances --instance-ids #{aws_instance_id(node)} --region #{AWS_REGION}"
  else
    raise "Older worker node failed to terminate. Aborting."
  end
end 

def aws_instance_id(node)
  node.dig("spec", "providerID").split("/").last
end

def cordoned?(node)
  spec = node.dig("spec")
  spec.has_key?("unschedulable") && spec.dig("unschedulable") == "true"
end

def log(msg)
  puts [Time.now.strftime("%Y-%m-%d %H:%M:%S"), msg].join(" ")
end

def cmd_successful?(cmd)
  log cmd
  system cmd
end

def execute(cmd, can_fail: false)
  log cmd
  result = `#{cmd}` # TODO: Use open3
  raise "Command: #{cmd} failed." unless (can_fail || $?.success?)
  result
end

main