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
      version = ">=2.13.0"
    }
    mso = {
      source  = "CiscoDevNet/mso"
      version = ">=1.0.0"
    }
  }
  required_version = ">= 1.3.0"
}
