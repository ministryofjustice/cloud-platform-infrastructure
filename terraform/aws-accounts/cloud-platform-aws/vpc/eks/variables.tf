variable "worker_node_machine_type" {
  description = "The AWS EC2 instance types to use for worker nodes"
  default     = "m4.xlarge"
}

variable "dockerhub_user" {
  description = "Cloud platform user (see lastpass). This is required to avoid hitting limits when pulling images."
}

variable "dockerhub_token" {
  description = "Token for the above"
}
