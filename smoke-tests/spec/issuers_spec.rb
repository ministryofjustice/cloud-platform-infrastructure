require "spec_helper"

describe "Clusterissuer", speed: "fast" do
  specify "expected Clusterissuer" do
    names = get_clusterissuers.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "letsencrypt-production",
      "letsencrypt-staging",
    ]
    expect(names).to include(*expected)
  end
end

describe "Issuer", speed: "fast" do
  specify "expected Issuer" do
    names = get_issuers.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "cert-manager-webhook-ca",
      "cert-manager-webhook-selfsign",
    ]
    expect(names).to include(*expected)
  end
end
