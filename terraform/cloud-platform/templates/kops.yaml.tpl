############################################
# NOTE: This file is managed by Terraform  #
# Don't make any manual modification to it #
############################################
apiVersion: kops/v1alpha2
kind: Cluster
metadata:
  creationTimestamp: null
  name: ${cluster_domain_name}
spec:
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
  additionalPolicies:
    node: |
      [
        {
          "Effect": "Allow",
          "Action": [
            "route53:ChangeResourceRecordSets"
          ],
          "Resource": [
            "arn:aws:route53:::hostedzone/${hosted_zone_id}"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
  authorization:
    rbac: {}
  channel: stable
  cloudProvider: aws
  sshKeyName: ${cluster_domain_name}
  configBase: s3://${kops_state_store}/${cluster_domain_name}
  dnsZone: ${cluster_domain_name}
  etcdClusters:
  - etcdMembers:
    - instanceGroup: master-eu-west-1a
      name: a
    - instanceGroup: master-eu-west-1b
      name: b
    - instanceGroup: master-eu-west-1c
      name: c
    name: main
  - etcdMembers:
    - instanceGroup: master-eu-west-1a
      name: a
    - instanceGroup: master-eu-west-1b
      name: b
    - instanceGroup: master-eu-west-1c
      name: c
    name: events
  iam:
    allowContainerRegistry: true
    legacy: false
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
    - Initializers
    - NamespaceLifecycle
    - LimitRanger
    - ServiceAccount
    - PersistentVolumeLabel
    - DefaultStorageClass
    - DefaultTolerationSeconds
    - MutatingAdmissionWebhook
    - ValidatingAdmissionWebhook
    - NodeRestriction
    - ResourceQuota
    - PodSecurityPolicy
  kubernetesApiAccess:
  - 0.0.0.0/0
  kubernetesVersion: 1.10.3
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
    name: eu-west-1a
    type: Private
    zone: eu-west-1a
  - cidr: 172.20.64.0/19
    id: ${internal_subnets_id_b}
    name: eu-west-1b
    type: Private
    zone: eu-west-1b
  - cidr: 172.20.96.0/19
    id: ${internal_subnets_id_c}
    name: eu-west-1c
    type: Private
    zone: eu-west-1c
  - cidr: 172.20.0.0/22
    id: ${external_subnets_id_a}
    name: utility-eu-west-1a
    type: Utility
    zone: eu-west-1a
  - cidr: 172.20.4.0/22
    id: ${external_subnets_id_b}
    name: utility-eu-west-1b
    type: Utility
    zone: eu-west-1b
  - cidr: 172.20.8.0/22
    id: ${external_subnets_id_c}
    name: utility-eu-west-1c
    type: Utility
    zone: eu-west-1c
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

apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: null
  labels:
    kops.k8s.io/cluster: ${cluster_domain_name}
  name: master-eu-west-1a
spec:
  image: kope.io/k8s-1.8-debian-jessie-amd64-hvm-ebs-2018-01-14
  machineType: c4.xlarge
  maxSize: 1
  minSize: 1
  nodeLabels:
    kops.k8s.io/instancegroup: master-eu-west-1a
  cloudLabels:
    application: moj-cloud-platform
    business-unit: platforms
    is-production: true
    role: master
    owner: cloud-platform:platforms@digital.justice.gov.uk
    source-code: https://github.com/ministryofjustice/cloud-platform-infrastructure
  role: Master
  subnets:
  - eu-west-1a

---

apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: null
  labels:
    kops.k8s.io/cluster: ${cluster_domain_name}
  name: master-eu-west-1b
spec:
  image: kope.io/k8s-1.8-debian-jessie-amd64-hvm-ebs-2018-01-14
  machineType: c4.xlarge
  maxSize: 1
  minSize: 1
  nodeLabels: 
    kops.k8s.io/instancegroup: master-eu-west-1b
  cloudLabels:
    application: moj-cloud-platform
    business-unit: platforms
    is-production: true
    role: master
    owner: cloud-platform:platforms@digital.justice.gov.uk
    source-code: https://github.com/ministryofjustice/cloud-platform-infrastructure
  role: Master
  subnets:
  - eu-west-1b

---

apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: null
  labels:
    kops.k8s.io/cluster: ${cluster_domain_name}
  name: master-eu-west-1c
spec:
  image: kope.io/k8s-1.8-debian-jessie-amd64-hvm-ebs-2018-01-14
  machineType: c4.xlarge
  maxSize: 1
  minSize: 1
  nodeLabels:
    kops.k8s.io/instancegroup: master-eu-west-1c
  cloudLabels:
    application: moj-cloud-platform
    business-unit: platforms
    is-production: true
    role: master
    owner: cloud-platform:platforms@digital.justice.gov.uk
    source-code: https://github.com/ministryofjustice/cloud-platform-infrastructure
  role: Master
  subnets:
  - eu-west-1c

---

apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: null
  labels:
    kops.k8s.io/cluster: ${cluster_domain_name}
  name: nodes
spec:
  image: kope.io/k8s-1.8-debian-jessie-amd64-hvm-ebs-2018-01-14
  machineType: c4.2xlarge
  maxSize: 6
  minSize: 6
  nodeLabels:
    kops.k8s.io/instancegroup: nodes
  cloudLabels:
    application: moj-cloud-platform
    business-unit: platforms
    is-production: true
    role: node
    owner: cloud-platform:platforms@digital.justice.gov.uk
    source-code: https://github.com/ministryofjustice/cloud-platform-infrastructure
  role: Node
  subnets:
  - eu-west-1a
  - eu-west-1b
  - eu-west-1c
