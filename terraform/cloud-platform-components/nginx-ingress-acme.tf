resource "helm_release" "nginx_ingress_acme" {
  name      = "nginx-ingress-acme"
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
      if ($scheme != 'https') {
        return 308 https://$host$request_uri;
      }

  stats:
    enabled: true

  metrics:
    enabled: true

  service:
    annotations:
      # external-dns.alpha.kubernetes.io/hostname: "*.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"

    externalTrafficPolicy: "Local"

  extraArgs:
    default-ssl-certificate: ingress-controllers/default-certificate

rbac:
  create: true
EOF
  ]

  // Although it _does_ depend on cert-manager for getting the default
  // certificate issued, it's not a hard dependency and will resort to using a
  // self-signed certificate until the proper one becomes available. This
  // dependency is not captured here.
  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

resource "null_resource" "nginx_ingress_default_certificate" {
  depends_on = ["helm_release.cert-manager"]

  provisioner "local-exec" {
    command = "kubectl apply -n ingress-controllers -f ${path.module}/resources/nginx-ingress/default-certificate.yaml"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete -n ingress-controllers -f ${path.module}/resources/nginx-ingress/default-certificate.yaml"
  }

  triggers {
    contents = "${sha1(file("${path.module}/resources/nginx-ingress/default-certificate.yaml"))}"
  }
}

resource "null_resource" "nginx_ingress_servicemonitor" {
  depends_on = ["helm_release.kube_prometheus"]

  provisioner "local-exec" {
    command = "kubectl apply -n ingress-controllers -f ${path.module}/resources/nginx-ingress/servicemonitor.yaml"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete -n ingress-controllers -f ${path.module}/resources/nginx-ingress/servicemonitor.yaml"
  }

  triggers {
    contents = "${sha1(file("${path.module}/resources/nginx-ingress/servicemonitor.yaml"))}"
  }
}
