require "spec_helper"

describe "namespaces", speed: "fast" do
  context "kube-system" do
    # The kube-system namespace MUST have this label, or the
    # OPA will prevent any pods from being launched in it.
    it "has opa webhook label" do
      data = kubectl_get("get namespace kube-system")
      label = data.dig("metadata", "labels", "openpolicyagent.org/webhook")
      expect(label).to eq("ignore")
    end
  end
end
