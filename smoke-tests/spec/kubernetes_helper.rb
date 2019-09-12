def current_cluster
  `kubectl config current-context`.chomp
end

def all_namespaces
  json = `kubectl get namespaces -o json`
  JSON.parse(json).fetch("items")
end

def create_namespace(namespace, opts = {})
  unless namespace_exists?(namespace)
    `kubectl create namespace #{namespace}`

    10.times do
      break if namespace_exists?(namespace)
      sleep 1
    end

    if annotations = opts[:annotations]
      `kubectl annotate --overwrite namespace #{namespace} '#{annotations}'`
    end
  end
end

def namespace_exists?(namespace)
  execute("kubectl get namespace #{namespace} > /dev/null 2>&1")
end

def delete_namespace(namespace)
  `kubectl delete namespace #{namespace}`
end

def delete_deployment(namespace, deployment)
  `kubectl -n #{namespace} delete deployment #{deployment}`
end

def apply_template_file(args)
  namespace = args.fetch(:namespace)
  file = args.fetch(:file)
  binding = args.fetch(:binding)

  renderer = ERB.new(File.read(file))
  yaml = renderer.result(binding)

  apply_yaml(namespace, yaml)
end

def apply_yaml_file(args)
  namespace = args.fetch(:namespace)
  file = args.fetch(:file)
  apply_yaml(namespace, File.read(file))
end

def apply_yaml(namespace, yaml)
  `kubectl -n #{namespace} apply -f - <<EOF\n#{yaml}\nEOF\n`
end

def wait_for(namespace, type, name, seconds = 10)
  seconds.times do
    break if object_exists?(namespace, type, name)
    sleep 1
  end
end

def object_exists?(namespace, type, name)
  execute("kubectl -n #{namespace} get #{type} #{name} > /dev/null")
end

def create_job(namespace, yaml_file, args)
  job_name = args.fetch(:job_name)
  search_url = args[:search_url]

  apply_template_file(namespace: namespace, file: yaml_file, binding: binding)
  wait_for_job_to_start(namespace, job_name)
end

def wait_for_job_to_start(namespace, job_name)
  controlled_by = "Job/#{job_name}"
  command = "kubectl describe pods -n #{namespace} | grep -B 2 #{controlled_by} | grep Succeeded > /dev/null"
  done = execute(command)

  10.times do
    break if done
    sleep 1
    done = execute(command)
  end

  raise "Job failed to start in #{namespace}" unless done
end

def execute(command)
  # puts command
  system command
end

def get_pod_logs(namespace, pod_name)
  `kubectl -n #{namespace} logs #{pod_name}`
end

def get_pods(namespace)
  JSON.parse(`kubectl -n #{namespace} get pods -o json`).fetch("items")
end

def get_running_app_pods(namespace, app, property = "app")
  get_running_pods(namespace)
    .filter { |pod| pod.dig("metadata", "labels", property) == app }
end

def get_running_pods(namespace)
  get_pods(namespace)
    .filter { |pod| pod.dig("status", "phase") == "Running" }
end

def all_containers_running?(pods)
  all_container_states = pods.map { |pod| pod.dig("status", "containerStatuses") }
    .flatten
    .map { |container| container.fetch("state").keys }
    .flatten

  all_container_states.uniq == ["running"]
end

def get_pod_matching_name(namespace, prefix)
  get_pods(namespace)
    .filter { |pod| pod.dig("metadata", "name") =~ %r{^#{prefix}} }
    .first
end

# Get all nodes an app runs on
def get_app_node_ips(namespace, app, status = "Running")
  pod_ips get_running_app_pods(namespace, app)
end

def pod_ips(pods)
  pods
    .map { |pod| pod.dig("status", "hostIP") }
    .sort
end

# Get the internal IPs of all cluster VMs
def get_cluster_ips
  node_ips get_nodes
end

def node_ips(nodes)
  nodes
    .map { |node| node.dig("status", "addresses").filter { |addr| addr.dig("type") == "InternalIP" } }
    .flatten
    .map { |i| i.fetch("address") }
    .sort
end

def master_nodes
  filter_by_role(get_nodes, "master")
end

def worker_nodes
  filter_by_role(get_nodes, "node")
end

def filter_by_role(nodes, role)
  nodes.filter { |node| node.dig("metadata", "labels", "kubernetes.io/role") == role }
end

def get_nodes
  JSON.parse(`kubectl get nodes -o json`).fetch("items")
end

def get_daemonsets
  JSON.parse(`kubectl get daemonsets --all-namespaces -o json`).fetch("items")
end
