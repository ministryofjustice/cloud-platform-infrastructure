require "spec_helper"

describe "Testing modsec" do
  let(:namespace) { "smoketest-modsec-#{readable_timestamp}" }
  let(:host) { "#{namespace}.apps.#{current_cluster}" }
  let(:good_url) { "https://#{host}" }
  let(:bad_url) { "https://#{host}?exec=/bin/bash" }
  let(:ingress_name) { "modsec-smoketest-app-ing" }

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

  after do
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
