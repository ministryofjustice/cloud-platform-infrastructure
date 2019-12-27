require "spec_helper"

describe "Alertmanager resources" do
  specify "expected Alertmanager resources" do
    names = get_alertmanagers.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-alertmanager",
    ]
    expect(names).to include(*expected)
  end
end
