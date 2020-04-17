require "spec_helper"

describe "certificates", speed: "fast" do
  specify "expected Certificate" do
    names = get_certificates.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "default", # ingress-controller certificate
    ]
    expect(names).to include(*expected)
  end
end
