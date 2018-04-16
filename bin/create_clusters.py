 #!/usr/bin/python

import subprocess

try:
  terraform = subprocess.check_output(['terraform', 'workspace', 'list']).decode('utf-8').split()
  terraform.remove('*')
except subprocess.CalledProcessError as e:
  print('error executing terraform command, exit.')

try:
  clusters = [ s.strip('.yaml') for s in subprocess.check_output(['ls', '../../kops/']).decode('utf-8').split() ]
except subprocess.CalledProcessError as e:
  print('error executing terraform command, exit.')

for item in clusters:
  if item in terraform:
    print('cluster ' + item + ' already exists, skipping')
  else:
    print('creating cluster ' + item)

    p = subprocess.Popen('../../bin/create_cluster.sh ' + item, stdout=subprocess.PIPE)
    while p.poll() is None:
      l = p.stdout.readline()
      print l
    print p.stdout.read()
