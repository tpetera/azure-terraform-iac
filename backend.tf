terraform {
  backend "azurerm" {
    resource_group_name  = "rg-azure-iac-p1" # Your_Resource_Group_Name
    storage_account_name = "azuretfstatep1" # Your_Storage_Account_Name
    container_name       = "tfstate" # This is the container name
    key                  = "azure_iac_p1.tfstate" # This will be the name of your state file in the container
    use_oidc             = true      # Use OpenID Connect for authenticating to the backend
    tenant_id            = "81146058-ee27-4637-b724-89ff65842da9" # Your Azure AD Tenant ID

    # For OIDC to work for the backend, the Service Principal associated with your GitHub Actions
    # (via the federated credential) must have permissions (like 'Storage Blob Data Contributor')
    # on the storage account. We set this up in the Azure portal.
  }
}