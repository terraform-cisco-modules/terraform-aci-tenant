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
  for_each    = { for k, v in local.application_profiles : k => v if local.controller_type == "apic" }
  tenant_dn   = aci_tenant.tenants[each.value.tenant].id
  annotation  = each.value.annotation
  description = each.value.description
  name        = each.key
  name_alias  = each.value.alias
  prio        = each.value.qos_class
  relation_fv_rs_ap_mon_pol = length(compact([each.value.monitoring_policy])
  ) > 0 ? "uni/tn-common/monepg-${each.value.monitoring_policy}" : ""
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAnnotation"
 - Distinguished Name: "uni/tn-{tenant}/ap-{application_profile}/annotationKey-[{key}]"
GUI Location:
 - Tenants > {tenant} > Application Profiles > {application_profile}: {annotations}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "application_profiles_annotations" {
  depends_on = [
    aci_application_profile.application_profiles
  ]
  for_each = {
    for i in flatten([
      for a, b in local.application_profiles : [
        for v in b.annotations : {
          application_profile = a
          key                 = v.key
          tenant              = b.tenant
          value               = v.value
        }
      ]
    ]) : "${i.application_profile}:${i.key}" => i if local.controller_type == "apic"
  }
  dn         = "uni/tn-${each.value.tenant}/ap-${each.value.application_profile}/annotationKey-[${each.value.key}]"
  class_name = "tagAnnotation"
  content = {
    key   = each.value.key
    value = each.value.value
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAliasInst"
 - Distinguished Name: "uni/tn-{tenant}/ap-{application_profile}/alias"
GUI Location:
 - Tenants > {tenant} > Application Profiles > {application_profile}: global_alias

_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "application_profiles_global_alias" {
  depends_on = [
    aci_application_profile.application_profiles
  ]
  for_each   = { for k, v in local.application_profiles : k => v if v.global_alias != "" && local.controller_type == "apic" }
  class_name = "tagAliasInst"
  dn         = "uni/tn-${each.key}/ap-${each.value.application_profile}/alias"
  content = {
    name = each.value.global_alias
  }
}


/*_____________________________________________________________________________________________________________________

Nexus Dashboard — Application Profiles
_______________________________________________________________________________________________________________________
*/
resource "mso_schema_template_anp" "application_profiles" {
  provider = mso
  depends_on = [
    mso_schema.schemas,
    mso_schema_site.template_sites
  ]
  for_each     = { for k, v in local.application_profiles : k => v if local.controller_type == "ndo" }
  display_name = each.key
  name         = each.key
  schema_id    = mso_schema.schemas[each.value.ndo.schema].id
  template     = each.value.ndo.template
}

resource "mso_schema_site_anp" "application_profiles" {
  provider = mso
  depends_on = [
    mso_schema_template_anp.application_profiles
  ]
  for_each      = { for k, v in local.application_sites : k => v if local.controller_type == "ndo" }
  anp_name      = each.value.application_profile
  schema_id     = mso_schema.schemas[each.value.schema].id
  site_id       = data.mso_site.sites[each.value.site].id
  template_name = each.value.template
}
