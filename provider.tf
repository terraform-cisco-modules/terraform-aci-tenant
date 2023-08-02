#_______________________________________________________________________
#
# Terraform Required Parameters:
#  - ACI Provider
#    https://registry.terraform.io/providers/CiscoDevNet/aci/latest
#  - MSO Provider
#    https://registry.terraform.io/providers/CiscoDevNet/mso/latest
#_______________________________________________________________________

terraform {
  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = ">=2.9.0"
    }
    mso = {
      source  = "CiscoDevNet/mso"
      version = ">=0.11.1"
    }
  }
  required_version = ">= 1.3.0"
}
