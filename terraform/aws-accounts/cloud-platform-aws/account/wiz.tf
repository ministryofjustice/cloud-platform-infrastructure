############################################################################
# Wiz read-only access role                                                #
#                                                                          #
# Mirrors the role the Wiz StackSet creates in other MoJ accounts:         #
# ministryofjustice/aws-root-account modules/wiz-stackset and              #
# organisation-security/terraform/wiz.tf. Same vendor module and version   #
# as aws-root-account management-account/terraform/wiz.tf.                 #
# Role: WizAccess-Role. The EKS clusters map it to the read-only           #
# "wiz-reader" Kubernetes group (vpc/eks/cluster.tf).                      #
############################################################################

locals {
  # Set to true once the cloud-platform/wiz-connector secret holds the real values.
  wiz_enabled = false
}

resource "aws_secretsmanager_secret" "wiz_connector" {
  name        = "cloud-platform/wiz-connector"
  description = "Wiz AWS connector external ID and Wiz trust role ARN, used by the WizAccess-Role trust policy"
}

resource "aws_secretsmanager_secret_version" "wiz_connector" {
  secret_id = aws_secretsmanager_secret.wiz_connector.id
  secret_string = jsonencode({
    external_id = "<WIZ_EXTERNAL_ID>"           # change this value manually in the console once the secret is created
    role_arn    = "<WIZ_TRUSTED_PRINCIPAL_ARN>" # change this value manually in the console once the secret is created
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Only read while enabled, so the placeholder value is never used in a trust policy.
data "aws_secretsmanager_secret_version" "wiz_connector" {
  count      = local.wiz_enabled ? 1 : 0
  secret_id  = aws_secretsmanager_secret.wiz_connector.id
  depends_on = [aws_secretsmanager_secret_version.wiz_connector]
}

locals {
  wiz_secret    = one(data.aws_secretsmanager_secret_version.wiz_connector[*].secret_string)
  wiz_connector = local.wiz_secret == null ? null : sensitive(jsondecode(local.wiz_secret))
}

# Wiz's own module. The checksum pins the reviewed archive; init fails if it changes.
module "wiz" {
  source = "https://wizio-public.s3.amazonaws.com/deployment-v3/aws/terraform/2796/wiz-aws-native-terraform-terraform-module.zip?checksum=sha256:ada51284d49dd3e6e2f1862385acd725dbadec693335b5af4f458763b21fbd06"
  count  = local.wiz_enabled ? 1 : 0

  external-id = local.wiz_connector.external_id
  remote-arn  = local.wiz_connector.role_arn

  # Feature switches match the StackSet's wiz_template_parameters.
  cloud-cost-scanning       = true  # CloudCostScanning
  data-scanning             = false # DataScanning
  eks-scanning              = false # EKSScanning (cluster access is via aws-auth instead)
  lightsail-scanning        = false # LightsailScanning
  s3-inventory-scanning     = true  # S3InventoryScanning
  terraform-bucket-scanning = true  # TerraformBucketScanning
  wiz-defend-awslogs-policy = true  # S3AWSLogsScanning
  wiz-defend-rds-policy     = true  # RDSLogsScanning
  wiz-defend-s3-kms-policy  = true  # S3KMSDecrypt
}
