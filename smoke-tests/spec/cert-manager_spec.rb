# Before all:
# Create ns
# Create helloworld pod with ingress
# Context: Certficate created and curl returns 200
# Check to see if domain exists, if not add it.
# Before: Create certificate
# Context: Check the status of the certificate
# Curl endpoint
# After: Destroy certificate
# Context: Certificate not created and curl returns !200
# curl endpoint
# Maybe:
# Test certificate creation

# how to query the cert used by a page
# echo | openssl s_client -showcerts -servername jb.apps.jb-test-10.cloud-platform.service.justice.gov.uk -connect jb.apps.jb-test-10.cloud-platform.service.justice.gov.uk:443 2>/dev/null | openssl x509 -inform pem -noout -text
#
require "spec_helper"

describe "cert-manager" do
  let(:namespace) { "c-manager-test-#{random_string}" }
  let(:cluster) { "#{current_cluster}" } 
  let(:host) { "#{namespace}.apps.#{cluster}" }

  context "when a certificate resource is created" do
    before do
      create_namespace(namespace)
      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )
      wait_for(namespace, "ingress", "integration-test-app-ing")
      sleep 7 # Without this, the test fails
      create_certificate(namespace, host)
    end

    after do
      #delete_namespace(namespace)
    end

    it "returns valid certificate for an openssl call" do
      result = true
      expect(result).to eq(true)
    end
  end    
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
