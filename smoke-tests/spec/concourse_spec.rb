require "spec_helper"

describe "concourse-test", "eks-manager": true do

  specify {
    expect(namespace_exists?("concourse")).to eq(true)
  }

  specify {
    expect(namespace_exists?("concourse-main")).to eq(true)
  }

  it "runs postgresql pods" do
    pods = get_running_app_pods("concourse", "postgresql")
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


