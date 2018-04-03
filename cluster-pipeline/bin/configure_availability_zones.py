#!/usr/bin/env python
import boto3
import json
import sys

with open('config.json', 'r') as f:
    config = json.loads(f.read() or '{}')

if not config.get('fabric_region'):
    if len(sys.argv) <= 1:
        print("""ERROR: Region information not configured! You can do one of...

        1. Set config.json['fabric_region'] to a valid region name (e.g. us-east-1)
        2. Pass a region name to this script as the first argument (e.g. {} us-east-1)""".format(sys.argv[0]))

        exit(1)

    else:
        config['fabric_region'] = sys.argv[1].lower()

ec2 = boto3.client('ec2', region_name=config['fabric_region'])
config['fabric_availability_zones'] = []

for zone in ec2.describe_availability_zones()['AvailabilityZones'][:3]:
    if zone['State'] == 'available':
        config['fabric_availability_zones'].append(zone['ZoneName'])

zone_count = len(config['fabric_availability_zones'])
if zone_count < 3:
    print("""ERROR: Region {} does not have enough availability zones! Expected at least 3 but only found {}!""".format(config['fabric_region'], zone_count))
    exit(1)

print("""Updating config.json...
    Region             = {0}
    Availability Zones = {1}
    """.format(config['fabric_region'],  config['fabric_availability_zones']))

with open('config.json', 'w+') as f:
    json.dump(config, f, sort_keys=True, indent=4, separators=(',', ': '))

print("Done!")
