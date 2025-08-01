provider "elasticsearch" {
  url                 = "https://${aws_opensearch_domain.live_modsec_audit.endpoint}"
  aws_assume_role_arn = aws_iam_role.os_access_role.arn
  aws_profile         = "moj-cp"
  sign_aws_requests   = true
  healthcheck         = false
  sniff               = false
}

locals {
  live_modsec_audit_domain = "cp-live-modsec-audit"
  mod_sec_tags = {
    Domain = local.live_modsec_audit_domain
  }
}

resource "aws_iam_role" "os_access_role" {
  name               = "opensearch-access-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [
    aws_iam_policy.os_access_policy.arn,
  ]
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_iam_policy" "os_access_policy" {
  name = "opensearch-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["es:*"]
        Effect = "Allow"
        Resource = [
          "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.live_modsec_audit_domain}/*",
        ]
      },
    ]
  })
}

data "aws_iam_policy_document" "live_modsec_audit" {
  statement {
    actions = [
      "es:Describe*",
      "es:List*",
      "es:ESHttpGet",
      "es:ESHttpHead",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpPatch"
    ]

    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.live_modsec_audit_domain}/*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}


resource "aws_kms_key" "live_modsec_audit" {
  description                        = "Used for OpenSearch: cp-live-modsec-audit"
  key_usage                          = "ENCRYPT_DECRYPT"
  bypass_policy_lockout_safety_check = false
  deletion_window_in_days            = 30
  is_enabled                         = true
  enable_key_rotation                = false
  multi_region                       = false
}

data "aws_route53_zone" "cloud_platform_justice_gov_uk" {
  name = "cloud-platform.service.justice.gov.uk."
}

# needed for load balancer cert
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name = "logs.${data.aws_route53_zone.cloud_platform_justice_gov_uk.name}"
  zone_id     = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id

  validation_method   = "DNS"
  wait_for_validation = false # for use in an automated pipeline set false to avoid waiting for validation to complete or error after a 45 minute timeout.

  tags = {
    Domain = local.live_modsec_audit_domain
  }
}


resource "aws_opensearch_domain" "live_modsec_audit" {
  domain_name    = "cp-live-modsec-audit"
  engine_version = "OpenSearch_2.5"

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "indices.query.bool.max_clause_count"    = 3000
    "override_main_response_version"         = "true"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = aws_iam_role.os_access_role.arn
    }
  }

  cluster_config {
    instance_type            = "r6g.xlarge.search"
    instance_count           = "3"
    dedicated_master_enabled = true
    dedicated_master_type    = "m6g.large.search"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true

    zone_awareness_config {
      availability_zone_count = 3
    }

    warm_count   = 3
    warm_enabled = true
    warm_type    = "ultrawarm1.medium.search"

    cold_storage_options {
      enabled = true
    }
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp3"
    volume_size = "500"
    iops        = "3000"
  }

  domain_endpoint_options {
    enforce_https                   = true
    tls_security_policy             = "Policy-Min-TLS-1-2-2019-07" # default to TLS 1.2
    custom_endpoint_enabled         = true
    custom_endpoint_certificate_arn = module.acm.acm_certificate_arn
    custom_endpoint                 = "logs.${data.aws_route53_zone.cloud_platform_justice_gov_uk.name}"
  }

  access_policies = null

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.live_modsec_audit.key_id
  }

  node_to_node_encryption {
    enabled = true
  }

  tags = {
    Domain = local.live_modsec_audit_domain
  }
}

# add vanity url to cluster
resource "aws_route53_record" "opensearch_custom_domain" {
  zone_id = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = "logs"
  type    = "CNAME"
  ttl     = 600 # 10 mins

  records = [aws_opensearch_domain.live_modsec_audit.endpoint]
}

resource "aws_opensearch_domain_policy" "live_modsec_audit" {
  domain_name     = aws_opensearch_domain.live_modsec_audit.domain_name
  access_policies = data.aws_iam_policy_document.live_modsec_audit.json
}

resource "elasticsearch_opensearch_ism_policy" "ism_policy_live_modsec_audit" {
  policy_id = "hot-warm-cold-delete"
  body = templatefile("${path.module}/resources/opensearch/ism-policy.json.tpl", {
    timestamp_field   = var.timestamp_field
    warm_transition   = var.warm_transition
    cold_transition   = var.cold_transition
    delete_transition = var.delete_transition
    index_pattern     = jsonencode(var.index_pattern_live_modsec_audit)
  })

  depends_on = [
    aws_opensearch_domain_saml_options.live_modsec_audit,
  ]
}

resource "elasticsearch_opensearch_ism_policy" "ism_policy_live_modsec_debug" {
  policy_id = "hot-warm-cold-delete-debug"
  body = templatefile("${path.module}/resources/opensearch/ism-policy.json.tpl", {
    timestamp_field   = var.timestamp_field
    warm_transition   = "1d"
    cold_transition   = "3d"
    delete_transition = "7d"
    index_pattern     = jsonencode(["live_k8s_modsec_ingress_debug*"])
  })

  depends_on = [
    aws_opensearch_domain_saml_options.live_modsec_audit,
  ]
}
### AWS Opensearch SAML -- client, rule, metadata and configure opensearch
resource "auth0_client" "opensearch" {
  name                 = "AWS Opensearch SAML for ${data.aws_iam_account_alias.current.account_alias}"
  description          = "Github SAML provider for cloud-platform-aws"
  app_type             = "spa"
  custom_login_page_on = true
  is_first_party       = true

  callbacks = ["https://${aws_route53_record.opensearch_custom_domain.fqdn}/_dashboards/_opendistro/_security/saml/acs"]
  logo_uri  = "https://ministryofjustice.github.io/assets/moj-crest.png"
  addons {
    samlp {
      audience    = "https://${aws_route53_record.opensearch_custom_domain.fqdn}"
      destination = "https://${aws_route53_record.opensearch_custom_domain.fqdn}/_dashboards/_opendistro/_security/saml/acs"
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

resource "auth0_action" "add-github-teams-to-opensearch-saml" {
  name = "add-github-teams-to-opensearch-saml"
  code = file(
    "${path.module}/resources/auth0-actions/add-github-teams-to-opensearch-saml.js",
  )
  deploy  = true
  runtime = "node18"

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }

  secrets {
    name  = "OPENSEARCH_APP_CLIENT_ID"
    value = auth0_client.opensearch.client_id
  }

  secrets {
    name  = "OPENSEARCH_APP_CLIENT_ID_APP_LOGS"
    value = auth0_client.opensearch_app_logs.client_id
  }

  secrets {
    name  = "OPENSEARCH_APP_LIVE2_CLIENT_ID_APP_LOGS"
    value = auth0_client.opensearch_live_2_app_logs.client_id
  }
}

data "http" "saml_metadata" {
  url    = "https://${var.auth0_tenant_domain}/samlp/metadata/${auth0_client.opensearch.client_id}"
  method = "GET"
}

resource "aws_opensearch_domain_saml_options" "live_modsec_audit" {
  domain_name = aws_opensearch_domain.live_modsec_audit.domain_name
  saml_options {
    enabled = true

    idp {
      entity_id        = "urn:${var.auth0_tenant_domain}"
      metadata_content = data.http.saml_metadata.response_body
    }

    master_backend_role = aws_iam_role.os_access_role.arn
    master_user_name    = aws_iam_role.os_access_role.arn
    roles_key           = "http://schemas.xmlsoap.org/claims/Group"
  }
}

data "aws_eks_node_groups" "current" {
  cluster_name = "live" # change to the cluster you need -- note there is no terraform.workspace at the account level
}

data "aws_eks_node_group" "current" {
  for_each = data.aws_eks_node_groups.current.names

  cluster_name    = "live"
  node_group_name = each.value
}

# Create a role mapping
resource "elasticsearch_opensearch_roles_mapping" "all_access" {
  role_name   = "all_access"
  description = "Mapping AWS IAM roles to ES role all_access"
  backend_roles = concat([
    "webops",
    aws_iam_role.os_access_role.arn,
    data.terraform_remote_state.components_live.outputs.fluent_bit_modsec_irsa_arn,
    data.terraform_remote_state.components_live.outputs.fluent_bit_non_prod_modsec_irsa_arn,
  ], values(data.aws_eks_node_group.current)[*].node_role_arn)
  // Permissions to manager-concourse in order to run modsec logging tests
  users = ["arn:aws:iam::754256621582:user/cloud-platform/manager-concourse", "arn:aws:iam::754256621582:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_ae2d551dbf676d8f"]
  depends_on = [
    aws_opensearch_domain_saml_options.live_modsec_audit,
  ]
}

resource "elasticsearch_opensearch_roles_mapping" "security_manager" {
  role_name   = "security_manager"
  description = "Mapping AWS IAM roles to ES role security_manager"
  backend_roles = [
    "webops",
    aws_iam_role.os_access_role.arn,
  ]

  users = [
    "arn:aws:iam::754256621582:user/cloud-platform/manager-concourse",
    "arn:aws:iam::754256621582:user/SteveWilliams",
    "arn:aws:iam::754256621582:user/SabluMiah",
    "arn:aws:iam::754256621582:user/TomSmith",
    "arn:aws:iam::754256621582:user/KyTruong"
  ]

  depends_on = [
    aws_opensearch_domain_saml_options.live_modsec_audit,
  ]
}

# Prevent document security overriding webops role by explicitly allowing webops to view all
resource "elasticsearch_opensearch_role" "webops" {
  role_name   = "webops"
  description = "role for all webops github users"

  cluster_permissions = ["*"]

  index_permissions {
    index_patterns          = ["*"]
    allowed_actions         = ["cluster_all", "indices_all", "unlimited"]
    document_level_security = "{\"match_all\": {}}"
  }

  tenant_permissions {
    tenant_patterns = ["global_tenant"]
    allowed_actions = ["kibana_all_write"]
  }
}

resource "elasticsearch_opensearch_roles_mapping" "webops" {
  role_name     = "webops"
  description   = "Mapping AWS IAM roles to ES role webops"
  backend_roles = ["webops"]
  depends_on = [
    aws_opensearch_domain_saml_options.live_modsec_audit,
    elasticsearch_opensearch_role.webops
  ]
}

# Create a role that restricts users from viewing documents for teams they are not members of
resource "elasticsearch_opensearch_role" "all_org_members" {
  role_name   = "all_org_members"
  description = "role for all moj github users"

  cluster_permissions = [
    "search",
    "data_access",
    "read",
    "opensearch_dashboards_all_read",
    "get",
    "cluster:admin/opendistro/alerting/alerts/get",
    "cluster:admin/opendistro/alerting/alerts/ack",
    "cluster:admin/opendistro/alerting/monitors/get",
    "cluster:admin/opendistro/alerting/monitors/search",
    "cluster:admin/opensearch/notifications/configs/get"
  ]

  index_permissions {
    index_patterns  = ["*"]
    allowed_actions = ["read", "search", "data_access"]
  }

  index_permissions {
    index_patterns  = ["live_k8s_modsec_ingress-*"]
    allowed_actions = ["read", "search", "data_access"]

    document_level_security = "{\"terms\": { \"github_teams.keyword\": [$${user.roles}]}}"
  }

  tenant_permissions {
    tenant_patterns = ["global_tenant"]
    allowed_actions = ["kibana_all_read"]
  }
}

resource "elasticsearch_opensearch_roles_mapping" "all_org_members" {
  role_name     = "all_org_members"
  description   = "Mapping AWS IAM roles to ES role all_org_members"
  backend_roles = ["all-org-members"]
  depends_on = [
    aws_opensearch_domain_saml_options.live_modsec_audit,
    elasticsearch_opensearch_role.all_org_members
  ]
}

module "live_mod_sec_opensearch_monitoring" {
  source                                   = "github.com/ministryofjustice/cloud-platform-terraform-opensearch-cloudwatch-alarm?ref=0.0.2"
  alarm_name_prefix                        = "CP-live-mod-sec-"
  domain_name                              = local.live_modsec_audit_domain
  sns_topic                                = module.baselines.slack_sns_topic
  min_available_nodes                      = aws_opensearch_domain.live_modsec_audit.cluster_config[0].instance_count
  monitor_free_storage_space_total_too_low = true

  # Using this calculation of (size-in-gb * 25% * 1024) because 25% is the best-practice for low disk, per AWS's recommendations. This value is in MiB so need to * 1024
  free_storage_space_threshold = aws_opensearch_domain.live_modsec_audit.ebs_options[0].volume_size * 0.25 * 1024

  # Using this calculation of (size-in-gb * total instance count * 25% * 1024) because 25% is the best-practice for low disk, per AWS's recommendations. This value is in MiB so need to * 1024
  free_storage_space_total_threshold = aws_opensearch_domain.live_modsec_audit.ebs_options[0].volume_size * aws_opensearch_domain.live_modsec_audit.cluster_config[0].instance_count * 0.25 * 1024
  tags                               = local.mod_sec_tags
}
