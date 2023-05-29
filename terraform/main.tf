# Get Current Client Details
data "azuread_client_config" "current" {}

# Create catalog
# resource "azuread_access_package_catalog" "catalog" {
#   display_name = local.em.Catalog.name
#   description  = "Some Description"
# }

data "azuread_access_package_catalog" "catalog" {
  display_name = local.catalog_name
}

# Get owner details
data "azuread_user" "this" {
  # mail = local.owner_email
  user_principal_name = local.owner_email
}

# Create the catalog AD Groups
resource "azuread_group" "catalog_ad_groups" {
  for_each         = toset(local.catalog_security_groups)
  display_name     = each.value
  security_enabled = true
  owners           = [data.azuread_user.this.object_id]
}

# Create the PIM AD Groups
resource "azuread_group" "pim_ad_groups" {
  for_each         = toset(local.pim_security_groups)
  display_name     = each.value
  security_enabled = true
  owners           = [data.azuread_user.this.object_id]
}

# Associate pim groups as resources to the catalog
resource "azuread_access_package_resource_catalog_association" "group_catalog_association" {
  for_each               = toset(local.pim_security_groups)
  catalog_id             = data.azuread_access_package_catalog.catalog.id
  resource_origin_id     = azuread_group.pim_ad_groups[each.value].id
  resource_origin_system = "AadGroup"
}

# Create Access Packages
resource "azuread_access_package" "access_package" {
  for_each     = { for k, v in local.access_packages_map : v.package_name => v }
  catalog_id   = data.azuread_access_package_catalog.catalog.id
  display_name = each.value.package_name
  description  = "Access Package"
}

# Requestor access policy for packages
resource "azuread_access_package_assignment_policy" "access_policies" {
  for_each          = local.package_to_policy_map
  access_package_id = azuread_access_package.access_package[each.value.package_name].id
  display_name      = each.value.policy.policyName
  description       = each.value.policy.description
  duration_in_days  = each.value.policy.duration


  dynamic "requestor_settings" {
    for_each = try(each.value.policy.requestorSettings, false) != false ? { for k, v in each.value.policy.requestorSettings : k => v } : {}
    content {
      scope_type        = requestor_settings.value.scopeType
      requests_accepted = requestor_settings.value.requestsAccepted
      dynamic "requestor" {
        for_each = { for k, v in requestor_settings.value.requestor : v.group => v }
        content {
          object_id    = azuread_group.catalog_ad_groups[requestor.value.group].object_id
          subject_type = requestor.value.subjectType
        }
      }
    }
  }

  dynamic "approval_settings" {
    for_each = try(each.value.policy.approverSettings, false) != false ? { for k, v in each.value.policy.approverSettings : k => v } : {}
    content {
      approval_required                = approval_settings.value.approvalRequired
      requestor_justification_required = approval_settings.value.requestorJustificationRequired
      approval_stage {
        approval_timeout_in_days = approval_settings.value.approvalStage.approvalTimeoutInDays
        primary_approver {
          object_id    = azuread_group.catalog_ad_groups[approval_settings.value.approvalStage.primaryApprover.group].object_id
          subject_type = approval_settings.value.approvalStage.primaryApprover.subjectType
        }
      }
    }
  }

  dynamic "assignment_review_settings" {
    for_each = try(each.value.policy.assignment_review_settings, false) != false ? { for k, v in each.value.policy.assignment_review_settings : k => v } : {}
    content {
      enabled                        = assignment_review_settings.value.enabled
      review_frequency               = assignment_review_settings.value.reviewFrequency
      duration_in_days               = assignment_review_settings.value.durationInDays
      review_type                    = assignment_review_settings.value.reviewType
      access_review_timeout_behavior = assignment_review_settings.value.accessReviewTimeoutBehavior
      dynamic "reviewer" {
        for_each = { for k, v in assignment_review_settings.value.reviewer : k => v }
        content {
          object_id    = azuread_group.catalog_ad_groups[reviewer.value.group].object_id
          subject_type = reviewer.value.subject_type
        }
      }
    }
  }
}

# Sleep for 10sec, lets wait for the groups/access packages to complete provisioning
resource "time_sleep" "wait_10_seconds" {
  create_duration = "10s"
}

# Add PIM group resources into the respective acess packages
resource "azuread_access_package_resource_package_association" "owner_ap_resource_assignment" {
  depends_on                      = [time_sleep.wait_10_seconds]
  for_each                        = { for k, v in local.pim_to_access_package : k => v }
  access_package_id               = each.value.package_id
  catalog_resource_association_id = each.value.cat_association_id
}
