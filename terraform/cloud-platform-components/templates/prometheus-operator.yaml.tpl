# Default values for prometheus-operator.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

## Create default rules for monitoring the cluster
##
defaultRules:
  create: true
  rules:
    general: false
    kubernetesApps: false

## Configuration for alertmanager
## ref: https://prometheus.io/docs/alerting/alertmanager/
##
alertmanager:
  ## Alertmanager configuration directives
  ## ref: https://prometheus.io/docs/alerting/configuration/#configuration-file
  ##      https://prometheus.io/webtools/alerting/routing-tree-editor/
  ##
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname', 'job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'null'
      routes:
      - match:
          alertname: KubeQuotaExceeded
        receiver: 'null'
      - match:
          alertname: CPUThrottlingHigh
        receiver: 'null'
      - match:
          alertname: DeadMansSwitch
        receiver: 'null'
      - match:
          alertname: DeploymentReplicasAreOutdated
        receiver: 'null'
      - match:
          alertname: PodIsRestartingFrequently
        receiver: 'null'
      - match:
          alertname: KubePersistentVolumeFullInFourDays
        receiver: 'null'
      - match:
          alertname: PrometheusTargetScrapesDuplicate
        receiver: 'null'
      
      - match:
          severity: critical
        receiver: pager-duty-high-priority
      ${indent(6, alertmanager_routes)}
    receivers:
    - name: 'null'
    # Add PagerDuty key to allow integration with a PD service.
    - name: 'pager-duty-high-priority'
      pagerduty_configs:
      - service_key: "${ pagerduty_config }"
    ${indent(4, alertmanager_receivers)}
    templates:
    - '/etc/alertmanager/config/cp-slack-templates.tmpl'

  ## Alertmanager template files to format alerts
  ## ref: https://prometheus.io/docs/alerting/notifications/
  ##      https://prometheus.io/docs/alerting/notification_examples/
  ##
  templateFiles:
    cp-slack-templates.tmpl: |-
      {{ define "slack.cp.title" -}}
        [{{ .Status | toUpper -}}
        {{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{- end -}}
        ] {{ template "__alert_severity_prefix_title" . }} {{ .CommonLabels.alertname }}
      {{- end }}

      {{/* The test to display in the alert */}}
      {{ define "slack.cp.text" -}}
        {{ range .Alerts }}
            *Alert:* {{ .Annotations.message}}
            *Details:*
            {{ range .Labels.SortedPairs }} - *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
            *-----*
          {{ end }}
      {{- end }}

      {{ define "__alert_silence_link" -}}
        {{ .ExternalURL }}/#/silences/new?filter=%7B
        {{- range .CommonLabels.SortedPairs -}}
          {{- if ne .Name "alertname" -}}
            {{- .Name }}%3D"{{- .Value -}}"%2C%20
          {{- end -}}
        {{- end -}}
          alertname%3D"{{ .CommonLabels.alertname }}"%7D
      {{- end }}

      {{ define "__alert_severity_prefix" -}}
          {{ if ne .Status "firing" -}}
          :white_check_mark:
          {{- else if eq .Labels.severity "critical" -}}
          :fire:
          {{- else if eq .Labels.severity "warning" -}}
          :warning:
          {{- else -}}
          :question:
          {{- end }}
      {{- end }}

      {{ define "__alert_severity_prefix_title" -}}
          {{ if ne .Status "firing" -}}
          :white_check_mark:
          {{- else if eq .CommonLabels.severity "critical" -}}
          :fire:
          {{- else if eq .CommonLabels.severity "warning" -}}
          :warning:
          {{- else if eq .CommonLabels.severity "info" -}}
          :information_source:
          {{- else if eq .CommonLabels.status_icon "information" -}}
          :information_source:
          {{- else -}}
          :question:
          {{- end }}
      {{- end }}

  ## Settings affecting alertmanagerSpec
  ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#alertmanagerspec
  ##
  alertmanagerSpec:
   ## Log level for Alertmanager to be configured with.
    ##
    logLevel: info

    ## Storage is the definition of how storage will be used by the Alertmanager instances.
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/storage.md
    ##
    storage:
    volumeClaimTemplate:
      spec:
        storageClassName: default
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
      selector: {}

    ## 	The external URL the Alertmanager instances will be available under. This is necessary to generate correct URLs. This is necessary if Alertmanager is not served from root of a DNS name.	string	false
    ##
    externalUrl: "${ alertmanager_ingress }"

## Using default values from https://github.com/helm/charts/blob/master/stable/grafana/values.yaml
##
grafana:
  enabled: true

  adminUser: "${ random_username }"
  adminPassword: "${ random_password }"

  ingress:
    ## If true, Prometheus Ingress will be created
    ##
    enabled: true

    hosts:
    - "${ grafana_ingress }"

    tls:
      - hosts:
        - "${ grafana_ingress }"

  env:
    GF_SERVER_ROOT_URL: "${ grafana_root }"
    GF_ANALYTICS_REPORTING_ENABLED: "false"
    GF_AUTH_DISABLE_LOGIN_FORM: "true"
    GF_USERS_ALLOW_SIGN_UP: "false"
    GF_USERS_AUTO_ASSIGN_ORG_ROLE: "Viewer"
    GF_USERS_VIEWERS_CAN_EDIT: "true"
    GF_SMTP_ENABLED: "false"
    GF_AUTH_GENERIC_OAUTH_ENABLED: "true"
    GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP: "true"
    GF_AUTH_GENERIC_OAUTH_NAME: "Auth0"
    GF_AUTH_GENERIC_OAUTH_SCOPES: "openid profile email"

  envFromSecret: "grafana-env"

  serverDashboardConfigmaps:
    - grafana-user-dashboards

  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
      searchNamespace: ALL
    datasources:
      enabled: true
      label: grafana_datasource

## Component scraping coreDns. Use either this or kubeDns
##
coreDns:
  enabled: false

## Component scraping kubeDns. Use either this or coreDns
##
kubeDns:
  enabled: true

## Component scraping etcd
##
kubeEtcd:
  enabled: true

## Component scraping kube scheduler
##
kubeScheduler:
  enabled: true

## Component scraping kube state metrics
##
kubeStateMetrics:
  enabled: true

## Manages Prometheus and Alertmanager components
##
prometheusOperator:
  enabled: true

  ## Deploy CRDs used by Prometheus Operator.
  ##
  createCustomResource: true

  ## Attempt to clean up CRDs created by Prometheus Operator.
  ##
  cleanupCustomResource: true

## Deploy a Prometheus instance
##
prometheus:

  enabled: true

  ## Settings affecting prometheusSpec
  ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusspec
  ##
  prometheusSpec:

    ## External URL at which Prometheus will be reachable.
    ##
    externalUrl: "${ prometheus_ingress }"

    ## How long to retain metrics
    ##
    retention: 30d

    ## Prometheus StorageSpec for persistent data
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/storage.md
    ##
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: default
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 750Gi
        selector: {}