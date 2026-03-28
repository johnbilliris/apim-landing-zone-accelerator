variable "workload_name" {
  type    = string
  default = "inte"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "hub_subscription_id" {
  type    = string
  default = "c8703ebc-bc5d-488d-9489-5883c9fde6c2"
}

variable "spoke_subscription_id" {
  type    = string
  default = "c8703ebc-bc5d-488d-9489-5883c9fde6c2"
}

variable "application_insights_subscription_id" {
  type    = string
  default = "c8703ebc-bc5d-488d-9489-5883c9fde6c2"
}
