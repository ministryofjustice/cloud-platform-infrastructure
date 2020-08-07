# Return the zone_id of a zone, found by name (domain)
# This will only use the first result
def get_zone_by_name(domain)
  client = Aws::Route53::Client.new

  zones = client.list_hosted_zones_by_name({
    dns_name: domain,
    max_items: 1
  })
  zones.hosted_zones[0].id.tr("/hostedzone/", "")
end

# Expects a the ingress template to exist at fixture_name
def create_ingress(namespace, ingress_name, fixture_name)
  apply_template_file(
    namespace: namespace,
    file: fixture_name,
    binding: binding
  )
  wait_for(namespace, "ingress", ingress_name, 60)
end

# delete ingress if namespace and ingress exist
def delete_ingress(namespace, ingress_name)
  if namespace_exists?(namespace) && object_exists?(namespace, "ingress", ingress_name)
    execute("kubectl delete ingress #{ingress_name} -n #{namespace}")
  end
end

def delete_record(zone_id, record)
  sleep 1 # for throttling
  client = Aws::Route53::Client.new
  record_change = {
    action: "DELETE",
    resource_record_set: record
  }

  client.change_resource_record_sets({
    hosted_zone_id: zone_id,
    change_batch: {
      changes: [record_change]
    }
  })
end

# Checks if the zone is empty, then deletes
# if not empty, it will assume it contains one A record and one TXT record created by external-dns
def cleanup_zone(domain, namespace, ingress_name, zone_id = nil)
  if zone_id.nil?
    zone_id = get_zone_by_name(domain)
  end

  records = get_zone_records(zone_id)

  if records.size > 2
    begin
      records.each do |record|
        case record[:type]
        when "A"
          delete_record(zone_id, record)
        when "TXT"
          delete_record(zone_id, record)
        end
      end
    rescue Aws::Route53::Errors::InvalidChangeBatch => e
      puts "Caught error when deleting record:\n#{record}\nContinuing..."
    end
  end
end
