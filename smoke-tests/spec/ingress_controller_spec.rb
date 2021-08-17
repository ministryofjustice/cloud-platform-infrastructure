require "spec_helper"

describe "test ingress controllers", speed: "fast", cluster: "test-cluster-only" do
  context "default" do
    host = "prometheus.#{current_cluster}"
    let(:url) { "https://#{host}" }

    it "returns 302 for http get" do
      result = Net::HTTP.get_response(URI(url))
      expect(result.code).to eq("302")
    end

    it "does not return a server header" do
      # The `Server` response header should be suppressed by the ingress-controller configuration
      result = Net::HTTP.get_response(URI(url))
      headers = result.each_header.to_h
      expect(headers).to_not have_key("server")
    end
  end
end

describe "live ingress controllers", speed: "fast", "live-1": true do
  context "default" do
    host = "prometheus.cloud-platform.service.justice.gov.uk"
    let(:url) { "https://#{host}" }

    it "returns 302 for http get" do
      result = Net::HTTP.get_response(URI(url))
      expect(result.code).to eq("302")
    end

    it "does not return a server header" do
      # The `Server` response header should be suppressed by the ingress-controller configuration
      result = Net::HTTP.get_response(URI(url))
      headers = result.each_header.to_h
      expect(headers).to_not have_key("server")
    end
  end
end
