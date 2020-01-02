require "spec_helper"

CLUSTER_ERROR_PAGE_HTML_BODY = "Error, service unavailable - GOV.UK"
CUSTOM_ERROR_GENERATOR_HTML_BODY = "Code="

def expect_open_url(url)
  expect { URI.open(url) }
end

# when Nginx cannot route a http request successfully.
# cluster level default-backend service will handle the response by serving cloud-platform cluster error page.
# This method check for HTTP error response is from cluster level default-backend service, serving cluster error page.
def expect_cluster_error_page(url, message)
  expect_open_url(url).to raise_error { |error|
                            expect(error).to be_a(OpenURI::HTTPError)
                            expect(error.message).to eq(message)
                            expect(error.io.string).to include(CLUSTER_ERROR_PAGE_HTML_BODY)
                          }
end

# when ingress in a namespace is annotated to not serve cluster_error_page, it serves no error page and get a HTTP error Status.
# This method check for HTTP error response is not from cluster default-backend and error is not cluster error page.
def expect_ingress_error_page(url, message)
  expect_open_url(url).to raise_error { |error|
                            expect(error).to be_a(OpenURI::HTTPError)
                            expect(error.message).to eq(message)
                            expect(error.io.string).to_not include(CLUSTER_ERROR_PAGE_HTML_BODY)
                          }
end

# application serve own error pages by annotating ingress to not serve cluster_error_page or default-backend in namespace.
# This method check for HTTP error response is from the application.
def expect_application_error_page(url, message, body)
  expect_open_url(url).to raise_error { |error|
                            expect(error).to be_a(OpenURI::HTTPError)
                            expect(error.message).to eq(message)
                            expect(error.io.string).to include(CUSTOM_ERROR_GENERATOR_HTML_BODY)
                          }
end

# custom default-backend service in a namespace will handle the error response by serving custom backend_error_page from the namespace.
# This method check for HTTP error response is from the default-backend service in a namespace, serving namespace backend error page.
def expect_backend_error_page(url, message, body)
  expect_open_url(url).to raise_error { |error|
                            expect(error).to be_a(OpenURI::HTTPError)
                            expect(error.message).to eq(message)
                            expect(error.io.string).to eq(body)
                          }
end

describe "http request error responses" do
  let(:unmatched_url) { "https://foobar.apps.#{current_cluster}" }

  context "cluster default backend" do
    context "when the error is 404" do # cluster default backend *always* serves 404 errors
      it "serves the cluster's error page" do
        expect_cluster_error_page(unmatched_url, "404 Not Found")
      end
    end
  end

  context "in a namespace with the HTTP handler" do # http 'handler' is an app. which raises whichever http error we ask it for.
    let(:namespace) { "integrationtest-errorpage-#{readable_timestamp}" }
    let(:host) { "#{namespace}.apps.#{current_cluster}" }
    let(:namespace_url) { "https://#{host}/err?code=#{error_to_raise}" }
    let(:ing_annotations) {
      [
        "nginx.ingress.kubernetes.io/default-backend=nginx-errors",
        %(nginx.ingress.kubernetes.io/custom-http-errors="#{error_to_annotate}"),
      ]
    }

    before do
      create_namespace(namespace)

      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/default-backend.yaml.erb", # Deploy application with the HTTP handler and custom default backend.
        binding: binding
      )
      sleep 10
    end

    after do
      delete_namespace(namespace)
    end

    # The list of error codes the cluster default backend will handle is defined in:
    # https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/cloud-platform-components/nginx-ingress-acme.tf
    # Currently (22/10/19) it is "413,502,503,504". We can't change this, because this test will run against live-1
    context "when the error code is in the cluster error list" do
      let(:error_to_raise) { "503" }

      it "serves the cluster's custom error page" do
        expect_cluster_error_page(namespace_url, "503 Service Unavailable")
      end
    end

    context "when the error code is not in the cluster error list" do
      let(:error_to_raise) { "501" }

      it "serves no error page" do
        expect_ingress_error_page(namespace_url, "501 Not Implemented")
      end
    end

    # This is a crazy hack by the kubernetes team. See here for more details:
    # https://github.com/kubernetes/ingress-nginx/pull/3344#issue-227791109
    context "when namespace defines list of errors including anything not in cluster list" do
      let(:ing_annotations) { [%(nginx.ingress.kubernetes.io/custom-http-errors="415")] }

      before do
        annotate_ingress(namespace, "integration-test-app-ing", ing_annotations)
        sleep 10 # sometimes 10 is enough here, but sometimes it's not
      end

      context "when the error is in the cluster error list and application not serving error page" do
        let(:error_to_raise) { "503" }

        before do
          scale_replicas(namespace, "integration-test-errorpage", "0") # Scaled down to 0, so application is not listening for requests.
          sleep 10
        end

        it "serves error page from nginx ingress" do
          expect_ingress_error_page(namespace_url, "503 Service Temporarily Unavailable")
        end
      end

      context "when the error is in the cluster error list and application serving error" do
        let(:error_to_raise) { "502" }

        it "serves error page from application" do
          expect_application_error_page(namespace_url, "502 Bad Gateway", "Code=502")
        end
      end

      context "when the error is not in the cluster error list" do
        let(:error_to_raise) { "401" }

        it "serves no error page" do
          expect_ingress_error_page(namespace_url, "401 Unauthorized")
        end
      end
    end

    context "when namespace has error list which is a subset of cluster-level error list" do
      let(:ing_annotations) { [%(nginx.ingress.kubernetes.io/custom-http-errors="503")] }

      before do
        annotate_ingress(namespace, "integration-test-app-ing", ing_annotations)
        sleep 10 # sometimes 10 is enough here, but sometimes it's not
      end

      context "when the error is in the namespace error list" do # i.e. it's 503
        let(:error_to_raise) { "503" }

        it "serves cluster error page for error in the list" do
          expect_cluster_error_page(namespace_url, "503 Service Unavailable")
        end
      end

      context "when the error is not in the namespace error list" do
        let(:error_to_raise) { "409" }

        it "serves no error page for error not in the list" do
          expect_ingress_error_page(namespace_url, "409 Conflict")
        end
      end
    end

    context "when namespace has its own default backend" do
      # Default backend annotation on the ingress is referenced to a service which will handle error responses inside the same namespace.
      before do
        annotate_ingress(namespace, "integration-test-app-ing", ing_annotations)
        sleep 10
      end

      context "when ingress is annotated with default-backend service but not with the list of http errors" do
        let(:ing_annotations) { ["nginx.ingress.kubernetes.io/default-backend=nginx-errors"] }
        let(:error_to_raise) { "503" }

        it "serves the cluster's custom error page" do
          expect_cluster_error_page(namespace_url, "503 Service Unavailable")
        end
      end

      # If a custom http error annotation is specified on the ingress, along with default backend annotation,
      # the errors will be routed to that annotation’s default backend service (instead of the global default backend).
      context "when ingress is annotated with an error code not from the cluster error list" do
        let(:error_to_annotate) { "415" }
        let(:error_to_raise) { "503" }

        context "application not serving error pages" do
          before do
            scale_replicas(namespace, "integration-test-errorpage", "0") # Scaled down to 0, so application is not listening for requests.
            sleep 10
          end

          it "serves error page from namespace default backend." do
            expect_backend_error_page(namespace_url, "503 Service Unavailable", "5xx html") # the page body "5xx html" is defined in the backend docker image
          end
        end

        context "application is serving error pages" do
          it "serves error page from application" do
            expect_application_error_page(namespace_url, "503 Service Unavailable", "Code=503") # the page body "Code=503" is from the application.
          end
        end

        context "error raised is same as annotated error code" do
          let(:error_to_annotate) { "429" }
          let(:error_to_raise) { "429" }

          it "serves error page from namespace default backend" do
            expect_backend_error_page(namespace_url, "429 Too Many Requests", "4xx html") # the page body "4xx html" is defined in the backend docker image
          end
        end
      end

      context "when the ingress is annotated with an error code from the cluster error list" do
        let(:error_to_annotate) { "503" }
        let(:error_to_raise) { "503" }

        it "serves 503 error page from namespace default backend" do
          expect_backend_error_page(namespace_url, "503 Service Unavailable", "5xx html") # the page body "5xx html" is defined in the backend docker image
        end
      end
    end
  end
end
