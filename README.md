# Azure Enterprise Entitlement Mangement : Access Catalogs & Access Packages


# How to provision new access packages in an existing catalog
1. Create/Update the yaml file for each project with access packages and resources.

2. update the terraform variable [ The YAML path is expected to be in the projects folder ]

3. Run terraform apply [ -state ] : Preffered approach to run terraform apply with state files in different names or path speficic to the project.

eg : terraform apply -auto-approve -state=../states/project1-state.tf# azure-entitlement-management
