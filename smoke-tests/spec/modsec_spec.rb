require "spec_helper"

# The spec in this file is for testing ModSecurity with dedicated ingress controller.
# Integration tests has the dedicated ingress controller with ingress class - integration-test
# The below spec uses the ingress_class = "integration-test" in its ingress annotation

describe "Testing modsec on ingress class: 'integration-test'", kops: true do
  namespace = "integrationtest-modsec-#{readable_timestamp}"
  host = "#{namespace}.apps.#{current_cluster}"
  let(:url) { "https://#{host}" }
  ingress_name = "integration-test-app-ing"
  ingress_class = "integration-test"

  let(:good_url) { "https://#{host}" }
  let(:bad_url) { "https://#{host}?exec=/bin/bash" }

  before(:all, kops: true) do
    create_namespace(namespace)

    apply_template_file(
      namespace: namespace,
      host: host,
      ingress_class: ingress_class,
      file: "spec/fixtures/helloworld-deployment-modsec.yaml.erb",
      binding: binding
    )
    wait_for(namespace, "ingress", ingress_name)
    sleep 180 # We need to wait for a while *after* the ingress is created before we try to test it, or we get failures.
  end

  after(:all, kops: true) do
    delete_namespace(namespace)
  end

  context "when modsec is deployed" do # this is the default behaviour
    before do
      annotations_hash = {'nginx.ingress.kubernetes.io/enable-modsecurity': "true"}
      annotate_ingress(namespace, ingress_name, annotations_hash)
      sleep 30
    end

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

  context "when modsec is disabled" do
    before do
      annotations_hash = {'nginx.ingress.kubernetes.io/enable-modsecurity': "false"}
      annotate_ingress(namespace, ingress_name, annotations_hash)
      sleep 30
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
