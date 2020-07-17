require "spec_helper"

describe "authorized_keys", "live-1": true, speed: "fast" do
  context "authorized-keys-provider namespace should exists" do
    it "Fail if namespace doesnt exist" do
      expect(namespace_exists?("authorized-keys-provider")).to eq(true)
    end
  end

  context "expected all pods running inside authorized-keys-provider namespace" do
    let(:pods) { get_running_app_pods("authorized-keys-provider", "authorized-keys-provider") }

    it "all pods inside authorized-keys-provider are running" do
      expect(all_containers_running?(pods)).to eq(true)
    end
  end

  context "expected authorized_keys file within the bastion repo" do
    it "authorized_keys file exists and it can be downloaded" do
      response = URI.open("https://github.com/ministryofjustice/cloud-platform-terraform-bastion/blob/main/files/authorized_keys.txt")
      expect(response.status).to eq(["200", "OK"])
    end
  end
end
