require "spec_helper"

describe "servicemonitors", speed: "fast" do
  specify "expected prometheus servicemonitors in all clusters" do
    names = get_servicemonitors("monitoring").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-alertmanager",
      "prometheus-operator-apiserver",
      "prometheus-operator-grafana",
      "prometheus-operator-kube-state-metrics",
      "prometheus-operator-kubelet",
      "prometheus-operator-node-exporter",
      "prometheus-operator-operator",
      "prometheus-operator-prometheus"
    ]
    expect(names).to include(*expected)
  end

  specify "expected prometheus servicemonitors in kops clusters", kops: true do
    names = get_servicemonitors("monitoring").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "prometheus-operator-kube-controller-manager",
      "prometheus-operator-coredns",
      "prometheus-operator-kube-etcd",
      "prometheus-operator-kube-scheduler"
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
