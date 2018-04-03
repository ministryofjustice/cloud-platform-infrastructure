#!/usr/bin/env python
import re
import json

with open('config.json', 'r') as f:
    config = json.loads(f.read() or '{}')


if not config.get('fabric_name'):
    print("""ERROR: Fabric domain name not set!

        Set config.json['fabric_name'] to a valid fabric name (DNS-compatible)""")

    exit(1)

fabric_name = re.sub("[\W\d]+", "-", config.get('fabric_name').lower().strip())
print(fabric_name, end='')
