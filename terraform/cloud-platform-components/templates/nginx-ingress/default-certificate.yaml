apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: default
  namespace: ingress-controllers
spec:
  secretName: default-certificate
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  commonName: '${common_name}'
  acme:
    config:
    - dns01:
        provider: route53-cloud-platform
      domains:
      - '${common_name}'
      ${alt_name}
  dnsNames:
    - '${common_name}'
    ${alt_name}
