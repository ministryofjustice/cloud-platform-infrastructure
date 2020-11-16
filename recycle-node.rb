#!/usr/bin/env ruby

# Usage:
#   export AWS_PROFILE=moj-cp
#   Edit "K8S_CLUSTER_NAME" to specify the cluster to recycle old node.
#   ./recycle-node.rb
#
#  Note:
#   The `target_worker_node_count` method looks for the instance group size in the kops manifest in our github repository, so it will always return the size of the live-1 cluster.
#   To run this on a test cluster, update method `target_worker_node_count` as shown below, to return number of worker nodes configured as minSize in kops/test-cluster.yaml.
#
#  def target_worker_node_count
#     return 3

require "json"
require "yaml"
require "net/http"
require "timeout"

K8S_CLUSTER_NAME = "live-1.cloud-platform.service.justice.gov.uk"
AWS_REGION = "eu-west-2"
KOPS_CONFIG_URL = "https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/main/kops/live-1.yaml"
NODE_DRAIN_TIMEOUT = 360 # Draining a node usually takes around 2 minutes. If it takes >6 minutes, it's not going to complete.
SIGTERM = 15 # The unix signal to send to kill a process
STUCK_STATES = ["ImagePullBackOff", "CrashLoopBackOff"]
INSTANCE_GROUP_LABEL = "cloud-platform-recycle-nodes" # Set this label to "true" to indicate recyclable worker node instancegroups

def main
  config_cluster

  unless correct_number_of_workers_running?
    raise "There should be #{target_worker_node_count} workers, but #{count_worker_nodes} found. Aborting."
  end

  node = get_oldest_worker_node

  cordon_node(node)
  # Delete any stuck pods, so that they don't prevent the node from being drained.
  stuck_pods(node).each { |pod| delete_pod(pod) }
  drain_node(node)

  sleep 30

  node = get_latest_node_details(node) # node status should have changed, after being drained
  delete_node(node)
  terminate_node(node)

  sleep 60

  wait_for_node_to_be_replaced
end

def config_cluster
  unless cmd_successful?("kubectl config use-context #{K8S_CLUSTER_NAME}")
    raise "config not found for #{K8S_CLUSTER_NAME}. Aborting."
  end
end

def correct_number_of_workers_running?
  count_worker_nodes == target_worker_node_count
end

def count_worker_nodes
  get_worker_nodes
    .find_all { |node| node_ready?(node) }
    .count
end

def get_nodes
  JSON.parse(execute("kubectl get nodes -o json")).dig("items")
end

def get_worker_nodes
  get_nodes.find_all { |node| worker_node?(node) }
end

def node_ready?(node)
  node_conditions = node.dig("status", "conditions")
  node_conditions.map { |c| c.dig("reason") }.include?("KubeletReady")
end

def recylable_instance_group_names
  recylable_instance_groups
    .map { |doc| doc.dig("metadata", "name") }
end

def recylable_instance_groups
  YAML.load_stream(get_kops_config)
    .find_all { |doc| doc.dig("metadata", "labels", INSTANCE_GROUP_LABEL) == "true" }
end

def worker_node?(node)
  instance_group = node.dig("metadata", "labels", "kops.k8s.io/instancegroup")

  node.dig("metadata", "labels")["kubernetes.io/role"] == "node" \
    && recylable_instance_group_names.include?(instance_group)
end

def target_worker_node_count
  recylable_instance_groups
    .map { |s| s.dig("spec", "minSize") }.sum
end

def get_kops_config
  Net::HTTP.get(URI(KOPS_CONFIG_URL))
end

def get_oldest_worker_node
  get_worker_nodes
    .min_by { |node| node.dig("metadata", "creationTimestamp") }
end

def cordon_node(node)
  name = node_name(node)
  cmd = "kubectl cordon #{name}"
  execute(cmd)
end

def stuck_pods(node)
  name = node_name(node)
  cmd = "kubectl get pods --all-namespaces -o json --field-selector spec.nodeName=#{name}"
  all_pods = JSON.parse(execute(cmd)).fetch("items")

  rtn = []

  all_pods.map do |pod|
    pod.dig("status", "containerStatuses").map do |c|
      container_state = c.dig("state", "waiting", "reason") # If container is not 'waiting', this will be nil
      rtn << pod if STUCK_STATES.include?(container_state)
    end
  end

  rtn
end

def delete_pod(pod)
  namespace = pod.dig("metadata", "namespace")
  name = pod.dig("metadata", "name")
  execute("kubectl -n #{namespace} delete pod #{name}")
end

def drain_node(node)
  name = node_name(node)

  cmd = "kubectl --ignore-daemonsets --delete-local-data drain #{name}"
  success = exec_with_timeout(cmd, NODE_DRAIN_TIMEOUT)

  if success
    log "worker node #{name} drained sucessfully."
  else
    raise "worker node #{name} failed to drain. Aborting."
  end
end

def node_name(node)
  node.dig("metadata", "name")
end

def get_latest_node_details(node)
  name = node_name(node)
  JSON.parse(execute("kubectl get node #{name} -o json"))
end

def delete_node(node)
  name = node_name(node)

  if cordoned?(node)
    execute "kubectl delete node #{name}"
  else
    raise "worker node #{name} was not cordoned."
  end
end

def terminate_node(node)
  if cordoned?(node)
    execute "aws ec2 terminate-instances --instance-ids #{aws_instance_id(node)} --region #{AWS_REGION}"
  else
    raise "worker node #{name} was not cordoned."
  end
end

def aws_instance_id(node)
  node.dig("spec", "providerID").split("/").last
end

def cordoned?(node)
  node.dig("spec").fetch("unschedulable", false)
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

def log(msg)
  puts [Time.now.strftime("%Y-%m-%d %H:%M:%S"), msg].join(" ")
end

def cmd_successful?(cmd)
  log cmd
  system cmd
end

def execute(cmd)
  log cmd
  `#{cmd}`
end

# https://stackoverflow.com/questions/8292031/ruby-timeouts-and-system-commands
def exec_with_timeout(cmd, timeout)
  log "CMD: #{cmd}, TIMEOUT: #{timeout}"

  pid = Process.spawn(cmd)

  begin
    Timeout.timeout(timeout) do
      Process.waitpid(pid, 0)
      $?.exitstatus == 0
    end
  rescue Timeout::Error
    begin
      Process.kill(SIGTERM, -Process.getpgid(pid))
      false # We never reach this point, although we should.
    rescue SignalException
      # https://ruby-doc.org/core-2.6.3/Process.html#method-c-kill
      # For some reason, when we send SIGTERM to the spawned
      # process, the parent process (us) also receives SIGTERM.
      # AFAICT from the documentation, this shouldn't be happening,
      # but it is, so we need to rescue it.
      false
    end
  end
end

main
