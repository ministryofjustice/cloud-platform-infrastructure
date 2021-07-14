require "spec_helper"

describe "concourse-test", "eks-manager": true, "concourse-test": true do
  specify do
    expect(namespace_exists?("concourse")).to eq(true)
  end

  specify do
    expect(namespace_exists?("concourse-main")).to eq(true)
  end

  it "runs postgresql pods" do
    pods = get_running_app_pods("concourse", "postgresql", "app.kubernetes.io/name")
    expect(all_containers_running?(pods)).to eq(true)
  end

  it "runs concourse-worker pods" do
    pods = get_running_app_pods("concourse", "concourse-worker")
    expect(all_containers_running?(pods)).to eq(true)
  end

  it "runs concourse-web pods" do
    pods = get_running_app_pods("concourse", "concourse-web")
    expect(all_containers_running?(pods)).to eq(true)
  end
end
