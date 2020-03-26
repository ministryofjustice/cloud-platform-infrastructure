require "spec_helper"

describe "Starter pack Apps", speed: "fast", cluster: "test-cluster-only" do
  let(:namespace) { "starter-pack" }
  let(:ingresses) { get_ingresses(namespace) }

  context "Test starter pack apps ingress urls" do
    it "Starter pack app response ok" do
      ingresses.each do |ingress|
        response = get_url(ingress)
        expect(response.code).to eq "200"
      end
    end
  end
end
