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
    expect(names).to include(*expected)
  end

  specify "expected nginx-ingress servicemonitors" do
    names = get_servicemonitors("ingress-controllers").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "nginx-ingress-acme-controller",
    ]
    expect(names).to eq(expected)
  end

  specify "expected concourse servicemonitors", cluster: "live-1" do
    names = get_servicemonitors("concourse").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "concourse",
    ]
    expect(names).to eq(expected)
  end

  specify "expected ECR and CloudWatch servicemonitors", cluster: "live-1" do
    names = get_servicemonitors("monitoring").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "ecr-exporter-prometheus-ecr-exporter",
      "cloudwatch-exporter-prometheus-cloudwatch-exporter",
    ]
    expect(names).to include(*expected)
  end

  specify "expected velero servicemonitors" do
    names = get_servicemonitors("velero").map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "velero",
    ]
    expect(names).to eq(expected)
  end
end
