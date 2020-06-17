require "spec_helper"

describe "pod security policies" do
  PRIVILEGED_POLICY = "PodSecurityPolicy/privileged"
  RESTRICTED_POLICY = "PodSecurityPolicy/restricted"

  # let(:namespace) { "integrationtest-psp-#{random_string}-#{readable_timestamp}" }
  # TODO: create a test to ensure priv and rest psp's exist
  # TODO: how do you create a priv namespace
  it "has expected policies" do
    names = get_psp.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "privileged",
      "restricted",
      "kube-system"
    ]
    expect(names).to include(*expected)
  end
end
  # before do
  #   create_namespace(namespace)
  #   create_test_psp()
  # end

  # after do
  #   delete_namespace(namespace)
  #   delete_test_psp()
  # end

  # context "privilege pod" do
  #   it "cannot run inside non-privileged namespaces"
  #   it "can run inside privileged namespaces"
  # context "restricted pod" do
  #   it "can run inside privileged namespaces"
  #   it "can run inside non-privileged namespaces"