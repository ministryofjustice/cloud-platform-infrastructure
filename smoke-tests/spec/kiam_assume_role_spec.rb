require "spec_helper"
# Prerequsities
###################
#Create a role 
#
#with a assume_role with right permissions
#createa an annotation for the namespace
#create an annotation for a pod 
# test whether the pod runs with assume role with namespace annotations and pod annotations
# test whether the pod runs with assume role without namespace annoations and with pod annotations and viceversa



describe "kiam" do
  #let(:role) { ENV.fetch('ROLE_NAME') }
  let(:namespace) { "integrationtest-kiam-#{Time.now.to_i}" }
  let(:account_id) { ENV.fetch('ACCOUNT_ID') }
  let(:aws_region) { ENV.fetch('AWS_REGION') }
  let(:kubernetes_cluster) { ENV.fetch('KUBERNETES_CLUSTER') }

  context "when pod is allowed to assume role" do
    let(:rolename) { "test-kiam-iam-role" }
    before do
      create_namespace(namespace)
      sleep 10
      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/namespace-annotations.yaml.erb",
        binding: binding
      )
      create_iam_with_assumerole(rolename)
      sleep 60
    end
  
    after do
      #delete_namespace(namespace)
      delete_iam_with_assumerole(rolename)
    end
    context "when namespace whitelists *" do
      it "can assume role" do
        result = try_to_assume_role(rolename)
        expect(result).to match(/SUCCESS: Pod able to AssumeRole/)
      end
    end
  end
 

#     context "when namespace whitelists the role*" do
#       let(:namespace_role_whitelist) { "foo,#{role},bar" }

#       it "can assume role" do
#         expect {
#           try_to_assume_role(role)
#         }.to_not raise_error(AWS::RoleError)
#       end
#     end

    # context "when namespace whitelists other roles" do
    #   let(:pod_role_whitelist) { "foo" }

    #   it "cannot assume role" do
    #     expect {
    #       try_to_assume_role(pod_role_whitelist)
    #     }.to raise_error(RuntimeError)
    #   end
    # end

#     context "when namespace whitelists no roles" do
#       let(:namespace_role_whitelist) { "" }

#       it "cannot assume role" do
#         expect {
#           try_to_assume_role(role)
#         }.to raise_error(AWS::RoleError)
#       end
#     end
#   end

context "when pod is allowed to assume role" do
  let(:rolename) { "test-kiam-iam-role" }
    before do
      create_namespace(namespace)
      sleep 10
      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/namespace-annotations.yaml.erb",
        binding: binding
      )
      create_iam_without_assumerole(rolename)
      sleep 60
    end
  
    after do
      #delete_namespace(namespace)
      delete_iam_without_assumerole(rolename)
    end
    context "when namespace whitelists *" do
      it "can assume role" do
        result = try_to_assume_role(rolename)
        expect(result).to match(/Aws::STS::Errors => Unable to AssumeRole/)
      end
    end
end


#   context "when pod is allowed to assume other roles" do
#     let(:pod_role_whitelist) { ["foo", "bar"] }

#     context "when namespace whitelists *" do
#       let(:namespace_role_whitelist) { "*" }

#       it "can assume role" do
#         expect {
#           try_to_assume_role(role)
#         }.to_not raise_error(AWS::RoleError)
#       end
#     end
#   end
end

def try_to_assume_role(role)

  # this pod returns 'I can assume role' if AssumeRole for given role is permitted
  create_job(namespace, "spec/fixtures/iam-assume-role-job.yaml.erb", {
    job_name: "integration-test-kiam-assume-role-job",
    role: role,
    account_id: account_id,
    aws_region: aws_region,
    kubernetes_cluster: kubernetes_cluster
  })
  pod = `kubectl -n #{namespace} get pods`.split(" ")
  result = `kubectl -n #{namespace} logs #{pod[5]}`
  result
end