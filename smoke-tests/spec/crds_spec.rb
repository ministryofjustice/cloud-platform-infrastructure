require "spec_helper"

describe "crds", speed: "fast" do
  specify "expected crds in all clusters" do
    names = get_crds.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "alertmanagers.monitoring.coreos.com",
      "certificaterequests.cert-manager.io",
      "certificates.cert-manager.io",
      "challenges.acme.cert-manager.io",
      "clusterissuers.cert-manager.io",
      "issuers.cert-manager.io",
      "orders.acme.cert-manager.io",
      "prometheuses.monitoring.coreos.com",
      "podmonitors.monitoring.coreos.com",
      "prometheusrules.monitoring.coreos.com",
      "servicemonitors.monitoring.coreos.com"
    ]
    expect(names).to include(*expected)
  end

  specify "expected crds in kops cluster", kops: true do
    names = get_crds.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "tzcronjobs.cronjobber.hidde.co"
    ]
    expect(names).to include(*expected)
  end
end   