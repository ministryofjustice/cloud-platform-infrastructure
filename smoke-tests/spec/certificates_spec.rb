require "spec_helper"

describe "certificates" do
  specify "expected Certificate" do
    names = get_certificates.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "default", # ingress-controller certificate
      "cert-manager-webhook-ca",
      "cert-manager-webhook-webhook-tls",
    ]
    expect(names).to include(*expected)
  end
end
