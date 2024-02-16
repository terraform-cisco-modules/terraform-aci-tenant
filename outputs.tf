output "application_profiles" {
  value = {
    application_profiles = local.controller.type == "apic" ? {
      for v in sort(keys(aci_application_profile.map)) : v => aci_application_profile.map[v].id
      } : local.controller.type == "ndo" ? {
      for v in sort(keys(mso_schema_template_anp.map)) : v => mso_schema_template_anp.map[v].id
    } : {}
    application_epgs = local.controller.type == "apic" ? merge(
      { for v in sort(keys(aci_application_epg.map)
        ) : v => aci_application_epg.map[v].id }, { for v in sort(keys(aci_node_mgmt_epg.mgmt_epgs)
        ) : v => aci_node_mgmt_epg.mgmt_epgs[v].id
      }) : local.controller.type == "ndo" ? {
      for v in sort(keys(mso_schema_template_anp_epg.map)) : v => mso_schema_template_anp_epg.map[v].id
    } : {}
    epg_to_aaep = { for v in sort(keys(aci_epgs_using_function.epg_to_aaeps)) : v => aci_epgs_using_function.epg_to_aaeps[v].id }
    epg_to_contracts = local.controller.type == "apic" ? merge({
      for v in sort(keys(aci_rest_managed.contract_to_epgs)) : v => aci_rest_managed.contract_to_epgs[v].id },
      { for v in sort(keys(aci_rest_managed.contract_to_oob_epgs)) : v => aci_rest_managed.contract_to_oob_epgs[v].id },
      { for v in sort(keys(aci_rest_managed.contract_to_inb_epgs)) : v => aci_rest_managed.contract_to_inb_epgs[v].id }
      ) : local.controller.type == "ndo" ? {
      for v in sort(keys(mso_schema_template_anp_epg_contract.map)) : v => mso_schema_template_anp_epg_contract.map[v].id
    } : {}
    epg_to_domains = local.controller.type == "apic" ? {
      for v in sort(keys(aci_epg_to_domain.map)) : v => aci_epg_to_domain.map[v].id
      } : local.controller.type == "ndo" ? {
      for v in sort(keys(mso_schema_site_anp_epg_domain.map)) : v => mso_schema_site_anp_epg_domain.map[v].id
    } : {}
    epg_to_static_paths = local.controller.type == "apic" ? {
      for v in sort(keys(aci_bulk_epg_to_static_path.map)) : v => [
        for e in aci_bulk_epg_to_static_path.map[v].static_path : e.interface_dn
      ]
    } : local.controller.type == "ndo" ? {} : {}
  }
}

output "contracts" {
  value = {
    contracts = local.controller.type == "apic" ? {
      oob_contracts = { for v in sort(keys(aci_rest_managed.oob_contracts)
      ) : v => aci_rest_managed.oob_contracts[v].id }
      standard_contracts = { for v in sort(keys(aci_contract.map)
      ) : v => aci_contract.map[v].id }
      taboo_contracts = { for v in sort(keys(aci_taboo_contract.map)
      ) : v => aci_taboo_contract.map[v].id }
      } : local.controller.type == "ndo" ? {
      standard_contracts = { for v in sort(keys(mso_schema_template_contract.map)
      ) : v => mso_schema_template_contract.map[v].id }
    } : {}
    filters = local.controller.type == "apic" ? {
      filters = { for v in sort(keys(aci_filter.map)
      ) : v => aci_filter.map[v].id }
      filter_entries = { for v in sort(keys(aci_filter_entry.map)
      ) : v => aci_filter_entry.map[v].id }
      } : local.controller.type == "ndo" ? {
      filter_entries = { for v in sort(keys(mso_schema_template_filter_entry.map)
      ) : v => mso_schema_template_filter_entry.map[v].id }
    } : {}
  }
}
output "networking" {
  value = {
    bridge_domains = local.controller.type == "apic" ? { for v in sort(keys(aci_bridge_domain.map)
      ) : v => aci_bridge_domain.map[v].id } : local.controller.type == "ndo" ? {
      for v in sort(keys(mso_schema_template_bd.map)) : v => mso_schema_template_bd.map[v].id
    } : {}
    bridge_domain_subnets = local.controller.type == "apic" ? { for v in sort(keys(aci_subnet.bridge_domain_subnets)
      ) : v => aci_subnet.bridge_domain_subnets[v].id } : local.controller.type == "ndo" ? {
      for v in sort(keys(mso_schema_template_bd_subnet.map)) : v => mso_schema_template_bd_subnet.map[v].id
    } : {}
    l3outs = {
      l3out = local.controller.type == "apic" ? {
        for v in sort(keys(aci_l3_outside.map)) : v => aci_l3_outside.map[v].id
      } : {}
      l3out_bgp_external_policy = local.controller.type == "apic" ? {
        for v in sort(keys(aci_l3out_bgp_external_policy.map)) : v => aci_l3out_bgp_external_policy.map[v].id
      } : {}
      l3out_external_epgs = local.controller.type == "apic" ? { for v in sort(keys(aci_external_network_instance_profile.map)
      ) : v => aci_external_network_instance_profile.map[v].id } : {}
      l3out_external_epg_subnets = local.controller.type == "apic" ? { for v in sort(keys(aci_l3_ext_subnet.map)
      ) : v => aci_l3_ext_subnet.map[v].id } : {}
      l3out_interface_profiles = local.controller.type == "apic" ? {
        for v in sort(keys(aci_logical_interface_profile.map)) : v => aci_logical_interface_profile.map[v].id
      } : {}
      l3out_interface_profile_ospf_interfaces = local.controller.type == "apic" ? {
        for v in sort(keys(aci_l3out_ospf_interface_profile.map)) : v => aci_l3out_ospf_interface_profile.map[v].id
      } : {}
      l3out_interface_profile_path_attachment = local.controller.type == "apic" ? {
        for v in sort(keys(aci_l3out_path_attachment.map)) : v => aci_l3out_path_attachment.map[v].id
      } : {}
      l3out_node_profiles = local.controller.type == "apic" ? {
        for v in sort(keys(aci_logical_node_profile.map)) : v => aci_logical_node_profile.map[v].id
      } : {}
      l3out_node_profile_bgp_peers = local.controller.type == "apic" ? {
        for v in sort(keys(aci_bgp_peer_connectivity_profile.map)) : v => aci_bgp_peer_connectivity_profile.map[v].id
      } : {}
      l3out_node_profile_nodes = local.controller.type == "apic" ? {
        for v in sort(keys(aci_logical_node_to_fabric_node.map)) : v => aci_logical_node_to_fabric_node.map[v].id
      } : {}
      l3out_node_profile_static_routes = local.controller.type == "apic" ? {
        for v in sort(keys(aci_l3out_static_route.map)) : v => aci_l3out_static_route.map[v].id
      } : {}
      l3out_ospf_external_policy = local.controller.type == "apic" ? {
        for v in sort(keys(aci_l3out_ospf_external_policy.map)) : v => aci_l3out_ospf_external_policy.map[v].id
      } : {}
    }
    vrf = local.controller.type == "apic" ? {
      for v in sort(keys(aci_vrf.map)) : v => aci_vrf.map[v].id } : local.controller.type == "ndo" ? {
      for v in sort(keys(mso_schema_template_vrf.map)) : v => mso_schema_template_vrf.map[v].id
    } : {}
  }
}

output "nd_orchestrator" {
  value = {
    schemas      = { for v in sort(keys(data.mso_schema.map)) : v => data.mso_schema.map[v].id }
    schema_sites = { for v in sort(keys(mso_schema_site.map)) : v => mso_schema_site.map[v].id }
    sites        = { for v in sort(keys(data.mso_site.map)) : v => data.mso_site.map[v].id }
    users        = { for v in sort(keys(data.mso_user.map)) : v => data.mso_user.map[v].id }
  }
}

output "policies" {
  value = { protocol = {
    bfd = { for v in sort(keys(aci_bfd_interface_policy.map)) : v => aci_bfd_interface_policy.map[v].id }
    bgp = {
      bgp_address_family_context = {
        for v in sort(keys(aci_bgp_address_family_context.map)) : v => aci_bgp_address_family_context.map[v].id
      }
      bgp_best_path           = { for v in sort(keys(aci_bgp_best_path_policy.map)) : v => aci_bgp_best_path_policy.map[v].id }
      bgp_peer_prefix         = { for v in sort(keys(aci_bgp_peer_prefix.map)) : v => aci_bgp_peer_prefix.map[v].id }
      bgp_route_summarization = { for v in sort(keys(aci_bgp_route_summarization.map)) : v => aci_bgp_route_summarization.map[v].id }
      bgp_timers              = { for v in sort(keys(aci_bgp_timers.map)) : v => aci_bgp_timers.map[v].id }
    }
    dhcp = {
      dhcp_option = { for v in sort(keys(aci_dhcp_option_policy.map)) : v => aci_dhcp_option_policy.map[v].id }
      dhcp_relay  = { for v in sort(keys(aci_dhcp_relay_policy.map)) : v => aci_dhcp_relay_policy.map[v].id }
    }
    endpoint_retention = { for v in sort(keys(aci_end_point_retention_policy.map)) : v => aci_end_point_retention_policy.map[v].id }
    hsrp = {
      hsrp_group     = { for v in sort(keys(aci_hsrp_group_policy.map)) : v => aci_hsrp_group_policy.map[v].id }
      hsrp_interface = { for v in sort(keys(aci_hsrp_interface_policy.map)) : v => aci_hsrp_interface_policy.map[v].id }
    }
    ip_sla = {
      ip_sla_monitoring = { for v in sort(keys(aci_ip_sla_monitoring_policy.map)) : v => aci_ip_sla_monitoring_policy.map[v].id }
      hsrp_interface    = { for v in sort(keys(aci_hsrp_interface_policy.map)) : v => aci_hsrp_interface_policy.map[v].id }
    }
    l4_l7_pbr = { for v in sort(keys(aci_service_redirect_policy.map)) : v => aci_service_redirect_policy.map[v].id }
    l4_l7_redirect_health_groups = {
      for v in sort(keys(aci_l4_l7_redirect_health_group.map)) : v => aci_l4_l7_redirect_health_group.map[v].id
    }
    l4_l7_pbr_destinations = {
      for v in sort(keys(aci_destination_of_redirected_traffic.map)) : v => aci_destination_of_redirected_traffic.map[v].id
    }
    ospf = {
      ospf_interface           = { for v in sort(keys(aci_ospf_interface_policy.map)) : v => aci_ospf_interface_policy.map[v].id }
      ospf_route_summarization = { for v in sort(keys(aci_ospf_route_summarization.map)) : v => aci_ospf_route_summarization.map[v].id }
      ospf_timers              = { for v in sort(keys(aci_ospf_timers.map)) : v => aci_ospf_timers.map[v].id }
    }
  } }
}

output "tenants" {
  value = local.controller.type == "apic" ? { for v in sort(keys(aci_tenant.map)
    ) : v => aci_tenant.map[v].id } : local.controller.type == "ndo" ? {
    for v in sort(keys(mso_tenant.map)) : v => mso_tenant.map[v].id
  } : {}
}

output "aaeps" {
  value = var.model.aaep_to_epgs
}

output "zepgs" {
  value = local.application_epgs
}