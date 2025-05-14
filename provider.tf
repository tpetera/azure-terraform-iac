terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # You can update to a more recent stable version if you wish
    }
  }
}

provider "azurerm" {
  features {}

  # For GitHub Actions:
  # Authentication will be handled by the `azure/login@v1` action using OIDC.
  # The Service Principal (whose details are used by OIDC) needs 'Contributor'
  # role on the resource group and 'Storage Blob Data Contributor' on the storage account.

  # For local execution (e.g., running `terraform plan` on your machine):
  # 1. Make sure you are logged in via Azure CLI (`az login`). Terraform will use these credentials.
  # 2. Alternatively, you could set environment variables for Service Principal authentication
  #    (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID) if not using OIDC locally.
  #    However, for OIDC with the backend, we'll configure that in backend.tf.
}