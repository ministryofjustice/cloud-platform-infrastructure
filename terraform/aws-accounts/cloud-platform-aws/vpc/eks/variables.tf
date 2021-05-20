variable "vpc_name" {
  description = "The VPC name where the cluster(s) are going to be provisioned. VPCs are created in cloud-platform-network"
  default = {
    manager = "live-1"
    live    = "live-1"
  }
}

variable "dockerhub_user" {
  description = "Cloud platform user (see lastpass). This is required to avoid hitting limits when pulling images."
}

variable "dockerhub_token" {
  description = "Token for the above"
}
