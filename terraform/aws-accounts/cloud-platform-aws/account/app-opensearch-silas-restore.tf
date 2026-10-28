# Temporary domain for restoring cold app-logs indices away from live.
# https://github.com/ministryofjustice/cloud-platform-security-issues/issues/150
# Off by default (enable_silas_log_restore). First enable: apply -target=aws_opensearch_domain.silas_log_restore, then a full apply.
# Readers are mapped by GitHub team and can only read silas150-extract-*.

locals {
  silas_log_restore_domain  = "cp-silas-log-restore"
  silas_log_restore_count   = var.enable_silas_log_restore ? 1 : 0
  silas_log_restore_fqdn    = "silas-log-restore.${data.aws_route53_zone.cloud_platform_justice_gov_uk.name}"
  silas_log_restore_tags    = { Domain = local.silas_log_restore_domain }
  silas_log_restore_sso_arn = "arn:aws:iam::754256621582:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_ae2d551dbf676d8f"
  manager_concourse_arn     = "arn:aws:iam::754256621582:user/cloud-platform/manager-concourse"
}

provider "elasticsearch" {
  alias               = "silas_log_restore"
  url                 = try("https://${aws_opensearch_domain.silas_log_restore[0].endpoint}", "https://localhost")
  aws_assume_role_arn = try(aws_iam_role.os_access_role_silas_log_restore[0].arn, null)
  aws_profile         = "moj-cp"
  sign_aws_requests   = true
  healthcheck         = false
  sniff               = false
}

provider "opensearch" {
  alias               = "silas_log_restore"
  url                 = try("https://${aws_opensearch_domain.silas_log_restore[0].endpoint}", "https://localhost")
  aws_assume_role_arn = try(aws_iam_role.os_access_role_silas_log_restore[0].arn, null)
  aws_profile         = "moj-cp"
  sign_aws_requests   = true
  healthcheck         = false
  sniff               = false
}

# IAM role used by terraform as the domain's master user
resource "aws_iam_role" "os_access_role_silas_log_restore" {
  count              = local.silas_log_restore_count
  name               = "opensearch-access-role-silas-log-restore"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_silas_log_restore.json
}

data "aws_iam_policy_document" "assume_role_policy_silas_log_restore" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [local.manager_concourse_arn, local.silas_log_restore_sso_arn]
    }
  }
}

resource "aws_iam_role_policy" "os_access_policy_silas_log_restore" {
  count = local.silas_log_restore_count
  name  = "opensearch-access-policy-silas-log-restore"
  role  = aws_iam_role.os_access_role_silas_log_restore[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["es:*"],
        Effect   = "Allow",
        Resource = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.silas_log_restore_domain}/*"]
      },
      {
        Action   = ["iam:PassRole"],
        Effect   = "Allow",
        Resource = aws_iam_role.opensearch_snapshot_role.arn
      }
    ]
  })
}

# Domain
resource "aws_kms_key" "silas_log_restore" {
  count                   = local.silas_log_restore_count
  description             = "Used for OpenSearch: ${local.silas_log_restore_domain}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

module "acm_silas_log_restore" {
  count   = local.silas_log_restore_count
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name         = local.silas_log_restore_fqdn
  zone_id             = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  validation_method   = "DNS"
  wait_for_validation = false

  tags = local.silas_log_restore_tags
}

resource "aws_opensearch_domain" "silas_log_restore" {
  count          = local.silas_log_restore_count
  domain_name    = local.silas_log_restore_domain
  engine_version = "OpenSearch_2.13" # must be >= live to restore its snapshots

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "override_main_response_version"         = "true"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = aws_iam_role.os_access_role_silas_log_restore[0].arn
    }
  }

  cluster_config {
    instance_type            = var.silas_log_restore_instance_type
    instance_count           = 3
    dedicated_master_enabled = false
    zone_awareness_enabled   = true

    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.silas_log_restore_volume_size
  }

  domain_endpoint_options {
    enforce_https                   = true
    tls_security_policy             = "Policy-Min-TLS-1-2-2019-07"
    custom_endpoint_enabled         = true
    custom_endpoint_certificate_arn = module.acm_silas_log_restore[0].acm_certificate_arn
    custom_endpoint                 = local.silas_log_restore_fqdn
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.silas_log_restore[0].key_id
  }

  node_to_node_encryption {
    enabled = true
  }

  tags = local.silas_log_restore_tags
}

# Alarms
# No CloudWatch log publishing: the account is at the 10 CloudWatch Logs resource policy limit in eu-west-2.
module "silas_log_restore_opensearch_monitoring" {
  count                                       = local.silas_log_restore_count
  source                                      = "github.com/ministryofjustice/cloud-platform-terraform-opensearch-cloudwatch-alarm?ref=0.0.2"
  alarm_name_prefix                           = "CP-silas-log-restore-"
  domain_name                                 = local.silas_log_restore_domain
  sns_topic                                   = module.baselines.slack_sns_topic
  min_available_nodes                         = aws_opensearch_domain.silas_log_restore[0].cluster_config[0].instance_count
  monitor_free_storage_space_total_too_low    = true
  monitor_master_cpu_utilization_too_high     = false
  monitor_master_jvm_memory_pressure_too_high = false

  free_storage_space_threshold       = var.silas_log_restore_volume_size * 0.25 * 1024
  free_storage_space_total_threshold = var.silas_log_restore_volume_size * aws_opensearch_domain.silas_log_restore[0].cluster_config[0].instance_count * 0.25 * 1024
  tags                               = local.silas_log_restore_tags
}

resource "aws_route53_record" "silas_log_restore" {
  count   = local.silas_log_restore_count
  zone_id = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = "silas-log-restore"
  type    = "CNAME"
  ttl     = 600
  records = [aws_opensearch_domain.silas_log_restore[0].endpoint]
}

# Principal must be "*": SAML Dashboards requests are not SigV4-signed. Fine-grained access control is the gate.
data "aws_iam_policy_document" "silas_log_restore" {
  statement {
    actions   = ["es:ESHttp*"]
    resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.silas_log_restore_domain}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  # SQL errors reveal whether an index exists
  statement {
    effect    = "Deny"
    actions   = ["es:*"]
    resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.silas_log_restore_domain}/_plugins/_sql"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_opensearch_domain_policy" "silas_log_restore" {
  count           = local.silas_log_restore_count
  domain_name     = aws_opensearch_domain.silas_log_restore[0].domain_name
  access_policies = data.aws_iam_policy_document.silas_log_restore.json
}

# SAML (Auth0 / GitHub login)
resource "auth0_client" "opensearch_silas_log_restore" {
  count                = local.silas_log_restore_count
  name                 = "AWS Opensearch SAML for ${data.aws_iam_account_alias.current.account_alias} for silas log restore"
  description          = "Github SAML provider for the temporary SiLAS log restore OpenSearch domain"
  app_type             = "spa"
  custom_login_page_on = true
  is_first_party       = true

  callbacks = ["https://${local.silas_log_restore_fqdn}/_dashboards/_opendistro/_security/saml/acs"]
  logo_uri  = "https://ministryofjustice.github.io/assets/moj-crest.png"
  addons {
    samlp {
      audience    = "https://${local.silas_log_restore_fqdn}"
      destination = "https://${local.silas_log_restore_fqdn}/_dashboards/_opendistro/_security/saml/acs"
      mappings = {
        email  = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
        name   = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
        groups = "http://schemas.xmlsoap.org/claims/Group"
      }
      include_attribute_name_format      = false
      create_upn_claim                   = false
      passthrough_claims_with_no_mapping = false
      map_unknown_claims_as_is           = false
      map_identities                     = false
      name_identifier_format             = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
      name_identifier_probes             = ["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
      lifetime_in_seconds                = 36000
    }
  }
}

data "http" "saml_metadata_silas_log_restore" {
  count  = local.silas_log_restore_count
  url    = "https://${var.auth0_tenant_domain}/samlp/metadata/${auth0_client.opensearch_silas_log_restore[0].client_id}"
  method = "GET"
}

resource "aws_opensearch_domain_saml_options" "silas_log_restore" {
  count       = local.silas_log_restore_count
  domain_name = aws_opensearch_domain.silas_log_restore[0].domain_name
  saml_options {
    enabled = true
    idp {
      entity_id        = "urn:${var.auth0_tenant_domain}"
      metadata_content = data.http.saml_metadata_silas_log_restore[0].response_body
    }
    master_backend_role = aws_iam_role.os_access_role_silas_log_restore[0].arn
    roles_key           = "http://schemas.xmlsoap.org/claims/Group"
  }
}

# Roles
resource "elasticsearch_opensearch_roles_mapping" "all_access_silas_log_restore" {
  count         = local.silas_log_restore_count
  provider      = elasticsearch.silas_log_restore
  role_name     = "all_access"
  description   = "Platform admins and the restore pipeline"
  backend_roles = ["webops", aws_iam_role.os_access_role_silas_log_restore[0].arn]
  users         = [local.manager_concourse_arn, local.silas_log_restore_sso_arn]
  depends_on    = [aws_opensearch_domain_saml_options.silas_log_restore]
}

resource "elasticsearch_opensearch_role" "silas_log_restore_reader" {
  count       = local.silas_log_restore_count
  provider    = elasticsearch.silas_log_restore
  role_name   = "silas_log_restore_reader"
  description = "Read-only access to extracted silas150-extract-* indices"

  cluster_permissions = [
    "cluster_composite_ops_ro",
    "cluster:admin/opendistro/reports/definition/create",
    "cluster:admin/opendistro/reports/definition/get",
    "cluster:admin/opendistro/reports/definition/list",
    "cluster:admin/opendistro/reports/definition/on_demand",
    "cluster:admin/opendistro/reports/instance/get",
    "cluster:admin/opendistro/reports/instance/list",
    "cluster:admin/opendistro/reports/menu/download",
  ]

  index_permissions {
    index_patterns  = ["silas150-extract-*"]
    allowed_actions = ["read", "search", "data_access", "indices:monitor/settings/get"]
  }

  tenant_permissions {
    tenant_patterns = ["global_tenant"]
    allowed_actions = ["kibana_all_read"]
  }

  depends_on = [aws_opensearch_domain_saml_options.silas_log_restore]
}

resource "elasticsearch_opensearch_roles_mapping" "silas_log_restore_reader" {
  count         = local.silas_log_restore_count
  provider      = elasticsearch.silas_log_restore
  role_name     = elasticsearch_opensearch_role.silas_log_restore_reader[0].role_name
  backend_roles = var.silas_log_restore_reader_teams
  depends_on    = [elasticsearch_opensearch_role.silas_log_restore_reader]
}

resource "elasticsearch_opensearch_roles_mapping" "reports_silas_log_restore" {
  count         = local.silas_log_restore_count
  provider      = elasticsearch.silas_log_restore
  role_name     = "reports_instances_read_access"
  backend_roles = var.silas_log_restore_reader_teams
  depends_on    = [aws_opensearch_domain_saml_options.silas_log_restore]
}

resource "elasticsearch_opensearch_roles_mapping" "opensearch_dashboards_user_silas_log_restore" {
  count         = local.silas_log_restore_count
  provider      = elasticsearch.silas_log_restore
  role_name     = "opensearch_dashboards_user"
  backend_roles = var.silas_log_restore_reader_teams
  depends_on    = [aws_opensearch_domain_saml_options.silas_log_restore]
}

# Snapshot repository (same S3 repo and role as live)
resource "opensearch_snapshot_repository" "silas_log_restore" {
  count    = local.silas_log_restore_count
  provider = opensearch.silas_log_restore
  name     = "${local.live_app_logs_domain}-snapshot-s3-repository"
  type     = "s3"

  # Live writes to this repository; other clusters must register it read-only.
  settings = {
    bucket   = module.s3_bucket_live_app_log.s3_bucket_id
    region   = data.aws_region.current.name
    role_arn = aws_iam_role.opensearch_snapshot_role.arn
    readonly = "true"
  }

  depends_on = [elasticsearch_opensearch_roles_mapping.all_access_silas_log_restore]
}
