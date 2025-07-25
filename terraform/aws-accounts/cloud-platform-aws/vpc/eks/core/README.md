# Cloud Platform - Core

## Core layer is a work in progress. We have some further modules to migrate from `components`:

- ingress controllers
- label pods
- others?
- break out CRDs from trivy operator and install here for better trivy upgrade management

This layer deploys core terraform components and must be applied before other components are applied.
