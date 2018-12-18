global:
  ## Hyperkube image to use when getting ThirdPartyResources & cleaning up
  ##
  hyperkube:
    repository: quay.io/coreos/hyperkube
    tag: v1.10.5_coreos.0
    pullPolicy: IfNotPresent

## Prometheus-config-reloader image to use for config and rule reloading
##
prometheusConfigReloader:
  repository: quay.io/coreos/prometheus-config-reloader
  tag: v0.26.0

## Configmap-reload image to use for reloading configmaps
##
configmapReload:
  repository: quay.io/coreos/configmap-reload
  tag: v0.0.1

## Prometheus-operator image
##
image:
  repository: quay.io/coreos/prometheus-operator
  tag: v0.26.0
  pullPolicy: IfNotPresent
