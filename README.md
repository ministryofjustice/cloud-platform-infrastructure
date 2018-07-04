# Cloud Platform Prometheus

This repository will allow you to create a monitoring namespace in a MoJ Cloud Platform cluster. It will also contain the neseccary values to perform an installation of Prometheus-Operator and Kube-Prometheus. 

  - [Pre-reqs](#pre-reqs)
  - [Creating a monitoring namespace](#creating-a-monitoring-namespace)
  - [Installing Prometheus-Operator](#installing-prometheus-operator)
  - [Installing Kube-Prometheus](#installing-kube-prometheus)
  - [Installing Alertmanager](#installing-alertmanager)
  - [Configuring AlertManager to send alerts to PagerDuty](#configuring-alertmanager-to-send-alerts-to-pagerduty)
  - [Configuring AlertManager to send alerts to Slack](#configuring-alertmanager-to-send-alerts-to-slack)
  - [Installing Exporter-Kubelets](#installing-exporter-kubelets)
  - [Exposing the port](#exposing-the-port)
  - [How to add an alert to Prometheus](#how-to-add-an-alert-to-prometheus)
  - [How to expose Prometheus UI and add oauth proxy](#how-to-expose-prometheus-ui-and-add-oauth-proxy)
  - [How to tear it all down](#how-to-tear-it-all-down)

```bash
TL;DR
# Copy ./monitoring dir to the namespace dir in the cloud-platform-environments repository.

# Add CoreOS Helm repo
$ helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/

# Install prometheus-operator
$ helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring -f ./helm/prometheus-operator/values.yaml

# Install kube-prometheus
$ helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring -f ./helm/kube-prometheus/values.yaml

# Expose the Prometheus port to your localhost
$ kubectl port-forward -n monitoring prometheus-kube-prometheus-0 9090

# Expose the AlertManager port to your localhost
$ kubectl port-forward -n monitoring alertmanager-kube-prometheus-0 9093
```

## Pre-reqs
It is assumed that you have authenticated to an MoJ Cloud-Platform Cluster and you have Helm installed and configured.

## Creating a monitoring namespace
To create a monitoring namespace you will need to copy the `./monitoring` directory in this repository to a branch in the [Cloud-Plarform-Environments](https://github.com/ministryofjustice/cloud-platform-environments/tree/master/namespaces). Once this branch has been reviewed and merged to `master` a pipeline is kicked off, creating a namespace called `monitoring`. 

## Installing Prometheus-Operator
> The mission of the Prometheus Operator is to make running Prometheus
> on top of Kubernetes as easy as possible, while preserving
> configurability as well as making the configuration Kubernetes native.
> [https://coreos.com/operators/prometheus/docs/latest/user-guides/getting-started.html](https://coreos.com/operators/prometheus/docs/latest/user-guides/getting-started.html)

The Prometheus Operator provides easy monitoring for Kubernetes services and deployments besides managing Prometheus, Alertmanager and Grafana configuration.

To install Prometheus Operator, run:
```bash
$ helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/

$ helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring -f ./monitoring/helm/prometheus-operator/values.yaml
```
And then confirm the operator is running in the monitoring namspace:
```bash
$ kubectl get pods -n monitoring
```

## Installing Kube-Prometheus
Prometheus is an open source toolkit to monitor and alert, inspired by Google Borg Monitor. It was previously developed by SoundCloud and afterwards donated to the CNCF.

To install kube-prometheus, run:
```bash 
$ helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring -f ./monitoring/helm/kube-prometheus/values.yaml
```

## Installing AlertManager
> The Alertmanager handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing   them to the correct receiver integration such as email or PagerDuty. It also takes care of silencing and inhibition of alerts - 
> [https://prometheus.io/docs/alerting/alertmanager/](https://prometheus.io/docs/alerting/alertmanager/)

AlertManager can be installed (using a sub-chart) as part of the installtion of Kube-Prometheus.

Set the following entry on the Kube-Prometheus `values.yaml` to true
```yaml
# AlertManager
deployAlertManager: true
```
## Configuring AlertManager to send alerts to PagerDuty

Make note of the `service_key:` key on the Kube-Prometheus `values.yaml` file. 

```yaml
# Add PagerDuty key to allow integration with a PD service. 
    - name: 'pager-duty-high-priority'
      pagerduty_configs:
      - service_key: "$KEY"
```
The `$KEY` value needs to be generated and copied from PagerDuty.

### PagerDuty Service Key retrieval

This is a quick guide on how to retrive your service key from PagerDuty by following these steps:

1) Login to PaderDuty

2) Go to the **Configuration** menu and select **Services**.

3) On the Services page: 

    * If you are creating a new service for your integration, click **Add New Service**.

    * If you are adding your integration to an existing service, click the name of the service you want to add the integration to. Then click the **Integrations** tab and click the **New Integration** button.
4) Select your app from the **Integration Type** menu and enter an **Integration Name**.

5) Click the **Add Service** or **Add Integration** button to save your new integration. You will be redirected to the Integrations page for your service.

6) Copy the **Integration Key** for your new integration.

7) Paste the **Integration Key** into the `service_key` placeholder, `$key` in the configuration `values.yaml` file.

## Configuring AlertManager to send alerts to Slack

Slack intergration is enabled using the kube-prometheus values.yaml file:

```yaml
# Add Slack webhook API URL and channel for integration with slack.
    - name: 'slack-low-priority'
      slack_configs:
      - api_url: "$WEBHOOK_URL"
        channel: "#general"
        text: "description: {{ .CommonAnnotations.description }}\nsummary: {{ .CommonAnnotations.summary }}"
        send_resolved: True
```

Follow the [official slack documentation](https://api.slack.com/incoming-webhooks) to create the `api_url:` and fill in the `channel:` with the name of the slack channel that will recieve the notifications. 

## Installing Exporter-Kubelets
Exporter-Kubelets is a simple service that enables container metrics to be scraped by prometheus.

Exporter-Kubelets can be installed as a [service monitor,](https://github.com/coreos/prometheus-operator#customresourcedefinitions) part of the installation of Kube-Prometheus.

Add the exporter-kubelets value under the `serviceMonitorsSelector:` section:

```yaml
serviceMonitorsSelector:
    matchExpressions:
    - key: app
      operator: In
      values:
      - exporter-kubelets
```

## Exposing the port
Due to a lack of auth options, we've decided to use port forwarding to prevent unauthorised access. Forward the Prometheus server to your machine so you can take a better look at the dashboard by opening http://localhost:9090.
```bash
$ kubectl port-forward -n monitoring prometheus-kube-prometheus-0 9090
```
To Expose the port for AlertManager, run:
```bash
$ kubectl port-forward -n monitoring alertmanager-kube-prometheus-0 9093
```

## How to add an alert to Prometheus

As we're using CoreOS Prometheus operater we have to use Prometheus rules. Prometheus rule files are held in PrometheusRule custom resources. It is recommended that you use the label selector field ruleSelector in the Prometheus object to define the rule files that you want to be mounted into Prometheus.

The best practice is to label the PrometheusRules containing rule files with role: alert-rules as well as the name of the Prometheus object, prometheus: example in this case.

```
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  creationTimestamp: null
  labels:
    prometheus: example
    role: alert-rules
  name: prometheus-example-rules
spec:
  groups:
  - name: ./example.rules
    rules:
    - alert: ExampleAlert
      expr: vector(1)
```

The example PrometheusRule always immediately triggers an alert, which is only for demonstration purposes. To validate that everything is working properly have a look at each of the Prometheus web UIs.

The directory `./custom-alerts` contains the manifest files for applying rules to your Prometheus alarms. 

To see the current rules applied to your Prometheus instance, run:

`kubectl get prometheusrule -n monitoring`

Once you've crafted your manifest use:

`kubectl create -n monitoring -f <./custom-alerts/manifest.yaml>`

To remove an alarm, grab the prometheusrule name and use:

`kubectl delete -n monitoring <ruleName>`.

## How to expose Prometheus UI and add oauth proxy

There are two files needed to expose a Prometheus instance to the Internet and then (probably most cruicially) force GitHub authentication. 

1. Before you begin, you MUST create a [custom GitHub OAuth application](https://github.com/settings/applications/new).
#### Fields
- **Application name** Please name the application sensibly along the lines of `cloud-platform-prometheus-auth-test-1`.
- **Homepage URL** This is the FQDN in the ingress rule, like https://foo.bar.com
- **Application description** This is optional.
- **Authorization callback URL** is the same as the base FQDN plus /oauth2, like https://foo.bar.com/oauth2

2. You must configure the `./monitoring/helm/kube-prometheus/oauth2_proxy.yaml` file. It should look like the example below:
```bash
- --provider=github
- --github-org=mycompanyname                                          # this would be your organisation name in github
- --github-team=myteamname                                            # this is the team name with the orgranisation
- --email-domain=*
- --upstream=file:///dev/null
- --http-address=0.0.0.0:4180
- --client-id=jdkshgksdhkh33878ifjd                                   # GitHub oauth application client ID
- --client-secret=dkhsfkhskjdfk33                                     # Gihub oauth app client secret
- --cookie-secret=lskdfhoh3ii35                                       # randomly generated 16 char string
- --redirect-url=https://prometheus.test-cluster.example.io/oauth2    # the FQDN in your ingress file
```
**Important**
>Now you must transfer ownership of the application to the `ministryofjustice` orginisation. You simply click the "Transfer ownership" button within the app and follow the instructions. Only admins of the orginisation have access to accept ownership. 

3. Now customise the contents of `./monitoring/helm/kube-prometheus/ingress.yaml`. Changing the `host` value only. This will look like:
`prometheus.apps.cluster.dsd.io`

4. Deploy the `oauth2-proxy.yaml` and `ingress.yaml` manifests:
```bash
$ kubectl create -f ./monitoring/helm/kube-prometheus/ingress.yaml,./monitoring/helm/kube-prometheus/oauth2_proxy.yaml
```

5. Test the auth integration by accessing the configured URL.

## How to tear it all down
If you need to uninstall kube-prometheus and the prometheus-operator then you will simple need to run the following:
```bash
$ helm del --purge kube-prometheus && helm del --purge prometheus-operator
```




