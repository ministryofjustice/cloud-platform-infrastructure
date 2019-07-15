module "logging" {
  source = "../../modules/logging"
  logging_enabled = "${var.logging_enabled}"
  depends_on = "${null_resource.deploy.id}"
}
