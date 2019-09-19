
def create_ingress(namespace, ingress_name, fixture_name)
    sleep 1
    apply_template_file(
          namespace: namespace,
          file: fixture_name,
          binding: binding
    )
    wait_for(namespace, "ingress", ingress_name, 60)
end

def delete_ingress(namespace, ingress_name)
    `kubectl delete ingress #{ingress_name} -n #{namespace}`
end

def get_ingress_enpoint(namespace, ingress_name)
  `kubectl get ingress #{ingress_name} -n #{namespace} -o json -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
end

def delete_A_record(zone_id, zone_name, domain_name, namespace, ingress_name)
  sleep 1
  client = Aws::Route53::Client.new

  a_record = {
    action: "DELETE",
    resource_record_set: {
      name: domain_name,
      alias_target: {
        "hosted_zone_id": "ZD4D7Y8KGAS4G",
        "dns_name": get_ingress_enpoint(namespace, ingress_name),
        "evaluate_target_health": true,
      },
      type: "A",
    },
  }
  
  client.change_resource_record_sets({
    hosted_zone_id: zone_id,
    change_batch: {
      changes: [a_record],
    },
  })
end

def delete_TXT_record(zone_id, zone_name, domain_name, namespace)
    sleep 1
    client = Aws::Route53::Client.new
    txt_record= { 
        action: "DELETE",
        resource_record_set: {
            name: "_external_dns.#{domain_name}",
            ttl: 300,
            resource_records:[
                {
                    value: %("heritage=external-dns,external-dns/owner=default,external-dns/resource=ingress/#{namespace}/#{domain_name}")
                }
            ],
            type: "TXT",
        }
    }

    client.change_resource_record_sets({
      :hosted_zone_id => zone_id,
      :change_batch => {
          :changes => [txt_record]
      },  
    })
end

def cleanup_zone(zone, domain, namespace, ingress_name)
    sleep 1
    if is_zone_empty?(zone.hosted_zone.id) == true
        delete_zone(zone.hosted_zone.id)
    else
        delete_A_record(zone.hosted_zone.id, zone.hosted_zone.name, domain, namespace, ingress_name)
        delete_TXT_record(zone.hosted_zone.id,zone.hosted_zone.name, domain, namespace)
        delete_zone(zone.hosted_zone.id)
    end
end

def is_zone_empty?(zone_id)
    sleep 1
    records = get_zone_records(zone_id)
    if records.size > 2
        false
    else
        true
    end
end
