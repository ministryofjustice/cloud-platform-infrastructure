# cloud-platform-components

## kiam

Example of IAM policy for a user application:

```hcl
// This is the kubernetes role that node hosts are assigned.
data "aws_iam_role" "nodes" {
  name = "nodes.${data.terraform_remote_state.cluster.cluster_domain_name}"
}

data "aws_iam_policy_document" "app_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_iam_role.nodes.arn}"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "app.${data.terraform_remote_state.cluster.cluster_domain_name}"
  assume_role_policy = "${data.aws_iam_policy_document.app_assume.json}"
}

data "aws_iam_policy_document" "app" {
  statement {
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "app" {
  name   = "policy"
  role   = "${aws_iam_role.app.id}"
  policy = "${data.aws_iam_policy_document.app.json}"
}
```

This can easily be configured as part of a user environment's resources, along with the required namespace annotation (see the [kiam docs](https://github.com/uswitch/kiam#overview)).

## Prometheus to Slack Alerting Routes

#### 1. Create a Slack incoming webhook

Log into the MOJ org Slack and find the 'AlertManager Notifications' App on https://api.slack.com/apps. 
Once within the app settings, select 'Incoming Webhooks' in the 'Features' section.
Scroll to the bottom of the page and click on 'Add New Webhook to Workspace' and choose the 'channel' you want the alerts to go to.
Once complete, make a note of the new Webhook for use within the Prometheus configuration.


#### 2. Add webhook to `terraform.tfvars` file
```yaml
slack_config_<team_name> = "https://hooks.slack.com/services/xxxxxx/xxxxxx/xxxxxx"
```

#### 3. Add new entries to `prometheus-operator.yaml.tpl`

`alertmanager:config:routes`

`alertmanager:config:receivers`

```yaml
alertmanager:
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'null'
      routes:
      - match:
          severity: <team_name>
        receiver: slack-<team_name>
    receivers:
    - name: 'slack-<team_name>'
      slack_configs:
      - api_url: "${slack_config_<team_name>}"
        channel: "#<channel_name>"
        send_resolved: True
        username: '{{ template "slack.default.username" . }}'
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'
        title: '{{ template "slack.default.title" . }}'
        title_link: '{{ template "slack.default.titlelink" . }}'
        pretext: 
        text: |-
          {{ range .Alerts }}
            *Alert:* {{ .Annotations.message}}
            *Runbook:* {{ .Annotations.runbook_url }}
            *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
            *-----*
          {{ end }}
        fallback: '{{ template "slack.default.fallback" . }}'
        icon_emoji: '{{ template "slack.default.iconemoji" . }}'
        icon_url: '{{ template "slack.default.iconurl" . }}'
        footer: ${ alertmanager_ingress }
```

Note: For alerts into multiple slack channels, add a second entry for `api_url` and `channel` under `slack_configs` 
#### Add a new vars entry in `prometheus.tf`

```yaml
data "template_file" "kube_prometheus" {
  template = "${file("${path.module}/templates/kube-prometheus.yaml.tpl")}"

  vars {
    slack_config_<team_name> = "${var.slack_config_<team_name>}"
  }
}
```
#### Add a new variable in `variables.tf`

```yaml
variable "slack_config_<teamn_name>" {
  description = "Add Slack webhook API URL and channel for integration with slack."
}
```

All alerts are routed using the `severity` label. Provide the development team the severity label created for each route (default is team_name),
which will be used by the developemt team when creating custom application alerts. 

#### prometheus-custom-alerts-<application_name>.yaml

Once the route configuration is complete by the Cloud Platform Team, the application team to use the 'severity' label value supplied and create a custom alert using the template below:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  creationTimestamp: null
  namespace: <namespace>
  labels:
    prometheus: prometheus-operator
    role: alert-rules
  name: prometheus-custom-alerts-<application_name>
spec:
  groups:
  - name: application-rules
    rules:
    - alert: <alert_name>
      expr: <alert_query>
      for: <check_time_length>
      labels:
        severity: <team_name>
      annotations:
        Message: <alert_message> 
        Runbook URL: <http://my-support-docs>
```


Example:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  creationTimestamp: null
  namespace: test-namespace
  labels:
    prometheus: prometheus-oprator
    role: alert-rules
  name: prometheus-custom-alerts-my-application
spec:
  groups:
  - name: node.rules
    rules:
    - alert: CPU-High
      expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 5m
      labels:
        severity: cp-team
      annotations:
        Message: This device's CPU usage has exceeded the threshold with a value of {{ $value }}. Instance {{ $labels.instance }} CPU usage is dangerously high
        Runbook URL: http://link-to-support-docs.website
```

