controller:
  replicaCount: 6

  electionID: ingress-controller-leader-acme

  config:
    custom-http-errors: 413,502,503,504
    generate-request-id: "true"
    proxy-buffer-size: "16k"
    proxy-body-size: "50m"
    server-snippet: |
      if ($scheme != 'https') {
        return 308 https://$host$request_uri;
      }

    #
    # For a list of available variables please check the documentation on
    # `log-format-upstream` and also the relevant nginx document:
    # - https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/log-format/
    # - https://nginx.org/en/docs/varindex.html
    #
    log-format-escape-json: "true"
    log-format-upstream: >-
      {
      "time": "$time_iso8601",
      "body_bytes_sent": $body_bytes_sent,
      "bytes_sent": $bytes_sent,
      "http_host": "$host",
      "http_referer": "$http_referer",
      "http_user_agent": "$http_user_agent",
      "http_x_real_ip": "$http_x_real_ip",
      "http_x_forwarded_for": "$http_x_forwarded_for",
      "http_x_forwarded_proto": "$http_x_forwarded_proto",
      "kubernetes_namespace": "$namespace",
      "kubernetes_ingress_name": "$ingress_name",
      "kubernetes_service_name": "$service_name",
      "kubernetes_service_port": "$service_port",
      "proxy_upstream_name": "$proxy_upstream_name",
      "proxy_protocol_addr": "$proxy_protocol_addr",
      "remote_addr": "$remote_addr",
      "remote_user": "$remote_user",
      "request_id": "$req_id",
      "request_length": $request_length,
      "request_method": "$request_method",
      "request_path": "$uri",
      "request_proto": "$server_protocol",
      "request_query": "$args",
      "request_time": "$request_time",
      "request_uri": "$request_uri",
      "response_http_location": "$sent_http_location",
      "server_name": "$server_name",
      "server_port": $server_port,
      "ssl_cipher": "$ssl_cipher",
      "ssl_client_s_dn": "$ssl_client_s_dn",
      "ssl_protocol": "$ssl_protocol",
      "ssl_session_id": "$ssl_session_id",
      "status": $status,
      "upstream_addr": "$upstream_addr",
      "upstream_response_length": $upstream_response_length,
      "upstream_response_time": $upstream_response_time,
      "upstream_status": $upstream_status
      }

  publishService:
    enabled: true

  stats:
    enabled: true

  metrics:
    enabled: true

  service:
    annotations:
      external-dns.alpha.kubernetes.io/hostname: "*.apps.${cluster_domain_name},apps.${cluster_domain_name}"
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"

    externalTrafficPolicy: "Local"

  extraArgs:
    default-ssl-certificate: ingress-controllers/default-certificate
  
  admissionWebhooks:
    enabled: true
    failurePolicy: Fail
    port: 8443

    service:
      annotations: {}
      omitClusterIP: false
      clusterIP: ""
      externalIPs: []
      loadBalancerIP: ""
      loadBalancerSourceRanges: []
      servicePort: 443
      type: ClusterIP

    patch:
      enabled: true
      image:
        repository: jettech/kube-webhook-certgen
        tag: v1.0.0
        pullPolicy: IfNotPresent
      priorityClassName: ""
      podAnnotations: {}
      nodeSelector: {}

defaultBackend:
  enabled: true

  name: default-backend
  image:
    repository: ministryofjustice/cloud-platform-custom-error-pages
    tag: "0.4"
    pullPolicy: IfNotPresent

  extraArgs: {}

  port: 8080

rbac:
  create: true
