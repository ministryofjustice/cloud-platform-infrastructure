# Legal hold for the live app-logs OpenSearch domain.
#
# hot-warm-cold-delete deletes cold indices at 366 days. Changing that policy does not affect
# existing indices (each managed index keeps the policy version it was initialised with), and
# re-entering its "cold" state would re-run cold_migration on already-cold indices and fail.
#
# This separate policy has no actions in its "cold" state and only deletes after
# var.legal_hold_delete_transition. It has no ism_template, so it is never attached automatically:
# existing cold indices are moved onto it with change_policy (see scripts/opensearch/README.md).
# hot -> warm -> cold for new indices is unchanged.
#
# To lift the hold: set legal_hold_delete_transition back to "366d", apply, and re-run change_policy.
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
