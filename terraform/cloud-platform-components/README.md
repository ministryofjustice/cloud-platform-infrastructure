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
- [Open-Policy-Agent](#Open-Policy-Agent)
- [Prometheus](#prometheus)
- [Pod Security Policies](#pod-security-policies)
- [RBAC](#rbac)

## External-dns
ExternalDNS synchronizes exposed Kubernetes Services and Ingresses with DNS providers. This basically makes Kubernetes resources discoverable via public DNS servers. We utilise the stable Helm [chart](https://github.com/helm/charts/tree/master/stable/external-dns) passing an IAM role and cluster domain name.

## Fluentd
The Terraform in this directory has all the required resources to deploy `fluentd` as a `DaemonSet` on the cluster. As long as applications are writing out to stdout logs are scrapped and pushed to Elasticsearch. 

### Full buffer
Fluentd has a buffer limit (defined by the chunk_limit_size and queue_limit_length values in helm-charts/fluentd-es/config/output.conf)

When full this normally indicates that Fluentd is unable to write to the ElasticSearch cluster. In this case, view various sources of metrics and logs to determine the cause. 

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

## Open-Policy-Agent

[Open Policy Agent](https://www.openpolicyagent.org/)(OPA) is a lightweight general-purpose policy engine that can be co-located with our service. Services offload policy decisions to OPA by executing queries. OPA evaluates policies and data to produce query results (which are sent back to the client).  

We utilise [opa-helm-chart](https://github.com/helm/charts/tree/master/stable/opa) to deploy opa onto the Cloud Platform. This helm chart installs OPA as a Kubernetes admission controller. In our case we are using validating admission controller. The helm Chart will automatically generate a CA and server certificate for the OPA. 

In Kubernetes, Admission Controllers enforce semantic validation of objects during create, update, and delete operations. With OPA we can enforce custom policies on Kubernetes objects without recompiling or reconfiguring the Kubernetes API server. Please see the following documentation by opa on Kubernetes Admission Control 
https://www.openpolicyagent.org/docs/kubernetes-admission-control.html

To restrict the kinds of operations and resources that are subject to OPA policy checks, see the below example. Configured in templates/opa/values.yaml.tpl under admissionControllerRules:

```yaml
    admissionControllerRules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: ["extensions", ""]
        apiVersions: ["v1beta1”, “v1”]
        resources: ["ingresses", "namespaces"]
```
The admissionControllerRules defines the operations and resources that the webhook will validate. Intercept API requests when a ingress or a namespace is CREATED or UPDATED, so apiGroups and apiVersions are filled out accordingly (extensions/v1beta1 for ingresses, v1 for namespaces). We can use wildcards (*) for these fields as well.

 ### kube-mgmt

kube-mgmt manages instances of the Open Policy Agent on top of kubernetes. Use kube-mgmt to:

  - Load policies into OPA via kubernetes.
  - Replicate kubernetes resources including CustomResourceDefinitions (CRDs) into OPA.

The example below would replicate namespaces and ingress into OPA:

```yaml
    cluster:
      - "v1/namespaces"
    namespace:
      - "extensions/v1beta1/ingresses"
    path: kubernetes
```

NOTE: IF we use replicate: remember to update the RBAC rules to allow permissions to replicate these things

 ### opa-policies

kube-mgmt automatically discovers policies stored in ConfigMaps in kubernetes and loads them into OPA. kube-mgmt assumes a ConfigMap contains policies if the ConfigMap is :

  - Created in a namespace listed in the --policies option. Configured in templates/opa/values.yaml.tpl under mgmt/configmapPolicies/namespaces:
  - Labelled with openpolicyagent.org/policy=rego.


When a policy has been successfully loaded into OPA, the openpolicyagent.org/policy-status annotation is set to
```json
{"status": "ok"}
```
If loading fails for some reason (e.g., because of a parse error), the openpolicyagent.org/policy-status annotation is set as below, where the error field contains details about the failure. 
```json
{"status": "error", "error": ...}
``` 
IMP NOTE: This [opa-default-system-main.yaml](https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/cloud-platform-components/resources/opa/opa-default-system-main.yaml) applies a ConfigMap that contains the main OPA policy and default response. This policy is used as an entry-point for policy evaluations and returns allowed:true if policies are not matched to inbound data.

 ### How to write Policies

Please see the following documentation by opa on how to write Policies https://www.openpolicyagent.org/docs/how-do-i-write-policies.html

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
#### Add a new vars entry in `prometheus.tf` in the following data config:

```yaml
data "template_file" "prometheus_operator" {
  template = "${file("${ path.module }/templates/prometheus-operator.yaml.tpl")}"

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

A Pod Security Policy is a cluster-level resource that controls security sensitive aspects of the pod specification.  
The PodSecurityPolicy objects define a set of conditions that a pod must run with in order to be accepted into the system, as well as defaults for the related fields. 

The admission controller is enabled in all new Cloud Platform clusters, whcih means we must define the rules for `restricted` and `priviledged` containers. This is done in `psp.tf`

 #### Restricted  

The restricted policy is the default one for anyone on the cluster. Unless a team or serviceaccount has been specifically granted higher privileges, it will be impossible to :
 - Run any container as the root user, which is usually the default user. 
 - Escalate Privilege to root 
 - Mount any volumes that are not of type ConfigMap, Secret, PVC, or similar.  
 

```yaml
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'docker/default'
spec:
  privileged: false
  # Required to prevent escalations to root.
  allowPrivilegeEscalation: false
  # This is redundant with non-root + disallow privilege escalation,
  # but we can provide it for defense in depth.
  requiredDropCapabilities:
    - ALL
  # Allow core volume types.
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    # Assume that persistentVolumes set up by the cluster admin are safe to use.
    - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    # Require the container to run without root privileges.
    rule: 'MustRunAsNonRoot'
  seLinux:
    # This policy assumes the nodes are using AppArmor rather than SELinux.
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  readOnlyRootFilesystem: false
  ```

In other words, when a namespace/environment is created, the restricted policy is automatically applied to it. 


##### NGINX and Networking 

Running as non-root also means that access to privileged ports will not be allowed.  
If an application used to listen on port 80 or 443, or any other port <1024 on live-0, it will have to be reconfigured to work on live-1.
This is an issue for regular nginx images, that default to a privileged user and ports.  

This section will be updated when a proper workaround for nginx has been found. 


#### Privileged  

The privileged policy allows all of the above, but needs to be specifically assigned to a namespace.
For example, the logging and monitoring namespaces, amongst others, are both allowed to run root containers.

```yaml
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: privileged
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: "*"
spec:
  privileged: true
  allowPrivilegeEscalation: true
  allowedCapabilities:
  - "*"
  volumes:
  - "*"
  hostNetwork: true
  hostPorts:
  - min: 0
    max: 65535
  hostIPC: true
  hostPID: true
  runAsUser:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

#### How to become privileged ? 

Being allowed to use the _privileged_ policy means binding it to the default serviceaccount of a namespace. 

A simple RoleBinding resource needs to be created, as described below : 

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: PrivilegedRoleBinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: psp:privileged
subjects:
- kind: Group
  name: system:serviceaccounts:<MY_NAMESPACE>
  apiGroup: rbac.authorization.k8s.io
```


You may have to re-login to the cluster for this change to take effect.


### RBAC
Role-based access control (RBAC) is a method of regulating access to computer or network resources based on the roles of individual users within an enterprise.
