variable "aws_region" {
  description = "Ireland"
  default     = "eu-west-1"
}

variable "aws_az_count" {
  description = "Number of AZs"
  default     = "2"
}

variable "aws_haproxy_instance_type" {
  description = "instance type for haproxy nodes"
  default     = "t2.micro"
}

variable "haproxy_cluster_size" {
  description = "number of haproxy nodes"
  default     = 1
}

variable "haproxy_aws_amis" {
  description = "Ubuntu Xenial"

  default = {
    "eu-west-1" = "ami-0eb66a0c3eb9f5183"
  }
}

variable "haproxy_domain" {
  default = "haproxy-test.cloud-platform.dsd.io"
}

variable "haproxy_host" {
  default = "www"
}

variable "backends_weights" {
  type = "list"

  default = [
    {
      "demo.apps.cloud-platform-test-0.k8s.integration.dsd.io" = "2"
    },
    {
      "demo.apps.cloud-platform-live-0.k8s.integration.dsd.io" = "8"
    },
  ]
}
