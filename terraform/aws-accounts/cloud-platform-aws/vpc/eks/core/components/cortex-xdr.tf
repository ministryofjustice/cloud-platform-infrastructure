module "cortex-xdr" {
    source = "github.com/ministryofjustice/cloud-platform-terraform-cortex-xdr?ref=main"

    xdr_distribution_id = var.cortex_xdr_distribution_id
    xdr_docker_secret   = var.cortex_xdr_docker_secret
    endpoint_tags       = "cloudp,test2"
}