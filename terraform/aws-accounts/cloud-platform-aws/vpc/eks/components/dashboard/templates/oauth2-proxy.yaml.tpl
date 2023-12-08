#
# This is a redacted version of the upstream values.yaml file found here:
# https://github.com/helm/charts/blob/dea84cfd139f0e7bd7721abfa53e4853c1379c0a/stable/oauth2-proxy/values.yaml
#
replicaCount: 2

config:
  clientID:
  clientSecret:
  cookieSecret:
  # Custom configuration file: oauth2_proxy.cfg
  # configFile: |-
  #   pass_basic_auth = false
  #   pass_access_token = true
  configFile: ""

image:
  imagePullSecrets:
  - name: "dockerhub-credentials"
extraArgs:
  provider: oidc
  oidc-issuer-url: ${issuer_url}
  email-domain: "*"
  upstream: "${upstream}"
  http-address: "0.0.0.0:4180"
  skip-auth-regex: "${exclude_paths}"
  cookie-expire: "7h"
  skip-provider-button: true
  pass-basic-auth: "false"
  pass-host-header: "false"

ingress:
  enabled: false
  className: default
  annotations: {
    external-dns.alpha.kubernetes.io/aws-weight: "100",
    external-dns.alpha.kubernetes.io/set-identifier: "dns-${clusterName}",
    cloud-platform.justice.gov.uk/ignore-external-dns-weight: "true"
  }
  path: /
%{ if ingress_redirect ~}
  hosts:
    - "${hostname}"
    - "${live_domain_hostname}"
  tls:
    - hosts:
      - "${hostname}"
      - "${live_domain_hostname}"
%{ else ~}
  hosts:
    - "${hostname}"
  tls:
    - hosts:
      - "${hostname}"
%{ endif ~}
serviceAccount:
  enabled: true

securityContext:
  enabled: true
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  runAsUser: 2000

sessionStorage:
  # Can be one of the supported session storage cookie/redis
  type: redis
redis:
  # provision an instance of the redis sub-chart
  enabled: true
  architecture: standalone
