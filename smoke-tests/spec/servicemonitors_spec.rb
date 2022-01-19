require "spec_helper"

describe "servicemonitors", speed: "fast" do
  specify "expected prometheus servicemonitors in all clusters" do
    names = get_servicemonitors("monitoring").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-kube-p-alertmanager",
      "prometheus-operator-kube-p-apiserver",
      "prometheus-operator-kube-p-coredns",
      "prometheus-operator-kube-p-grafana",
      "prometheus-operator-kube-p-kubelet",
      "prometheus-operator-kube-p-operator",
      "prometheus-operator-kube-p-prometheus"
    ]
    expect(names).to include(*expected)
  end

  specify "expected prometheus servicemonitors in kops clusters", kops: true do
    names = get_servicemonitors("monitoring").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-kube-p-kube-controller-manager",
      "prometheus-operator-kube-p-kube-etcd",
      "prometheus-operator-kube-p-kube-proxy",
      "prometheus-operator-kube-p-kube-scheduler",
      "prometheus-operator-kube-p-kube-state-metrics",
      "prometheus-operator-kube-p-node-exporter"
    ]
    expect(names).to include(*expected)
  end

  specify "expected ECR and CloudWatch servicemonitors", "live-1": true do
    names = get_servicemonitors("monitoring").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "ecr-exporter-prometheus-ecr-exporter",
      "cloudwatch-exporter-prometheus-cloudwatch-exporter"
    ]
    expect(names).to include(*expected)
  end

  specify "expected velero servicemonitors", kops: true do
    names = get_servicemonitors("velero").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "velero"
    ]
    expect(names).to eq(expected)
  end
end
