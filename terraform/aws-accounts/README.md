# AWS Accounts folder

```text
├── cloud-platform-ephemeral-test       # Account Name
│   ├── bootstrap                       # Creation of terraform state backend.
│   ├── cloud-platform                  # Holding kops/bastion/route53, workspaces for individual clusters.
│   ├── cloud-platform-account          # AWS Account specific configuration.
│   ├── cloud-platform-components       # K8S components. Workspaces for individual clusters
│   └── cloud-platform-network          # VPC creation. Workspaces for individual clusters
├── cloud-platform-dsd
│   └── main.tf                         # DSD account is dying, we only manage a single DNS entry there (cloud-platform.service.justice.gov.uk)
├── cloud-platform
│   ├── bootstrap
│   ├── cloud-platform
│   ├── cloud-platform-account
│   ├── cloud-platform-components
│   └── cloud-platform-network
└── README.md                           # This README

```

## Proposal 2

```text
aws-accounts
├── cloud-platform-prod
│   ├── bootstrap
│   ├── cloud-platform-account
│   ├── cloud-platform-eks
│   │   └── components
│   ├── cloud-platform-kops
│   │   └── components
│   └── cloud-platform-network
├── cloud-platform-nonprod
│   ├── bootstrap
│   ├── cloud-platform-account
│   ├── cloud-platform-eks
│   │   └── components
│   ├── cloud-platform-kops
│   │   └── components
│   └── cloud-platform-network
├── cloud-platform-dsd
├── cloud-platform-ephemeral-test
│   ├── bootstrap
│   ├── cloud-platform-account
│   ├── cloud-platform-eks
│   │   └── components
│   ├── cloud-platform-kops
│   │   └── components
│   └── cloud-platform-network
└── README.md

```
