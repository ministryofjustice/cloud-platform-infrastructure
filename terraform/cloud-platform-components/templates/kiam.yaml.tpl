extraArgs: {}

agent:
  image:
    tag: ${ kiam_version }

  gatewayTimeoutCreation: 5000ms

  tolerations:
    - key: "monitoring-node"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"

  ## Host networking settings
  ##
  host:
    iptables: true
    port: 8181
    interface: cali+

  ## Node labels for pod assignment
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector:
    # kubernetes.io/role: node

  ## Additional container hostPath mounts
  ##
  extraHostPathMounts:
  - name: ssl-certs
    mountPath: /etc/ssl/certs
    hostPath: /etc/ssl/certs
    readOnly: true

  ## Base64-encoded PEM values for agent's CA certificate(s), certificate and private key
  ##
  tlsFiles:
    ca: ${ ca }
    cert: ${ agent_cert }
    key: ${ agent_key }

server:
  useHostNetwork: true

  image:
    tag: ${ kiam_version }

  probes:
    serverAddress: 127.0.0.1

  gatewayTimeoutCreation: 500ms

  nodeSelector: {}
    # kubernetes.io/role: master

  ## Pod tolerations
  ## Ref https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
  ##
  tolerations:
    - key: "monitoring-node"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"

  # - key: node-role.kubernetes.io/master
  #   effect: NoSchedule

  ## Additional container hostPath mounts
  ##
  extraHostPathMounts:
  - name: ssl-certs
    mountPath: /etc/ssl/certs
    hostPath: /etc/ssl/certs
    readOnly: true

  ## Base64-encoded PEM values for server's CA certificate(s), certificate and private key
  ##
  tlsFiles:
    ca: ${ ca }
    cert: ${ server_cert }
    key: ${ server_key }

  prometheus:
    port: 9621
