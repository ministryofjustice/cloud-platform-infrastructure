require "spec_helper"

describe "external DNS" do
  # let!(zone) { nil }

  context "when zone matches ingress domain" do
    let(:domain) { "child.parent.service.justice.gov.uk" }
    let(:namespace) { "child-parent" }
    let(:ingress_domain) { domain }
    let(:parent_zone_id) { "ZQVC43X15AWL9" }
    zone = nil

    # Create a new zone per test
    before do
      zone = create_zone(domain)
      create_delegation_set(zone, parent_zone_id)
    end

    after do
      cleanup_zone(zone, domain)
      delete_delegation_set(zone, parent_zone_id)
    end

    # When I create an ingress
    context "when an ingress is created" do
      before do
        create_namespace(namespace)
      end

      after do
        delete_namespace(namespace)
      end

      # an A record should be created
      it "creates an A record" do
        create_ingress
        sleep 120
        records = get_zone_records(zone.hosted_zone.id)
        record_types = records.map { |rec| rec.fetch(:type) }
        expect(record_types).to include("A")
      end

      # When the ingress is deleted
      context "when ingress is deleted" do
        before do
          delete_ingress(namespace) # includes waiting for confirmation
        end

        # The existing record in the zone should not deleted
        it "does not delete records" do
          records = get_zone_records(zone.hosted_zone.id)
          expect(records).to_not be_nil
        end
      end
    end
  end

  # When no Route53 Zone match the ingress domain
  context "when zone does not match ingress domain" do
    let(:domain) { "otherchild.parent.service.justice.gov.uk" }
    let(:namespace) { "child-parent" }
    let(:parent_zone_id) { "ZQVC43X15AWL9" }
    zone = nil

    before do
      create_namespace(namespace)
      create_ingress
      sleep 120
    end

    after do
      delete_ingress(namespace)
      delete_namespace(namespace)
    end

    context "when an ingress is created" do
      it "a record is created in the parent zone" do
        records = get_zone_records(parent_zone_id)
        record_types = records.map { |rec| rec.fetch(:type) }
        expect(record_types).to include("A")
      end
    end
  end
end
