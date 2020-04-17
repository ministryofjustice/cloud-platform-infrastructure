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

