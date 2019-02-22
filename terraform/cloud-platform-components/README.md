# Cloud Platform Components - Terraform

This directory contains application layer components that essentially bootstrap the cluster into what we would consider "ready to use". This includes applications such as Prometheus etc. 


## Contents
- [External-dns](#external-dns)
- [Fluentd](#fluentd)
- [Helm](#helm)
- [KIAM](#kiam)
- [Kuberos](#kuberos)
- [Metrics-server](#metrics-server)
- [Nginx-ingress](#nginx-ingress)
- [Prometheus](#prometheus)
- [Pod Security Policies](#pod-security-policies)
- [RBAC](#rbac)

## External-dns
ExternalDNS synchronizes exposed Kubernetes Services and Ingresses with DNS providers. This basically makes Kubernetes resources discoverable via public DNS servers. We utilise the stable Helm [chart](https://github.com/helm/charts/tree/master/stable/external-dns) passing an IAM role and cluster domain name.

## Fluentd
The Terraform in this directory has all the required resources to deploy `fluentd` as a `DaemonSet` on the cluster. As long as applications are writing out to stdout logs are scrapped and pushed to Elasticsearch. 

## Helm
To enable three quarters of deployments on the cluster we must first install and configure Helm. This is done via a series of `local_exec`'s in the `helm.tf` file. 

## KIAM

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

## Kuberos
To allow users to authenticate we spin up a `Kuberos` pod. Kuberos is an OIDC authentication helper for Kubernetes' kubectl and enables users to perform queries against the clusters API. 

Again, we use the stable Helm chart for the deployment.

## Metrics-server
Metrics-server allows us to perform resource queries against the cluster. Commands like `kubectl top pods` allow us to diagnose resource constraints. 

## Nginx-ingress
A vital component in the cluster. The Nginx-ingress controller is a daemon, deployed as a Kubernetes Pod, that watches the apiserver's /ingresses endpoint for updates to the Ingress resource. Its job is to satisfy requests for Ingresses.

## Prometheus
We utilise [Prometheus-Operator](https://github.com/helm/charts/tree/master/stable/prometheus-operator) to deploy Prometheus onto the Cloud Platform. Once installed a `DaemonSet` of exporters is deployed scraping metrics from across the cluster. Grafana and AlertManager are also deployed as part of this chart along with relevant proxies. 

### Persistent Volumes with Prometheus

To maintain data across deployments and version upgrades data must be persisted to a volume (AWS EBS) other than emptyDir, allowing it to be reused by pods after upgrade. Please see the following documentation by CoreOS on how to do this. https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/storage.md

This has previously been achieved by applying an individual storage class manifest and referencing it in the values.yaml Prometheus-operator Helm chart.

### Adding Pingdom Alerts to monitor Prometheus and Alermanager Externally
Prometheus and AlertManager will be behind an OIDC proxy with GitHub credentials required to view the GUI. However, the /-/healthy endpoint for each application will be exposed directly to the internet.

```
https://$PROMETHEUS_URL$/-/healthy
https://$ALERTMANAGER_URL$/-/healthy
```

A pingdom alert should be setup (with appropriate alert recipients) to the /healthy endpoints for each application described above.

### Prometheus to Slack Alerting Routes

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
        title: '{{ template "slack.cp.title" . }}'
        text: '{{ template "slack.cp.text" . }}'
        footer: ${ alertmanager_ingress }
        actions:
        - type: button
          text: 'Runbook :blue_book:'
          url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
        - type: button
          text: 'Query :mag:'
          url: '{{ (index .Alerts 0).GeneratorURL }}'
        - type: button
          text: 'Silence :no_bell:'
          url: '{{ template "__alert_silence_link" . }}'
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
which will be used by the development team when creating custom application alerts. 

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
        message: <alert_message> 
        runbook_url: <http://my-support-docs>
```


Example:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  creationTimestamp: null
  namespace: test-namespace
  labels:
    prometheus: prometheus-operator
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
        message: This device's CPU usage has exceeded the threshold with a value of {{ $value }}. Instance {{ $labels.instance }} CPU usage is dangerously high
        runbook_url: http://link-to-support-docs.website
```

### Pod Security Policies
A Pod Security Policy is a cluster-level resource that controls security sensitive aspects of the pod specification. The PodSecurityPolicy objects define a set of conditions that a pod must run with in order to be accepted into the system, as well as defaults for the related fields.

The admission controller is enabled in all new Cloud Platform clusters, whcih means we must define the rules for `restricted` and `priviledged` containers. This is done in `psp.tf`

### RBAC
Role-based access control (RBAC) is a method of regulating access to computer or network resources based on the roles of individual users within an enterprise.
