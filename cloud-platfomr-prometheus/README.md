# Cloud Platform Prometheus

This repository will allow you to create a monitoring namespace in a MoJ Cloud Platform cluster. It will also contain the necessary values to perform an installation of Prometheus-Operator and Kube-Prometheus.

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
  - [How to expose the web interfaces behind an OIDC proxy](#how-to-expose-the-web-interfaces-behind-an-oidc-proxy)
  - [Adding Pingdom Alerts to monitor Prometheus and Alermanager Externally](#adding-pingdom-alerts-to-monitor-prometheus-and-alermanager-externally)
  - [How to tear it all down](#how-to-tear-it-all-down)

```bash
TL;DR
# Copy ./monitoring dir to the namespace dir in the cloud-platform-environments repository.

# Add CoreOS Helm repo
$ helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/

# Install prometheus-operator
$ helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring -f ./helm/prometheus-operator/values.yaml

# Install kube-prometheus
$ helm install \
  coreos/kube-prometheus \
  -f ./helm/kube-prometheus/values.yaml \
  --name kube-prometheus \
  --set global.rbacEnable=true \
  --namespace monitoring \
  --set-string grafana.adminUser=$(head -c 16 /dev/urandom | xxd -p) \
  --set-string grafana.adminPassword=$(head -c 16 /dev/urandom | xxd -p)

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

### Persistent Volumes with Kube-Prometheus
To maintain data across deployments and version upgrades, the data must be persisted to a volume (AWS EBS) other than emptyDir, allowing it to be reused by pods after upgrade.
Please see the following documentation by CoreOS on how to do this.
https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/storage.md

This has previously been achieved by applying an individual storage class manifest and referencing it in the values.yaml kube-prometheus Helm chart.

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

## How to expose the web interfaces behind an OIDC proxy

To expose the web interface for prometheus, alertmanager or other monitoring services using OIDC authentication, we use the `evry/oidc-proxy` image with a few modifications for the nginx configuration. It's all managed in kubernetes and there are two files needed: `monitoring/oidc-proxy.yaml` and `monitoring/oidc-proxy-sercret.yaml`.

### New installation
1. Before you begin, you need to create an Auth0 application. We only need one for all the services we want to expose in the `monitoring` namespace. Please name the application sensibly along the lines of `cloud-platform-test-1: monitoring proxy`.
1. Edit `oidc-proxy-sercret.yaml` filling in the OIDC application credentials and a new randomly generated cookie secret.
1. Edit `oidc-proxy.yaml` and replace the following three placeholders: `[[PROMETHEUS_HOSTNAME]]`, `[[ALERTMANAGER_HOSTNAME]]` and `[[AUTH0_TENANT_NAME]]`. Refer to the environments repository for deployed examples.
1. Update the Auth0 application with the callback URLs: `https://[[PROMETHEUS_HOSTNAME]]/redirect_uri` and `https://[[ALERTMANAGER_HOSTNAME]]/redirect_uri`
1. `kubectl apply`

### Exposing more services
To expose another service through the proxy,
1. Create a new attribute in the `oidc-proxy-config` `ConfigMap`:
  ```
  10-proxy_newservice.conf: |
    upstream newservice {
        # This should point to the kubernetes Service
        server newservice:8080;
    }
    server {
        # The external hostname, should match what's defined in the Ingress object.
        server_name newservice.apps.cluster.dsd.io;
        set $upstream newservice;
        include sites/.common.conf;
    }
  ```
1. Create a new rule for the `oidc-proxy` `Ingress`:
  ```
  - host:
    http: newservice.apps.cluster.dsd.io
      paths:
      - backend:
          serviceName: oidc-proxy
          servicePort: 80
  ```
1. Update the Auth0 application with the new callback URL, `https://newservice.apps.cluster.dsd.io/redirect_uri`
1. `kubectl apply`

## Adding Pingdom Alerts to monitor Prometheus and Alermanager Externally

Prometheus and AlertManager will be behind an OIDC proxy with GitHub credentials required to view the GUI. However, the `/-/healthy` endpoint for each applcation will be exposed directly to the internet.
```
https://$PROMETHEUS_URL$/-/healthy
https://$ALERTMANAGER_URL$/-/healthy
```

To expose the `/-/healthy` endpoint, an additional path entry is required in the `Ingress` object. Please see (oidc-proxy.yaml)[monitoring/oidc-proxy.yaml] for details.

A pingdom alert should be setup (with appropiate alert recipients) to the /healthy endpoints for each application described above.

## How to tear it all down
If you need to uninstall kube-prometheus and the prometheus-operator then you will simple need to run the following:
```bash
$ helm del --purge kube-prometheus && helm del --purge prometheus-operator
```
