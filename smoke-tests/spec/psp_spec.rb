require "spec_helper"

# Pod security policies (PSP) is a cluster-level resource that
# controls security sensitive aspects of the pod specification.
# This spec confirms the Cloud Platform psp's are operational
# within its cluster.
describe "pod security policies" do
  let(:namespace) { "integrationtest-psp-#{readable_timestamp}" }
  let(:pods) { get_running_pods(namespace) }

  # Confirms the main psp's currently exist
  specify "has the expected policies" do
    names = get_psp.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "privileged",
      "restricted"
    ]
    expect(names).to include(*expected)
  end

  # Creates a privileged container in a privileged and unprivileged namespace.
  # Expected behaviour, the privileged container will run in the privileged namespace
  # and fail in the unprivileged namespace.
  context "when a container requires privileges" do
    let(:deployment_file) { "spec/fixtures/privileged-deployment.yaml.erb" }

    before do
      create_namespace(namespace)
    end

    after do
      delete_namespace(namespace)
    end

    it "runs in a privileged namespace" do
      make_namespace_privileged(namespace)
      create_psp_deployment(namespace, deployment_file)
      # On occasion the expect runs before the container runs.
      # Sleep for ten seconds to avoid this.
      sleep 10

      expect(all_containers_running?(pods)).to eq(true)
      delete_clusterrolebinding(namespace)
    end

    it "fails in an unprivileged namespace" do
      create_psp_deployment(namespace, deployment_file)

      expect(all_containers_running?(pods)).to eq(false)
    end
  end

  # Creates an unprivileged container in a privileged and unprivileged namespace.
  # Expected behaviour, the container is able to run in both namespaces.
  context "when a container doesn't require privileges" do
    let(:deployment_file) { "spec/fixtures/unprivileged-deployment.yaml.erb" }

    before do
      create_namespace(namespace)
    end

    after do
      delete_namespace(namespace)
    end

    it "runs in a privileged namespace" do
      make_namespace_privileged(namespace)

      create_psp_deployment(namespace, deployment_file)
      # On occasion the expect runs before the container runs.
      # Sleep for ten seconds to avoid this.
      sleep 10
      expect(all_containers_running?(pods)).to eq(true)
      delete_clusterrolebinding(namespace)
    end

    it "runs in a unprivileged namespace" do
      create_psp_deployment(namespace, deployment_file)
      # On occasion the expect runs before the container runs.
      # Sleep for ten seconds to avoid this.
      sleep 10
      expect(all_containers_running?(pods)).to eq(true)
    end
  end
end

# Creates a clusterrolebinding between the privileged psp
# and the namespaces default service account.
def make_namespace_privileged(namespace)
  json = <<~EOF
    {
      "apiVersion": "rbac.authorization.k8s.io/v1",
      "kind": "ClusterRoleBinding",
      "metadata": {
          "name": "#{namespace}"
      },
      "roleRef": {
          "apiGroup": "rbac.authorization.k8s.io",
          "kind": "ClusterRole",
          "name": "psp:privileged"
      },
      "subjects": [
          {
              "apiGroup": "rbac.authorization.k8s.io",
              "kind": "Group",
              "name": "system:serviceaccounts:#{namespace}"
          }
      ]
    }
  EOF

  jsn = JSON.parse(json).to_json

  cmd = %(echo '#{jsn}' | kubectl -n #{namespace} apply -f -)
  execute(cmd)
end

# Creates a deplyoment using the arguments defined
def create_psp_deployment(namespace, deployment_file)
  apply_template_file(
    namespace: namespace,
    file: deployment_file,
    binding: binding
  )
end
