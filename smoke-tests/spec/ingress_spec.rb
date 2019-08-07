require "spec_helper"

describe "nginx ingress", cluster: 'live-1' do
  let(:cluster_domain) { "apps.live-1.cloud-platform.service.justice.gov.uk" }
  let(:namespace) { "smoketest-ingress-#{Time.now.to_i}" }
  let(:host) { "#{namespace}.#{cluster_domain}" }
  let(:url) { "https://#{host}" }

  context "when ingress is not deployed" do
    it "fails http get" do
      expect {
        URI.open(url)
      }.to raise_error(OpenURI::HTTPError)
    end
  end

  context "when ingress is deployed" do
    before do
      create_namespace(namespace)

      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/ingress-smoketest.yaml.erb",
        binding: binding
      )
      wait_for(namespace, "ingress", "ingress-smoketest-app-ing")
      sleep 7 # Without this, the test fails
    end

    after do
      delete_namespace(namespace)
    end

    it "returns 200 for http get" do
      result = URI.open(url)
      expect(result.status).to eq(["200", "OK"])
    end
  end
end
