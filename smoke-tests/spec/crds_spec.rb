require "spec_helper"

describe "crds", speed: "fast" do
  specify "expected crds" do
    names = get_crds.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "alertmanagers.monitoring.coreos.com",
      "certificates.certmanager.k8s.io",
      "challenges.certmanager.k8s.io",
      "clusterissuers.certmanager.k8s.io",
      "issuers.certmanager.k8s.io",
      "orders.certmanager.k8s.io",
      "prometheuses.monitoring.coreos.com",
      "prometheusrules.monitoring.coreos.com",
      "servicemonitors.monitoring.coreos.com",
      "tzcronjobs.cronjobber.hidde.co",
    ]
    expect(names).to include(*expected)
  end
end
