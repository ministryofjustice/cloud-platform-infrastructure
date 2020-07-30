require "spec_helper"

describe "daemonsets", speed: "fast" do
  let(:worker_ips) { node_ips worker_nodes }
  let(:master_ips) { node_ips master_nodes }
  let(:all_node_ips) { node_ips(get_nodes) }

  let(:app_node_ips) { pod_ips pods }

  specify "expected daemonsets in kops", kops: true do
    names = get_daemonsets.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "calico-node",
      "fluent-bit",
      "fluentd-es",
      "kiam-agent",
      "kiam-server",
      "kops-controller",
      "prometheus-operator-prometheus-node-exporter"

    ]

    expect(names).to eq(expected)
  end

  specify "expected daemonsets in eks", "eks-manager": true do
    names = get_daemonsets.map { |set| set.dig("metadata", "name") }.sort

    expected = [
      "aws-node",
      "calico-node",
      "fluentd-es",
      "kube-proxy",
      "prometheus-operator-prometheus-node-exporter"
    ]

    expect(names).to eq(expected)
  end

  context "fluentd" do
    let(:pods) { get_running_app_pods("logging", "fluentd-es") }

    it "runs fluentd" do
      expect(all_node_ips).to eq(app_node_ips)
    end

    specify "all fluentd containers are running" do
      expect(all_containers_running?(pods)).to eq(true)
    end
  end

  context "fluent-bit", kops: true do
    let(:pods) { get_running_app_pods("logging", "fluent-bit") }

    it "runs fluent-bit" do
      expect(all_node_ips).to eq(app_node_ips)
    end

    specify "all fluent-bit containers are running" do
      expect(all_containers_running?(pods)).to eq(true)
    end
  end

  context "kiam", kops: true do
    let(:pods) { get_running_app_pods("kiam", "kiam") }

    let(:app_node_ips) {
      pod_ips(pods.filter { |pod| pod.dig("metadata", "labels", "component") == component })
    }

    specify "all containers are running" do
      expect(all_containers_running?(pods)).to eq(true)
    end

    context "agent" do
      let(:component) { "agent" }

      it "runs on workers" do
        expect(worker_ips).to eq(app_node_ips)
      end

      it "doesn't run on masters" do
        expect(app_node_ips & master_ips).to be_empty
      end
    end

    context "server" do
      let(:component) { "server" }

      it "runs on workers" do
        expect(worker_ips).to eq(app_node_ips)
      end

      it "doesn't run on masters" do
        expect(app_node_ips & master_ips).to be_empty
      end
    end
  end

  context "prometheus exporter" do
    let(:pods) { get_running_app_pods("monitoring", "prometheus-node-exporter") }

    it "runs on all nodes" do
      expect(app_node_ips).to eq(all_node_ips)
    end

    specify "all containers are running" do
      expect(all_containers_running?(pods)).to eq(true)
    end
  end

  context "calico" do
    let(:pods) { get_running_app_pods("kube-system", "calico-node", "k8s-app") }

    it "runs on all nodes" do
      expect(app_node_ips).to eq(all_node_ips)
    end

    specify "all containers are running" do
      expect(all_containers_running?(pods)).to eq(true)
    end
  end

  context "calico-kube-controllers", kops: true do
    specify "there can be only one" do
      pods = get_running_app_pods("kube-system", "calico-kube-controllers", "k8s-app")
      expect(pods.size).to eq(1)
    end
  end
end
