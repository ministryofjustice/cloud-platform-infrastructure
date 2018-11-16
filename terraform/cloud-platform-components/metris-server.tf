resource "helm_release" "metrics_server" {
  name      = "metrics-server"
  chart     = "stable/metrics-server"
  namespace = "kube-system"
  keyring   = ""
  version   = "2.0.4"

  values = [<<EOF
rbac:
  create: true

serviceaccount:
  create: true

apiservice:
  create: true

image:
  repository: gcr.io/google_containers/metrics-server-amd64
  tag: v0.3.1
  pullpolicy: IfNotPresent

args:
  value[0]: "--kubelet-insecure-tls"
  value[1]: "--logtostderr"

EOF
  ]
}
