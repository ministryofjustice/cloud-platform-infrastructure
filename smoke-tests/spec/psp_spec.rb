require "spec_helper"

# Pod security policies (PSP) is a cluster-level resource that
# controls security sensitive aspects of the pod specification.
# This spec confirms the Cloud Platform psp's are operational
# within its cluster.
describe "pod security policies" do
  let(:namespace) { "integrationtest-psp-#{readable_timestamp}" }
  let(:pods) { get_running_pods(namespace)}

  # Confirms the main psp's currently exist
  specify "has the expected policies" do
    names = get_psp.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "privileged",
      "restricted",
      "kube-system"
    ]
    expect(names).to include(*expected)
  end


  # Checks a privileged container i.e. something that can either run
  # as root or esculate its privilege in someway, can only run
  # inside select namespaces.
  context "a privileged container" do

    before do
      create_namespace(namespace)
    end

    # after do
    #   # delete_namespace(namespace)
    # end

    it "cannot run inside non-privileged namespaces" do
      create_privileged_deploy(namespace)
      expect(all_containers_running?(pods)).to eq(false)
    end

    it "can run inside privileged namespaces" do
      make_namespace_privileged(namespace)
      create_privileged_deploy(namespace)

      expect(all_containers_running?(pods)).to eq(true)
      delete_clusterrolebinding(namespace)
    end
  end

  # Checks unprivileged containers i.e. non-root user, can run
  # anywhere.
  context "restricted containers" do
    it "can run inside non-privileged namespaces" do
      create_unprivileged_deploy(namespace)
      expect(all_containers_running?(pods)).to eq(true)
    end

    it "can run inside privileged namespaces" do
      make_namespace_privileged(namespace)
      create_unprivileged_deploy(namespace)

      expect(all_containers_running?(pods)).to eq(true)
      delete_clusterrolebinding(namespace)
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
