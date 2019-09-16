require "spec_helper"

describe "http request error responses" do
  let(:unmatched_url) { "https://foobar.apps.#{current_cluster}" }

  context "cluster default backend" do
    it "serves a custom page for 404 errors" do
      expect {
        URI.open(unmatched_url)
      }.to raise_error { |error|
        expect(error).to be_a(OpenURI::HTTPError)
        expect(error.message).to eq("404 Not Found")
        expect(error.io.string).to include("Error, service unavailable - GOV.UK")
      }
    end
  end

  context "in a namespace" do
    let(:namespace) { "integrationtest-#{readable_timestamp}" }
    let(:host) { "#{namespace}.apps.#{current_cluster}" }
    let(:namespace_url) { "https://#{host}" }

    before do
      create_namespace(namespace)

      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )
    end

    after do
      delete_namespace(namespace)
    end

    context "handling 503 error" do
      before do
        # if nothing in the namespace is listening for requests, we get a 503 error
        scale_replicas(namespace, "intergration-test-helloworld", "0")
        sleep 10
      end

      it "serves the cluster's custom 503 page" do
        expect {
          URI.open(namespace_url)
        }.to raise_error { |error|
          expect(error).to be_a(OpenURI::HTTPError)
          expect(error.message).to eq("503 Service Unavailable")
          expect(error.io.string).to include("Error, service unavailable - GOV.UK")
        }
      end
    end

  end
end

describe "Namespace with no custom default-backend but with ingress annotations, serve nginx error page" do
  let(:namespace) { "no-backend-#{readable_timestamp}" }
  let(:host) { "#{namespace}.apps.#{current_cluster}" }
  let(:url) { "https://#{host}" }
  let(:ing_annotations) {
    [
     %{nginx.ingress.kubernetes.io/custom-http-errors="404,415,504"}
    ]
  }

  context "when app is deployed with ingress annotations" do
    before do
      create_namespace(namespace)

      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )

      annotate_ingress(namespace, "integration-test-app-ing", ing_annotations)

      scale_replicas(namespace, "intergration-test-helloworld", "0")

      sleep 10 # Without this, the test fails
    end

    after do
      delete_namespace(namespace)
    end

    it "serves nginx error" do
      expect {
        URI.open(url)
      }.to raise_error { |error|
        expect(error).to be_a(OpenURI::HTTPError)
        expect(error.message).to eq("503 Service Temporarily Unavailable")
        expect(error.io.string).to include("503 Service Temporarily Unavailable")
      }
    end
  end
end

describe "Namespace with custom default-backend and ingress annotations, serve custom default-backend error page" do
  let(:namespace) { "custom-backend-#{readable_timestamp}" }
  let(:host) { "#{namespace}.apps.#{current_cluster}" }
  let(:url) { "https://#{host}" }
  let(:ing_annotations) {
    [
     "nginx.ingress.kubernetes.io/default-backend=nginx-errors",
     %{nginx.ingress.kubernetes.io/custom-http-errors="404,415,504"}
    ]
  }

  context "when app and defaut-backend is deployed with ingress annotations" do
    before do
      create_namespace(namespace)

      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )

      annotate_ingress(namespace, "integration-test-app-ing", ing_annotations)

      apply_yaml_file(
        namespace: namespace,
        file: "spec/fixtures/default-backend.yaml.erb"
      )

      scale_replicas(namespace, "intergration-test-helloworld", "0")

      sleep 60 # Without this, the test fails
    end

    after do
      delete_namespace(namespace)
    end

    it "serves custom default-backend" do
      expect {
        URI.open(url)
      }.to raise_error { |error|
        expect(error).to be_a(OpenURI::HTTPError)
        expect(error.message).to eq("503 Service Unavailable")
        expect(error.io.string).to eq("5xx html")
      }
    end
  end
end
