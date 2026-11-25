resource "aws_iam_outbound_web_identity_federation" "this" {}

output "outbound_web_identity_federation_issuer" {
  value = aws_iam_outbound_web_identity_federation.this.issuer_identifier
}