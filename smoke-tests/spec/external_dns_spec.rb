require "spec_helper"

describe "external DNS" do
  namespace = "child-#{readable_timestamp}"
  let(:domain) { "child.parent.service.justice.gov.uk" }
  let(:ingress_domain) { domain }
  let(:ingress_name) { domain }
  let(:parent_domain) { "parent.service.justice.gov.uk" }
  let(:fixture_name) { "spec/fixtures/external-dns-ingress.yaml.erb" }
  zone = nil
  parent_zone = nil

  context "when zone matches ingress domain" do
    # Create a new zone per test
    before do
      parent_zone = create_zone(parent_domain)
      zone = create_zone(domain)
      create_delegation_set(zone, parent_zone.hosted_zone.id)
    end

    after do
      cleanup_zone(zone, domain, namespace, ingress_name)
      delete_delegation_set(zone, parent_zone.hosted_zone.id)
      delete_zone(parent_zone.hosted_zone.id)
    end

    # When I create an ingress
    context "when an ingress is created" do
      before(:all) do
        sleep 1
        create_namespace(namespace)
      end

      after(:all) do
        delete_namespace(namespace)
      end

      # an A record should be created
      it "creates an A record" do
        create_ingress(namespace, ingress_name, fixture_name)
        # Ingress is created immediately, but we're waiting for ext-dns to propagate the change to R53
        sleep 120
        records = get_zone_records(zone.hosted_zone.id)
        record_types = records.map { |rec| rec.fetch(:type) }
        expect(record_types).to include("A")
      end

      # When the ingress is deleted
      context "when ingress is deleted" do
        before do
          delete_ingress(namespace, ingress_name)
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
    let(:timestamp) { readable_timestamp }
    before do
      parent_zone = create_zone(parent_domain)
      create_namespace(namespace)
      create_ingress(namespace, ingress_name, fixture_name)
      sleep 120
    end

    after do
      cleanup_zone(parent_zone, domain, namespace, ingress_name)
      delete_ingress(namespace, ingress_name)
      delete_namespace(namespace)
    end

    context "when an ingress is created" do
      it "a record is created in the parent zone" do
        records = get_zone_records(parent_zone.hosted_zone.id)
        record_types = records.map { |rec| rec.fetch(:type) }
        expect(record_types).to include("A")
      end
    end
  end
end
