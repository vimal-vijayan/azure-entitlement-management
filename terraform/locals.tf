locals {

  em                      = yamldecode(file("../projects/${var.yaml_file}"))
  catalog_name            = local.em.Catalog.name
  owner_email             = local.em.owner
  pim_security_groups     = flatten([for k, v in local.em.SecurityGroups : values(v) if one(keys(v)[*]) == "pimSecurityGroups"])
  catalog_security_groups = flatten([for k, v in local.em.SecurityGroups : values(v) if one(keys(v)[*]) == "catalogSecurityGroups"])
  access_packages         = { for k, v in local.em.Catalog.AccessPackages : v.name => v }
  access_packages_map = flatten([for k, v in local.access_packages :
    {
      catalog_id              = azuread_access_package_catalog.catalog.id,
      package_name            = v.name,
      security_groups         = v.SecurityGroups,
      requestor_access_policy = v.accessPolicy
    }
  ])
  package_to_policy     = flatten([for k, v in local.access_packages : [for a, b in v.accessPolicy : { package_name = v.name, policy = b }]])
  package_to_policy_map = { for k, v in local.package_to_policy : k => v }
  pim_to_access_package = flatten([for k, v in local.access_packages_map : [for a, b in v.security_groups :
    {
      package_name       = v.package_name,
      package_id         = azuread_access_package.access_package[v.package_name].id,
      cat_association_id = azuread_access_package_resource_catalog_association.group_catalog_association[b].id
    }
  ]])

}
