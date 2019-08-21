require "spec_helper"
require 'tempfile'

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

  let(:namespace) { "integrationtest-kiam-#{random_string}-#{readable_timestamp}" }

  # There is no after(:all) cleanup, because we want to use the same role every time
  before(:all) do
    create_role_if_not_exists(role_args)
  end

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
      create_deployment(namespace)
      sleep 30 # TODO: replace with a wait loop that checks for a running pod
    end

    after do
      delete_namespace(namespace)
    end

    context "when namespace whitelists *" do
      it "can assume role" do
        # TODO: get the role_arn via the AWS gem
        json = try_to_assume_role(namespace: namespace, role_arn: "arn:aws:iam::754256621582:role/test-kiam-iam-role")
        result = JSON.parse(json).has_key?("Credentials")
        expect(result).to be true
      end
    end
  end

  context "namespace has no annotations" do
    before do
      create_namespace(namespace)
      create_deployment(namespace)
      sleep 30 # TODO: replace with a wait loop that checks for a running pod
    end

    after do
      delete_namespace(namespace)
    end

    context "when namespace whitelists *" do
      it "cannot assume role" do
        result = try_to_assume_role(namespace: namespace, role_arn: "arn:aws:iam::754256621582:role/test-kiam-iam-role")
        expect(result).to match(/Unable to locate credentials/)
      end
    end
  end
end

def try_to_assume_role(args)
  namespace = args.fetch(:namespace)
  pod = get_pod_name(namespace, 0) # there is only one pod, get the name of the first
  role_arn = args.fetch(:role_arn)

  cmd = %[kubectl exec -n #{namespace} #{pod} -- aws sts assume-role --role-arn "#{role_arn}" --role-session-name dummy]
  `#{cmd} 2>&1`
end

def create_role_if_not_exists(args)
  role_name = args.fetch(:role_name)
  kubernetes_cluster = args.fetch(:kubernetes_cluster)
  account_id = args.fetch(:account_id)
  aws_region = args.fetch(:aws_region)

  unless role_exists?(role_name, aws_region)
    create_role(role_name, kubernetes_cluster, account_id, aws_region)
  end
end

def role_exists?(role_name, aws_region)
  client = Aws::IAM::Client.new(region: aws_region)

  begin
    !!client.get_role(role_name: role_name)
  rescue Aws::IAM::Errors::NoSuchEntity
    false
  end
end

def create_role(role_name, kubernetes_cluster, account_id, aws_region)
  client = Aws::IAM::Client.new(region: aws_region)
  iam = Aws::IAM::Resource.new(client: client)

  policy_doc = {
    Version:"2012-10-17",
    Statement:[
      {
        Effect:"Allow",
        Principal:{
          AWS: "arn:aws:iam::#{account_id}:role/nodes.#{kubernetes_cluster}"
        },
        Action:"sts:AssumeRole"
      }
    ]
  }

  role = iam.create_role(
    role_name: role_name,
    assume_role_policy_document: policy_doc.to_json,
  )

  client.wait_until(:role_exists, role_name: role_name)

  # TODO: Needs to be created at runtime
  role.attach_policy(policy_arn: 'arn:aws:iam::754256621582:policy/test-kiam-policy')
end

# TODO: pass in image name
# TODO: move to kubernetes_helper
# TODO: pass in command
# TODO: pass in annotations
def create_deployment(namespace)
  json = <<~EOF
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": { "name": "test-kiam-deployment" },
    "spec": {
      "selector": { "matchLabels": { "app": "not-needed" } },
      "template": {
        "metadata": {
          "annotations": { "iam.amazonaws.com/role": "test-kiam-iam-role" },
          "labels": { "app": "not-needed" }
        },
        "spec": {
          "securityContext": {
            "runAsUser": 1000,
            "runAsGroup": 3000
          },
          "containers": [
            {
              "name": "tools-image",
              "image": "754256621582.dkr.ecr.eu-west-2.amazonaws.com/cloud-platform/tools",
              "command": [ "sleep", "86400" ]
            }
          ]
        }
      }
    }
  }
  EOF

  # collapse the json onto a single line
  jsn = JSON.parse(json).to_json

  cmd = %[echo '#{jsn}' | kubectl -n #{namespace} apply -f -]

  `#{cmd}`
end
