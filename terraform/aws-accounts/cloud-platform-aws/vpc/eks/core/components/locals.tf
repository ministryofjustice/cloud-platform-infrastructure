locals {
  parameters = [
    # {
    #   name = "This is the name of the {githubteam-channel) that owns this parameter"
    #   inputs = {
    #    webhook  = "parameterstrore path to the webhook"
    #    channel  = "slack channel to send alerts to (e.g., #alerts)"
    #    severity = "created for you by the script"
    #   }
    # },
		{
			name = "webops-cloud-platform"
			inputs = {
				channel = "#cloud-platform"
				webhook = "/cloud-platform/infrastructure/components/slack_hook_id"
				severity = "cloud-platform-ZdIiggCp"
			}
		},
    {
      name = "webops-cloud-platform-operations"
      inputs = {
        channel = "#cloud-platform-operations"
        webhook = "/cloud-platform/infrastructure/components/slack_webhook_url"
        severity = "cloud-platform-ZdIiggCi"
      }
    }
    # append above to add more parameters as needed
  ]

  alertmanager_slack_receivers_test = [
    for p in local.parameters : {
      severity = p.inputs.severity
      webhook  = data.aws_ssm_parameter.parameter[p.inputs.webhook].value
      channel  = p.inputs.channel
    }
  ]
}

data "aws_ssm_parameter" "parameter" {
  for_each = { for p in local.parameters : p.inputs.webhook => p.inputs.webhook }
  name = each.value
}