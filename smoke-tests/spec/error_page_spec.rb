require "spec_helper"

describe "custom error pages" do
  context "404" do
    let(:url) do
      "https://foobar.apps.#{current_cluster}"
    end

    it "gets a 404 status" do
      expect {
        URI.open(url)
      }.to raise_error(OpenURI::HTTPError, "404 Not Found")
    end

    it "serves a 404 response" do
      begin
        URI.open(url)
      rescue OpenURI::HTTPError => e
        body = e.io.string
        expect(body).to eq("404 page not found\n")
      end
    end
  end
end
