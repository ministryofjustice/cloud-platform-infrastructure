def create_ingress
  apply_template_file(
    namespace: namespace,
    file: "spec/fixtures/external-dns-ingress.yaml.erb",
    binding: binding
  )
  wait_for(namespace, "ingress", "ingress-external-dns", 60)
end

def delete_ingress(namespace)
  `kubectl delete ingress ingress-external-dns -n #{namespace}`
  sleep 10
end

def get_ingress_enpoint
  `kubectl get ingress integration-test -o json -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
end

def delete_A_record(zone_id, zone_name, domain_name)
  client = Aws::Route53::Client.new

  a_record = {
    action: "DELETE",
    resource_record_set: {
      name: zone_name,
      alias_target: {
        "hosted_zone_id": "ZD4D7Y8KGAS4G",
        "dns_name": get_ingress_enpoint,
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

def delete_TXT_record(zone_id, zone_name)
  client = Aws::Route53::Client.new
  txt_record = {
    action: "DELETE",
    resource_record_set: {
      name: "_external_dns.#{zone_name}",
      ttl: 300,
      resource_records: [
        {
          value: '"heritage=external-dns,external-dns/owner=default,external-dns/resource=ingress/child-parent/ingress-external-dns"',
        },
      ],
      type: "TXT",
    },
  }

  client.change_resource_record_sets({
    hosted_zone_id: zone_id,
    change_batch: {
      changes: [txt_record],
    },
  })
end

def cleanup_zone(zone, a_record_name)
  if is_zone_empty?(zone.hosted_zone.id) == true
    delete_zone(zone.hosted_zone.id)
  else
    delete_A_record(zone.hosted_zone.id, zone.hosted_zone.name, a_record_name)
    delete_TXT_record(zone.hosted_zone.id, zone.hosted_zone.name)
    delete_zone(zone.hosted_zone.id)
  end
end

def is_zone_empty?(zone_id)
  records = get_zone_records(zone_id)
  !(records.size > 2)
end
