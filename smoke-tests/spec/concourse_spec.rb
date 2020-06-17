require "spec_helper"

describe "concourse-test", "eks-manager": true do
  context "concourse namespace should exists" do
    it "Fail if namespace doesnt exist" do
      expect(namespace_exists?("concourse")).to eq(true)
    end
  end

  context "concourse-main namespace should exists" do
    it "Fail if namespace doesnt exist" do
      expect(namespace_exists?("concourse-main")).to eq(true)
    end
  end

  context "expected all concourse-worker pods running inside concourse namespace" do
    let(:pods) { get_running_app_pods("concourse", "concourse-worker") }

    it "all concourse-worker pods inside concourse are running" do
      expect(all_containers_running?(pods)).to eq(true)
    end
  end

  context "expected all postgresql pods running inside concourse namespace" do
    let(:pods) { get_running_app_pods("concourse", "postgresql") }

    it "all postgresql pods inside concourse are running" do
      expect(all_containers_running?(pods)).to eq(true)
    end
  end

  context "expected all concourse-web running inside concourse namespace" do
    let(:pods) { get_running_app_pods("concourse", "concourse-web") }

    it "all concourse-web pods inside concourse are running" do
      expect(all_containers_running?(pods)).to eq(true)
    end
  end
end


