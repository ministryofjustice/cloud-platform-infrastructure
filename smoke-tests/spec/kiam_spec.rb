require "spec_helper"

describe "kiam" do

  # Do not use a dynamically-generated role_name here. This test
  # only works using a stable set of AWS entities
  role_args = {
    role_name: KIAM_ROLE_NAME,
    account_id: AWS[:account_id],
    aws_region: AWS[:region],
    kubernetes_cluster: current_cluster
  }

  pod = ""  # name of the running pod in our namespace

  # we want to use the same role every time, so we're not going to clean this up
  role = fetch_or_create_role(role_args)

  let(:namespace) { "integrationtest-kiam-#{random_string}-#{readable_timestamp}" }

  before do
    create_namespace(namespace, namespace_annotations)
    pod = create_deployment(namespace)
  end

  after do
    delete_namespace(namespace)
  end

  context "namespace has annotations" do
    let(:namespace_annotations) { { annotations: "iam.amazonaws.com/permitted=.*" } }

    context "pod has annotations" do
      it "can assume role" do
        json = try_to_assume_role(namespace: namespace, pod: pod, role_arn: role.arn)
        result = JSON.parse(json).has_key?("Credentials")
        expect(result).to be true
      end
    end

  #   context "pod does not have annotations" do
  #     it "cannot assume role"
  #   end

  end

  # context "namespace does not have annotations" do
  #   context "pod has annotations" do
  #     it "cannot assume role"
  #   end
  # end

  context "namespace has no annotations" do
    let(:namespace_annotations) { {} }

    #   context "pod has annotations" do

    context "when namespace whitelists *" do
      it "cannot assume role" do
        result = try_to_assume_role(namespace: namespace, pod: pod, role_arn: role.arn)
        expect(result).to match(/Unable to locate credentials/)
      end
    end

    # end

    #
    #   context "pod does not have annotations" do
    #     it "cannot assume role"
    #   end

  end
end
