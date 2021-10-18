# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"

    }
  }

  #required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Create the resource group
resource "azurerm_resource_group" "acme" {
  name     = var.resource_group_name
  location = "uksouth"
  
   tags = {
     Environment = "Staging"
     Team = "DevOps"
   }
}

# Create the public DNS zone 
resource "azurerm_dns_zone" "ACME-public" {
  name = "jeremywinchester.info"
  resource_group_name = azurerm_resource_group.acme.name
}

# Create the key vault 
resource "azurerm_key_vault" "ACME" {
  name                        = "ACMEKeyVaultJez"
  location                    = "uksouth"
  resource_group_name         = azurerm_resource_group.acme.name
  enabled_for_disk_encryption = true
  tenant_id                   = "9149d31e-9921-4b8a-8c3f-7659a036db74"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false # will need to be set to true for production workloads; set to false to simplify cleanup 
  enable_rbac_authorization	 = true
  sku_name = "standard"

  # Needs Access Policy 
}

# Create the storage account 
resource "azurerm_storage_account" "acmecertsjez" {
  name = "acmecertsjez"
  location = "uksouth"
  resource_group_name = azurerm_resource_group.acme.name
  account_tier = "Standard"
  account_kind = "StorageV2"
  account_replication_type = "LRS"
  enable_https_traffic_only = true
  }

# Create the storage account container 
resource "azurerm_storage_container" "poshacme" { 
  name = "poshacme"
  storage_account_name = azurerm_storage_account.acmecertsjez.name
  container_access_type = "private"
}

# Create Az AD Application, Service Principal (SPN), and SPN password
resource "azuread_application" "ACME_Certificate_Automation" {
  display_name = "ACME Certificate Automation"
  identifier_uris = [ "http://jeremywinchester.info/acme" ]
}

resource "azuread_service_principal" "ACME_Certificate_Automation" {
  application_id = azuread_application.ACME_Certificate_Automation.application_id
  #app_role_assignment_required = false
  tags = ["test"]
} 

resource "azuread_service_principal_password" "ACME_Certificate_Automation" {
  service_principal_id = azuread_service_principal.ACME_Certificate_Automation.object_id
  end_date_relative = "8760h"
}

# Create the required role definitions
# (may be able to simplify with for each)
# Grant SPN DNS Zone Contributor on the DNS Zone 
resource "azurerm_role_assignment" "SPN_granted_DNS_Zone_Contributor" {
  scope = azurerm_dns_zone.ACME-public.id
  role_definition_name = "DNS Zone Contributor"
  principal_id = azuread_service_principal.ACME_Certificate_Automation.object_id
}

# Grant SPN reader access to Key Vaults 
resource "azurerm_role_assignment" "SPN_granted_Reader" {
  scope = azurerm_key_vault.ACME.id
  role_definition_name = "Reader"
  principal_id = azuread_service_principal.ACME_Certificate_Automation.object_id
}

resource "azurerm_role_assignment" "SPN_granted_GetPermissionsToCertificates" {
  scope = azurerm_key_vault.ACME.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id = azuread_service_principal.ACME_Certificate_Automation.object_id
}
# Generate SAS token 
data "azurerm_storage_account_blob_container_sas" "acmecertsjez_SASToken" {
  connection_string = azurerm_storage_account.acmecertsjez.primary_connection_string
  container_name    = azurerm_storage_container.poshacme.name
  https_only        = true

  start  = "2021-08-16T00:00:00Z"
  expiry = "2023-08-16T00:00:00Z"

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = false
    create  = false
  }
}

resource "azuread_application" "example" {
  name = "example"
}

resource "azuread_service_principal" "example" {
  application_id = azuread_application.example.application_id
}

resource "azuread_service_principal_password" "example" {
  service_principal_id = azuread_service_principal.example.object_id
}