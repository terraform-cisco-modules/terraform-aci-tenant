/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvBD"
 - Distinguised Name: "/uni/tn-{Tenant}/BD-{bridge_domain}"
GUI Location:
 - Tenants > {tenant} > Networking > Bridge Domains > {bridge_domain}
_______________________________________________________________________________________________________________________
*/
resource "aci_bridge_domain" "bridge_domains" {
  depends_on = [
    aci_tenant.tenants,
    aci_vrf.vrfs,
    # aci_l3_outside.l3outs
  ]
  for_each = { for k, v in local.bridge_domains : k => v if v.controller_type == "apic" }
  # General
  annotation                = each.value.general[0].annotation != "" ? each.value.general[0].annotation : var.annotation
  arp_flood                 = each.value.general[0].arp_flooding == true ? "yes" : "no"
  bridge_domain_type        = each.value.general[0].type
  description               = each.value.general[0].description
  host_based_routing        = each.value.general[0].advertise_host_routes == true ? "yes" : "no"
  ipv6_mcast_allow          = each.value.general[0].pimv6 == true ? "yes" : "no"
  limit_ip_learn_to_subnets = each.value.general[0].limit_ip_learn_to_subnets == true ? "yes" : "no"
  mcast_allow               = each.value.general[0].pim == true ? "yes" : "no"
  name                      = each.key
  name_alias                = each.value.general[0].alias
  multi_dst_pkt_act         = each.value.general[0].multi_destination_flooding
  relation_fv_rs_bd_to_ep_ret = each.value.general[0
  ].endpoint_retention_policy != "" ? "uni/tn-${each.value.policy_source_tenant}/epRPol-${each.value.general[0].endpoint_retention_policy}" : ""
  relation_fv_rs_ctx = each.value.general[0
  ].vrf != "" ? "uni/tn-${each.value.general[0].vrf_tenant}/ctx-${each.value.general[0].vrf}" : ""
  relation_fv_rs_igmpsn = each.value.general[0
  ].igmp_snooping_policy != "" ? "uni/tn-${each.value.policy_source_tenant}/snPol-${each.value.general[0].igmp_snooping_policy}" : ""
  relation_fv_rs_mldsn = each.value.general[0
  ].mld_snoop_policy != "" ? "uni/tn-${each.value.policy_source_tenant}/mldsnoopPol-${each.value.general[0].mld_snoop_policy}" : ""
  tenant_dn         = aci_tenant.tenants[each.value.general[0].tenant].id
  unk_mac_ucast_act = each.value.general[0].l2_unknown_unicast
  unk_mcast_act     = each.value.general[0].l3_unknown_multicast_flooding
  v6unk_mcast_act   = each.value.general[0].ipv6_l3_unknown_multicast
  # L3 Configurations
  ep_move_detect_mode = each.value.l3_configurations[0].ep_move_detection_mode == true ? "garp" : "disable"
  ll_addr             = each.value.l3_configurations[0].link_local_ipv6_address
  mac                 = each.value.l3_configurations[0].custom_mac_address
  # class: l3extOut
  relation_fv_rs_bd_to_out = length(each.value.l3_configurations[0].associated_l3outs
  ) > 0 ? [for k, v in each.value.l3_configurations[0].associated_l3outs : "uni/tn-${v.tenant}/out-${v.l3out[0]}"] : []
  # class: rtctrlProfile
  relation_fv_rs_bd_to_profile = join(",", [
    for k, v in each.value.l3_configurations[0
    ].associated_l3outs : "uni/tn-${v.tenant}/out-${v.l3out[0]}/prof-${v.route_profile}" if v.route_profile != ""
  ])
  # class: monEPGPol
  # relation_fv_rs_bd_to_nd_p = length(
  # [each.value.nd_policy]) > 0 ? "uni/tn-${each.value.policy_source_tenant}/ndifpol-${each.value.nd_policy}" : ""
  unicast_route = each.value.l3_configurations[0].unicast_routing == true ? "yes" : "no"
  vmac          = each.value.l3_configurations[0].virtual_mac_address != "" ? each.value.l3_configurations[0].virtual_mac_address : "not-applicable"
  # Advanced/Troubleshooting
  ep_clear    = each.value.advanced_troubleshooting[0].endpoint_clear == true ? "yes" : "no"
  ip_learning = each.value.advanced_troubleshooting[0].disable_ip_data_plane_learning_for_pbr == true ? "no" : "yes"
  intersite_bum_traffic_allow = length(regexall(
    true, each.value.advanced_troubleshooting[0].intersite_l2_stretch)
  ) > 0 && length(regexall(true, each.value.advanced_troubleshooting[0].intersite_bum_traffic_allow)) > 0 ? "yes" : "no"
  intersite_l2_stretch   = each.value.advanced_troubleshooting[0].intersite_l2_stretch == true ? "yes" : "no"
  optimize_wan_bandwidth = length(regexall(true, each.value.advanced_troubleshooting[0].optimize_wan_bandwidth)) > 0 ? "yes" : "no"
  # class: monEPGPol
  relation_fv_rs_abd_pol_mon_pol = each.value.advanced_troubleshooting[0
  ].monitoring_policy != "" ? "uni/tn-${each.value.policy_source_tenant}/monepg-${each.value.advanced_troubleshooting[0].monitoring_policy}" : ""
  # class: netflowMonitorPol
  dynamic "relation_fv_rs_bd_to_netflow_monitor_pol" {
    for_each = each.value.advanced_troubleshooting[0].netflow_monitor_policies
    content {
      flt_type                    = relation_l3ext_rs_l_if_p_to_netflow_monitor_pol.value.filter_type # ipv4|ipv6|ce
      tn_netflow_monitor_pol_name = "uni/tn-${each.value.policy_source_tenant}/monitorpol-${relation_l3ext_rs_l_if_p_to_netflow_monitor_pol.value.netflow_policy}"
    }
  }
  # class: fhsBDPol
  relation_fv_rs_bd_to_fhs = each.value.advanced_troubleshooting[0
    ].first_hop_security_policy != "" ? "uni/tn-${each.value.policy_source_tenant}/bdpol-${each.value.advanced_troubleshooting[0
  ].first_hop_security_policy}" : ""
  # class: dhcpRelayP
  # dynamic "relation_fv_rs_bd_to_relay_p" {
  #   for_each = each.value.dhcp_relay_labels
  #   content {
  #     owner = relation_fv_rs_bd_to_relay_p.value.owner
  #     name = relation_fv_rs_bd_to_relay_p.value.name
  #   }
  # }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "dhcpLbl"
 - Distinguished Name: "/uni/tn-{tenant}/BD-{bridge_domain}/dhcplbl-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Bridge Domains > {bridge_domain} > DHCP Relay > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bd_dhcp_label" "bridge_domain_dhcp_relay_labels" {
  depends_on = [
    aci_bridge_domain.bridge_domains,
  ]
  for_each         = { for k, v in local.bridge_domain_dhcp_relay_labels : k => v if v.controller_type == "apic" }
  annotation       = each.value.annotation != "" ? each.value.annotation : var.annotation
  bridge_domain_dn = "uni/tn-${each.value.tenant}/BD-${each.value.bridge_domain}"
  name             = each.value.name
  owner            = each.value.scope
  relation_dhcp_rs_dhcp_option_pol = length(compact([each.value.dhcp_option_policy])
  ) > 0 ? "uni/tn-${each.value.tenant}/dhcpoptpol-${each.value.dhcp_option_policy}" : ""
  # description      = each.value.description
  # tag              = each.value.tag
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvSubnet"
 - Distinguished Name: "/uni/tn-{tenant}/BD-{bridge_domain}/subnet-[{subnet}]"
GUI Location:
 - Tenants > {tenant} > Networking > Bridge Domains > {bridge_domain} > Subnets
_______________________________________________________________________________________________________________________
*/
resource "aci_subnet" "bridge_domain_subnets" {
  depends_on = [
    aci_bridge_domain.bridge_domains,
    # aci_l3_outside.l3outs
  ]
  for_each  = { for k, v in local.bridge_domain_subnets : k => v if v.controller_type == "apic" }
  parent_dn = aci_bridge_domain.bridge_domains[each.value.bridge_domain].id
  ctrl = anytrue([each.value.subnet_control[0]["neighbor_discovery"
    ], each.value.subnet_control[0]["no_default_svi_gateway"], each.value.subnet_control[0]["querier_ip"]
    ]) ? compact(concat([
      length(regexall(true, each.value.subnet_control[0]["neighbor_discovery"])) > 0 ? "nd" : ""], [
      length(regexall(true, each.value.subnet_control[0]["no_default_svi_gateway"])) > 0 ? "no-default-gateway" : ""], [
    length(regexall(true, each.value.subnet_control[0]["querier_ip"])) > 0 ? "querier" : ""]
  )) : ["unspecified"]
  description = each.value.description
  ip          = each.value.gateway_ip
  preferred   = each.value.make_this_ip_address_primary == true ? "yes" : "no"
  # class: rtctrlProfile
  # relation_fv_rs_bd_subnet_to_out = length(compact(
  #   [each.value.l3out])
  # ) > 0 ? "uni/tn-${each.value.tenant}/out-${each.value.l3out}" : ""
  # relation_fv_rs_bd_subnet_to_profile = length(compact(
  #   [each.value.route_profile])
  # ) > 0 ? each.value.route_profile : ""
  scope = anytrue([each.value.scope[0]["advertise_externally"
    ], each.value.scope[0]["shared_between_vrfs"]]) ? compact(concat([
    length(regexall(true, each.value.scope[0]["advertise_externally"])) > 0 ? "public" : ""], [
    length(regexall(true, each.value.scope[0]["shared_between_vrfs"])) > 0 ? "shared" : ""]
  )) : ["private"]
  virtual = each.value.treat_as_virtual_ip_address == true ? "yes" : "no"
}


resource "mso_schema_template_bd" "bridge_domains" {
  provider = ndo
  depends_on = [
    mso_schema.schemas,
    mso_schema_site.sites
  ]
  for_each     = { for k, v in local.bridge_domains : k => v if v.controller_type == "ndo" }
  arp_flooding = each.value.general[0].arp_flooding
  # dynamic "dhcp_policy" {
  #   for_each = each.value.dhcp_relay_policy
  #   content {
  #     name                       = dhcp_policy.value.name
  #     version                    = dhcp_policy.value.version
  #     dhcp_option_policy_name    = dhcp_policy.value.dhcp_option_policy_name
  #     dhcp_option_policy_version = dhcp_policy.value.dhcp_option_policy_version
  #   }
  # }
  display_name                    = each.key
  name                            = each.key
  intersite_bum_traffic           = each.value.advanced_troubleshooting[0].intersite_bum_traffic_allow
  ipv6_unknown_multicast_flooding = each.value.general[0].ipv6_l3_unknown_multicast
  multi_destination_flooding = length(regexall(
    each.value.general[0].multi_destination_flooding, "bd-flood")
    ) > 0 ? "flood_in_bd" : length(regexall(
    each.value.general[0].multi_destination_flooding, "encap-flood")
  ) > 0 ? "flood_in_encap" : "drop"
  layer2_unknown_unicast     = each.value.general[0].l2_unknown_unicast
  layer2_stretch             = each.value.advanced_troubleshooting[0].intersite_l2_stretch
  layer3_multicast           = each.value.general[0].pim
  optimize_wan_bandwidth     = each.value.advanced_troubleshooting[0].optimize_wan_bandwidth
  schema_id                  = mso_schema.schemas[each.value.schema].id
  template_name              = each.value.template
  unknown_multicast_flooding = each.value.general[0].l3_unknown_multicast_flooding
  unicast_routing            = each.value.l3_configurations[0].unicast_routing
  virtual_mac_address        = each.value.l3_configurations[0].virtual_mac_address
  vrf_name                   = each.value.general[0].vrf
  vrf_schema_id = each.value.general[0].vrf != "" && length(compact(
    [each.value.general[0].vrf_schema])
    ) > 0 ? data.mso_schema.schemas[each.value.general[0].vrf_schema].id : length(compact(
    [each.value.general[0].vrf])
  ) > 0 ? data.mso_schema.schemas[each.value.schema].id : ""
  vrf_template_name = each.value.general[0].vrf != "" && length(compact(
    [each.value.general[0].vrf_template])
    ) > 0 ? each.value.general[0].vrf_template : length(compact(
    [each.value.general[0].vrf])
  ) > 0 ? each.value.template : ""
}

resource "mso_schema_site_bd" "bridge_domains" {
  provider = ndo
  depends_on = [
    mso_schema_template_bd.bridge_domains
  ]
  for_each      = { for k, v in local.bridge_domain_sites : k => v if v.controller_type == "ndo" }
  bd_name       = each.value.bridge_domain
  host_route    = each.value.advertise_host_routes
  schema_id     = mso_schema.schemas[each.value.schema].id
  site_id       = data.mso_site.ndo_sites[each.value.site].id
  template_name = each.value.template
}

resource "mso_schema_site_bd_l3out" "bridge_domain_l3outs" {
  provider = ndo
  depends_on = [
    mso_schema_site_bd.bridge_domains
  ]
  for_each      = { for k, v in local.bridge_domain_sites : k => v if v.controller_type == "ndo" }
  bd_name       = each.key
  l3out_name    = each.value.l3out
  schema_id     = mso_schema.schemas[each.value.schema].id
  site_id       = data.mso_site.ndo_sites[each.value.site].id
  template_name = each.value.template
}

resource "mso_schema_template_bd_subnet" "bridge_domain_subnets" {
  provider = ndo
  depends_on = [
    mso_schema_template_bd.bridge_domains
  ]
  for_each           = { for k, v in local.bridge_domain_subnets : k => v if v.controller_type == "ndo" }
  bd_name            = each.value.bridge_domain
  description        = each.value.description
  ip                 = each.value.gateway_ip
  no_default_gateway = each.value.subnet_control[0]["no_default_svi_gateway"]
  schema_id          = mso_schema.schemas[each.value.schema].id
  scope              = each.value.scope[0]["advertise_externally"] == true ? "public" : "private"
  template_name      = each.value.template
  shared             = each.value.scope[0]["shared_between_vrfs"]
  querier            = each.value.subnet_control[0]["querier_ip"]
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvRogueExceptionMac"
 - Distinguished Name: "uni/tn-{tenant}/BD-{bridge_domain}/rgexpmac-{mac_address}"
GUI Location:
 - Tenants > {tenant} > Networking > Bridge Domains > {bridge_domain} > Policy > Advanced/Troubleshooting > Rogue/Coop Exception List.
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "rogue_coop_exception_list" {
  depends_on = [
    aci_bridge_domain.bridge_domains
  ]
  for_each   = local.rogue_coop_exception_list
  dn         = "uni/tn-${each.value.tenant}/BD-${each.value.bridge_domain}/rgexpmac-${each.value.mac_address}"
  class_name = "fvRogueExceptionMac"
  content = {
    mac = each.value.mac_address
  }
}
