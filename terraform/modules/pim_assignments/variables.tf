variable "request_type" {
  default     = "AdminUpdate"
  description = "The type of the role assignment schedule request. Eg: SelfActivate, AdminAssign etc"

  validation {
    condition = contains([
      "AdminAssign", "AdminExtend", "AdminRemove", "AdminRenew", "AdminUpdate", "SelfActivate", "SelfDeactivate",
      "SelfExtend", "SelfRenew"
    ], var.request_type )
    error_message = "Request Type Error"
  }
}

variable "subscription_id" {
  type        = string
  description = "Subscription ID"
  default     = null
}

variable "principal_id" {
  description = "User/Group Principal ID"
  type        = string
}

variable "role_definition_id" {
  description = "Role Definition ID"
  type        = string
}