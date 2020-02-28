require "spec_helper"

describe "Prometheus", speed: "fast" do
  specify "expected Prometheus resource" do
    names = get_prometheuses.map { |set| set.dig("metadata", "name") }.sort
    expected = [
      "prometheus-operator-prometheus",
    ]
    expect(names).to include(*expected)
  end
end
