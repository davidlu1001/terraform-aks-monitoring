# versions.tf
#
# Specifies the version constraints for Terraform and the required providers.
# This ensures that the module is used with compatible versions, preventing
# unexpected errors or breaking changes.

terraform {
  required_version = "~> 1.3"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Updated to reflect the current major version for access to the latest features.
      # Allows versions >= 4.0.0 and < 5.0.0
      version = "~> 4.0"
    }
  }
}
