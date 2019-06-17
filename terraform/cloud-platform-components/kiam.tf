resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm     = tls_private_key.ca.algorithm
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  validity_period_hours = 87600 // 10 years
  early_renewal_hours   = 720   // 1 month

  subject {
    common_name = "Kiam CA"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "tls_private_key" "agent" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "agent" {
  key_algorithm   = tls_private_key.agent.algorithm
  private_key_pem = tls_private_key.agent.private_key_pem

  subject {
    common_name = "Kiam Agent"
  }
}

resource "tls_locally_signed_cert" "agent" {
  cert_request_pem   = tls_cert_request.agent.cert_request_pem
  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760 // 1 year
  early_renewal_hours   = 720  // 1 month

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth",
  ]
}

resource "tls_private_key" "server" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "server" {
  key_algorithm   = tls_private_key.server.algorithm
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name = "Kiam Server"
  }

  dns_names = [
    "kiam-server",
  ]

  ip_addresses = [
    "127.0.0.1",
  ]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760 // 1 year
  early_renewal_hours   = 720  // 1 month

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth",
  ]
}

data "template_file" "kiam" {
  template = file("${path.module}/templates/kiam.yaml.tpl")

  vars = {
    kiam_version = "v3.0"
    ca           = base64encode(tls_self_signed_cert.ca.cert_pem)
    agent_cert   = base64encode(tls_locally_signed_cert.agent.cert_pem)
    agent_key    = base64encode(tls_private_key.agent.private_key_pem)
    server_cert  = base64encode(tls_locally_signed_cert.server.cert_pem)
    server_key   = base64encode(tls_private_key.server.private_key_pem)
  }
}

resource "null_resource" "kube_system_kiam_annotation" {
  provisioner "local-exec" {
    command = "kubectl annotate --overwrite namespace kube-system 'iam.amazonaws.com/permitted=.*'"
  }
}

resource "helm_release" "kiam" {
  name          = "kiam"
  chart         = "stable/kiam"
  namespace     = "kiam"
  version       = "2.0.0-rc3"
  recreate_pods = "true"

  values = [
    data.template_file.kiam.rendered,
  ]

  depends_on = [null_resource.deploy]

  lifecycle {
    ignore_changes = [keyring]
  }
}

resource "kubernetes_service" "server-metrics" {
  depends_on = [helm_release.kiam]

  metadata {
    name      = "kiam-server-metrics"
    namespace = "kiam"

    labels = {
      app       = "kiam"
      component = "server-metrics"
    }
  }

  spec {
    selector = {
      component = "server"
    }

    port {
      name        = "metrics"
      port        = 9621
      target_port = 9621
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service" "agent-metrics" {
  depends_on = [helm_release.kiam]

  metadata {
    name      = "kiam-agent-metrics"
    namespace = "kiam"

    labels = {
      app       = "kiam"
      component = "agent-metrics"
    }
  }

  spec {
    selector = {
      component = "agent"
    }

    port {
      name        = "metrics"
      port        = 9620
      target_port = 9620
      protocol    = "TCP"
    }
  }
}

