/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvTenant"
 - Distinguished Name: "uni/tn-{tenant}""
GUI Location:
 - Tenants > Create Tenant > {tenant}
_______________________________________________________________________________________________________________________
*/
resource "aci_tenant" "tenants" {
  for_each                      = { for k, v in local.tenants : k => v if v.controller_type == "apic" }
  annotation                    = each.value.annotation != "" ? each.value.annotation : var.annotation
  description                   = each.value.description
  name                          = each.key
  name_alias                    = each.value.alias
  relation_fv_rs_tenant_mon_pol = each.value.monitoring_policy != "" ? "uni/tn-common/monepg-${each.value.monitoring_policy}" : ""
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAnnotation"
 - Distinguished Name: "uni/tn-{tenant}/annotationKey-[{key}]"
GUI Location:
 - Tenants > {tenant}: {annotations}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "tenants_annotations" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each   = local.tenants_annotations
  dn         = "uni/tn-${each.value.tenant}/annotationKey-[${each.value.key}]"
  class_name = "tagAnnotation"
  content = {
    key   = each.value.key
    value = each.value.value
  }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAliasInst"
 - Distinguished Name: "uni/tn-{tenant}/alias"
GUI Location:
 - Tenants > {tenant} > Networking > VRFs > {vrf}: global_alias

_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "tenants_global_alias" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each   = local.tenants_global_alias
  class_name = "tagAliasInst"
  dn         = "uni/tn-${each.value.tenant}/alias"
  content = {
    name = each.value.global_alias
  }
}


/*_____________________________________________________________________________________________________________________

Nexus Dashboard — Tenants
_______________________________________________________________________________________________________________________
*/
data "mso_site" "ndo_sites" {
  provider = mso
  for_each = toset(local.ndo_sites)
  name     = each.key
}

data "mso_user" "ndo_users" {
  provider = mso
  for_each = toset(local.ndo_users)
  username = each.key
}

resource "mso_tenant" "tenants" {
  provider = mso
  depends_on = [
    data.mso_site.ndo_sites,
    data.mso_user.ndo_users
  ]
  for_each     = { for k, v in local.tenants : k => v if v.controller_type == "ndo" }
  description  = each.value.description
  name         = each.key
  display_name = each.key
  dynamic "site_associations" {
    for_each = { for k, v in each.value.sites : k => v if v.vendor == "aws" }
    content {
      aws_access_key_id = length(regexall(
        "aws", site_associations.value.vendor)
      ) > 0 ? site_associations.value.aws_access_key_id : ""
      aws_account_id = length(regexall(
        "aws", site_associations.value.vendor)
      ) > 0 ? site_associations.value.aws_account_id : ""
      aws_secret_key = length(regexall(
        "aws", site_associations.value.vendor)
      ) > 0 ? var.aws_secret_key : ""
      site_id = data.mso_site.sites[site_associations.value.site].id
      vendor  = site_associations.value.vendor
    }
  }
  dynamic "site_associations" {
    for_each = { for k, v in each.value.sites : k => v if v.vendor == "azure" }
    content {
      azure_access_type = length(regexall(
        "azure", site_associations.value.vendor)
      ) > 0 ? site_associations.value.azure_access_type : ""
      azure_active_directory_id = length(regexall(
        "azure", site_associations.value.vendor)
      ) > 0 && site_associations.value.azure_access_type == "credentials" ? site_associations.value.azure_active_directory_id : ""
      azure_application_id = length(regexall(
        "azure", site_associations.value.vendor)
      ) > 0 && site_associations.value.azure_access_type == "credentials" ? site_associations.value.azure_application_id : ""
      azure_client_secret = length(regexall(
        "azure", site_associations.value.vendor)
      ) > 0 && site_associations.value.azure_access_type == "credentials" ? var.azure_client_secret : ""
      azure_shared_account_id = length(regexall(
        "azure", site_associations.value.vendor)
      ) > 0 && site_associations.value.azure_access_type == "shared" ? site_associations.value.azure_shared_account_id : ""
      azure_subscription_id = length(regexall(
        "azure", site_associations.value.vendor)
      ) > 0 ? site_associations.value.azure_subscription_id : ""
      site_id = data.mso_site.sites[site_associations.value.site].id
      vendor  = site_associations.value.vendor
    }
  }
  dynamic "site_associations" {
    for_each = {
      for k, v in each.value.sites : k => v if v.vendor == "cisco" && length(
        regexall("^(common|infra)$", each.key)
      ) == 0
    }
    content {
      site_id = data.mso_site.ndo_sites[site_associations.value.site].id
    }
  }
  dynamic "user_associations" {
    for_each = toset(each.value.users)
    content {
      user_id = data.mso_user.ndo_users[user_associations.value].id
    }
  }
}
