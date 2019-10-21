#!/usr/bin/env ruby

# See example.env.create-cluster for the environment variables
# which must be set before running this script.
#
# Usage:
#   Change the K8S_CLUSTER_NAME and kubectl use-context of #K8S_CLUSTER_NAME
#   ./create-cluster.rb
#

require 'json'
require "pry-byebug"
require 'optparse'

K8S_CLUSTER_NAME = "vij-ing-fire.cloud-platform.service.justice.gov.uk"

def main
  number_of_workers = count_worker_nodes
  worker_instance_group_size = get_worker_instance_group_size

  unless number_of_workers == worker_instance_group_size
    raise "There should be #{worker_instance_group_size} workers, but #{number_of_workers} found. Aborting."
  end

  # drain_node
  # sleep 30
  # terminate_node
  # sleep 60
  # wait_for_kops_validate
end

def count_worker_nodes
  #data = `kubectl get nodes -l kubernetes.io/role=node --sort-by=".status.conditions[?(@.reason == 'KubeletReady' )].status"`.chomp
  
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

# def count_worker_nodes
#   `kubectl get nodes -l kubernetes.io/role=node | grep -e Ready | wc -l | xargs`
# end

# puts count_worker_nodes

def get_worker_instance_group_size
  execute "kops get ig --name #{K8S_CLUSTER_NAME} nodes -o json | jq -r '.spec.maxSize'"
end

def get_oldest_worker_node
  get_worker_nodes
    .sort_by {|node| node.dig("metadata", "creationTimestamp") }
    .first
end

def drain_node(node)
  name = node.dig("metadata", "name")

  cmd = "kubectl  --ignore-daemonsets --delete-local-data drain #{name}"

  if cmd_successful?(cmd)
    log "worker node #{name} drained sucessfully."
  else
    raise "worker node #{name} failed to drain. Aborting."
  end
end

def terminate_node(node)
  node_name = node.dig("metadata", "name")

  # TODO - json
  aws_instance_id_drained_node = `kubectl get node #{node_name} -o 'jsonpath={.spec.providerID}' | cut -d "/" -f 5`.chomp

  if cordoned?(node)
    execute "aws ec2 terminate-instances --instance-ids #{aws_instance_id_drained_node} --region eu-west-2"
  else
    raise "Older worker node failed to terminate. Aborting."
  end
end 

def cordoned?(node)
  binding.pry
  execute("kubectl get nodes #{node_name} -o 'jsonpath={.spec.unschedulable}'") == "true"
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

cordoned? get_oldest_worker_node
# main
