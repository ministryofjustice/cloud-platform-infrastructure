 #!/usr/bin/python

import subprocess, json, argparse, yaml

parser = argparse.ArgumentParser(description='Create Kubernetes clusters.')
parser.add_argument('clusterconfig', help='the base yaml file to create the cluster from')

args = parser.parse_args()
print(args.clusterconfig)

templates = []

stream = open(args.clusterconfig)
for template in yaml.load_all(stream):
  templates.append(template)
stream.close()

try:
 terraform = json.loads(str(subprocess.check_output(['terraform', 'output', '-json']).decode('utf-8')))
except subprocess.CalledProcessError as e:
  print('error executing terraform command')

#dir_namespaces = str(subprocess.check_output(['ls', 'namespaces']).decode('utf-8')).split()
#k8_json = json.loads(str(subprocess.check_output(["kubectl", "get", "namespaces", "-o", "json"]).decode('utf-8')))
#print(subprocess.check_output(['kubectl', 'create', '-f', 'namespaces/' + item + '/namespace.yaml']) )

cluster_name = terraform['cluster_domain_name']['value']

for template  in templates:
#  print(template)
  if template['kind'] == 'Cluster':
    template['metadata'].update({'name': cluster_name })  
    print template

print(terraform)

print(cluster_name)

