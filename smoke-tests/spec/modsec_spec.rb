require "spec_helper"

describe "Testing modsec" do
  namespace = "integrationtest-modsec-#{readable_timestamp}"
  host = "#{namespace}.apps.#{current_cluster}"
  ingress_name = "modsec-integrationtest-app-ing"

  let(:good_url) { "https://#{host}" }
  let(:bad_url) { "https://#{host}?exec=/bin/bash" }

  before(:all) do
    create_namespace(namespace)

    apply_template_file(
      namespace: namespace,
      file: "spec/fixtures/modsec-integrationtest.yaml.erb",
      binding: binding,
    )
    wait_for(namespace, "ingress", ingress_name)
    sleep 20
  end

  after(:all) do
    delete_namespace(namespace)
  end

  context "when modsec deployed" do  # this is the default behaviour
    context "when the url is benign" do
      let(:url) { good_url }

      specify "request succeeds" do
        expect(URI.open(url).status).to eq(["200", "OK"])
      end
    end

    context "when the url is malicious" do
      let(:url) { bad_url }

      specify "request is blocked" do
        expect { URI.open(url) }.to raise_error(OpenURI::HTTPError, "403 Forbidden")
      end
    end
  end

  context "when modsec disabled" do
    before do
      set_modsec_ing_annotation_false(namespace, ingress_name)
      sleep 5
    end

    context "when the url is benign" do
      let(:url) { good_url }

      specify "request succeeds" do
        expect(URI.open(url).status).to eq(["200", "OK"])
      end
    end

    context "when the url is malicious" do
      let(:url) { bad_url }

      specify "request succeeds" do
        expect(URI.open(url).status).to eq(["200", "OK"])
      end
    end
  end
end
