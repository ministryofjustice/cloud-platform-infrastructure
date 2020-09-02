require "spec_helper"

# The spec in this file is for testing ModSecurity with default "nginx"
# ingress controller by using the ingress_class = "nginx" in their ingress annotation

describe "Testing modsec" do
  namespace = "integrationtest-modsec-#{readable_timestamp}"
  host = "#{namespace}-nginx.apps.#{current_cluster}"
  let(:url) { "https://#{host}" }
  ingress_name = "integration-test-app-ing"
  ingress_class = "nginx"

  let(:good_url) { "https://#{host}" }
  let(:bad_url) { "https://#{host}?exec=/bin/bash" }

  before(:all) do
    create_namespace(namespace)

    apply_template_file(
      namespace: namespace,
      host: host,
      ingress_class: ingress_class,
      file: "spec/fixtures/helloworld-deployment.yaml.erb",
      binding: binding
    )
    wait_for(namespace, "ingress", ingress_name)
    sleep 120 # We need to wait for a while *after* the ingress is created before we try to test it, or we get failures.
  end

  after(:all) do
    delete_namespace(namespace)
  end

  context "when modsec deployed with nginx ingress class" do # this is the default behaviour
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

  context "when modsec disabled  with nginx ingress class" do
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
