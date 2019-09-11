require "spec_helper"

# We want a fluentd pod running on each node, including masters
describe "fluentd" do
  # gets all node IPs, then the fluentd pods, compares the lists
  it "runs fluentd" do
    cluster_nodes = get_cluster_ips
    app_nodes = get_app_node_ips("logging", "fluentd-es")
    expect(cluster_nodes).to eq(app_nodes)
  end

  specify "all fluentd containers are running" do
    pods = get_running_app_pods("logging", "fluentd-es")
    expect(all_containers_running?(pods)).to eq(true)
  end
end

describe "kiam" do
  let(:kiam_pods) {  get_running_app_pods("kiam", "kiam") }
  let(:worker_ips) { node_ips worker_nodes }
  let(:master_ips) { node_ips master_nodes }

  let(:app_node_ips) {
    pod_ips(kiam_pods.filter { |pod| pod.dig("metadata", "labels", "component") == component })
  }

  specify "all containers are running" do
    expect(all_containers_running?(kiam_pods)).to eq(true)
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

describe "prometheus exporter" do
  let(:pods) { get_running_app_pods("monitoring", "prometheus-node-exporter") }

  it "runs on all nodes" do
    ips = node_ips(get_nodes)
    app_nodes = get_app_node_ips("monitoring", "prometheus-node-exporter")
    expect(app_nodes).to eq(ips)
  end

  specify "all containers are running" do
    expect(all_containers_running?(pods)).to eq(true)
  end
end
