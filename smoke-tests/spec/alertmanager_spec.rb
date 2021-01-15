require "spec_helper"

describe "Alertmanager resources", speed: "fast" do
  specify "expected Alertmanager resources" do
    names = get_alertmanagers.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-kube-p-alertmanager",
    ]
    expect(names).to include(*expected)
  end
end
