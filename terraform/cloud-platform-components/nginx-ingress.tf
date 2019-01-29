resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  chart     = "stable/nginx-ingress"
  namespace = "ingress-controllers"
  version   = "v1.1.4"

  values = [<<EOF
controller:
  replicaCount: 3
  config:
    generate-request-id: "true"
    proxy-buffer-size: "16k"
    proxy-body-size: "16m"
    server-snippet: |
      if ($http_x_forwarded_proto != 'https') {
        return 308 https://$host$request_uri;
      }
  stats:
    enabled: true
  metrics:
    enabled: true
  service:
    annotations:
      external-dns.alpha.kubernetes.io/hostname: "*.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "${data.terraform_remote_state.cluster.certificate_arn}"
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
    targetPorts:
      https: 80
    externalTrafficPolicy: "Local"
rbac:
  create: true
EOF
  ]

  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
