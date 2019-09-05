require "spec_helper"

describe "namespace" do
  def can_i_get(type, team, namespace = "kube-system")
    `kubectl auth can-i get #{type} --namespace #{namespace} --as test --as-group github:#{team} --as-group system:authenticated`.chomp
  end

  let(:yes) { "yes" }
  let(:no) { "no" }

  context "when group is webops" do
    let(:group) { "webops" }

    it "allows webops to access namespace" do
      result = can_i_get "namespace", group
      expect(result).to eq(yes)
    end

    it "allows webops to access pods" do
      result = can_i_get "pod", group
      expect(result).to eq(yes)
    end
  end

  context "when group is not webops" do
    let(:group) { "not-webops" }

    it "does not allow non-webops to access namespace" do
      result = can_i_get "namespace", group
      expect(result).to eq(no)
    end

    it "does not allow non-webops to access pods" do
      result = can_i_get "pod", group
      expect(result).to eq(no)
    end
  end

  context "when group is test-webops" do
    namespace = "smoketest-namespace-#{readable_timestamp}"
    before(:all) do
      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/namespace-smoketest.yaml.erb",
        binding: binding
      )
    end

    after(:all) do
      delete_namespace(namespace)
    end

    it "allows non-webops to access pods" do
      result = can_i_get "pod", "test-webops", namespace
      expect(result).to eq(yes)
    end

    it "allows non-webops to access namespace" do
      result = can_i_get "namespace", "test-webops", namespace
      expect(result).to eq(yes)
    end
  end
end
