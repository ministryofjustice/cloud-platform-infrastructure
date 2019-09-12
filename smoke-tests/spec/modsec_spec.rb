require "spec_helper"

describe "modsec ingress" do
  let(:namespace) { "smoketest-modsec-#{readable_timestamp}" }
  let(:host) { "#{namespace}.apps.#{current_cluster}" }
  let(:url) { "https://#{host}?exec=/bin/bash" }

  context "deploy modsec ingress" do
    before do
      create_namespace(namespace)

      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/modsec-smoketest.yaml.erb",
        binding: binding,
      )
      wait_for(namespace, "ingress", "modsec-smoketest-app-ing")
      sleep 20
    end

    it "gets a 403 Forbidden error" do
      expect { URI.open(url) }.to raise_error(OpenURI::HTTPError, "403 Forbidden")
    end

    after do
      delete_namespace(namespace)
    end
  end
end
