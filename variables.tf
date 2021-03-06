variable "resource_group_name" {
  default = "acme"
}


variable "subscription_id" {
  type        = string
  description = "Your Azure Subscription ID"
}
variable "client_id" {
  type        = string
  description = "Your Azure Service Principal appId"
}
variable "client_secret" {
  type        = string
  sensitive = true
  description = "Your Azure Service Principal Password"
}
variable "tenant_id" {
  type        = string
  description = "Your Azure Tenant ID"
}

variable "object_id" {
  type        = string
  description = "Your SPN ID - if using"
}