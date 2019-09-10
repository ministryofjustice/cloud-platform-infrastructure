require "spec_helper"

# We want a fluentd pod running on each node, including masters
describe "Log shipping" do

  # gets all node IPs, then the fluentd pods, compares the lists
  it "runs fluentd" do
    cluster_nodes = get_cluster_ips()
    app_nodes = get_app_nodes("logging", "fluentd-es")
    expect(cluster_nodes).to eq(app_nodes)
  end

end
