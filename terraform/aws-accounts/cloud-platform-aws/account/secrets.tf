#############################################
# Secrets for use across the Cloud Platform #
#############################################

# CircleCI Organisation ID
resource "aws_secretsmanager_secret" "circleci" {
  name        = "cloud-platform-circleci"
  description = "CircleCI organisation ID for ministryofjustice, used for OIDC IAM policies"
}

resource "aws_secretsmanager_secret_version" "circleci" {
  secret_id = aws_secretsmanager_secret.circleci.id
  secret_string = jsonencode({
    organisation_id = "CHANGE_ME_IN_THE_CONSOLE" # change this value manually in the console once the secret is created
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}