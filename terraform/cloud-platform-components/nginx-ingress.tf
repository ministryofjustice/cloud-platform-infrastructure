data "terraform_remote_state" "cloud_platform_state" {
  backend   = "s3"
  workspace = "${terraform.workspace}"

  config {
    region = "eu-west-1"
    bucket = "moj-cp-k8s-investigation-platform-terraform"
    key    = "terraform.tfstate"
  }
}

resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  chart     = "stable/nginx-ingress"
  namespace = "ingress-controller"

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

      external-dns.alpha.kubernetes.io/hostname: "*.apps.${data.terraform_remote_state.cloud_platform_state.cluster_domain_name}"
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "${data.terraform_remote_state.cloud_platform_state.certificate_arn}"
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"

    targetPorts:
      https: 80

    externalTrafficPolicy: "Local"

rbac:
  create: true
serviceAccountName: default
EOF
  ]

  depends_on = [
    "kubernetes_service_account.tiller",
    "kubernetes_cluster_role_binding.tiller",
    "null_resource.deploy",
    "helm_release.external_dns",
  ]
}
