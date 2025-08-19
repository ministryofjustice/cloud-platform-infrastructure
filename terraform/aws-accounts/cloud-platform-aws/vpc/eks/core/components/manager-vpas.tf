## Defining a map of namespace and deployment/statefulset resources for which to create some VPA resources to monitor
## Concourse cluster resources requests/usage

# This is a temporary home for VPA resources. Future is perhaps a module for CP infrastructure estate??

locals {
	vpa_targets = {
		"ingress-controllers" = [
			{ name = "nginx-ingress-default-controller", kind = "Deployment" }
		]
		"concourse" = [
			{ name = "concourse-web", kind = "Deployment" },
			{ name = "concourse-worker", kind = "StatefulSet" },
			{ name = "concourse-postgresql", kind = "StatefulSet" }
		]
        "monitoring" = [
            { name = "thanos-compactor", kind = "Deployment" }
        ]
	}
	is_manager_workspace = terraform.workspace == "manager"
	vpa_objects = local.is_manager_workspace ? flatten([
		for ns, targets in local.vpa_targets : [
			for target in targets : {
				namespace  = ns
				name       = target.name
				kind       = target.kind
			}
		]
	]) : []
}

resource "kubernetes_manifest" "vpa" {
	for_each = { for obj in local.vpa_objects : "${obj.namespace}/${obj.kind}/${obj.name}" => obj }

	manifest = {
		apiVersion = "autoscaling.k8s.io/v1"
		kind       = "VerticalPodAutoscaler"
		metadata = {
			name      = each.value.name
			namespace = each.value.namespace
		}
		spec = {
			targetRef = {
				apiVersion = "apps/v1"
				kind       = each.value.kind
				name       = each.value.name
			}
			updatePolicy = {
				updateMode = "Off"
			}
		}
	}
}
