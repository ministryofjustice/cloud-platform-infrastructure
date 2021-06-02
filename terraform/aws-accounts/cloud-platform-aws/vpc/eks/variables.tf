variable "dockerhub_user" {
  description = "Cloud platform user (see lastpass). This is required to avoid hitting limits when pulling images."
}

variable "dockerhub_token" {
  description = "Token for the above"
}
