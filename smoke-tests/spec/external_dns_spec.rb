require "spec_helper"

ZONE_ID = "Z02429076QQMAO8KXV68" # integrationtest.service.justice.gov.uk zone_id

# This test can only be ran against live-1. Test clusters do not have enough privileges.
describe "external DNS", "live-1": true do
  let(:domain) { "integrationtest.service.justice.gov.uk" } # That zone already exists
  namespace = "integrationtest-dns-#{readable_timestamp}"
  let(:ingress_domain) { domain }
  let(:ingress_name) { domain }
  let(:fixture_name) { "spec/fixtures/external-dns-ingress.yaml.erb" }

  # NOTE: The spec in this file can fail with the following error:
  #
  # 1) external DNS when zone matches ingress domain and an ingress is created it creates an A record
  #    Failure/Error: expect(record_types).to include("A")
  #      expected ["NS", "SOA"] to include "A"
  #    # ./spec/external_dns_spec.rb:41:in `block (4 levels) in <top (required)>'
  #
  # To fix this, use the AWS console to find the hosted zone "parent.service.justice.gov.uk."
  # and delete everything except the NS and SOA records, then delete the hosted zone itself.
  # After that, the tests should pass.

  context "when zone matches ingress domain" do
    before do
      cleanup_zone(domain, namespace, ingress_name)
      create_namespace(namespace)
    end

    after do
      delete_namespace(namespace)
    end

    # When I create an ingress
    context "and an ingress is created" do
      before do
        create_ingress(namespace, ingress_name, fixture_name)
        sleep 120 # waiting for ext-dns to detect the change
      end

      # an A record should be created
      it "it creates an A record" do
        records = get_zone_records(ZONE_ID)
        add_A_record = records.select { |r| r.type == "A" }
        expect(add_A_record).not_to be_empty
      end
    end

    # We have sync configured in external-dns, It should delete the A record, when ingress is deleted.
    context "and an ingress is deleted" do
      before do
        delete_ingress(namespace, ingress_name)
        sleep 120 # waiting for ext-dns to detect the change
      end

      # an A record should be deleted
      it "it deletes an A record" do
        records = get_zone_records(ZONE_ID)
        del_A_record = records.select { |r| r.type == "A" }
        expect(del_A_record).to be_empty
      end
    end
  end
end
