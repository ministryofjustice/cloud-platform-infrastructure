require 'spec_helper'

describe "external DNS" do

  context "when zone matches ingress domain" do
    let(:domain) { "child.parent.service.justice.gov.uk" }
    let(:namespace_name) { "test" }
    let(:ingress_domain) { domain }
    let(:parent_zone_id) { "ZQVC43X15AWL9" }
    zone = nil


    # Create a new zone per test
    before do
      zone = create_zone(domain)
      create_delegation_set(zone, parent_zone_id )
    end

    # Delete the zone at each test
    after do
      delete_zone(zone.hosted_zone.id)
      delete_delegation_set(zone, parent_zone_id)
    end

    #When I create an ingress
    context "when an ingress is created" do
      # before do
      #   create_namespace(namespace_name)
      #   apply_yaml_file
      # end

      # an A record should be created
      it "creates an A record" do
        records = get_zone_records(zone.hosted_zone.id)      
        record_types = records.map { |rec| rec.fetch(:type) }

        expect(record_types).to include("NS")
      end

      # When the ingress is deleted
      # context "when ingress is deleted" do
      #   before do
      #     delete_ingress(ingress_domain) # includes waiting for confirmation
      #   end

      #   # The existing record in the zone should not deleted
      #   xit "does not delete records" do
      #     records = get_zone_records(zone.hosted_zone.id)
      #     expect(records).to_not be_nil  # doesn't work yet
      #   end
      # end
    end

    # When an ingress is not created
    # context "when no ingress is created" do

    #   # No new record should be created
    #   xit "does not create any records" do
    #     record = get_zone_records(zone.hosted_zone.id)
    #     expect(record).to be_nil  # doesn't work yet
    #   end
    # end
  end

# When no Route53 Zone match the ingress domain
  # context "when zone does not match ingress domain" do
  #   let(:ingress_domain) { "some.other.domain" }

  #   context "when an ingress is created" do
  #     before do
  #       ingress = create_ingress(ingress_domain)
  #     end

  #     xit "does not create any records" do
  #       record = get_zone_records(zone.hosted_zone.id)
  #       expect(records).to be_nil
  #     end
  #   end
  # end

end
