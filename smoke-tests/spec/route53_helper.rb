# Create new Route53 zone
# Expect a domain name in input
# Return route53 zone object https://docs.aws.amazon.com/sdkforruby/api/Aws/Route53/Types/CreateHostedZoneResponse.html
def create_zone(domain)
  client = Aws::Route53::Client.new
  client.create_hosted_zone(
    name: domain, # required
    caller_reference: readable_timestamp, # required, different each time
    hosted_zone_config: {
      comment: "FOR TESTING PURPOSES ONLY",
      private_zone: false,
    },
  )
end

# Delegate a Route53 zone (child -> Parent)
# Expect a Route53 zone object and the parent zone_id
def create_delegation_set(child_zone, parent_id)
  client = Aws::Route53::Client.new
  client.change_resource_record_sets(
    change_batch: {
      changes: [
        {
          action: "CREATE",
          resource_record_set: {
            name: child_zone.hosted_zone.name,
            resource_records: child_zone.delegation_set.name_servers.map { |ns| {value: ns} },
            ttl: 60,
            type: "NS",
          },
        },
      ],
      comment: "FOR TESTING PURPOSES ONLY",
    },
    hosted_zone_id: parent_id,
  )
end

# Retrieves a list of records from an existing Route53 zones
# Expect a zone_id in input
# Returns an array of hashes {type, name, value} of records.
def get_zone_records(zone_id)
  client = Aws::Route53::Client.new
  records = client.list_resource_record_sets(
    hosted_zone_id: zone_id, # required
  )

  records.resource_record_sets.collect { |r| {type: r.type, name: r.name, value: r.resource_records.map { |item| item.value }} }
  # example:
  # [
  #   {:type=>"NS", :name=>"test.service.justice.gov.uk.", :value=>["ns-000.awsdns-00.net.", "ns-000.awsdns-00.net.", "ns-000.awsdns-00.net.", "ns-000.awsdns-00.net."]},
  #   {:type=>"SOA", :name=>"mourad2.service.justice.gov.uk.", :value=>["ns-000.awsdns-00.net. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]}
  # ]
end
