/*_____________________________________________________________________________________________________________________

API Location:
 - Class: "fvAp"
 - Distinguished Name: "uni/tn-[tenant]/ap-{application_profile}"
GUI Location:
 - Tenants > {tenant} > Application Profiles > {application_profile}
_______________________________________________________________________________________________________________________
*/
resource "aci_application_profile" "application_profiles" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each                  = { for k, v in local.application_profiles : k => v if v.controller_type == "apic" }
  tenant_dn                 = aci_tenant.tenants[each.value.tenant].id
  annotation                = each.value.annotation != "" ? each.value.annotation : var.annotation
  description               = each.value.description
  name                      = each.key
  name_alias                = each.value.alias
  prio                      = each.value.qos_class
  relation_fv_rs_ap_mon_pol = each.value.monitoring_policy != "" ? "uni/tn-common/monepg-${each.value.monitoring_policy}" : ""
}

resource "mso_schema_template_anp" "application_profiles" {
  provider = ndo
  depends_on = [
    mso_schema.schemas,
    mso_schema_site.sites
  ]
  for_each     = { for k, v in local.application_profiles : k => v if v.controller_type == "ndo" }
  display_name = each.key
  name         = each.key
  schema_id    = mso_schema.schemas[each.value.schema].id
  template     = each.value.template
}

resource "mso_schema_site_anp" "application_profiles" {
  provider = ndo
  depends_on = [
    mso_schema_template_anp.application_profiles
  ]
  for_each      = { for k, v in local.application_profile_sites : k => v if v.controller_type == "ndo" }
  anp_name      = each.value.application_profile
  schema_id     = mso_schema.schemas[each.value.schema].id
  site_id       = data.mso_site.ndo_sites[each.value.site].id
  template_name = each.value.template
}
