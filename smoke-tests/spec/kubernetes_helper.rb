def current_cluster
  `kubectl config current-context`.chomp
end

def create_namespace(namespace)
  unless namespace_exists?(namespace)
    `kubectl create namespace #{namespace}`

    10.times do
      break if namespace_exists?(namespace)
      sleep 1
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

# Get the name of the Nth pod in the namespace
def get_pod_name(namespace, index)
  `kubectl get pods -n #{namespace} | awk 'FNR == #{index + 1} {print $1}'`.chomp
end

