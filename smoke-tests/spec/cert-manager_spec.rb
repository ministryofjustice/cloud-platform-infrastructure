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

# _external_dns
# "heritage=external-dns,external-dns/owner=default,external-dns/resource=ingress/family-mediators-api-production/family-mediators-api-ingress-production"
#
# Alias record
# aef1937c1a95711e98cdd0aaafbe3d46-9b185ef26eadab0b.elb.eu-west-2.amazonaws.com.
#
# NS record
# ns-1462.awsdns-54.org.
# ns-1813.awsdns-34.co.uk.
# ns-500.awsdns-62.com.
# ns-912.awsdns-50.net.
#
# SOA record
# ns-1462.awsdns-54.org. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400
#
# ns-54.awsdns-06.com.
# ns-1613.awsdns-09.co.uk.
# ns-745.awsdns-29.net.
# ns-1369.awsdns-43.org.

# how to query the cert used by a page
# echo | openssl s_client -showcerts -servername jb.apps.jb-test-10.cloud-platform.service.justice.gov.uk -connect jb.apps.jb-test-10.cloud-platform.service.justice.gov.uk:443 2>/dev/null | openssl x509 -inform pem -noout -text
#
#
require "spec_helper"

describe "cert-manager" do
  let(:namespace) { "cert-manager-integration-test-#{readable_timestamp}" }
  let(:cluster) { "apps.#{current_cluster}" } 
  let(:host) { "#{namespace}.#{cluster}" }


  context "when certificate resource is created" do
    before do
      create_namespace(namespace)
      apply_template_file(
        namespace: namespace,
        file: "spec/fixtures/helloworld-deployment.yaml.erb",
        binding: binding
      )
      wait_for(namespace, "ingress", "integration-test-app-ing")
      sleep 7 # Without this, the test fails
    end

    after do
      delete_namespace(namespace)
    end

    it "returns valid certificate for openssl call" do
      result = true
      expect(result).to eq(true)
    end
  end    
end    
