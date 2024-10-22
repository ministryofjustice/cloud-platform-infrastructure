module "global_auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-global-resources-auth0?ref=2.1.5"

  auth0_tenant_domain = local.auth0_tenant_domain
  auth0_groupsClaim   = local.auth0_groupsClaim
}
