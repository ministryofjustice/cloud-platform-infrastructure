
module "webops_ecr_scan_slack_lambda" {

  source = "git::ssh://git@github.com/ministryofjustice/cloud-platform-terraform-lambda?ref=v1.3"

  team_name                = "webops"
  business-unit            = "webops"
  application              = "webops-ecr-slack-app"
  is-production            = "false"
  environment-name         = "development"
  infrastructure-support   = "example-team@digtal.justice.gov.uk"
  lambda_function_zip_path = filebase64sha256("resources/ecr-scan-results-slack/lambda_ecr-scan-slack.zip")
  filename                 = "lambda_ecr-scan-slack.zip"
  policy_file              = file("resources/ecr-scan-results-slack/policy-lambda.json")
  function_name            = "ecr-scan-results-to-slack"
  handler                  = "lambda_ecr-scan-slack.lambda_handler"
  lambda_role_name         = "lambda-role-ecr"
  lambda_policy_name       = "lambda-pol-ecr"

  providers = {
    aws = aws.ireland
  }
}
