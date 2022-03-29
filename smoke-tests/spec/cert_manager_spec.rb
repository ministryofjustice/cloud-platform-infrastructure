require "spec_helper"

describe "cert-manager" do
  let(:namespace) { "cert-manager-test-#{readable_timestamp}" }
  ingress_class = "nginx"
  ingress_name = "integration-test-app-ing"
  let(:set_identifier) { "#{ingress_name}-#{namespace}-#{external_dns_annotation_color}" }

  before do
    create_namespace(namespace)
  end

  after do
    delete_namespace(namespace)
  end

  context "when a certificate resource is created" do
    let(:host) { "cert-test#{random_string(length = 2)}.#{current_cluster}" }

    it "returns valid certificate from an openssl call" do
      # Creates a deplyment using the bintami/nginx image to return a 200.
      apply_template_file(
        namespace: namespace,
        host: host,
        ingress_class: ingress_class,
        set_identifier: set_identifier,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )
      wait_for(namespace, "ingress", "integration-test-app-ing")

      # Certificate creation and subsequent 2 minute wait for certificate status to equal "True"
      create_certificate(namespace, host)
      sleep 240

      result = validate_certificate(host)
      expect(result).to match(/#{host}/)
    end
  end
end

def validate_certificate(host)
  cmd = %(echo | openssl s_client -showcerts -servername #{host} -connect #{host}:443 2>/dev/null | openssl x509 -inform pem -noout -text | grep DNS)

  `#{cmd} 2>&1`
end

def create_certificate(namespace, host)
  json = <<~EOF
    {
      "apiVersion": "cert-manager.io/v1",
      "kind": "Certificate",
      "metadata": {
        "name": "cert-manager-integration-test",
        "namespace": "#{namespace}"
      },
      "spec": {
        "commonName": "#{host}",
        "issuerRef": {
          "kind": "ClusterIssuer",
          "name": "letsencrypt-staging"
        },
        "dnsNames": [
          "#{host}"
        ],
        "secretName": "hello-world-ssl"
      }
    }
  EOF

  jsn = JSON.parse(json).to_json

  cmd = %(echo '#{jsn}' | kubectl -n #{namespace} apply -f -)
  execute(cmd)
end
