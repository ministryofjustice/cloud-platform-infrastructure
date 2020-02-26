require "spec_helper"

describe "master nodes", speed: "fast" do

  # normalise pod names for ease of comparison, e.g.
  #
  #   calico-node-mv48v -> calico-node
  #   etcd-manager-events-ip-172-20-100-1.eu-west-2.compute.internal -> etcd-manager-events
  #
  def shorten_pod_name(name, node_name)
    name
      .sub(node_name, '')  # remove node name
      .sub(/-[^-]*$/, '')  # remove last '-' and everything after it
  end

  # return a list of [namespace, shortened-pod-name] tuples, for
  # every pod running on a given node
  def pods_on_master(pods, node_name)
    node_pods = pods.find_all { |p| p.dig("spec", "nodeName") == node_name }
    node_pods.map { |p| [
      p.dig("metadata", "namespace"),
      shorten_pod_name(p.dig("metadata", "name"), node_name)
    ] }.sort
  end

  let(:masters) {
    kubectl_items("get nodes")
      .find_all { |node| node.dig("metadata", "labels", "kubernetes.io/role") == "master" }
  }

  let(:pods) { kubectl_items("get pods --all-namespaces") }

  # We should have 3 masters
  specify {
    expect(masters.size).to eq(3)
  }

  # Every master should have these pods running, in these namespaces
  it "has standard pods" do
    expected_pods = [
      ["kube-system", "calico-node"],
      ["kube-system", "etcd-manager-events"],
      ["kube-system", "etcd-manager-main"],
      ["kube-system", "kube-apiserver"],
      ["kube-system", "kube-controller-manager"],
      ["kube-system", "kube-proxy"],
      ["kube-system", "kube-scheduler"],
      ["logging", "fluentd-es"],
      ["monitoring", "prometheus-operator-prometheus-node-exporter"]
    ]

    masters.each do |node|
      node_name = node.dig("metadata", "name")
      master_pods = pods_on_master(pods, node_name)
      expected_pods.each do |tuple|
        expect(master_pods).to include(tuple)
      end
    end
  end

  # Across all masters, there should be a single dns-controller pod running
  specify "only one dns-controller pod" do
    all_master_pods = masters.map do |node|
      node_name = node.dig("metadata", "name")
      pods_on_master(pods, node_name).map {|t| t[1]} # We only want the pod name
    end.flatten

    expect(all_master_pods.grep(/dns-controller/).size).to eq(1)
  end
end
