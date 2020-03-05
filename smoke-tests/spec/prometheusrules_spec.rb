require "spec_helper"

describe "Prometheus Rules", speed: "fast" do
  specify "expected in all clusters" do
    names = get_prometheus_rules.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-alertmanager.rules",
      "prometheus-operator-custom-kubernetes-apps.rules",
      "prometheus-operator-etcd",
      "prometheus-operator-k8s.rules",
      "prometheus-operator-kube-apiserver.rules",
      "prometheus-operator-kube-prometheus-node-alerting.rules",
      "prometheus-operator-kube-prometheus-node-recording.rules",
      "prometheus-operator-kube-scheduler.rules",
      "prometheus-operator-kubernetes-absent",
      "prometheus-operator-kubernetes-resources",
      "prometheus-operator-kubernetes-storage",
      "prometheus-operator-kubernetes-system",
      "prometheus-operator-node.rules",
      "prometheus-operator-prometheus-operator",
      "prometheus-operator-prometheus",
      "fluentd-es",
    ]
    expect(names).to include(*expected)
  end

  specify "in production", cluster: "live-1" do
    names = get_prometheus_rules.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-custom-alerts-ecr-exporter",
    ]
    expect(names).to include(*expected)
  end
end
