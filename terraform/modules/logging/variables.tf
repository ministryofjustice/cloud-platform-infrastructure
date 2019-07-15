

variable "LOCAL_ELASTICSEARCH" {
  default = true
}

variable "LOCAL_ELASTICSEARCH_HOST" {
  default="elasticsearch-master"
}


variable "depends_on"{
    default=""
}

variable "logging_enabled" {
  default = true
}
