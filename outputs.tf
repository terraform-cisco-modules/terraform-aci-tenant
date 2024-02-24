/*_____________________________________________________________________________________________________________________

Application Profile — Outputs
_______________________________________________________________________________________________________________________
*/
output "application_profiles" {
  description = <<-EOT
    Identifiers for Application Profiles:
     * application_profiles:
       - ACI: Tenants => {Tenant Name} => Application Profiles: {Name}
       - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name}
       - application_epgs:
         * ACI: Tenants => {Tenant Name} => Application Profiles: {Name} => Application EPGs: {Name}
         * NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name} => EPGs: {Name}
         * epg_to_contracts:
           - ACI: Tenants => {Tenant Name} => Application Profiles: {Name} => Application EPGs: {Name} => Contracts
           - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name} => EPGs: {Name}: Contracts
         * epg_to_domains:
           - ACI: Tenants => {Tenant Name} => Application Profiles: {Name} => Application EPGs: {Name} => Domains
           - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name} => EPGs: {Name}: {Select Site}: Domains
         * epg_to_static_paths:
           - ACI: Tenants => {Tenant Name} => Application Profiles: {Name} => Application EPGs: {Name} => Static Ports
           - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name} => EPGs: {Name}: {Select Site}: Static Ports
  EOT
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
      } : local.controller.type == "ndo" ? {
      for v in sort(keys(mso_schema_site_anp_epg_bulk_staticport.map)) : v => [
        for e in mso_schema_site_anp_epg_bulk_staticport.map[v].static_ports : "${e.pod}/${e.leaf}/${e.path}"
      ]
    } : {}
  }
}

/*_____________________________________________________________________________________________________________________

Contracts — Outputs
_______________________________________________________________________________________________________________________
*/
output "contracts" {
  description = <<-EOT
    Identifiers for Contracts:
     * contracts:
       - oob_contracts: Tenants => {Tenant Name} => Contracts => Out-of-Band Contracts: {Name}
       - standard_contracts:
         * ACI: Tenants => {Tenant Name} => Contracts => Standard: {Name}
         * NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Contracts: {Name}
       - taboo_contracts: Tenants => {Tenant Name} => Contracts => Taboos: {Name}
     * filters:
       - filters: Tenants => {Tenant Name} => Contracts => Filters: {Name}
       - filter_entries:
         * ACI: Tenants => {Tenant Name} => Contracts => Filters: {Name} => Entries
         * NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Filter: {Name}
  EOT
  value = {
    contracts = local.controller.type == "apic" ? {
      oob_contracts      = { for v in sort(keys(aci_rest_managed.oob_contracts)) : v => aci_rest_managed.oob_contracts[v].id }
      standard_contracts = { for v in sort(keys(aci_contract.map)) : v => aci_contract.map[v].id }
      taboo_contracts    = { for v in sort(keys(aci_taboo_contract.map)) : v => aci_taboo_contract.map[v].id }
      } : local.controller.type == "ndo" ? {
      standard_contracts = { for v in sort(keys(mso_schema_template_contract.map)) : v => mso_schema_template_contract.map[v].id }
    } : {}
    filters = local.controller.type == "apic" ? {
      filters        = { for v in sort(keys(aci_filter.map)) : v => aci_filter.map[v].id }
      filter_entries = { for v in sort(keys(aci_filter_entry.map)) : v => aci_filter_entry.map[v].id }
      } : local.controller.type == "ndo" ? {
      filter_entries = { for v in sort(keys(mso_schema_template_filter_entry.map)) : v => mso_schema_template_filter_entry.map[v].id }
    } : {}
  }
}

/*_____________________________________________________________________________________________________________________

Networking — Outputs
_______________________________________________________________________________________________________________________
*/
output "networking" {
  description = <<-EOT
    Identifiers for Tenant Networking:
     * bridge_domains:
       - ACI: Tenants => {Tenant Name} => Networking => Bridge Domains: {Name}
       - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => Bridge Domains: {Name}
       - bridge_domain_subnets: Tenants => {Tenant Name} => Networking => Bridge Domains: {Name} => Subnets
     * l3outs:
       - ACI: Tenants => {Tenant Name} => Networking => L3Outs: {Name}
       - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => Bridge Domains: {Name}
       - l3out_bgp_external_policy: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Policy => Enabled BGP/EIGRP/OSPF: BGP
       - l3out_external_epgs: Tenants => Tenants => {Tenant Name} => Networking => L3Outs: {Name} => External EPGs: {Name}
         * l3out_external_epg_subnets: Tenants => Tenants => {Tenant Name} => Networking => L3Outs: {Name} => External EPGs: {Name} => Subnets
       - l3out_node_profiles: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name}
         * l3out_interface_profiles: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name} => Logical Interface Profiles: {Name}
           - l3out_interface_profile_ospf_interfaces: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name} => Logical Interface Profiles: {Name} => OSPF Interface Profile
           - l3out_interface_profile_path_attachment: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name} => Logical Interface Profiles: {Name}: Routed Sub-Interfaces/Routed Interfaces/SVI/Floating SVI
         * l3out_node_profile_bgp_peers:  Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name}: BGP Peer Connectivity
         * l3out_node_profile_static_routes:  Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name}: (Double click node under Nodes): Static Routes
         * l3out_ospf_external_policy:  Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Policy => Enabled BGP/EIGRP/OSPF: OSPF
     * vrf:
       - ACI: Tenants => {Tenant Name} => Networking => VRFs: {Name}
       - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => VRFs
  EOT
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

/*_____________________________________________________________________________________________________________________

Nexus Dashboard Orchestrator — Outputs
_______________________________________________________________________________________________________________________
*/
output "nd_orchestrator" {
  description = <<-EOT
    Identifiers for Nexus Dashboard Orchestrator:
     * schema: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name}
     * schema_sites: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => Sites
     * sites: Nexus Dashboard => Sites: {Site Name}
     * users:
       - External Users: Nexus Dashboard => Admin Console => Administrative => Authentication
       - Local Users: Nexus Dashboard => Admin Console => Administrative => Users
  EOT
  value = {
    schemas      = { for v in sort(keys(data.mso_schema.map)) : v => data.mso_schema.map[v].id }
    schema_sites = { for v in sort(keys(mso_schema_site.map)) : v => mso_schema_site.map[v].id }
    sites        = { for v in sort(keys(data.mso_site.map)) : v => data.mso_site.map[v].id }
    users        = { for v in sort(keys(data.mso_user.map)) : v => data.mso_user.map[v].id }
  }
}

/*_____________________________________________________________________________________________________________________

Tenant Policies — Outputs
_______________________________________________________________________________________________________________________
*/
output "policies" {
  description = <<-EOT
    Identifiers for Tenant Policies:
     * bfd: Tenants => {Tenant Name} => Policies => Protocol => BFD: {Name}
     * bgp:
       - bgp_address_family_context: Tenants => {Tenant Name} => Policies => Protocol => BGP => BGP Address Family Context: {Name}
       - bgp_best_path: Tenants => {Tenant Name} => Policies => Protocol => BGP => BGP Best Path Policy: {Name}
       - bgp_route_summarization: Tenants => {Tenant Name} => Policies => Protocol => BGP => BGP Route Summarization: {Name}
       - bgp_timers: Tenants => {Tenant Name} => Policies => Protocol => BGP => BGP Timers: {Name}
     * dhcp:
       - dhcp_option: Tenants => {Tenant Name} => Policies => Protocol => DHCP => Option Policies: {Name}
       - dhcp_relay: Tenants => {Tenant Name} => Policies => Protocol => DHCP => Relay Policies: {Name}
     * endpoint_retention: Tenants => {Tenant Name} => Policies => Protocol => End Point Retention: {Name}
     * hsrp:
       - hsrp_group: Tenants => {Tenant Name} => Policies => Protocol => HSRP => Interface Policies: {Name}
       - hsrp_interface: Tenants => {Tenant Name} => Policies => Protocol => HSRP => Group Policies: {Name}
     * ip_sla:
       - ip_sla_monitoring: Tenants => {Tenant Name} => Policies => Protocol => IP SLA => IP SLA Monitoring Policies: {Name}
       - track_lists: Tenants => {Tenant Name} => Policies => Protocol => IP SLA => Track Lists: {Name}
       - track_members: Tenants => {Tenant Name} => Policies => Protocol => IP SLA => Track Members: {Name}
     * l4_l7_pbr: Tenants => {Tenant Name} => Policies => Protocol => L4-L7 Policy-Based Redirect: {Name}
     * l4_l7_redirect_health_groups: Tenants => {Tenant Name} => Policies => Protocol => L4-L7 Policy-Based Redirect Health Groups: {Name}
     * l4_l7_pbr_destinations: Tenants => {Tenant Name} => Policies => Protocol => L4-L7 Policy-Based Redirect Destinations: {Name}
     * ospf:
       - ospf_interface: Tenants => {Tenant Name} => Policies => Protocol => OSPF => OSPF Interface: {Name}
       - ospf_route_summarization: Tenants => {Tenant Name} => Policies => Protocol => OSPF => OSPF Route Summarization: {Name}
       - ospf_timers: Tenants => {Tenant Name} => Policies => Protocol => OSPF => OSPF Timers: {Name}
  EOT
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
      track_lists       = { for v in sort(keys(aci_rest_managed.track_lists)) : v => aci_rest_managed.track_lists[v].id }
      track_members     = { for v in sort(keys(aci_rest_managed.track_members)) : v => aci_rest_managed.track_members[v].id }
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

/*_____________________________________________________________________________________________________________________

Tenant — Outputs
_______________________________________________________________________________________________________________________
*/
output "tenants" {
  description = "Tenant Identifiers."
  value = local.controller.type == "apic" ? { for v in sort(keys(aci_tenant.map)
    ) : v => aci_tenant.map[v].id } : local.controller.type == "ndo" ? {
    for v in sort(keys(mso_tenant.map)) : v => mso_tenant.map[v].id
  } : {}
}
