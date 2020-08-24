require "spec_helper"

xdescribe "nginx ingress" do
  namespace = "smoketest-ingress-#{readable_timestamp}"
  host = "#{namespace}.apps.#{current_cluster}"
  let(:url) { "https://#{host}" }

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
  context "when ingress is deployed" do
    before do
      apply_template_file(
        namespace: namespace,
        host: host,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )

      wait_for(namespace, "ingress", "integration-test-app-ing")
      sleep 60 # Without this, the test fails
    end

    it "returns 200 for http get" do
      result = URI.open(url)
      expect(result.status).to eq(["200", "OK"])
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
