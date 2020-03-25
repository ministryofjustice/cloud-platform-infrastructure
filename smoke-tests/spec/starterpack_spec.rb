require "spec_helper"

describe "Starter pack Apps", speed: "fast" do
  let(:namespace) { "starter-pack" }
  let(:ingresses) { get_ingresses(namespace) }
  let(:ingress_first) { ingresses[0] }
  let(:ingress_second) { ingresses[1] }

  it "Hello world app response ok" do
    response = get_url(ingress_first)
    expect(response.code).to eq "200"
  end

  it "Multi container app response ok" do
    response = get_url(ingress_second)
    expect(response.code).to eq "200"
  end
end
