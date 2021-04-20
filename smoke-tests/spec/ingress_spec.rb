require "spec_helper"

describe "nginx ingress", speed: "slow" do
  namespace = "smoketest-ingress-#{readable_timestamp}"
  host = "#{namespace}-nginx.apps.#{current_cluster}"
  let(:url) { "https://#{host}" }
  ingress_name = "integration-test-app-ing"
  ingress_class = "nginx"

  # Delay of 300 or lower consistently results in at least one test failure
  # Delay of 360 fails 50/50
  let(:sleep_delay) { 400 } # How long to wait after creating/modifying an ingress

  before(:all) do
    create_namespace(namespace)
  end

  after(:all) do
    delete_namespace(namespace)
  end

  context "when ingress is not deployed" do
    it "fails http get" do
      expect {
        URI.open(url)
      }.to raise_error(OpenURI::HTTPError)
    end
  end

  # TODO: This test is failing a lot of the time due to performance problems with our shared ingress.
  # So, I'm disabling it for now. When we have fixed the underlying problem, this should be
  # reinstated.
  context "when ingress is deployed using 'nginx' ingress controller" do
    before do
      apply_template_file(
        namespace: namespace,
        host: host,
        ingress_class: ingress_class,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )

      wait_for(namespace, "ingress", ingress_name)
      sleep sleep_delay # Without this, the test fails
    end

    it "returns 200 for http get" do
      result = URI.open(url)
      expect(result.status).to eq(["200", "OK"])
    end
  end

  context "when ingress is deployed using 'integration-test' ingress controller", kops: true do
    before do
      host = "#{namespace}-integration-test.apps.#{current_cluster}"
      ingress_class = "integration-test"

      apply_template_file(
        namespace: namespace,
        host: host,
        ingress_class: ingress_class,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )

      wait_for(namespace, "ingress", ingress_name)
      sleep sleep_delay # Without this, the test fails
    end

    it "responds to http get" do
      result = URI.open(url)
      expect(result.status).to eq(["200", "OK"])

      # The `Server` response header should be suppressed by the ingress-controller configuration
      expect(result.meta).to_not have_key("server")
    end
  end

  context "when ingress is deployed with invalid syntax" do
    it "is rejected by the admission webhook" do
      stdout_str, stderr_str, status = apply_template_file(
        namespace: namespace,
        host: host,
        file: "spec/fixtures/invalid-nginx-syntax.yaml.erb",
        binding: binding
      )
      expect(stderr_str).to match(/admission webhook "validate.nginx.ingress.kubernetes.io" denied the request/)
    end
  end
end
