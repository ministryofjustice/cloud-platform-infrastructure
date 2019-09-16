require "spec_helper"

describe "Testing modsec" do
  let(:namespace) { "smoketest-modsec-#{readable_timestamp}" }
  let(:host) { "#{namespace}.apps.#{current_cluster}" }
  let(:url1) { "https://#{host}" }
  let(:url2) { "https://#{host}?exec=/bin/bash" }
  let(:ingress_name) { "modsec-smoketest-app-ing" }

  context "deploy ingress with modsec" do
    before do
      create_namespace(namespace)

      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/modsec-smoketest.yaml.erb",
        binding: binding,
      )
      wait_for(namespace, "ingress", ingress_name)
      sleep 10
    end

  context "when modsec deployed" do
    it "URL benign and request successful" do
      result = URI.open(url1)
      expect(result.status).to eq(["200", "OK"])
      delete_namespace(namespace)
    end

    it "URL malicious and request blocked" do
      expect { URI.open(url2) }.to raise_error(OpenURI::HTTPError, "403 Forbidden")
      delete_namespace(namespace)
    end
  end
  
  context "when modsec disabled" do
    it "URL benign and request successful" do
      set_modsec_ing_annotation_false(namespace, ingress_name)
      sleep 5
      result = URI.open(url1)
      expect(result.status).to eq(["200", "OK"])
      delete_namespace(namespace)
    end

    it "URL malicious and request successful" do
      set_modsec_ing_annotation_false(namespace, ingress_name)
      sleep 5
      result = URI.open(url2)
      expect(result.status).to eq(["200", "OK"])
      delete_namespace(namespace)
      end
    end
  end
end
