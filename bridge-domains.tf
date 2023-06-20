/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvBD"
 - Distinguised Name: "uni/tn-{Tenant}/BD-{bridge_domain}"
GUI Location:
 - Tenants > {tenant} > Networking > Bridge Domains > {bridge_domain}
_______________________________________________________________________________________________________________________
*/
resource "aci_bridge_domain" "bridge_domains" {
  depends_on = [
    aci_tenant.tenants,
    aci_vrf.vrfs,
    aci_l3_outside.l3outs
  ]
  for_each = { for k, v in local.bridge_domains : k => v if local.controller_type == "apic" }
  # General
  annotation                = each.value.general.annotation
  arp_flood                 = each.value.general.arp_flooding == true ? "yes" : "no"
  bridge_domain_type        = each.value.general.type
  description               = each.value.general.description
  host_based_routing        = each.value.general.advertise_host_routes == true ? "yes" : "no"
  ipv6_mcast_allow          = each.value.general.pimv6 == true ? "yes" : "no"
  limit_ip_learn_to_subnets = each.value.general.limit_ip_learn_to_subnets == true ? "yes" : "no"
  mcast_allow               = each.value.general.pim == true ? "yes" : "no"
  name                      = each.value.name
  name_alias                = each.value.general.alias
  multi_dst_pkt_act         = each.value.general.multi_destination_flooding
  relation_fv_rs_bd_to_ep_ret = length(compact([each.value.general.endpoint_retention_policy])
  ) > 0 ? "uni/tn-${local.policy_tenant}/epRPol-${each.value.general.endpoint_retention_policy}" : ""
  relation_fv_rs_ctx = length(each.value.general.vrf
  ) > 0 ? "uni/tn-${each.value.general.vrf.tenant}/ctx-${each.value.general.vrf.name}" : ""
  relation_fv_rs_igmpsn = length(compact([each.value.general.igmp_snooping_policy])
  ) > 0 ? "uni/tn-${local.policy_tenant}/snPol-${each.value.general.igmp_snooping_policy}" : ""
  relation_fv_rs_mldsn = length(compact([each.value.general.mld_snoop_policy])
  ) > 0 ? "uni/tn-${local.policy_tenant}/mldsnoopPol-${each.value.general.mld_snoop_policy}" : ""
  tenant_dn         = "uni/tn-${each.value.general.tenant}"
  unk_mac_ucast_act = each.value.general.l2_unknown_unicast
  unk_mcast_act     = each.value.general.l3_unknown_multicast_flooding
  v6unk_mcast_act   = each.value.general.ipv6_l3_unknown_multicast
  # L3 Configurations
  ep_move_detect_mode = each.value.l3_configurations.ep_move_detection_mode == true ? "garp" : "disable"
  ll_addr             = each.value.l3_configurations.link_local_ipv6_address
  mac                 = each.value.l3_configurations.custom_mac_address
  # class: l3extOut
  relation_fv_rs_bd_to_out = length(each.value.l3_configurations.associated_l3outs
  ) > 0 ? [for v in each.value.l3_configurations.associated_l3outs : "uni/tn-${v.tenant}/out-${v.l3outs[0]}"] : []
  # class: rtctrlProfile
  relation_fv_rs_bd_to_profile = join(",", [
    for v in each.value.l3_configurations.associated_l3outs : "uni/tn-${v.tenant}/out-${v.l3out[0]}/prof-${v.route_profile}" if v.route_profile != ""
  ])
  # class: monEPGPol
  # relation_fv_rs_bd_to_nd_p = length(
  # [each.value.nd_policy]) > 0 ? "uni/tn-${local.policy_tenant}/ndifpol-${each.value.nd_policy}" : ""
  unicast_route = each.value.l3_configurations.unicast_routing == true ? "yes" : "no"
  vmac = length(compact([each.value.l3_configurations.virtual_mac_address])
  ) > 0 ? each.value.l3_configurations.virtual_mac_address : "not-applicable"
  # Advanced/Troubleshooting
  ep_clear    = each.value.advanced_troubleshooting.endpoint_clear == true ? "yes" : "no"
  ip_learning = each.value.advanced_troubleshooting.disable_ip_data_plane_learning_for_pbr == true ? "no" : "yes"
  intersite_bum_traffic_allow = length(regexall(
    true, each.value.advanced_troubleshooting.intersite_l2_stretch)
  ) > 0 && length(regexall(true, each.value.advanced_troubleshooting.intersite_bum_traffic_allow)) > 0 ? "yes" : "no"
  intersite_l2_stretch   = each.value.advanced_troubleshooting.intersite_l2_stretch == true ? "yes" : "no"
  optimize_wan_bandwidth = length(regexall(true, each.value.advanced_troubleshooting.optimize_wan_bandwidth)) > 0 ? "yes" : "no"
  # class: monEPGPol
  relation_fv_rs_abd_pol_mon_pol = length(compact([each.value.advanced_troubleshooting.monitoring_policy])
  ) > 0 ? "uni/tn-${local.policy_tenant}/monepg-${each.value.advanced_troubleshooting.monitoring_policy}" : ""
  # class: netflowMonitorPol
  dynamic "relation_fv_rs_bd_to_netflow_monitor_pol" {
    for_each = each.value.advanced_troubleshooting.netflow_monitor_policies
    content {
      flt_type = relation_l3ext_rs_l_if_p_to_netflow_monitor_pol.value.filter_type # ipv4|ipv6|ce
      tn_netflow_monitor_pol_name = length(compact([relation_l3ext_rs_l_if_p_to_netflow_monitor_pol.value.netflow_policy])
      ) > 0 ? "uni/tn-${local.policy_tenant}/monitorpol-${relation_l3ext_rs_l_if_p_to_netflow_monitor_pol.value.netflow_policy}" : ""
    }
  }
  # class: fhsBDPol
  relation_fv_rs_bd_to_fhs = length(compact([each.value.advanced_troubleshooting.first_hop_security_policy])
  ) > 0 ? "uni/tn-${local.policy_tenant}/bdpol-${each.value.advanced_troubleshooting.first_hop_security_policy}" : ""
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "dhcpLbl"
 - Distinguished Name: "uni/tn-{tenant}/BD-{bridge_domain}/dhcplbl-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Bridge Domains > {bridge_domain} > DHCP Relay > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bd_dhcp_label" "bridge_domain_dhcp_labels" {
  depends_on = [
    aci_bridge_domain.bridge_domains,
  ]
  for_each         = { for k, v in local.bridge_domain_dhcp_labels : k => v if local.controller_type == "apic" }
  annotation       = each.value.annotation
  bridge_domain_dn = "uni/tn-${each.value.tenant}/BD-${each.value.bridge_domain}"
  name             = each.value.name
  owner            = each.value.scope
  relation_dhcp_rs_dhcp_option_pol = length(compact([each.value.dhcp_option_policy])
  ) > 0 ? "uni/tn-${each.value.tenant}/dhcpoptpol-${each.value.dhcp_option_policy}" : ""
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvSubnet"
 - Distinguished Name: "uni/tn-{tenant}/BD-{bridge_domain}/subnet-[{subnet}]"
GUI Location:
 - Tenants > {tenant} > Networking > Bridge Domains > {bridge_domain} > Subnets
_______________________________________________________________________________________________________________________
*/
resource "aci_subnet" "bridge_domain_subnets" {
  depends_on = [
    aci_bridge_domain.bridge_domains,
    aci_l3_outside.l3outs
  ]
  for_each  = { for k, v in local.bridge_domain_subnets : k => v if local.controller_type == "apic" }
  parent_dn = aci_bridge_domain.bridge_domains[each.value.bridge_domain].id
  ctrl = anytrue([each.value.subnet_control["neighbor_discovery"
    ], each.value.subnet_control["no_default_svi_gateway"], each.value.subnet_control["querier_ip"]
    ]) ? compact(concat([
      length(regexall(true, each.value.subnet_control["neighbor_discovery"])) > 0 ? "nd" : ""], [
      length(regexall(true, each.value.subnet_control["no_default_svi_gateway"])) > 0 ? "no-default-gateway" : ""], [
    length(regexall(true, each.value.subnet_control["querier_ip"])) > 0 ? "querier" : ""]
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
  scope = anytrue([each.value.scope["advertise_externally"
    ], each.value.scope["shared_between_vrfs"]]) ? compact(concat([
    length(regexall(true, each.value.scope["advertise_externally"])) > 0 ? "public" : ""], [
    length(regexall(true, each.value.scope["shared_between_vrfs"])) > 0 ? "shared" : ""]
  )) : ["private"]
  virtual = each.value.treat_as_virtual_ip_address == true ? "yes" : "no"
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAnnotation"
 - Distinguished Name: "uni/tn-{tenant}/BD-{bridge_domain}/annotationKey-[{key}]"
GUI Location:
 - Tenants > {tenant} > Networking > Bridge Domains > {bridge_domain}: {annotations}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "bridge_domain_annotations" {
  depends_on = [
    aci_bridge_domain.bridge_domains
  ]
  for_each = {
    for i in flatten([
      for a, b in local.bridge_domains : [
        for v in b.general.annotations : {
          bridge_domain = a
          key           = v.key
          tenant        = b.tenant
          value         = v.value
        }
      ]
    ]) : "${i.bridge_domain}:${i.key}" => i if local.controller_type == "apic"
  }
  dn         = "uni/tn-${each.value.tenant}/BD-${each.value.bridge_domain}/annotationKey-[${each.value.key}]"
  class_name = "tagAnnotation"
  content = {
    key   = each.value.key
    value = each.value.value
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAliasInst"
 - Distinguished Name: "uni/tn-{tenant}/BD-{bridge_domain}/alias"
GUI Location:
 - Tenants > {tenant} > Networking > Bridge Domains > {bridge_domain}: global_alias

_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "bridge_domain_global_alias" {
  depends_on = [
    aci_bridge_domain.bridge_domains
  ]
  for_each   = { for k, v in local.bridge_domains : k => v if v.general.global_alias != "" && local.controller_type == "apic" }
  class_name = "tagAliasInst"
  dn         = "uni/tn-${each.key}/BD-${each.value.bridge_domain}/alias"
  content = {
    name = each.value.general.global_alias
  }
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


/*_____________________________________________________________________________________________________________________

Nexus Dashboard — Tenants
_______________________________________________________________________________________________________________________
*/
resource "mso_schema_template_bd" "bridge_domains" {
  provider = mso
  depends_on = [
    mso_schema.schemas,
    mso_schema_site.template_sites,
    mso_schema_site_vrf.vrfs,
    mso_schema_template_vrf.vrfs
  ]
  for_each     = { for k, v in local.bridge_domains : k => v if local.controller_type == "ndo" }
  arp_flooding = each.value.general.arp_flooding
  #dynamic "dhcp_policies" {
  #  for_each = each.value.dhcp_relay_labels
  #  content {
  #    name                       = dhcp_policies.value.name
  #    version                    = dhcp_policy.value.version
  #    dhcp_option_policy_name    = dhcp_policies.value.dhcp_option_policy
  #    dhcp_option_policy_version = dhcp_policies.value.dhcp_option_policy_version
  #  }
  #}
  #description                     = each.value.general.description
  display_name                    = each.value.combine_description == true ? "${each.value.name}-${each.value.general.description}" : each.value.name
  name                            = each.value.name
  intersite_bum_traffic           = each.value.advanced_troubleshooting.intersite_bum_traffic_allow
  ipv6_unknown_multicast_flooding = each.value.general.ipv6_l3_unknown_multicast
  multi_destination_flooding = length(regexall(
    each.value.general.multi_destination_flooding, "bd-flood")
    ) > 0 ? "flood_in_bd" : length(regexall(
    each.value.general.multi_destination_flooding, "encap-flood")
  ) > 0 ? "flood_in_encap" : "drop"
  layer2_unknown_unicast     = each.value.general.l2_unknown_unicast
  layer2_stretch             = each.value.advanced_troubleshooting.intersite_l2_stretch
  layer3_multicast           = each.value.general.pim
  optimize_wan_bandwidth     = each.value.advanced_troubleshooting.optimize_wan_bandwidth
  schema_id                  = mso_schema.schemas[each.value.ndo.schema].id
  template_name              = each.value.ndo.template
  unknown_multicast_flooding = each.value.general.l3_unknown_multicast_flooding
  unicast_routing            = each.value.l3_configurations.unicast_routing
  virtual_mac_address        = each.value.l3_configurations.virtual_mac_address
  vrf_name                   = each.value.general.vrf.name
  vrf_schema_id = length(compact([each.value.general.vrf.schema])
  ) > 0 ? data.mso_schema.schemas[each.value.general.vrf.schema].id : data.mso_schema.schemas[each.value.ndo.schema].id
  vrf_template_name = each.value.general.vrf.template
  lifecycle {
    ignore_changes = [
      schema_id
    ]
  }
}

resource "mso_schema_site_bd" "bridge_domains" {
  provider = mso
  depends_on = [
    mso_schema_template_bd.bridge_domains
  ]
  for_each      = { for k, v in local.ndo_bd_sites : k => v if local.controller_type == "ndo" }
  bd_name       = each.value.bridge_domain
  host_route    = each.value.advertise_host_routes
  schema_id     = data.mso_schema.schemas[each.value.schema].id
  site_id       = data.mso_site.sites[each.value.site].id
  template_name = each.value.template
  lifecycle {
    ignore_changes = [
      schema_id,
      site_id
    ]
  }
}

resource "mso_schema_site_bd_l3out" "bridge_domain_l3outs" {
  provider = mso
  depends_on = [
    mso_schema_site_bd.bridge_domains
  ]
  for_each      = { for k, v in local.ndo_bd_sites : k => v if local.controller_type == "ndo" && length(compact([v.l3out])) > 0 }
  bd_name       = each.value.bridge_domain
  l3out_name    = each.value.l3out
  schema_id     = data.mso_schema.schemas[each.value.schema].id
  site_id       = data.mso_site.sites[each.value.site].id
  template_name = each.value.template
  lifecycle {
    ignore_changes = [
      schema_id,
      site_id
    ]
  }
}

resource "mso_schema_template_bd_subnet" "bridge_domain_subnets" {
  provider = mso
  depends_on = [
    mso_schema_template_bd.bridge_domains,
    mso_schema_site_bd.bridge_domains
  ]
  for_each           = { for k, v in local.bridge_domain_subnets : k => v if local.controller_type == "ndo" }
  bd_name            = each.value.bridge_domain
  description        = each.value.description
  ip                 = each.value.gateway_ip
  no_default_gateway = each.value.subnet_control.no_default_svi_gateway
  schema_id          = data.mso_schema.schemas[each.value.ndo.schema].id
  scope              = each.value.scope.advertise_externally == true ? "public" : "private"
  template_name      = each.value.ndo.template
  shared             = each.value.scope.shared_between_vrfs
  querier            = each.value.subnet_control.querier_ip
  lifecycle {
    ignore_changes = [
      schema_id
    ]
  }
}
