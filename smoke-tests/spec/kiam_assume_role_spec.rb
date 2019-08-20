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
  let(:rolename) { "test-kiam-iam-role" }

  let(:namespace) { "integrationtest-kiam-#{readable_timestamp}" }
  let(:account_id) { "754256621582" }
  let(:aws_region) { "eu-west-2" }

  kubernetes_cluster = current_cluster

  context "when role  have permissions to assume role on the pod" do
    before do
      puts "creating namespace"
      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/namespace-annotations.yaml.erb",
        binding: binding
      )
      #json = set_json_file(
      #  file: "spec/fixtures/test-kiam-assume-role-policy-document.json.erb",
      #  account_id: account_id,
      #  kubernetes_cluster: kubernetes_cluster,
      #  binding: binding
      #)
      #t = Tempfile.new("test_temp")
      #t.write(json)
      #t.close
      #create_iam_with_assumerole(rolename,t.path)
      #puts "creating role"
      create_role_if_not_exists(rolename, kubernetes_cluster, account_id, aws_region)
      #sleep 60
    end

    after do
      #delete_namespace(namespace)
      #puts "deleting namespace"
      #delete_role(rolename, aws_region)
      #sleep 10
      #puts "deleting job"
      #`kubectl delete job integration-test-kiam-assume -n #{namespace}`
      #sleep 10
      #delete_iam_with_assumerole(rolename)
    end

    context "when namespace whitelists *" do
      it "can assume role" do
        puts "trying test"
        sleep 10
        result = try_to_assume_role(rolename)
        expect(result).to match(/SUCCESS: Pod able to AssumeRole/)
      end
    end
  end


  #context "when role doesnot have permissions to assume on the pod" do
  #  let(:rolename) { "test-kiam-iam-role" }
  #    before do
  #      apply_template_file(
  #        namespace: namespace,
  #        file: "spec/fixtures/namespace-annotations.yaml.erb",
  #        binding: binding
  #      )
  #      json = set_json_file(
  #        file: "spec/fixtures/test-kiam-assume-role-policy-document.json.erb",
  #        account_id: account_id,
  #        kubernetes_cluster: kubernetes_cluster,
  #        binding: binding
  #      )

  #      t = Tempfile.new("test_temp")
  #      t.write(json)
  #      t.close
  #      create_iam_without_assumerole(rolename,t.path)
  #    end
  #
  #    after do
  #      delete_namespace(namespace)
  #      delete_iam_without_assumerole(rolename)
  #    end
  #    context "when namespace whitelists *" do
  #      it "can assume role" do
  #        result = try_to_assume_role(rolename)
  #        expect(result).to match(/Aws::STS::Errors => Unable to AssumeRole/)
  #      end
  #    end
  #end
end

def try_to_assume_role(rolename)
  puts "creating job"
  kubernetes_cluster = current_cluster
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

def delete_role(rolename, aws_region)
  client = Aws::IAM::Client.new(region: aws_region)
  iam = Aws::IAM::Resource.new(client: client)

  resp = client.detach_role_policy({
    role_name: rolename,# required
    policy_arn: 'arn:aws:iam::754256621582:policy/test-kiam-policy', # required
  })

  client.delete_role({
    role_name: rolename,
  })
end

def create_role_if_not_exists(rolename, kubernetes_cluster, account_id, aws_region)
  unless role_exists?(rolename, aws_region)
    create_role(rolename, kubernetes_cluster, account_id, aws_region)
  end
end

def role_exists?(rolename, aws_region)
  client = Aws::IAM::Client.new(region: aws_region)
  iam = Aws::IAM::Resource.new(client: client)

  begin
    !!client.get_role(role_name: rolename)
  rescue Aws::IAM::Errors::NoSuchEntity => e
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

  role = iam.create_role({
    role_name: rolename,
    assume_role_policy_document: policy_doc.to_json,
  })

  client.wait_until(:role_exists, role_name: rolename)

# Needs to be created at runtime
  role.attach_policy({
  policy_arn: 'arn:aws:iam::754256621582:policy/test-kiam-policy'
})
end
