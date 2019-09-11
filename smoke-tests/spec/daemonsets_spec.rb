require "spec_helper"

# We want a fluentd pod running on each node, including masters
describe "Log shipping" do
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
