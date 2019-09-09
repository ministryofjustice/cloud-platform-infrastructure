require "spec_helper"

# We want a fluentd pod running on each node, including masters
describe "Log shipping" do

  # gets all node IPs, then the fluentd pods, compares the lists
  it "runs fluentd" do
    nodes = `kubectl get nodes -o json -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' --sort-by='.status.addresses[?(@.type=="InternalIP")].address'`.chomp
    pods = `kubectl -n logging get pods -o json -o jsonpath='{..items[*].status.hostIP}' --field-selector status.phase='Running' --selector app=='fluentd-es' --sort-by='.status.hostIP'`.chomp
    expect(nodes).to eq(pods)
  end

end
