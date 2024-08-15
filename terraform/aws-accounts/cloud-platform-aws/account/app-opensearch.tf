provider "elasticsearch" {
  alias               = "app_logs"
  url                 = "https://${aws_opensearch_domain.live_app_logs.endpoint}"
  aws_assume_role_arn = aws_iam_role.os_access_role_app_logs.arn
  aws_profile         = "moj-cp"
  sign_aws_requests   = true
  healthcheck         = false
  sniff               = false
}

locals {
  live_app_logs_domain = "cp-live-app-logs"
  app_logs_tags = {
    Domain = local.live_app_logs_domain
  }
}

data "aws_eks_node_groups" "manager" {
  cluster_name = "manager" # change to the cluster you need -- note there is no terraform.workspace at the account level
}

data "aws_eks_node_group" "manager" {
  for_each = data.aws_eks_node_groups.manager.names

  cluster_name    = "manager"
  node_group_name = each.value
}

resource "aws_iam_role" "os_access_role_app_logs" {
  name               = "opensearch-access-role-app-logs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_app_logs.json
  managed_policy_arns = [
    aws_iam_policy.os_access_policy_app_logs.arn,
  ]
}

data "aws_iam_policy_document" "assume_role_policy_app_logs" {
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

resource "aws_iam_policy" "os_access_policy_app_logs" {
  name = "opensearch-access-policy-app-logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["es:*"]
        Effect = "Allow"
        Resource = [
          "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.live_app_logs_domain}/*",
        ]
      },
    ]
  })
}

data "aws_iam_policy_document" "live_app_logs" {
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
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.live_app_logs_domain}/*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}


resource "aws_kms_key" "live_app_logs" {
  description                        = "Used for OpenSearch: cp-live-app-logs"
  key_usage                          = "ENCRYPT_DECRYPT"
  bypass_policy_lockout_safety_check = false
  deletion_window_in_days            = 30
  is_enabled                         = true
  enable_key_rotation                = false
  multi_region                       = false
}

# needed for load balancer cert
module "acm_app_logs" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.0.0"

  domain_name = "app-logs.${data.aws_route53_zone.cloud_platform_justice_gov_uk.name}"
  zone_id     = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id

  validation_method   = "DNS"
  wait_for_validation = false # for use in an automated pipeline set false to avoid waiting for validation to complete or error after a 45 minute timeout.

  tags = {
    Domain = local.live_app_logs_domain
  }
}

resource "aws_opensearch_domain" "live_app_logs" {
  domain_name    = "cp-live-app-logs"
  engine_version = "OpenSearch_2.13"

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
      master_user_arn = aws_iam_role.os_access_role_app_logs.arn
    }
  }

  cluster_config {
    instance_type            = "r6g.4xlarge.search"
    instance_count           = "15"
    dedicated_master_enabled = true
    dedicated_master_type    = "m6g.large.search"
    dedicated_master_count   = "5"
    zone_awareness_enabled   = true

    zone_awareness_config {
      availability_zone_count = 3
    }

    warm_count   = 15
    warm_enabled = true
    warm_type    = "ultrawarm1.medium.search"

    cold_storage_options {
      enabled = true
    }
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp3"
    volume_size = "12000"
    iops        = "20000" # limit is between 15,000 and 20,000 https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html
    throughput  = "593"   # Throughput scales proportionally up. iops x 0.25 (maximum 4,000) https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose.html
  }

  domain_endpoint_options {
    enforce_https                   = true
    tls_security_policy             = "Policy-Min-TLS-1-2-2019-07" # default to TLS 1.2
    custom_endpoint_enabled         = true
    custom_endpoint_certificate_arn = module.acm_app_logs.acm_certificate_arn
    custom_endpoint                 = "app-logs.${data.aws_route53_zone.cloud_platform_justice_gov_uk.name}"
  }

  access_policies = null

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.live_app_logs.key_id
  }

  node_to_node_encryption {
    enabled = true
  }

  tags = {
    Domain = local.live_app_logs_domain
  }
}

# add vanity url to cluster
resource "aws_route53_record" "opensearch_custom_domain_app_logs" {
  zone_id = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = "app-logs"
  type    = "CNAME"
  ttl     = 600 # 10 mins

  records = [aws_opensearch_domain.live_app_logs.endpoint]
}

resource "aws_opensearch_domain_policy" "live_app_logs" {
  domain_name     = aws_opensearch_domain.live_app_logs.domain_name
  access_policies = data.aws_iam_policy_document.live_app_logs.json
}

resource "elasticsearch_opensearch_ism_policy" "ism_policy_live_app_logs" {
  provider  = elasticsearch.app_logs
  policy_id = "hot-warm-cold-delete"
  body = templatefile("${path.module}/resources/opensearch/ism-policy.json.tpl", {
    timestamp_field   = var.timestamp_field
    warm_transition   = var.warm_transition
    cold_transition   = var.cold_transition
    delete_transition = var.delete_transition
    index_pattern     = jsonencode(var.index_pattern_live_app_logs)
  })

  depends_on = [
    aws_opensearch_domain_saml_options.live_app_logs,
  ]
}

resource "aws_opensearch_domain_saml_options" "live_app_logs" {
  domain_name = aws_opensearch_domain.live_app_logs.domain_name
  saml_options {
    enabled = true

    idp {
      entity_id        = "urn:${var.auth0_tenant_domain}"
      metadata_content = data.http.saml_metadata_app_logs.response_body
    }

    master_backend_role = aws_iam_role.os_access_role_app_logs.arn
    master_user_name    = aws_iam_role.os_access_role_app_logs.arn
    roles_key           = "http://schemas.xmlsoap.org/claims/Group"
  }
}


# Create a role mapping
resource "elasticsearch_opensearch_roles_mapping" "all_access_app_logs" {
  provider    = elasticsearch.app_logs
  role_name   = "all_access"
  description = "Mapping AWS IAM roles to ES role all_access"
  backend_roles = concat([
    "webops",
    aws_iam_role.os_access_role_app_logs.arn,
  ], values(data.aws_eks_node_group.current)[*].node_role_arn, values(data.aws_eks_node_group.manager)[*].node_role_arn)

  // Permissions to manager-concourse in order to run logging tests
  users = ["arn:aws:iam::754256621582:user/cloud-platform/manager-concourse"]
  depends_on = [
    aws_opensearch_domain_saml_options.live_app_logs,
  ]
}

resource "elasticsearch_opensearch_roles_mapping" "security_manager_app_logs" {
  provider    = elasticsearch.app_logs
  role_name   = "security_manager"
  description = "Mapping AWS IAM roles to ES role security_manager"
  backend_roles = [
    "webops",
    aws_iam_role.os_access_role_app_logs.arn,
  ]

  users = [
    "arn:aws:iam::754256621582:user/cloud-platform/manager-concourse",
    "arn:aws:iam::754256621582:user/JaskaranSarkaria",
    "arn:aws:iam::754256621582:user/PoornimaKrishnasamy",
    "arn:aws:iam::754256621582:user/SteveWilliams",
    "arn:aws:iam::754256621582:user/SabluMiah",
    "arn:aws:iam::754256621582:user/TomSmith",
    "arn:aws:iam::754256621582:user/KyTruong"
  ]

  depends_on = [
    aws_opensearch_domain_saml_options.live_app_logs,
  ]
}

# Prevent document security overriding webops role by explicitly allowing webops to view all
resource "elasticsearch_opensearch_role" "webops_app_logs" {
  provider    = elasticsearch.app_logs
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

resource "elasticsearch_opensearch_roles_mapping" "webops_app_logs" {
  provider      = elasticsearch.app_logs
  role_name     = "webops"
  description   = "Mapping AWS IAM roles to ES role webops"
  backend_roles = ["webops"]
  depends_on = [
    aws_opensearch_domain_saml_options.live_app_logs,
    elasticsearch_opensearch_role.webops_app_logs
  ]
}

resource "elasticsearch_opensearch_role" "all_org_members_app_logs" {
  provider    = elasticsearch.app_logs
  role_name   = "all_org_members"
  description = "role for all moj github users"

  cluster_permissions = ["search", "data_access", "read", "opensearch_dashboards_all_read", "get"]

  index_permissions {
    index_patterns  = ["*"]
    allowed_actions = ["read", "search", "data_access"]
  }

  index_permissions {
    index_patterns  = ["live_kubernetes_cluster-*"]
    allowed_actions = ["read", "search", "data_access"]

    document_level_security = "{\"terms\": { \"github_teams.keyword\": [$${user.roles}]}}"
  }

  tenant_permissions {
    tenant_patterns = ["global_tenant"]
    allowed_actions = ["kibana_all_read"]
  }
}

resource "elasticsearch_opensearch_roles_mapping" "all_org_members_app_logs" {
  provider      = elasticsearch.app_logs
  role_name     = "all_org_members"
  description   = "Mapping AWS IAM roles to ES role all_org_members"
  backend_roles = ["all-org-members"]
  depends_on = [
    aws_opensearch_domain_saml_options.live_app_logs,
    elasticsearch_opensearch_role.all_org_members_app_logs
  ]
}

data "http" "saml_metadata_app_logs" {
  url    = "https://${var.auth0_tenant_domain}/samlp/metadata/${auth0_client.opensearch_app_logs.client_id}"
  method = "GET"
}

### AWS Opensearch SAML -- client, rule, metadata and configure opensearch
resource "auth0_client" "opensearch_app_logs" {
  name                       = "AWS Opensearch SAML for ${data.aws_iam_account_alias.current.account_alias} for user app logs"
  description                = "Github SAML provider for cloud-platform live cluster for application logs"
  app_type                   = "spa"
  custom_login_page_on       = true
  is_first_party             = true
  token_endpoint_auth_method = "none"

  callbacks = ["https://${aws_route53_record.opensearch_custom_domain_app_logs.fqdn}/_dashboards/_opendistro/_security/saml/acs"]
  logo_uri  = "https://ministryofjustice.github.io/assets/moj-crest.png"
  addons {
    samlp {
      audience    = "https://${aws_route53_record.opensearch_custom_domain_app_logs.fqdn}"
      destination = "https://${aws_route53_record.opensearch_custom_domain_app_logs.fqdn}/_dashboards/_opendistro/_security/saml/acs"
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

resource "auth0_rule_config" "opensearch_app_logs_client_id" {
  key   = "OPENSEARCH_APP_CLIENT_ID_APP_LOGS"
  value = auth0_client.opensearch_app_logs.client_id
}

module "live_app_logs_opensearch_monitoring" {
  source                                   = "github.com/ministryofjustice/cloud-platform-terraform-opensearch-cloudwatch-alarm?ref=0.0.2"
  alarm_name_prefix                        = "CP-live-app-logs-"
  domain_name                              = local.live_app_logs_domain
  sns_topic                                = module.baselines.slack_sns_topic
  min_available_nodes                      = aws_opensearch_domain.live_app_logs.cluster_config[0].instance_count
  monitor_free_storage_space_total_too_low = true
  free_storage_space_total_threshold       = 20480 * aws_opensearch_domain.live_app_logs.cluster_config[0].instance_count
  tags                                     = local.app_logs_tags
}

