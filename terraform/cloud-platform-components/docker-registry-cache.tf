resource "kubernetes_namespace" "docker_registry_cache" {
  metadata {
    name = "docker-registry-cache"

    labels = {
      "name"                                           = "docker-registry-cache"
      "component"                                      = "docker-registry"
      "cloud-platform.justice.gov.uk/environment-name" = "production"
      "cloud-platform.justice.gov.uk/is-production"    = "true"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"   = "docker-registry-cache"
      "cloud-platform.justice.gov.uk/business-unit" = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"   = "https://github.com/ministryofjustice/cloud-platform-docker-registry-cache"
    }
  }
}

data "template_file" "docker_registry_cache_template" {
  template = file("./templates/docker-registry-cache/docker-registry-cache.yaml.tpl")
  vars = {
    cluster_name = terraform.workspace
    nat_gateway_ips = "${data.terraform_remote_state.cluster.outputs.nat_gateway_ips}"
  }
}

resource "null_resource" "docker-registry-cache-namespace-config" {
  provisioner "local-exec" {
    command = "kubectl apply -n docker-registry-cache -f ${path.module}/templates/docker-registry-cache/namespace.yaml"
  }

  provisioner "local-exec" {
    when = destroy
    command = "exit 0"
  }

  triggers = {
    namespace = filesha1("${path.module}/templates/docker-registry-cache/namespace.yaml")
  }

  depends_on = [kubernetes_namespace.docker_registry_cache]
}

resource "null_resource" "docker-registry-cache" {
  provisioner "local-exec" {
    command = <<EOS
kubectl apply -n docker-registry-cache -f - <<EOF
${data.template_file.docker_registry_cache_template.rendered}
EOF
EOS
  }

  # Everything in the namespace will be destroyed when the namespace is deleted.
  # We need the `exit 0` here so that terraform thinks it has successfully
  # destroyed the resource, when it applies changes (by destroying then applying)
  provisioner "local-exec" {
    when = destroy
    command = "exit 0"
  }

  triggers = {
    contents = filesha1("${path.module}/templates/docker-registry-cache/docker-registry-cache.yaml.tpl")
  }

  depends_on = [kubernetes_namespace.docker_registry_cache]
}


