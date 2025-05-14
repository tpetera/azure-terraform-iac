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

  # Skip attempting to register Azure Resource Providers.
  # This is useful if the Service Principal does not have subscription-level
  # permissions to register providers.
  # Ensure that necessary providers (e.g., Microsoft.Compute, Microsoft.Network)
  # are already registered in your Azure subscription.
  skip_provider_registration = true
}
