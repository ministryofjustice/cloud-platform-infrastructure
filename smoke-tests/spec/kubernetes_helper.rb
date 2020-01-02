def current_cluster
  `kubectl config current-context`.chomp
end

def all_namespaces
  kubectl_items "get namespaces"
end

def create_namespace(namespace, opts = {})
  unless namespace_exists?(namespace)
    `kubectl create namespace #{namespace}`
    `kubectl annotate --overwrite namespace #{namespace} 'cloud-platform-integration-test=default'`

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
  Open3.capture3("kubectl -n #{namespace} apply -f - <<EOF\n#{yaml}\nEOF\n")
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
  kubectl_items "get pods -n #{namespace}"
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
  kubectl_items "get nodes"
end

def get_daemonsets
  get_from_all_namespaces "daemonsets"
end

def get_crds
  get_from_all_namespaces "crds"
end

# CRD certificates.certmanager.k8s.io
def get_certificates
  get_from_all_namespaces "certificate"
end

# CRD issuers.certmanager.k8s.io
def get_issuers
  get_from_all_namespaces "issuers"
end

# CRD clusterissuers.certmanager.k8s.io
def get_clusterissuers
  get_from_all_namespaces "clusterissuers"
end

# CRD prometheuses.monitoring.coreos.com
def get_prometheuses
  get_from_all_namespaces "prometheus"
end

# CRD prometheusrules.monitoring.coreos.com
def get_prometheus_rules
  get_from_all_namespaces "prometheusrules"
end

# CRD alertmanagers.monitoring.coreos.com
def get_alertmanagers
  get_from_all_namespaces "alertmanagers"
end

def get_from_all_namespaces(entity)
  kubectl_items "get #{entity} --all-namespaces"
end

def get_servicemonitors(namespace)
  kubectl_items "get servicemonitors -n #{namespace}"
end

def kubectl_items(cmd)
  JSON.parse(`kubectl #{cmd} -o json`).fetch("items")
end

# Set the enable-modsecurity flag to false on the ingress annotation
def set_modsec_ing_annotation_false(namespace, ingress_name)
  `kubectl -n #{namespace} annotate --overwrite ingresses/#{ingress_name} nginx.ingress.kubernetes.io/enable-modsecurity='false'`.chomp
end

def scale_replicas(namespace, deployment, replicas = "")
  `kubectl -n #{namespace} scale deployment #{deployment} --replicas=#{replicas}`
end

def annotate_ingress(namespace, ingress, annotations)
  `kubectl -n #{namespace} annotate ingress #{ingress} #{ing_annotations.join(" ")}`
end
