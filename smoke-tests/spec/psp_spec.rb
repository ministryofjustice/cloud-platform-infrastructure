require "spec_helper"

describe "pod security policies:" do
  # TODO: create a test to ensure priv and rest psp's exist
  # TODO: how do you create a priv namespace
  specify "has the expected policies" do
    names = get_psp.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "privileged",
      "restricted",
      "kube-system"
    ]
    expect(names).to include(*expected)
  end

    let(:namespace) { "integrationtest-psp-#{random_string}-#{readable_timestamp}" }

    before do
      create_namespace(namespace)
    end

    after do
      delete_namespace(namespace)
    end

  context "a privilege pod" do

    # it "cannot run inside non-privileged namespaces"
    it "can run inside privileged namespaces" do
      make_namespace_privileged(namespace)
    end
  end

  # context "restricted pod" do
  #   it "can run inside privileged namespaces"
  #   it "can run inside non-privileged namespaces"


  # Creates a clusterrolebinding between the privileged pod
  # security policy and the namespaces default service account
  def make_namespace_privileged(namespace)
    json = <<~EOF
      {
        "apiVersion": "rbac.authorization.k8s.io/v1",
        "kind": "ClusterRoleBinding",
        "metadata": {
            "name": "integration-test:#{namespace}"
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
end