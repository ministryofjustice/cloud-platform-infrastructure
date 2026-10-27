# Defers deletion of existing cold app-logs indices. Applied manually with scripts/opensearch/legal-hold.
# Lowering legal_hold_delete_transition deletes every held index older than the new value. See scripts/opensearch/README.md.
resource "elasticsearch_opensearch_ism_policy" "legal_hold_retain_live_app_logs" {
  provider  = elasticsearch.app_logs
  policy_id = "legal-hold-retain"
  body = templatefile("${path.module}/resources/opensearch/ism-policy-legal-hold.json.tpl", {
    delete_transition = var.legal_hold_delete_transition
  })

  depends_on = [
    aws_opensearch_domain_saml_options.live_app_logs,
  ]
}
