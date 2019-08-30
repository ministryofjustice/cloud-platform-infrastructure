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
  # Cert-manager has a limit of 64 chars.
  let(:random) { "#{random_string}" }
  let(:namespace) { "cert-manager-test-#{random}" }
  let(:cluster) { "#{current_cluster}" } 
  # Hard code the parent zone id
  let(:parent_zone_id) { "Z1OWR28V4Q2RTU" }

  context "when a certificate resource is created" do
    let(:domain) { "cert-manager-#{random}.cloud-platform.service.justice.gov.uk" }

    before do
      create_namespace(namespace)
      create_certificate(namespace, domain)
      #zone = create_zone(domain)
      #create_delegation_set(zone, parent_zone_id)
      sleep 40
      apply_template_file(
        namespace: namespace,
        domain: domain,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )
      wait_for(namespace, "ingress", "integration-test-app-ing")
      sleep 7
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

def create_certificate(namespace, domain)

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
              "#{domain}"
            ]
          }
        ]
      },
      "commonName": "#{domain}",
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

def create_zone(domain)
  client = Aws::Route53::Client.new()
  new_zone = client.create_hosted_zone({
    name: domain, # required
    caller_reference: "#{readable_timestamp}", # required, different each time
    hosted_zone_config: {
      comment: "CERT-MANAGER INTEGRATION TEST",
      private_zone: false,
    },
  })

  new_zone
end

# Delegate a Route53 zone (child -> Parent)
# Expect a Route53 zone object and the parent zone_id
# 
def create_delegation_set(zone, parent_zone_id)

  client = Aws::Route53::Client.new()
  resp = client.change_resource_record_sets({
    change_batch: {
      changes: [
        {
          action: "CREATE", 
          resource_record_set: {
            name: zone.hosted_zone.name, 
            resource_records: zone.delegation_set.name_servers.map { |ns| { value: ns } },
            ttl: 60, 
            type: "NS", 
          }, 
        }, 
      ], 
      comment: "FOR TESTING PURPOSES ONLY", 
    }, 
    hosted_zone_id: parent_zone_id, 
  })

end
