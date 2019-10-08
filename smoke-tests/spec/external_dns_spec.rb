require "spec_helper"

describe "external DNS" do
  namespace = "integrationtest-dns-#{readable_timestamp}"
  zone = nil
  parent_zone = nil
  let(:domain) { "child.parent.service.justice.gov.uk" }
  let(:ingress_domain) { domain }
  let(:ingress_name) { domain }
  let(:parent_domain) { "parent.service.justice.gov.uk" }
  let(:fixture_name) { "spec/fixtures/external-dns-ingress.yaml.erb" }

  context "when zone matches ingress domain" do
    # Create a new zone per test
    before do
      parent_zone = create_zone(parent_domain)
      zone = create_zone(domain)
      create_delegation_set(zone, parent_zone.hosted_zone.id)
      create_namespace(namespace)
    end

    after do
      cleanup_zone(zone, domain, namespace, ingress_name)
      delete_delegation_set(zone, parent_zone.hosted_zone.id)
      delete_zone(parent_zone.hosted_zone.id)
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
        records = get_zone_records(zone.hosted_zone.id)
        record_types = records.map { |rec| rec.fetch(:type) }
        expect(record_types).to include("A")
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
      sleep 160
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
