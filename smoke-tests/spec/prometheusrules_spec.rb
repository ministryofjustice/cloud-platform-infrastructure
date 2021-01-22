require "spec_helper"

describe "Prometheus Rules", speed: "fast" do
  specify "expected in all clusters" do
    names = get_prometheus_rules.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-kube-p-alertmanager.rules",
      "prometheus-operator-custom-kubernetes-apps.rules",
      "prometheus-operator-kube-p-k8s.rules",
      "prometheus-operator-kube-p-kube-apiserver.rules",
      "prometheus-operator-kube-p-kube-apiserver-slos",
      "prometheus-operator-kube-p-kubernetes-resources",
      "prometheus-operator-kube-p-kubernetes-storage",
      "prometheus-operator-kube-p-kubernetes-system",
      "prometheus-operator-kube-p-node.rules",
      "prometheus-operator-kube-p-prometheus-operator",
      "prometheus-operator-kube-p-prometheus",
      "prometheus-operator-kube-p-node-exporter.rules",
      "prometheus-operator-kube-p-kubernetes-system-apiserver",
      "prometheus-operator-kube-p-kubernetes-system-kubelet",
      "prometheus-operator-kube-p-node-exporter",
      "certificate-expiry"
    ]
    expect(names).to include(*expected)
  end

  specify "expected in kops clusters", kops: true do
    names = get_prometheus_rules.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-kube-p-etcd",
      "prometheus-operator-kube-p-kube-scheduler.rules",
      "prometheus-operator-kube-p-kubernetes-system-controller-manager",
      "prometheus-operator-kube-p-kubernetes-system-scheduler"
    ]
    expect(names).to include(*expected)
  end
end
