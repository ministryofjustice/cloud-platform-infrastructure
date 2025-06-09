# Cloud Platform Network Firewall

This Terraform module provisions a network firewall within an AWS VPC to secure traffic between the Cloud Platform and the Ministry of Justice (MOJ) internal network.

## Overview

This configuration sets up the following:

- A dedicated VPC with multiple availability zones and both private and intra subnets.
- An AWS Network Firewall instance using the `terraform-aws-modules/network-firewall` module.
- A stateful firewall rule group built dynamically from a local `firewall_rules.json` file.
- A firewall policy referencing the stateful rules.
- Logging of firewall alerts to CloudWatch Logs.
- Routing configuration to direct traffic through the firewall using VPC endpoints.
- Supporting infrastructure like subnets, route tables, and log groups.

## Components

- **Firewall Rule Group**: Configured using stateful rules derived from `firewall_rules.json`.
- **Firewall Policy**: Specifies how traffic is handled (e.g. forwarding or dropping).
- **Network Firewall**: Deployed into dedicated subnets with subnet mappings.
- **Logging**: Captures alerts to a CloudWatch Log Group with a 7-day retention.
- **Routing**: Sets up routes from intra subnets to the firewall and placeholders for future transit gateway integration.

## Notes

- `firewall_rules.json` must exist and define the expected schema for rules to be applied.
- This module assumes three availability zones are used.
- The final transit gateway routing is stubbed and not yet implemented.
