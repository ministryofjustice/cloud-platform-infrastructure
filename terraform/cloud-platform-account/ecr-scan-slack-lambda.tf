module "webops_ecr_scan_repos_s3_bucket" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=4.1"

  team_name              = "cloudplatform"
  business-unit          = "webops"
  application            = "cloud-platform-terraform-s3-bucket-ecr-scan-slack"
  is-production          = "false"
  environment-name       = "development"
  infrastructure-support = "platform@digtal.justice.gov.uk"

  providers = {
    aws = aws.ireland
  }
}

module "webops_ecr_scan_slack_lambda" {

  source                     = "git::ssh://git@github.com/ministryofjustice/cloud-platform-terraform-lambda?ref=v1.4"
  team_name                  = "webops"
  business-unit              = "webops"
  application                = "webops-ecr-slack-app"
  is-production              = "true"
  environment-name           = "development"
  infrastructure-support     = "example-team@digtal.justice.gov.uk"
  policy_file                = file("resources/ecr-scan-results-slack/policy-lambda.json")
  function_name              = "ecr-scan-results-to-slack"
  handler                    = "lambda_ecr-scan-slack.lambda_handler"
  lambda_role_name           = "lambda-role-ecr-scan-slack"
  lambda_policy_name         = "lambda-pol-ecr-scan-slack"
  lambda_zip_source_location = "resources/ecr-scan-results-slack/lambda-function"
  lambda_zip_output_location = "resources/ecr-scan-results-slack/lambda-function-ecr-scan-slack.zip"

  providers = {
    aws = aws.ireland
  }
}
