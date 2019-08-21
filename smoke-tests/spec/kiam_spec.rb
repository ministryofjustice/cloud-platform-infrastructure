require "spec_helper"

TOOLS_IMAGE = "754256621582.dkr.ecr.eu-west-2.amazonaws.com/cloud-platform/tools"

describe "kiam" do

  # Do not use a dynamically-generated role_name here. This test
  # only works using a stable set of AWS entities
  role_args = {
    role_name: "test-kiam-iam-role",
    account_id: "754256621582",
    aws_region: "eu-west-2",
    kubernetes_cluster: current_cluster
  }

  pod = ""  # name of the running pod in our namespace

  # we want to use the same role every time, so we're not going to clean this up
  role = create_role_if_not_exists(role_args)
  role_arn = role.to_h.dig(:role, :arn)

  let(:namespace) { "integrationtest-kiam-#{random_string}-#{readable_timestamp}" }

  # context "namespace has annotations" do
  #   context "pod has annotations" do
  #     it "can assume role"
  #   end
  #
  #   context "pod does not have annotations" do
  #     it "cannot assume role"
  #   end
  # end
  #
  # context "namespace does not have annotations" do
  #   context "pod has annotations" do
  #     it "cannot assume role"
  #   end
  #
  #   context "pod does not have annotations" do
  #     it "cannot assume role"
  #   end
  # end

  context "namespace annotations allow assuming role" do
    before do
      create_namespace(namespace, annotations: %[iam.amazonaws.com/permitted=.*])
      pod = create_deployment(namespace)
    end

    after do
      delete_namespace(namespace)
    end

    context "when namespace whitelists *" do
      it "can assume role" do
        json = try_to_assume_role(namespace: namespace, pod: pod, role_arn: role_arn)
        result = JSON.parse(json).has_key?("Credentials")
        expect(result).to be true
      end
    end
  end

  context "namespace has no annotations" do
    before do
      create_namespace(namespace)
      pod = create_deployment(namespace)
    end

    after do
      delete_namespace(namespace)
    end

    context "when namespace whitelists *" do
      it "cannot assume role" do
        result = try_to_assume_role(namespace: namespace, pod: pod, role_arn: role_arn)
        expect(result).to match(/Unable to locate credentials/)
      end
    end
  end
end
