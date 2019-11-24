rbac:
  create: true

sslCertPath: /etc/ssl/certs/ca-bundle.crt

cloudProvider: aws
awsRegion: eu-west-2

autoDiscovery:
  clusterName: ${cluster_name}
  enabled: true

podAnnotations:
  iam.amazonaws.com/role: ${iam_role}