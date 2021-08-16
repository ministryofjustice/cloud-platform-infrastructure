apiVersion: v1
kind: Config
current-context: ""

clusters:
%{ for x in clusters ~}
- name: ${x.name}
  cluster:
     server: ${x.host}
     certificate-authority-data: ${x.ca_data}
%{ endfor ~}

contexts:
%{ for x in clusters ~}
- context:
    cluster: ${x.name}
    user: ${x.name}
  name: ${x.name}
%{ endfor ~}

users:
%{ for x in clusters ~}
- name: ${x.name}
  user:
    token: ${x.token}
%{ endfor ~}
