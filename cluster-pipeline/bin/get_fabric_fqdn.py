#!/usr/bin/env python
import re
import json

with open('config.json', 'r') as f:
    config = json.loads(f.read() or '{}')


if not config.get('fabric_name'):
    print("""ERROR: Fabric domain name not set!

        Set config.json['fabric_name'] to a valid fabric name""")

    exit(1)

if not config.get('domain_name'):
    print("""ERROR: domain domain name not set!

        Set config.json['domain_name'] to a valid domain name in Route53""")

    exit(1)

fabric_name = re.sub("[\W\d]+", "-", config.get('fabric_name').lower().strip())
fqdn = fabric_name + "." + config["domain_name"]
print(fqdn, end='')
