require "spec_helper"

def expect_cluster_error_page(url, message)
  expect {
    URI.open(url)
  }.to raise_error { |error|
    expect(error).to be_a(OpenURI::HTTPError)
    expect(error.message).to eq(message)
    expect(error.io.string).to include("Error, service unavailable - GOV.UK")
  }
end

def expect_ingress_error_page(url, message)
  expect {
    URI.open(url)
  }.to raise_error { |error|
    expect(error).to be_a(OpenURI::HTTPError)
    expect(error.message).to eq(message)
    expect(error.io.string).to_not include("Error, service unavailable - GOV.UK")
  }
end

def expect_backend_error_page(url, message, body)
  expect {
    URI.open(url)
  }.to raise_error { |error|
    expect(error).to be_a(OpenURI::HTTPError)
    expect(error.message).to eq(message)
    expect(error.io.string).to eq(body)
  }
end

describe "http request error responses" do
  let(:unmatched_url) { "https://foobar.apps.#{current_cluster}" }

  context "cluster default backend" do
    context "when the error is 404" do   # cluster default backend *always* serves 404 errors
      it "serves the cluster's error page" do
        expect_cluster_error_page(unmatched_url, "404 Not Found")
      end
    end
  end

  context "in a namespace with no http listeners" do
    let(:namespace) { "integrationtest-#{readable_timestamp}" }
    let(:host) { "#{namespace}.apps.#{current_cluster}" }
    let(:namespace_url) { "https://#{host}" }

    before do
      create_namespace(namespace)

      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",   # TODO: deploy the custom error generator
        binding: binding
      )

      # if nothing in the namespace is listening for requests, we get a 503 error
      scale_replicas(namespace, "intergration-test-helloworld", "0")
      sleep 10
    end

    after do
      delete_namespace(namespace)
    end

    # The list of error codes the cluster default backend will handle is defined in:
    # https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/cloud-platform-components/nginx-ingress-acme.tf
    # Currently (16/09/19) it is "413,502,503,504". We can't change this, because this test will run against live-1
    context "when the error code is in the cluster error list" do
      it "serves the cluster's custom error page" do
        expect_cluster_error_page(namespace_url, "503 Service Unavailable")
      end
    end

    context "when the error code is not in the cluster error list" # result: no error page at all

    # This is a crazy hack by the kubernetes team. See here for more details:
    # https://github.com/kubernetes/ingress-nginx/pull/3344#issue-227791109
    context "when namespace defines list of errors including anything not in cluster list" do
      let(:ing_annotations) { [ %{nginx.ingress.kubernetes.io/custom-http-errors="415,503"} ] }

      before do
        annotate_ingress(namespace, "integration-test-app-ing", ing_annotations)
        sleep 120 # sometimes 10 is enough here, but sometimes it's not
      end

      context "when the error is in the namespace error list" do # i.e. it's 503
        it "serves error page from nginx ingress" do
          expect_ingress_error_page(namespace_url, "503 Service Temporarily Unavailable")
        end
      end

      context "when the error is not in the namespace error list" do
        it "serves no error page"
      end
    end

    context "when namespace has error list which is a subset of cluster-level error list" do
      let(:ing_annotations) { [ %{nginx.ingress.kubernetes.io/custom-http-errors="503"} ] }

      it "serves cluster error page for error in the list" # 503 gets cluster error page

      it "serves no error page for error not in the list" # even if the error is in the cluster list. TODO: raise a 502 error
    end

    context "when namespace has its own default backend" do
      let(:ing_annotations) { [ "nginx.ingress.kubernetes.io/default-backend=nginx-errors" ] }

      before do
        apply_yaml_file(
          namespace: namespace,
          file: "spec/fixtures/default-backend.yaml.erb"
        )
        annotate_ingress(namespace, "integration-test-app-ing", ing_annotations)
        sleep 10
      end

      it "serves the cluster's custom error page" do
        expect_cluster_error_page(namespace_url, "503 Service Unavailable")
      end

      context "when namespace is annotated with a list of http errors, including anything not in cluster list" do
        let(:ing_annotations) { [
          "nginx.ingress.kubernetes.io/default-backend=nginx-errors",
          %{nginx.ingress.kubernetes.io/custom-http-errors="415"},
        ] }

        # All error pages will be served from the namespace default backend, regardless of status code
        it "serves error page from namespace default backend" do
          expect_backend_error_page(namespace_url, "503 Service Unavailable", "5xx html") # the page body "5xx html" is defined in the backend docker image
        end
      end

      context "when the namespace is annotated with an error code from the cluster error list" do
        let(:ing_annotations) { [
          "nginx.ingress.kubernetes.io/default-backend=nginx-errors",
          %{nginx.ingress.kubernetes.io/custom-http-errors="504"},  # 504 is a proxy for 503. 504 is raised, but 503 is handled
        ] }

        it "serves 503 error page from namespace default backend" do
          expect_backend_error_page(namespace_url, "503 Service Unavailable", "5xx html") # the page body "5xx html" is defined in the backend docker image
        end

        it "serves other errors from the cluster default backend" # this will only work after we upgrade the ingress controller
      end
    end
  end
end
