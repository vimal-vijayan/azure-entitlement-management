resource "random_uuid" "pim_assignment_uuid" {}

data "azurerm_subscription" "subscription" {
  subscription_id = var.subscription_id
}

resource "azapi_resource" "pim_assignment_sub" {
  type      = "Microsoft.Authorization/roleEligibilityScheduleRequests@2022-04-01-preview"
  name      = random_uuid.pim_assignment_uuid.result
  parent_id = data.azurerm_subscription.subscription.id
  body      = jsonencode({
    properties = {
      principalId      = var.principal_id
      requestType      = var.request_type
      roleDefinitionId = "${var.role_definition_id}"
      scheduleInfo     = {
        expiration = {
          duration    = "P365D"
          endDateTime = "null"
          type        = "AfterDuration"
        }
      }
    }
  })
}

