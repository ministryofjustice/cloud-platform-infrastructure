#!/usr/bin/env python3                                                                                                                                

import subprocess
import json
import shlex

statestore = 'moj-cp-k8s-investigation-kops'
domain = '.k8s.integration.dsd.io'

def run(command):
    process = subprocess.Popen(shlex.split(command), stdout=subprocess.PIPE)
    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            print(output.strip())
    rc = process.poll()
    return rc

# terraform init
try:
    print(subprocess.check_output(['terraform', 'init']))
except subprocess.CalledProcessError as e:
    print('error initing terraform, exit.')

# get terraform workspace list
try:
    workspaces = subprocess.check_output(
        ['terraform', 'workspace', 'list']).decode('utf-8').split()
    workspaces.remove('*')
except subprocess.CalledProcessError as e:
    print('error listing workspaces, exit.')

try:
    yaml = [s.strip('.yaml') for s in subprocess.check_output(
        ['ls', '../../kops/']).decode('utf-8').split()]
except subprocess.CalledProcessError as e:
    print('error listing cluster yaml files, exit.')

# query the kops state store to list the active clusters
try:
    clusters = json.loads(str(subprocess.check_output(
        ['kops', 'get', 'clusters', '--state=s3://' + statestore,
         '--output=json']).decode('utf-8')))
except subprocess.CalledProcessError as e:
    print('error listing clusters, exit.')

# generate a list of cluster names only
clusterlist = []
for item in clusters:
    clusterlist.append(item['metadata']['name'].replace(domain, ''))

# create the corresponding clusters
for item in yaml:
    if item in workspaces and item in clusterlist:
        print('cluster ' + item + ' already exists, skipping')
    else:
        print('creating cluster ' + item)
        run('../../bin/00-cluster_pipeline.sh' + ' ' + item)

print('Done.')
