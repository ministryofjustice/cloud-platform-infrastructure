# AWS Accounts folder

```text
aws-accounts
├── cloud-platform-aws
│   ├── cloud-platform-account  # AWS Account specific configuration.
│   └── cloud-platform-network  # VPC creation. Workspaces for individual clusters
│       ├── cloud-platform-eks  # Holding EKS, workspaces for individual clusters.
│       │   └── components      # EKS components. Workspaces for individual clusters
│       └── cloud-platform-kops # Holding KOPS, workspaces for individual clusters.
│           └── components      # KOPS components. Workspaces for individual clusters
├── cloud-platform-dsd
│   └── main.tf
├── cloud-platform-ephemeral-test
│   ├── cloud-platform-account
│   └── cloud-platform-network
│       ├── cloud-platform-eks
│       │   └── components
│       └── cloud-platform-kops
│           └── components
└── README.md
```
