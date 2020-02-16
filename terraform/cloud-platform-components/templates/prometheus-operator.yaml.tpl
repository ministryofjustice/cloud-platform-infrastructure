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

  ## Pod Annotations
  podAnnotations: 
    iam.amazonaws.com/role: "${ grafana_pod_annotation }"

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

  ## Configure additional grafana datasources
  ## ref: http://docs.grafana.org/administration/provisioning/#datasources
  additionalDataSources:
  - name: Cloudwatch
    type: cloudwatch
    editable: true
    access: proxy
    jsonData:
      authType: arn
      defaultRegion: eu-west-2
      assumeRoleArn: "${ grafana_assumerolearn }"
    orgId: 1
    version: 1

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

  ## If using kubeScheduler.endpoints only the port and targetPort are used
  ##
  service:
    selector:
      k8s-app: kube-scheduler

## Component scraping the kube controller manager
##
kubeControllerManager:
  enabled: true

  ## If using kubeControllerManager.endpoints only the port and targetPort are used
  ##
  service:
    selector:
      k8s-app: kube-controller-manager

## Component scraping kube state metrics
##
kubeStateMetrics:
  enabled: true

## Configuration for kube-state-metrics subchart
##
kube-state-metrics:
  image:
    tag: v1.7.0

## Manages Prometheus and Alertmanager components
##
prometheusOperator:
  enabled: true

  tlsProxy:
    enabled: false

  admissionWebhooks:
    enabled: false

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

    ## Namespaces to be selected for PrometheusRules discovery.
    ## If unspecified, only the same namespace as the Prometheus object is in is used.
    ##
    ruleNamespaceSelector:
      any: true

    ## Rules CRD selector
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/design.md
    ## If unspecified the release `app` and `release` will be used as the label selector
    ## to load rules
    ##
    ruleSelector:
      any: true
    ## Example which select all prometheusrules resources
    ## with label "prometheus" with values any of "example-rules" or "example-rules-2"
    # ruleSelector:
    #   matchExpressions:
    #     - key: prometheus
    #       operator: In
    #       values:
    #         - example-rules
    #         - example-rules-2
    #
    ## Example which select all prometheusrules resources with label "role" set to "example-rules"
    # ruleSelector:
    #   matchLabels:
    #     role: example-rules

    ## serviceMonitorSelector will limit which servicemonitors are used to create scrape
    ## configs in Prometheus. See serviceMonitorSelectorUseHelmLabels
    ##
    serviceMonitorSelector:
      any: true

    # serviceMonitorSelector: {}
    #   matchLabels:
    #     prometheus: somelabel

    ## serviceMonitorNamespaceSelector will limit namespaces from which serviceMonitors are used to create scrape
    ## configs in Prometheus. By default all namespaces will be used
    ##
    serviceMonitorNamespaceSelector:
      any: true

    ## How long to retain metrics
    ##
    retention: 30d

    podMetadata:
      annotations:
        iam.amazonaws.com/role: "${monitoring_aws_role}"

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

    thanos: 
      baseImage: quay.io/thanos/thanos
      version: v0.10.1
      objectStorageConfig:
        key: thanos.yaml
        name: thanos-objstore-config 

