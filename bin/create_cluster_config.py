#!/usr/bin/python

import sys
import subprocess
import json
import argparse
import yaml
import pprint
import os.path
from ast import literal_eval

# Init lists
templates = []
clusters = []
instances = []
bastions = []
nodes = []
masters = []
output = []

# Json output configuration


class literal(str):
    pass


def literal_presenter(dumper, data):
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')

# Function to fetch a value from the terraform dictionary


def tf(key):
    if terraform[key]['value']:
        return terraform[key]['value']
    else:
        sys.exit(key + ' not found, exit.')


# Dumper config
yaml.SafeDumper.add_representer(literal, literal_presenter)
yaml.SafeDumper.ignore_aliases = lambda *args: True

# Parser config
p = pprint.PrettyPrinter(indent=4)
parser = argparse.ArgumentParser(description='Create Kubernetes clusters.')
parser.add_argument(
    'clusterconfig',
    help='the base yaml file to create the cluster from')

args = parser.parse_args()
#print( 'loading file ' + args.clusterconfig)

# Load the base kops yaml file located in the repo
if os.path.isfile(args.clusterconfig):
    stream = open(args.clusterconfig)
    for template in yaml.load_all(stream):
        templates.append(template)
    stream.close()
else:
    sys.exit(args.clusterconfig + ' file not found, exit.')

# Load the terraform outputs from the terraform command
try:
    terraform = json.loads(str(subprocess.check_output(
        ['terraform', 'output', '-json']).decode('utf-8')))
except subprocess.CalledProcessError as e:
    print('error executing terraform command, exit.')

# Populate variables from terraform output
cluster_name = tf('cluster_domain_name')
dns_zone = cluster_name
kops_state_store = 's3://' + tf('kops_state_store') + '/' + cluster_name
availability_zones = tf('availability_zones')
master_public_name = 'api.' + cluster_name
network_cidr = tf('network_cidr_block')
topology = 'bastion.' + cluster_name
internal_subnets = tf('internal_subnets')
external_subnets = tf('external_subnets')

# Organize in lists by kind and role
for template in templates:
    if template['kind'] == 'Cluster':
        clusters.append(template)
    if template['kind'] == 'InstanceGroup':
        instances.append(template)
        if template['spec']['role'] == 'Bastion':
            bastions.append(template)
        if template['spec']['role'] == 'Node':
            nodes.append(template)
        if template['spec']['role'] == 'Master':
            masters.append(template)

# Update all Cluster kind
for template in clusters:
    template['metadata'].update({'name': cluster_name})
    policies = template['spec']['additionalPolicies']['node']
    template['spec'].update(
        {'additionalPolicies': {'node': literal(policies)}})
    template['spec'].update({'configBase': kops_state_store})
    template['spec'].update({'dnsZone': dns_zone})

    etcdclusters = []
    etcdmembers = []
    for az in availability_zones:
        etcdmembers.append({'instanceGroup': 'master-' + az, 'name': az[-1:]})
    for name in ['main', 'events']:
        etcdclusters.append({'name': name, 'etcdMembers': etcdmembers})
    template['spec'].update({'etcdClusters': etcdclusters})

    template['spec'].update({'masterPublicName': master_public_name})
    template['spec'].update({'networkCIDR': network_cidr})
    template['spec'].update({
        'topology': {
            'bastion': {
                'bastionPublicName': topology
            },
            'dns': {
                'type': 'Public'
            },
            'masters': 'private',
            'nodes': 'private'
        }
    })

    subnets = []
    if len(internal_subnets) == len(
            external_subnets) == len(availability_zones):
        for i in range(len(external_subnets)):
            subnets.append(
                {
                    'cidr': external_subnets[i],
                    'name': availability_zones[i],
                    'type': 'Private',
                    'zone': availability_zones[i]})
        for i in range(len(internal_subnets)):
            subnets.append(
                {
                    'cidr': internal_subnets[i],
                    'name': 'utility-' + availability_zones[i],
                    'type': 'Utility',
                    'zone': availability_zones[i]})
    template['spec'].update({'subnets': subnets})
    output.append(template)

# Update all instanceGroup kind
for template in instances:
    template['metadata'].update(
        {'labels': {'kops.k8s.io/cluster': cluster_name}})

# Update masters
if len(masters) == len(availability_zones):
    for i in range(len(masters)):
        masters[i]['spec'].update({'subnets': [availability_zones[i]]})
        masters[i]['spec'].update({
            'nodeLabels': {
                'kops.k8s.io/instancegroup': 'master-' + availability_zones[i]
            }
        })
        output.append(masters[i])

# Update nodes
for template in nodes:
    template['spec'].update({'subnets': availability_zones})
    template['spec'].update(
        {'nodeLabels': {'kops.k8s.io/instancegroup': 'nodes'}})
    output.append(template)

# Update bastions
for template in bastions:
    azs = []
    for az in availability_zones:
        azs.append('utility-' + az)
    template['spec'].update({'subnets': azs})
    template['spec'].update(
        {'nodeLabels': {'kops.k8s.io/instancegroup': 'bastions'}})
    output.append(template)

# Print outputs
for item in output:
    print('---')
    print(yaml.safe_dump(item, default_flow_style=False))
