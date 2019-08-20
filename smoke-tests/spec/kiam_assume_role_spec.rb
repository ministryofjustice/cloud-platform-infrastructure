require "spec_helper"
require 'tempfile'
###################
#create a namespace with annotations
#Create a role
#with a assume_role with and without right permissions
#create an annotation for a pod
# test whether the pod runs with assume role with namespace and pod annotations
# test whether the pod runs without correct assume role without namespace and pod annotations

describe "kiam" do
  # Do not use a dynamically-generated rolename here. This test
  # only works using a stable set of AWS entities
  rolename = "test-kiam-iam-role"
  account_id = "754256621582"
  aws_region = "eu-west-2"
  kubernetes_cluster = current_cluster

  let(:namespace) { "integrationtest-kiam-#{random_string}-#{readable_timestamp}" }

  # There is no after(:all) cleanup, because we want to use the same role every time
  before(:all) do
    create_role_if_not_exists(rolename, kubernetes_cluster, account_id, aws_region)
  end

  context "namespace annotations allow assuming role" do
    before do
      create_namespace(namespace, annotations: %[iam.amazonaws.com/permitted=.*])
    end

    context "when namespace whitelists *" do
      it "can assume role" do
        puts namespace
        result = try_to_assume_role(rolename, account_id, aws_region, kubernetes_cluster, namespace)
        expect(result).to match(/SUCCESS: Pod able to AssumeRole/)
      end
    end
  end

  context "namespace has no annotations" do
    before do
      create_namespace(namespace)
    end

    after do
      delete_namespace(namespace)
    end

    context "when namespace whitelists *" do
      it "cannot assume role" do
        result = try_to_assume_role(rolename, account_id, aws_region, kubernetes_cluster, namespace)
        expect(result).to match(/Aws::STS::Errors => Unable to AssumeRole/)
      end
    end
  end
end

# TODO: no positional arguments
def try_to_assume_role(rolename, account_id, aws_region, kubernetes_cluster, namespace)
  create_job(namespace, "spec/fixtures/iam-assume-role-job.yaml.erb", {
    job_name: "integration-test-kiam-assume",
    role: rolename,
    account_id: account_id,
    aws_region: aws_region,
    kubernetes_cluster: kubernetes_cluster
  })

  #get_pod_name
  pod = `kubectl -n #{namespace} get pods`.split(" ")
  result = `kubectl -n #{namespace} logs #{pod[5]}`
  result
end

def create_role_if_not_exists(rolename, kubernetes_cluster, account_id, aws_region)
  unless role_exists?(rolename, aws_region)
    create_role(rolename, kubernetes_cluster, account_id, aws_region)
  end
end

def role_exists?(rolename, aws_region)
  client = Aws::IAM::Client.new(region: aws_region)

  begin
    !!client.get_role(role_name: rolename)
  rescue Aws::IAM::Errors::NoSuchEntity
    false
  end
end

def create_role(rolename, kubernetes_cluster, account_id, aws_region)
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
    role_name: rolename,
    assume_role_policy_document: policy_doc.to_json,
  )

  client.wait_until(:role_exists, role_name: rolename)

  # Needs to be created at runtime
  role.attach_policy(policy_arn: 'arn:aws:iam::754256621582:policy/test-kiam-policy')
end
