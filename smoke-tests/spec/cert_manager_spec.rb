# This test must NOT be run as part of a pipeline. This is due to the Let's Encrypt 
# limit of 50 certificates per week. The intention of this script is to be used as 
# a user command to execute from their machine as and when required. 
#
# This test uses the cluster: 'live-1' tag to identify tests which can only run against 
# the live-1 cluster (in this case it's because only live clusters have access to the 
# 'cloud-platform.service.justice.gov.uk domain'
require "spec_helper"

describe "cert-manager", cluster: 'live-1'  do
  let(:namespace) { "cert-manager-test-#{random_string}" }

  before do
    create_namespace(namespace)
  end

  after do
    delete_namespace(namespace)
  end

  context "when a certificate resource is created" do
    let(:host) { "cert-manager-#{random_string}.cloud-platform.service.justice.gov.uk" }

    it "returns valid certificate from an openssl call" do
      # Creates a deplyment using the bintami/nginx image to return a 200.
      apply_template_file(
        namespace: namespace,
        host: host,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )
      wait_for(namespace, "ingress", "integration-test-app-ing")

      # Certificate creation and subsequent 2 minute wait for certificate status to equal "True"
      create_certificate(namespace, host)
      sleep 120

      result = validate_certificate(host)
      expect(result).to match(/#{host}/)
    end
  end
end 

def validate_certificate(host)
  cmd = %[echo | openssl s_client -showcerts -servername #{host} -connect #{host}:443 2>/dev/null | openssl x509 -inform pem -noout -text | grep DNS]

  `#{cmd} 2>&1`
end

def create_certificate(namespace, host)

  json = <<~EOF
  {
    "apiVersion": "certmanager.k8s.io/v1alpha1",
    "kind": "Certificate",
    "metadata": {
      "name": "cert-manager-integration-test",
      "namespace": "#{namespace}"
    },
    "spec": {
      "acme": {
        "config": [
          {
            "dns01": {
              "provider": "route53-cloud-platform"
            },
            "domains": [
              "#{host}"
            ]
          }
        ]
      },
      "commonName": "#{host}",
      "issuerRef": {
        "kind": "ClusterIssuer",
        "name": "letsencrypt-production"
      },
      "secretName": "hello-world-ssl"
    }
  }
  EOF

  jsn = JSON.parse(json).to_json

  cmd = %[echo '#{jsn}' | kubectl -n #{namespace} apply -f -]
  `#{cmd}`
end
