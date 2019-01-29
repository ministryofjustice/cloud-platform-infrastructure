# This file will be populated by terraform and must not be used manually.
# This is a YAML-formatted file.

# Application definition to be placed behind the proxy.
replicaCount: 1

image:
  repository: evry/oidc-proxy
  tag: v1.3.0
  pullPolicy: Always

nameOverride: ""
fullnameOverride: ""

# OIDC service
service:
  type: ClusterIP
  port: 80

# Application
application:
  serviceName: ${ application_service_name }
  port: ${ application_port }
  hostName: ${ application_hostname }
  healthCheck:
    enabled: ${ application_healthcheck }
    path: ${ application_healthcheck_port }

resources:
  limits:
    cpu: 5m
    memory: 64Mi
  requests:
    cpu: 5m
    memory: 64Mi

# OIDC prvider
oidc:
  clientId: ${ oidc_client_id }
  clientSecret: ${ oidc_client_secret }
  discovery: "https://moj-cloud-platforms-dev.eu.auth0.com/.well-known/openid-configuration"
  renewToken: "true"
  sessionName: "oidc_proxy"
  sessionSecret: ${ oidc_session_secret }