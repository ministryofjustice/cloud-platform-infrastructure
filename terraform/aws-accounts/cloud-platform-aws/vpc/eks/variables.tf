variable "vpc_name" {
  description = "The VPC name where the cluster(s) are going to be provisioned. VPCs are created in cloud-platform-network"
  default = {
    manager = "live-1"
    live    = "live-1"
  }
}
