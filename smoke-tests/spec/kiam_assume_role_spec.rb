require "spec_helper"
require "aws-sdk-iam"

describe "kiam" do
  let(:account_id) { "754256621582" }
  let(:aws_region) { "eu-west-2" }
  let(:namespace) { "integrationtest-kiam-#{Time.now.to_i}" }
  let(:pod_name) { "kiam-test" }
  let(:rolename) { "integrationtest-kiam" }
  kubernetes_cluster = current_cluster
  container_ref = nill

  before(:all) do
    create_namespace(namespace)
    create_role(rolename, kubernetes_cluster, account_id, aws_region)
    container_ref = launch_pod(pod_name: pod_name, image: tools-image, cmd: "sleep 86400")
  end

  context "annotated pod and namespace"
    let(:annotation) {"iam.amazonaws.com/permitted=.*"}
    before do
      annotate_namespace(namespace, annotation)
      annotate_pod(namespace, pod_name, annotation)
    end

    it "can assume aws role" do
      output = `kubectl exec #{container_ref} aws sts-assume-role #{myrole}`
      expect(output).to match(success_message) # was able to assume role
    end

  context "unannotated pod and namespace"
    it "cannot assume aws role" do
      output = `kubectl exec #{container_ref} aws sts-assume-role #{myrole}`
      expect(output).to match(error_message) # was NOT able to assume role
    end

  after(:all) do
    delete_namespace(namespace)
    delete_role(name)
  end
end

#
#
#
#
#  context "when pod is able to assume aws role"
#    before do
#      create_namespace(namespace)
#
#      # apply_template_file(
#      #   namespace: namespace,
#      #   file: "spec/fixtures/namespace-annotations.yaml.erb",
#      #   binding: binding
#      # )
#      annotate_namespace(namespace)
#      
#      # creates the json policy to be assumed in the role, is there an 
#      # easier way to apply this?
#      json = set_json_file(
#        file: "spec/fixtures/test-kiam-assume-role-policy-document.json.erb",
#        account_id: account_id,
#        kubernetes_cluster: kubernetes_cluster,
#        binding: binding
#      )
#      # application of the role creation, tidy this up
#      t = Tempfile.new("test_temp")
#      t.write(json) 
#      t.close
#      create_iam_with_assumerole(rolename,t.path)
#    end
#  
#    after do
#      delete_namespace(namespace)
#      delete_iam_with_assumerole(rolename)
#    end
#
#    # rename this context and make it easier to understand
#    context "when namespace whitelists *" do
#      it "can assume role" do
#        result = try_to_assume_role(rolename)
#        expect(result).to match(/SUCCESS: Pod able to AssumeRole/)
#      end
#    end
#  end
# 
#  # rename context to make it easier to understand
#  context "when role doesnot have permissions to assume on the  pod" do
#    let(:rolename) { "test-kiam-iam-role" }
#      before do
#        apply_template_file(
#          namespace: namespace,
#          file: "spec/fixtures/namespace-annotations.yaml.erb",
#          binding: binding
#        )
#        json = set_json_file(
#          file: "spec/fixtures/test-kiam-assume-role-policy-document.json.erb",
#          account_id: account_id,
#          kubernetes_cluster: kubernetes_cluster,
#          binding: binding
#        )
#
#        t = Tempfile.new("test_temp")
#        t.write(json) 
#        t.close
#        create_iam_without_assumerole(rolename,t.path)
#      end
#    
#      after do
#        delete_namespace(namespace)
#        delete_iam_without_assumerole(rolename)
#      end
#      context "when namespace whitelists *" do
#        it "can assume role" do
#          result = try_to_assume_role(rolename)
#          expect(result).to match(/Aws::STS::Errors => Unable to AssumeRole/)
#        end
#      end
#  end
#
#def try_to_assume_role(rolename)
#  kubernetes_cluster = current_cluster
#  create_job(namespace, "spec/fixtures/iam-assume-role-job.yaml.erb", {
#    job_name: "integration-test-kiam-assume-role-job",
#    role: rolename,
#    account_id: account_id,
#    aws_region: aws_region,
#    kubernetes_cluster: kubernetes_cluster
#  })
#
#  #get_pod_name
#  pod = `kubectl -n #{namespace} get pods`.split(" ")
#  result = `kubectl -n #{namespace} logs #{pod[5]}`
#  result
#end
