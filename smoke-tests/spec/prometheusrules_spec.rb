require "spec_helper"

describe "Prometheus Rules", speed: "fast" do
  specify "expected in all clusters" do
    names = get_prometheus_rules.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-alertmanager.rules",
      "prometheus-operator-custom-kubernetes-apps.rules",
      "prometheus-operator-k8s.rules",
      "prometheus-operator-kube-apiserver.rules",
      "prometheus-operator-kubernetes-absent",
      "prometheus-operator-kubernetes-resources",
      "prometheus-operator-kubernetes-storage",
      "prometheus-operator-kubernetes-system",
      "prometheus-operator-node.rules",
      "prometheus-operator-prometheus-operator",
      "prometheus-operator-prometheus",
      "prometheus-operator-node-exporter.rules",
      "prometheus-operator-kubernetes-system-apiserver",
      "prometheus-operator-kubernetes-system-kubelet",
      "prometheus-operator-node-exporter",
      "fluentd-es",
      "certificate-expiry"
    ]
    expect(names).to include(*expected)
  end

  specify "expected in kops clusters", kops: true do
    names = get_prometheus_rules.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-etcd",
      "prometheus-operator-kube-apiserver-error",
      "prometheus-operator-kube-scheduler.rules",
      "prometheus-operator-kubernetes-system-controller-manager",
      "prometheus-operator-kubernetes-system-scheduler"
    ]
    expect(names).to include(*expected)
  end

  specify "expected in eks", "eks-manager": true do
    names = get_prometheus_rules.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-kubernetes-apps"
    ]
    expect(names).to include(*expected)
  end

  specify "in production", "live-1": true do
    names = get_prometheus_rules.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-custom-alerts-ecr-exporter"
    ]
    expect(names).to include(*expected)
  end
end
