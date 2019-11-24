
agent:
  image:
    tag: ${ kiam_version }

  ## Host networking settings
  ##
  host:
    iptables: true

  ## Additional container hostPath mounts
  ##
  extraHostPathMounts:
  - name: ssl-certs
    mountPath: /etc/ssl/certs
    hostPath: /etc/pki/ca-trust/extracted/pem
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

  ## Additional container hostPath mounts
  ##
  extraHostPathMounts:
  - name: ssl-certs
    mountPath: /etc/ssl/certs
    hostPath: /etc/pki/ca-trust/extracted/pem
    readOnly: true

  assumeRoleArn: arn:aws:iam::754256621582:role/kiam-server

  ## Base64-encoded PEM values for server's CA certificate(s), certificate and private key
  ##
  tlsFiles:
    ca: ${ ca }
    cert: ${ server_cert }
    key: ${ server_key }

  prometheus:
    port: 9621
