#_______________________________________________________________________
#
# Terraform Required Parameters - Intersight Provider
# https://registry.terraform.io/providers/CiscoDevNet/intersight/latest
#_______________________________________________________________________

terraform {
  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = ">= 2.5.2"
    }
    ndo = {
      source  = "CiscoDevNet/mso"
      version = ">=0.7.0"
    }
  }
  required_version = ">= 1.3.0"
}
