# Manage CRDs separately so they can be upgraded independently of Envoy Gateway.
# Follow the official approach of rendering the CRD chart and applying its manifests.
# https://gateway.envoyproxy.io/docs/install/install-helm/#upgrading-from-the-previous-version

locals {
  envoy_gateway_crds_version = "v1.10.0"
  gateway_api_channel        = "standard"
}

# Render the official CRD Helm chart into Kubernetes manifests.
data "helm_template" "envoy_gateway_crds" {
  name       = "envoy-gateway-crds"
  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-crds-helm"
  version    = local.envoy_gateway_crds_version

  values = [
    yamlencode({
      crds = {
        gatewayAPI = {
          enabled = true
          channel = local.gateway_api_channel
        }

        envoyGateway = {
          enabled = true
        }
      }
    })
  ]
}

# Split the rendered chart into individual resources for Terraform management.
data "kubectl_file_documents" "envoy_gateway_crds" {
  content = data.helm_template.envoy_gateway_crds.manifest
}

# Apply CRDs and safe-upgrade admission resources using kubectl apply.
resource "kubectl_manifest" "envoy_gateway_crds" {
  for_each = data.kubectl_file_documents.envoy_gateway_crds.manifests

  yaml_body = each.value

  server_side_apply = true
  force_conflicts   = true
  apply_only        = true
}