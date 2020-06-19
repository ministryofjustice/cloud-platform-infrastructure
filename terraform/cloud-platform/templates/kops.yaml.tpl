############################################
# NOTE: This file is managed by Terraform  #
# Don't make any manual modification to it #
############################################
apiVersion: kops.k8s.io/v1alpha2
kind: Cluster
metadata:
  creationTimestamp: null
  name: ${cluster_domain_name}
spec:
  docker:
    registryMirrors:
    # The docker-registry-cache is defined in terraform/cloud-platform-components/docker-registry-cache.tf
    - https://docker-registry-cache.apps.${cluster_domain_name}
  fileAssets:
  - name: kubernetes-audit
    path: /srv/kubernetes/audit.yaml
    roles: [Master]
    content: |
      # The following audit policy is based on two sources from upstream:
      #   - the kubernetes docs example: https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/audit/audit-policy.yaml
      #   - the GCE reference policy: https://github.com/kubernetes/kubernetes/blob/master/cluster/gce/gci/configure-helper.sh#L784
      #
      apiVersion: audit.k8s.io/v1beta1
      kind: Policy
      omitStages:
        - "RequestReceived"
      rules:
        # The following requests were manually identified as high-volume and low-risk,
        # so drop them.
        - level: None
          users: ["system:kube-proxy"]
          verbs: ["watch"]
          resources:
            - group: "" # core
              resources: ["endpoints", "services", "services/status"]
        - level: None
          namespaces: ["ingress-controllers"]
          verbs: ["get"]
          resources:
            - group: "" # core
              resources: ["configmaps"]
              resourceNames: ["ingress-controller-leader-nginx"]
        - level: None
          users: ["kubelet"] # legacy kubelet identity
          verbs: ["get"]
          resources:
            - group: "" # core
              resources: ["nodes", "nodes/status"]
        - level: None
          userGroups: ["system:nodes"]
          verbs: ["get"]
          resources:
            - group: "" # core
              resources: ["nodes", "nodes/status"]
        - level: None
          users:
            - system:kube-controller-manager
            - system:kube-scheduler
            - system:serviceaccount:kube-system:endpoint-controller
          verbs: ["get", "update"]
          namespaces: ["kube-system"]
          resources:
            - group: "" # core
              resources: ["endpoints"]
        - level: None
          users: ["system:apiserver"]
          verbs: ["get"]
          resources:
            - group: "" # core
              resources: ["namespaces", "namespaces/status", "namespaces/finalize"]
        # Don't log HPA fetching metrics.
        - level: None
          users:
            - system:kube-controller-manager
          verbs: ["get", "list"]
          resources:
            - group: "metrics.k8s.io"
        # Don't log these read-only URLs.
        - level: None
          nonResourceURLs:
            - /healthz*
            - /version
            - /swagger*
        # Don't log authenticated requests to certain non-resource URL paths.
        - level: None
          userGroups: ["system:authenticated"]
          nonResourceURLs:
          - "/api*"
        # Don't log events requests.
        - level: None
          resources:
            - group: "" # core
              resources: ["events"]

        # Log "pods/log", "pods/status" at Metadata level
        - level: Metadata
          resources:
          - group: ""
            resources: ["pods/log", "pods/status"]
        # node and pod status calls from nodes are high-volume and can be large, don't log responses for expected updates from nodes
        - level: Request
          users: ["kubelet", "system:node-problem-detector", "system:serviceaccount:kube-system:node-problem-detector"]
          verbs: ["update","patch"]
          resources:
            - group: "" # core
              resources: ["nodes/status", "pods/status"]
        - level: Request
          userGroups: ["system:nodes"]
          verbs: ["update","patch"]
          resources:
            - group: "" # core
              resources: ["nodes/status", "pods/status"]
        # deletecollection calls can be large, don't log responses for expected namespace deletions
        - level: Request
          users: ["system:serviceaccount:kube-system:namespace-controller"]
          verbs: ["deletecollection"]
        # Secrets, ConfigMaps, and TokenReviews can contain sensitive & binary data,
        # so only log at the Metadata level.
        - level: Metadata
          resources:
            - group: "" # core
              resources: ["secrets", "configmaps"]
            - group: authentication.k8s.io
              resources: ["tokenreviews"]
        # Get repsonses can be large; skip them.
        - level: Request
          verbs: ["get", "list", "watch"]
          resources:
          - group: "" # core
          - group: "admissionregistration.k8s.io"
          - group: "apiextensions.k8s.io"
          - group: "apiregistration.k8s.io"
          - group: "apps"
          - group: "authentication.k8s.io"
          - group: "authorization.k8s.io"
          - group: "autoscaling"
          - group: "batch"
          - group: "certificates.k8s.io"
          - group: "extensions"
          - group: "metrics.k8s.io"
          - group: "networking.k8s.io"
          - group: "policy"
          - group: "rbac.authorization.k8s.io"
          - group: "scheduling.k8s.io"
          - group: "settings.k8s.io"
          - group: "storage.k8s.io"
        # Default level for known APIs
        - level: RequestResponse
          resources:
          - group: "" # core
          - group: "admissionregistration.k8s.io"
          - group: "apiextensions.k8s.io"
          - group: "apiregistration.k8s.io"
          - group: "apps"
          - group: "authentication.k8s.io"
          - group: "authorization.k8s.io"
          - group: "autoscaling"
          - group: "batch"
          - group: "certificates.k8s.io"
          - group: "extensions"
          - group: "metrics.k8s.io"
          - group: "networking.k8s.io"
          - group: "policy"
          - group: "rbac.authorization.k8s.io"
          - group: "scheduling.k8s.io"
          - group: "settings.k8s.io"
          - group: "storage.k8s.io"
        # Default level for all other requests.
        - level: Metadata
          omitStages:
            - "RequestReceived"

  api:
    loadBalancer:
      type: Public
  authorization:
    rbac: {}
  channel: stable
  cloudProvider: aws
  sshKeyName: ${cluster_domain_name}
  configBase: s3://${kops_state_store}/${cluster_domain_name}
  dnsZone: ${cluster_domain_name}
  etcdClusters:
  - etcdMembers:
    - instanceGroup: master-eu-west-2a
      name: a
      encryptedVolume: true
      kmsKeyId: "${ kms_key }"
    - instanceGroup: master-eu-west-2b
      name: b
      encryptedVolume: true
      kmsKeyId: "${ kms_key }"
    - instanceGroup: master-eu-west-2c
      name: c
      encryptedVolume: true
      kmsKeyId: "${ kms_key }"
    name: main
    version: 3.3.10
  - etcdMembers:
    - instanceGroup: master-eu-west-2a
      name: a
      encryptedVolume: true
      kmsKeyId: "${ kms_key }"
    - instanceGroup: master-eu-west-2b
      name: b
      encryptedVolume: true
      kmsKeyId: "${ kms_key }"
    - instanceGroup: master-eu-west-2c
      name: c
      encryptedVolume: true
      kmsKeyId: "${ kms_key }"
    name: events
    version: 3.3.10
  iam:
    allowContainerRegistry: true
    legacy: false
  kubelet:
    anonymousAuth: false
    readOnlyPort: 0
    authenticationTokenWebhook: true
  kubeAPIServer:
    oidcClientID: ${oidc_client_id}
    oidcIssuerURL: ${oidc_issuer_url}
    oidcUsernameClaim: nickname
    oidcGroupsClaim: https://k8s.integration.dsd.io/groups
    auditLogPath: /var/log/kube-apiserver-audit.log
    auditLogMaxAge: 10
    auditLogMaxBackups: 1
    auditLogMaxSize: 100
    auditPolicyFile: /srv/kubernetes/audit.yaml
    enableAdmissionPlugins:
    - NamespaceLifecycle
    - LimitRanger
    - ServiceAccount
    - DefaultStorageClass
    - DefaultTolerationSeconds
    - MutatingAdmissionWebhook
    - ValidatingAdmissionWebhook
    - NodeRestriction
    - ResourceQuota
    - PodSecurityPolicy
    featureGates:
      TTLAfterFinished: "true"
  kubeControllerManager:
    featureGates:
      TTLAfterFinished: "true"
  kubeProxy:
    metricsBindAddress: 0.0.0.0
  kubernetesApiAccess:
  - 0.0.0.0/0
  kubernetesVersion: 1.15.12
  masterPublicName: api.${cluster_domain_name}
  networkCIDR: ${network_cidr_block}
  networkID: ${network_id}
  networking:
    calico: {}
  nonMasqueradeCIDR: 100.64.0.0/10
  sshAccess:
  - 0.0.0.0/0
  subnets:
  - cidr: 172.20.32.0/19
    id: ${internal_subnets_id_a}
    name: eu-west-2a
    type: Private
    zone: eu-west-2a
  - cidr: 172.20.64.0/19
    id: ${internal_subnets_id_b}
    name: eu-west-2b
    type: Private
    zone: eu-west-2b
  - cidr: 172.20.96.0/19
    id: ${internal_subnets_id_c}
    name: eu-west-2c
    type: Private
    zone: eu-west-2c
  - cidr: 172.20.0.0/22
    id: ${external_subnets_id_a}
    name: utility-eu-west-2a
    type: Utility
    zone: eu-west-2a
  - cidr: 172.20.4.0/22
    id: ${external_subnets_id_b}
    name: utility-eu-west-2b
    type: Utility
    zone: eu-west-2b
  - cidr: 172.20.8.0/22
    id: ${external_subnets_id_c}
    name: utility-eu-west-2c
    type: Utility
    zone: eu-west-2c
  topology:
    dns:
      type: Public
    masters: private
    nodes: private
  hooks:
  - name: authorized-keys-manager.service
    roles:
    - Master
    - Node
    manifest: |
      ${authorized_keys_manager_systemd_unit}

---

apiVersion: kops.k8s.io/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: null
  labels:
    kops.k8s.io/cluster: ${cluster_domain_name}
  name: master-eu-west-2a
spec:
  image: kope.io/k8s-1.15-debian-stretch-amd64-hvm-ebs-2020-01-17
  machineType: ${master_node_machine_type}
  maxSize: 1
  minSize: 1
  nodeLabels:
    kops.k8s.io/instancegroup: master-eu-west-2a
  cloudLabels:
    application: moj-cloud-platform
    business-unit: platforms
    is-production: "true"
    role: master
    owner: cloud-platform:platforms@digital.justice.gov.uk
    source-code: https://github.com/ministryofjustice/cloud-platform-infrastructure
  role: Master
  subnets:
  - eu-west-2a

---

apiVersion: kops.k8s.io/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: null
  labels:
    kops.k8s.io/cluster: ${cluster_domain_name}
  name: master-eu-west-2b
spec:
  image: kope.io/k8s-1.15-debian-stretch-amd64-hvm-ebs-2020-01-17
  machineType: ${master_node_machine_type}
  maxSize: 1
  minSize: 1
  nodeLabels:
    kops.k8s.io/instancegroup: master-eu-west-2b
  cloudLabels:
    application: moj-cloud-platform
    business-unit: platforms
    is-production: "true"
    role: master
    owner: cloud-platform:platforms@digital.justice.gov.uk
    source-code: https://github.com/ministryofjustice/cloud-platform-infrastructure
  role: Master
  subnets:
  - eu-west-2b

---

apiVersion: kops.k8s.io/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: null
  labels:
    kops.k8s.io/cluster: ${cluster_domain_name}
  name: master-eu-west-2c
spec:
  image: kope.io/k8s-1.15-debian-stretch-amd64-hvm-ebs-2020-01-17
  machineType: ${master_node_machine_type}
  maxSize: 1
  minSize: 1
  nodeLabels:
    kops.k8s.io/instancegroup: master-eu-west-2c
  cloudLabels:
    application: moj-cloud-platform
    business-unit: platforms
    is-production: "true"
    role: master
    owner: cloud-platform:platforms@digital.justice.gov.uk
    source-code: https://github.com/ministryofjustice/cloud-platform-infrastructure
  role: Master
  subnets:
  - eu-west-2c

%{ if enable_large_nodesgroup }

---

apiVersion: kops.k8s.io/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: null
  labels:
    kops.k8s.io/cluster: ${cluster_domain_name}
  name: 2xlarge-nodes-1.15.12
spec:
  image: kope.io/k8s-1.15-debian-stretch-amd64-hvm-ebs-2020-01-17
  machineType: r5.2xlarge
  maxSize: 2
  minSize: 2
  rootVolumeSize: 256
  nodeLabels:
    kops.k8s.io/instancegroup: 2xlarge-nodes-1.15.12
  cloudLabels:
    application: moj-cloud-platform
    business-unit: platforms
    is-production: "true"
    k8s.io/cluster/${cluster_domain_name}: ""
    role: node
    owner: cloud-platform:platforms@digital.justice.gov.uk
    source-code: https://github.com/ministryofjustice/cloud-platform-infrastructure
  role: Node
  taints:
  - monitoring-node=true:NoSchedule
  subnets:
  - eu-west-2b

%{ endif }

---

########################################################################################################################################
#                                                                                                                                      #
# NOTE: This InstanceGroup must always be the last entry in this file, for the node-recycler.                                          #
#                                                                                                                                      #
# https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/091ff8cc054fb2f87734edef8de28dd31d71b0b2/recycle-node.rb#L85 #
#                                                                                                                                      #
########################################################################################################################################

apiVersion: kops.k8s.io/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: null
  labels:
    kops.k8s.io/cluster: ${cluster_domain_name}
  name: nodes-1.15.12
spec:
  image: kope.io/k8s-1.15-debian-stretch-amd64-hvm-ebs-2020-01-17
  machineType: ${worker_node_machine_type}
  maxSize: ${cluster_node_count}
  minSize: ${cluster_node_count}
  rootVolumeSize: 256
  nodeLabels:
    kops.k8s.io/instancegroup: nodes-1.15.12
  cloudLabels:
    application: moj-cloud-platform
    business-unit: platforms
    is-production: "true"
    k8s.io/cluster/${cluster_domain_name}: ""
    role: node
    owner: cloud-platform:platforms@digital.justice.gov.uk
    source-code: https://github.com/ministryofjustice/cloud-platform-infrastructure
  role: Node
  subnets:
  - eu-west-2a
  - eu-west-2b
  - eu-west-2c
