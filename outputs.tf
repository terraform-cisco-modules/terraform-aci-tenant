output "application_profiles" {
  value = {
    application_profiles = var.controller_type == "apic" ? {
      for v in sort(keys(aci_application_profile.map)
      ) : v => aci_application_profile.map[v].id } : var.controller_type == "ndo" ? {
      for v in sort(keys(mso_schema_template_anp.map)
      ) : v => mso_schema_template_anp.map[v].id
    } : {}
    application_epgs = var.controller_type == "apic" ? merge(
      { for v in sort(keys(aci_application_epg.map)
        ) : v => aci_application_epg.map[v].id }, { for v in sort(keys(aci_node_mgmt_epg.mgmt_epgs)
        ) : v => aci_node_mgmt_epg.mgmt_epgs[v].id
      }) : var.controller_type == "ndo" ? {
      for v in sort(keys(mso_schema_template_anp_epg.map)) : v => mso_schema_template_anp_epg.map[v].id
    } : {}
  }
}

output "contracts" {
  value = {
    contracts = var.controller_type == "apic" ? {
      oob_contracts = { for v in sort(keys(aci_rest_managed.oob_contracts)
      ) : v => aci_rest_managed.oob_contracts[v].id }
      standard_contracts = { for v in sort(keys(aci_contract.map)
      ) : v => aci_contract.map[v].id }
      taboo_contracts = { for v in sort(keys(aci_taboo_contract.map)
      ) : v => aci_taboo_contract.map[v].id }
      } : var.controller_type == "ndo" ? {
      standard_contracts = { for v in sort(keys(mso_schema_template_contract.map)
      ) : v => mso_schema_template_contract.map[v].id }
    } : {}
    filters = var.controller_type == "apic" ? {
      filters = { for v in sort(keys(aci_filter.map)
      ) : v => aci_filter.map[v].id }
      filter_entries = { for v in sort(keys(aci_filter_entry.map)
      ) : v => aci_filter_entry.map[v].id }
      } : var.controller_type == "ndo" ? {
      filter_entries = { for v in sort(keys(mso_schema_template_filter_entry.map)
      ) : v => mso_schema_template_filter_entry.map[v].id }
    } : {}
  }
}
output "networking" {
  value = {
    bridge_domains = var.controller_type == "apic" ? { for v in sort(keys(aci_bridge_domain.map)
      ) : v => aci_bridge_domain.map[v].id } : var.controller_type == "ndo" ? {
      for v in sort(keys(mso_schema_template_bd.map)) : v => mso_schema_template_bd.map[v].id
    } : {}
    l3outs = {}
    vrf = var.controller_type == "apic" ? {
      for v in sort(keys(aci_vrf.map)) : v => aci_vrf.map[v].id } : var.controller_type == "ndo" ? {
      for v in sort(keys(mso_schema_template_vrf.map)) : v => mso_schema_template_vrf.map[v].id
    } : {}
  }
}

output "endpoint_retention" {
  value = local.policies_endpoint_retention != {} ? { for v in sort(
    keys(aci_end_point_retention_policy.map)
  ) : v => aci_end_point_retention_policy.map[v].id } : {}
}

output "nexus_dashboard_orchestrator" {
  value = {
    schemas = { for v in sort(keys(data.mso_schema.map)) : v => data.mso_schema.map[v].id }
    sites   = { for v in sort(keys(data.mso_site.map)) : v => data.mso_site.map[v].id }
    users   = { for v in sort(keys(data.mso_user.map)) : v => data.mso_user.map[v].id }
  }
}

output "tenants" {
  value = var.controller_type == "apic" ? { for v in sort(keys(aci_tenant.map)
    ) : v => aci_tenant.map[v].id } : var.controller_type == "ndo" ? {
    for v in sort(keys(mso_tenant.map)) : v => mso_tenant.map[v].id
  } : {}
}

output "zzzz" {
  value = {
    aaep_last = local.aaep_to_epgs
    both      = local.epg_to_aaeps
  }
}
