require "spec_helper"

# Kiam will enable code running in the cluster to assume an AWS role if
# both the pod and the namespace are annotated appropriately.
describe "kiam" do
  KIAM_ROLE_NAME = "integration-test-kiam-iam-role"

  # Do not use a dynamically-generated role_name here. This test
  # only works using a stable set of AWS entities
  # Note: If you run these tests when the role/policy setup does not exist, the
  # test will create it. But, you might see failures on the first few runs. It
  # seems to take a while for things to 'settle' on AWS.
  # The error you might see includes 'An error occurred (InvalidClientTokenId)'
  # If you see that error, wait a few minutes and retry.
  role_args = {
    role_name: KIAM_ROLE_NAME,
    account_id: AWS[:account_id],
    aws_region: AWS[:region],
    kubernetes_cluster: current_cluster,
  }

  pod = "" # name of the running pod in our test namespace

  # we want to use the same role every time, so we're not going to clean this up
  role = fetch_or_create_role(role_args)

  let(:namespace) { "integrationtest-kiam-#{random_string}-#{readable_timestamp}" }

  let(:assume_role_args) {
    {
      namespace: namespace,
      pod: pod,
      role_arn: role.arn,
      pod_annotations: pod_annotations,
    }
  }

  before do
    create_namespace(namespace, namespace_annotations)
    pod = create_deployment(namespace: namespace, pod_annotations: pod_annotations)
  end

  after do
    delete_namespace(namespace)
  end

  after(:all) do
    remove_cluster_nodes_from_trust_relationship(role_args, role)
  end

  context "namespace has annotations" do
    let(:namespace_annotations) { {annotations: "iam.amazonaws.com/permitted=.*"} }

    context "pod has annotations" do
      let(:pod_annotations) { {"iam.amazonaws.com/role" => KIAM_ROLE_NAME} }

      it "can assume role" do
        json = try_to_assume_role(assume_role_args)
        result = JSON.parse(json).key?("Credentials")
        expect(result).to be true
      end
    end

    context "pod does not have annotations" do
      let(:pod_annotations) { {} }

      it "cannot assume role" do
        result = try_to_assume_role(assume_role_args)
        expect(result).to match(/Unable to locate credentials/)
      end
    end
  end

  context "namespace has no annotations" do
    let(:namespace_annotations) { {} }

    context "pod has annotations" do
      let(:pod_annotations) { {"iam.amazonaws.com/role" => KIAM_ROLE_NAME} }

      it "cannot assume role" do
        result = try_to_assume_role(assume_role_args)
        expect(result).to match(/Unable to locate credentials/)
      end
    end

    context "pod does not have annotations" do
      let(:pod_annotations) { {} }

      it "cannot assume role" do
        result = try_to_assume_role(assume_role_args)
        expect(result).to match(/Unable to locate credentials/)
      end
    end
  end
end
