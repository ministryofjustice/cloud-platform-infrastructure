# Create new Route53 zone
# Expect a domain name in input
# Return route53 zone object https://docs.aws.amazon.com/sdkforruby/api/Aws/Route53/Types/CreateHostedZoneResponse.html 
def create_zone(domain)
    client = Aws::Route53::Client.new()
    new_zone = client.create_hosted_zone({
        name: domain, # required
        caller_reference: "#{readable_timestamp}", # required, different each time
        hosted_zone_config: {
            comment: "FOR TESTING PURPOSES ONLY",
            private_zone: false,
        },
    })

    new_zone
end

# Delegate a Route53 zone (child -> Parent)
# Expect a Route53 zone object and the parent zone_id
# 
def create_delegation_set(child_zone, parent_id)

    client = Aws::Route53::Client.new()
    resp = client.change_resource_record_sets({
    change_batch: {
        changes: [
        {
            action: "CREATE", 
            resource_record_set: {
                name: child_zone.hosted_zone.name, 
                resource_records: child_zone.delegation_set.name_servers.map { |ns| { value: ns } },
                ttl: 60, 
                type: "NS", 
            }, 
        }, 
        ], 
        comment: "FOR TESTING PURPOSES ONLY", 
    }, 
    hosted_zone_id: parent_id, 
    })

end

# Delete zone
# Should match the zone ID returne by create_zone
def delete_zone(zone_id)
    "deleted"
end