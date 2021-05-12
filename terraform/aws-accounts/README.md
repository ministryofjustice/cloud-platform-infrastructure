# AWS Accounts folder

```text
aws-accounts
├── cloud-platform-aws
│   ├── account                  # AWS Account specific configuration.
│   └── vpc                      # VPC creation. Workspaces for individual clusters
│       ├── eks                  # Holding EKS, workspaces for individual clusters.
│       │   └── components       # EKS components. Workspaces for individual clusters
│       └── kops                 # Holding KOPS, workspaces for individual clusters.
│           └── components       # KOPS components. Workspaces for individual clusters
├── cloud-platform-dsd
│   └── main.tf
├── cloud-platform-ephemeral-test
│   ├── account
│   └── vpc
│       ├── eks
│       │   └── components
│       └── kops
│           └── components
└── README.md
```
