terraform {
  required_providers {
    azurerm = {
      version = ">=2.0"
      source  = "hashicorp/azurerm"

    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name = "devops-pipeline-rg"
    storage_account_name = "devterraformbackendsadey"
    container_name       = "terraform-backend-files"
    key                  = "terraform.tfstate"
  }

}

