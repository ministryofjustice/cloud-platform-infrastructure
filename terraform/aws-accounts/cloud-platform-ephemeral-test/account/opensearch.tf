provider "elasticsearch" {
  url                 = "https://${aws_opensearch_domain.live_modsec_audit.endpoint}"
  aws_assume_role_arn = aws_iam_role.os_access_role.arn
  aws_profile         = "moj-et"
  sign_aws_requests   = true
  healthcheck         = false
  sniff               = false
}

locals {
  live_modsec_audit_domain = "cp-live-modsec-audit"
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
  description = "Used for OpenSearch: cp-live-modsec-audit"
  key_usage   = "ENCRYPT_DECRYPT"
  bypass_policy_lockout_safety_check = false
  deletion_window_in_days            = 30
  is_enabled                         = true
  enable_key_rotation                = false
  multi_region                       = false
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
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07" # default to TLS 1.2
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

resource "aws_opensearch_domain_policy" "live_modsec_audit" {
  domain_name     = aws_opensearch_domain.live_modsec_audit.domain_name
  access_policies = data.aws_iam_policy_document.live_modsec_audit.json
}

resource "elasticsearch_opensearch_ism_policy" "ism_policy_live_modsec_audit" {
  policy_id = "hot-warm-cold-delete"
  body      = data.template_file.ism_policy_live_modsec_audit.rendered
  depends_on = [
    aws_opensearch_domain_saml_options.live_modsec_audit,
  ]
}

data "template_file" "ism_policy_live_modsec_audit" {
  template = templatefile("${path.module}/resources/opensearch/ism-policy.json.tpl", {

    timestamp_field   = var.timestamp_field
    warm_transition   = var.warm_transition
    cold_transition   = var.cold_transition
    delete_transition = var.delete_transition
    index_pattern     = jsonencode(var.index_pattern_live_modsec_audit)
  })
}

### AWS Opensearch SAML -- client, rule, metadata and configure opensearch
resource "auth0_client" "opensearch" {
  name                       = "AWS Opensearch SAML for ${data.aws_iam_account_alias.current.account_alias}"
  description                = "Github SAML provider for cloud-platform-ephemeral-test"
  app_type                   = "spa"
  custom_login_page_on       = true
  is_first_party             = true
  token_endpoint_auth_method = "none"

  callbacks = ["https://${aws_opensearch_domain.live_modsec_audit.endpoint}/_dashboards/_opendistro/_security/saml/acs"]
  logo_uri  = "https://ministryofjustice.github.io/assets/moj-crest.png"
  addons {
    samlp {
      audience    = "https://${aws_opensearch_domain.live_modsec_audit.endpoint}"
      destination = "https://${aws_opensearch_domain.live_modsec_audit.endpoint}/_dashboards/_opendistro/_security/saml/acs"
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

resource "auth0_rule" "add-github-teams-to-opensearch-saml" {
  name = "add-github-teams-to-opensearch-saml"
  script = file(
    "${path.module}/resources/auth0-rules/add-github-teams-to-opensearch-saml.js",
  )
  order   = 40
  enabled = true
}

resource "auth0_rule_config" "opensearch-app-client-id" {
  key   = "OPENSEARCH_APP_CLIENT_ID"
  value = auth0_client.opensearch.client_id
}

data "curl" "saml_metadata" {
  http_method = "GET"
  uri         = "https://${var.auth0_tenant_domain}/samlp/metadata/${auth0_client.opensearch.client_id}"
}

resource "aws_opensearch_domain_saml_options" "live_modsec_audit" {
  domain_name = aws_opensearch_domain.live_modsec_audit.domain_name
  saml_options {
    enabled = true
    idp {
      entity_id        = "urn:${var.auth0_tenant_domain}"
      metadata_content = data.curl.saml_metadata.response

    }
    master_backend_role = aws_iam_role.os_access_role.arn
    master_user_name    = aws_iam_role.os_access_role.arn
    roles_key           = "http://schemas.xmlsoap.org/claims/Group"
  }
}

data "aws_eks_node_groups" "current" {
  cluster_name = "pk-test-01" // change to the cluster you need -- note there is no terraform.workspace at the account level
}

data "aws_eks_node_group" "current" {
  for_each = data.aws_eks_node_groups.current.names

  cluster_name    = "pk-test-01"
  node_group_name = each.value
}

# Create a role mapping
resource "elasticsearch_opensearch_roles_mapping" "all_access" {
  role_name   = "all_access"
  description = "Mapping AWS IAM roles to ES role all_access"
  backend_roles = concat([
    "webops",
    aws_iam_role.os_access_role.arn,
  ], values(data.aws_eks_node_group.current)[*].node_role_arn)
  depends_on = [
    aws_opensearch_domain_saml_options.live_modsec_audit,
  ]
}

resource "elasticsearch_opensearch_roles_mapping" "security_manager" {
  role_name   = "security_manager"
  description = "Mapping AWS IAM roles to ES role security_manager"
  backend_roles = concat([
    "webops",
    aws_iam_role.os_access_role.arn,
  ], values(data.aws_eks_node_group.current)[*].node_role_arn)
  depends_on = [
    aws_opensearch_domain_saml_options.live_modsec_audit,
  ]
}
