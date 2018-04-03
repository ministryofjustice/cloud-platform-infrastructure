#!/usr/bin/env python
import json

from pathlib import Path


class TfvarsCheck:

    def __init__(self, tfvars_file):
        self.tfvars_file = Path(tfvars_file)

    def check(self):
        if not self.tfvars_file.exists():
            fatal('Terraform variables in <file://$REPO_ROOT/config.json> is not found')

        tfvars = {}
        with self.tfvars_file.open('r') as f:
            tfvars = json.loads(f.read() or '{}')

        if not tfvars:
            fatal('Terraform variables in <file://$REPO_ROOT/config.json> is empty')

        if not tfvars.get('domain_name', None):
            fatal('Terraform variable "domain_name" in <file://$REPO_ROOT/config.json> is empty or null')


def fatal(msg):
    print("--> [FATAL] - {0}".format(msg))
    exit(1)


class ProgramCheck:

    def __init__(self, name):
        self.name = str(name)

    def check(self):
        return False


CHECKS = [
    ProgramCheck("aws"),
    ProgramCheck("kops"),
    ProgramCheck("kubectl"),
    ProgramCheck("terraform")
]


def main():
    TfvarsCheck('config.json').check()


if __name__ == "__main__":
    main()
