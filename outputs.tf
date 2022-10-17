output "application_profiles" {
  value = length(local.application_profiles) > 0 && local.controller_type == "apic" ? {
    for v in sort(keys(aci_application_profile.application_profiles)
    ) : v => aci_application_profile.application_profiles[v].id } : length(local.application_profiles
    ) > 0 && local.controller_type == "ndo" ? {
    for v in sort(keys(mso_schema_template_anp.application_profiles)
    ) : v => mso_schema_template_anp.application_profiles[v].id
  } : {}
}

output "bridge_domains" {
  value = length(local.bridge_domains) > 0 && local.controller_type == "apic" ? {
    for v in sort(keys(aci_bridge_domain.bridge_domains)
    ) : v => aci_bridge_domain.bridge_domains[v].id } : length(local.bridge_domains
    ) > 0 && local.controller_type == "ndo" ? {
    for v in sort(keys(mso_schema_template_bd.bridge_domains)
    ) : v => mso_schema_template_bd.bridge_domains[v].id
  } : {}
}

output "ndo_sites" {
  value = local.sites != [] ? { for v in sort(
    keys(data.mso_site.sites)
  ) : v => data.mso_site.sites[v].id } : {}
}

output "ndo_users" {
  value = local.users != [] ? { for v in sort(
    keys(data.mso_user.users)
  ) : v => data.mso_user.users[v].id } : {}
}

output "ndo_schemas" {
  value = local.schemas != {} ? { for v in sort(
    keys(data.mso_schema.schemas)
  ) : v => data.mso_schema.schemas[v].id } : {}
}

# output "ndo_templates" {
#   value = {
#     schemas = local.schemas != {} ? { for v in sort(
#       keys(data.mso_schema.schemas)
#     ) : v => data.mso_schema.schemas[v].id } : {}
#   }
# }

output "tenants" {
  value = local.controller_type == "apic" && length(local.tenants) > 0 ? {
    for v in sort(keys(aci_tenant.tenants)
    ) : v => aci_tenant.tenants[v].id } : local.controller_type == "ndo" && length(local.tenants) > 0 ? {
    for v in sort(keys(mso_tenant.tenants)
    ) : v => mso_tenant.tenants[v].id
  } : {}
}

output "vrfs" {
  value = local.controller_type == "apic" && length(local.vrfs) > 0 ? {
    for v in sort(keys(aci_vrf.vrfs)
    ) : v => aci_vrf.vrfs[v].id } : local.controller_type == "ndo" && length(local.vrfs) > 0 ? {
    for v in sort(keys(mso_schema_template_vrf.vrfs)
    ) : v => mso_schema_template_vrf.vrfs[v].id
  } : {}
}

