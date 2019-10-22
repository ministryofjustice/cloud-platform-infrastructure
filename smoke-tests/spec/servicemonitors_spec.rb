require "spec_helper"

describe "servicemonitors" do

  specify "expected prometheus servicemonitors" do
    names = get_servicemonitors("monitoring").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-alertmanager",
      "prometheus-operator-apiserver",
      "prometheus-operator-grafana",
      "prometheus-operator-kube-controller-manager",
      "prometheus-operator-kube-dns",
      "prometheus-operator-kube-etcd",
      "prometheus-operator-kube-scheduler",
      "prometheus-operator-kube-state-metrics",
      "prometheus-operator-kubelet",
      "prometheus-operator-node-exporter",
      "prometheus-operator-operator",
      "prometheus-operator-prometheus",
    ]
    expect(names).to eq(expected)
  end

  # specify "expected nginx-ingress servicemonitors" do
  #   names = get_servicemonitors.map { |set| set.dig("metadata", "name") }.sort

  #   expected = [
  #     "alertmanagers.monitoring.coreos.com",
  #     "certificates.certmanager.k8s.io",
  #     "challenges.certmanager.k8s.io",
  #     "clusterissuers.certmanager.k8s.io",
  #     "issuers.certmanager.k8s.io",
  #     "orders.certmanager.k8s.io",
  #     "prometheuses.monitoring.coreos.com",
  #     "prometheusrules.monitoring.coreos.com",
  #     "servicemonitors.monitoring.coreos.com",
  #     "tzcronjobs.cronjobber.hidde.co",
  #   ]
  #   expect(names).to eq(expected)
  # end

  # specify "expected concourse servicemonitors" do
  #   names = get_servicemonitors.map { |set| set.dig("metadata", "name") }.sort

  #   expected = [
  #     "alertmanagers.monitoring.coreos.com",
  #     "certificates.certmanager.k8s.io",
  #     "challenges.certmanager.k8s.io",
  #     "clusterissuers.certmanager.k8s.io",
  #     "issuers.certmanager.k8s.io",
  #     "orders.certmanager.k8s.io",
  #     "prometheuses.monitoring.coreos.com",
  #     "prometheusrules.monitoring.coreos.com",
  #     "servicemonitors.monitoring.coreos.com",
  #     "tzcronjobs.cronjobber.hidde.co",
  #   ]
  #   expect(names).to eq(expected)
  # end

end
