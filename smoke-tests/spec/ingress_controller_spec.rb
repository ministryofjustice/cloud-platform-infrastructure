require "spec_helper"

describe "ingress controllers", speed: "fast" do
  context "default" do
    # This needs to be any url of an ingress on the default controller,
    let(:url) { "https://how-out-of-date-are-we.apps.live-1.cloud-platform.service.justice.gov.uk/dashboard" }

    it "returns 200 for http get" do
      result = Net::HTTP.get_response(URI(url))
      expect(result.code).to eq("200")
      expect(result.message.strip).to eq("OK")
    end

    it "does not return a server header" do
      # The `Server` response header should be suppressed by the ingress-controller configuration
      result = Net::HTTP.get_response(URI(url))
      headers = result.each_header.to_h
      expect(headers).to_not have_key("server")
    end
  end

  context "modsec01" do
    # This needs to be any hostname of an ingress on the modsec01 controller,
    let(:url) { "https://manage-hmpps-auth-accounts-dev.prison.service.justice.gov.uk/" }

    it "returns 302 for http get" do
      result = Net::HTTP.get_response(URI(url))
      expect(result.code).to eq("302")
    end

    it "does not return a server header" do
      result = Net::HTTP.get_response(URI(url))
      headers = result.each_header.to_h
      expect(headers).to_not have_key("server")
    end
  end
end
