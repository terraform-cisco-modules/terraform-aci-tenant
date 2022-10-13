/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bfdIfPol"
 - Distinguised Name: "uni/tn-{name}/bfdIfPol-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > BFD > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bfd_interface_policy" "policies_bfd_interface" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each   = local.policies_bfd_interface
  admin_st   = each.value.admin_state
  annotation = each.value.annotation != "" ? each.value.annotation : var.annotation
  # Bug 803 Submitted
  # ctrl          = each.value.enable_sub_interface_optimization == true ? "opt-subif" : "none"
  description   = each.value.description
  detect_mult   = each.value.detection_multiplier
  echo_admin_st = each.value.echo_admin_state
  echo_rx_intvl = each.value.echo_recieve_interval
  min_rx_intvl  = each.value.minimum_recieve_interval
  min_tx_intvl  = each.value.minimum_transmit_interval
  name          = each.key
  tenant_dn     = aci_tenant.tenants[each.value.tenant].id
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpCtxAfPol"
 - Distinguised Name: "uni/tn-{name}/bgpCtxAfP-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > BGP > BGP Address Family Context > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bgp_address_family_context" "policies_bgp_address_family_context" {
  depends_on = [
    aci_tenant.tenants
  ]
  # Missing Local Max ECMP
  for_each      = local.policies_bgp_address_family_context
  annotation    = each.value.annotation != "" ? each.value.annotation : var.annotation
  ctrl          = each.value.enable_host_route_leak == true ? "host-rt-leak" : "none"
  description   = each.value.description
  e_dist        = each.value.ebgp_distance
  i_dist        = each.value.ibgp_distance
  local_dist    = each.value.local_distance
  max_ecmp      = each.value.ebgp_max_ecmp
  max_ecmp_ibgp = each.value.ibgp_max_ecmp
  name          = each.key
  tenant_dn     = aci_tenant.tenants[each.value.tenant].id
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpBestPathCtrlPol"
 - Distinguised Name: "uni/tn-{name}/bestpath-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > BGP > BGP Best Path > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bgp_best_path_policy" "policies_bgp_best_path" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each    = local.policies_bgp_best_path
  annotation  = each.value.annotation != "" ? each.value.annotation : var.annotation
  ctrl        = each.value.relax_as_path_restriction == true ? "asPathMultipathRelax" : "0"
  description = each.value.description
  name        = each.key
  tenant_dn   = aci_tenant.tenants[each.value.tenant].id
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpPeerPfxPol"
 - Distinguished Name: "uni/tn-{tenant}/bgpPfxP-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > BGP >  BGP Peer Prefix > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bgp_peer_prefix" "policies_bgp_peer_prefix" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each     = local.policies_bgp_peer_prefix
  action       = each.value.action
  annotation   = each.value.annotation != "" ? each.value.annotation : var.annotation
  description  = each.value.description
  name         = each.key
  max_pfx      = each.value.maximum_number_of_prefixes
  restart_time = each.value.restart_time == 65535 ? "infinite" : each.value.restart_time
  tenant_dn    = aci_tenant.tenants[each.value.tenant].id
  thresh       = each.value.threshold
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpRtSummPol"
 - Distinguised Name: "uni/tn-{name}/bgprtsum-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > BGP > BGP Route Summarization > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bgp_route_summarization" "policies_bgp_route_summarization" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each   = local.policies_bgp_route_summarization
  annotation = each.value.annotation != "" ? each.value.annotation : var.annotation
  # attrmap     = each.value.attrmap
  ctrl        = each.value.generate_as_set_information == true ? "as-set" : "none"
  description = each.value.description
  name        = each.key
  tenant_dn   = aci_tenant.tenants[each.value.tenant].id
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpCtxPol"
 - Distinguised Name: "uni/tn-{name}/bgpCtxP-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > BGP > BGP Timers > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bgp_timers" "policies_bgp_timers" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each     = local.policies_bgp_timers
  annotation   = each.value.annotation != "" ? each.value.annotation : var.annotation
  description  = each.value.description
  gr_ctrl      = each.value.graceful_restart_helper == true ? "helper" : "none"
  hold_intvl   = each.value.hold_interval
  ka_intvl     = each.value.keepalive_interval
  max_as_limit = each.value.maximum_as_limit
  name         = each.key
  stale_intvl  = each.value.stale_interval == 300 ? "default" : each.value.stale_interval
  tenant_dn    = aci_tenant.tenants[each.value.tenant].id
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "dhcpOptionPol"
 - Distinguised Name: "uni/tn-{name}/dhcpoptpol-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > DHCP > Options Policies > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_dhcp_option_policy" "policies_dhcp_option" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each    = local.policies_dhcp_option
  annotation  = each.value.annotation
  description = each.value.description
  name        = each.key
  tenant_dn   = aci_tenant.tenants[each.value.tenant].id
  dynamic "dhcp_option" {
    for_each = each.value.options
    content {
      annotation     = dhcp_option.value.annotation
      data           = dhcp_option.value.data
      dhcp_option_id = dhcp_option.value.dhcp_option_id
      name           = dhcp_option.value.name
    }
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "dhcpRelayPol"
 - Distinguised Name: "uni/tn-{name}/relayp-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > DHCP > Relay Policies > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_dhcp_relay_policy" "policies_dhcp_relay" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each    = local.policies_dhcp_relay
  annotation  = each.value.annotation != "" ? each.value.annotation : var.annotation
  description = each.value.description
  mode        = each.value.mode
  name        = each.key
  owner       = "tenant"
  tenant_dn   = aci_tenant.tenants[each.value.tenant].id
  dynamic "relation_dhcp_rs_prov" {
    for_each = each.value.dhcp_relay_providers
    content {
      addr = relation_dhcp_rs_prov.value.address
      tdn = length(
        regexall("external_epg", relation_dhcp_rs_prov.value.epg_type)
        ) > 0 ? "uni/tn-${relation_dhcp_rs_prov.value.tenant}/out-${relation_dhcp_rs_prov.value.l3out}/instP-${relation_dhcp_rs_prov.value.epg}" : length(
        regexall("application_epg", relation_dhcp_rs_prov.value.epg_type)
      ) > 0 ? "uni/tn-${relation_dhcp_rs_prov.value.tenant}/ap-${relation_dhcp_rs_prov.value.application_profile}/epg-${relation_dhcp_rs_prov.value.epg}" : ""
    }
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvEpRetPol"
 - Distinguised Name: "uni/tn-{name}/epRPol-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > End Point Retention > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_end_point_retention_policy" "policies_endpoint_retention" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each            = local.policies_endpoint_retention
  annotation          = each.value.annotation != "" ? each.value.annotation : var.annotation
  bounce_age_intvl    = each.value.bounce_entry_aging_interval
  bounce_trig         = each.value.bounce_trigger
  description         = each.value.description
  hold_intvl          = each.value.hold_interval
  local_ep_age_intvl  = each.value.local_endpoint_aging_interval
  move_freq           = each.value.move_frequency
  name                = each.key
  remote_ep_age_intvl = each.value.remote_endpoint_aging_interval == 0 ? "infinite" : each.value.remote_endpoint_aging_interval
  tenant_dn           = aci_tenant.tenants[each.value.tenant].id
}
output "policies_endpoint_retention" {
  value = var.policies_endpoint_retention != {} ? { for v in sort(
    keys(aci_end_point_retention_policy.policies_endpoint_retention)
  ) : v => aci_end_point_retention_policy.policies_endpoint_retention[v].id } : {}
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "hsrpGroupPol"
 - Distinguished Name: "/uni/tn-{tenant}/hsrpGroupPol-{name}"
GUI Location:
tenants > {tenant} > Policies > Protocol > HSRP > Group Policies > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_hsrp_group_policy" "policies_hsrp_group" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each               = local.policies_hsrp_group
  annotation             = each.value.annotation
  description            = each.value.description
  ctrl                   = each.value.enable_preemption_for_the_group == true ? "preempt" : 0
  hello_intvl            = each.value.hello_interval
  hold_intvl             = each.value.hold_interval
  key                    = each.value.key
  name                   = each.key
  preempt_delay_min      = each.value.min_preemption_delay
  preempt_delay_reload   = each.value.preemption_delay_after_reboot
  preempt_delay_sync     = each.value.max_seconds_to_prevent_preemption
  prio                   = each.value.priority
  timeout                = each.value.timeout
  hsrp_group_policy_type = each.value.type == "md5_authentication" ? "md5" : "simple"
  tenant_dn              = aci_tenant.tenants[each.value.tenant].id
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "hsrpIfPol"
 - Distinguished Name: "/uni/tn-{tenant}/hsrpIfPol-{name}"
GUI Location:
tenants > {tenant} > Policies > Protocol > HSRP > Interface Policies > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_hsrp_interface_policy" "policies_hsrp_interface" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each   = local.policies_hsrp_interface
  annotation = each.value.annotation
  ctrl = anytrue(
    [each.value.enable_bidirectional_forwarding_detection, each.value.use_burnt_in_mac_address_of_the_interface]
    ) ? compact(concat([
      length(regexall(true, each.value.enable_bidirectional_forwarding_detection)) > 0 ? "bfd" : ""], [
      length(regexall(true, each.value.use_burnt_in_mac_address_of_the_interface)) > 0 ? "bia" : ""]
  )) : []
  delay        = each.value.delay
  description  = each.value.description
  name         = each.key
  reload_delay = each.value.reload_delay
  tenant_dn    = aci_tenant.tenants[each.value.tenant].id
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ospfIfPol"
 - Distinguished Name: "/uni/tn-{tenant}/ospfIfPol-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > OSPF >  OSPF Interface > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_ospf_interface_policy" "policies_ospf_interface" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each    = local.policies_ospf_interface
  tenant_dn   = aci_tenant.tenants[each.value.tenant].id
  annotation  = each.value.annotation != "" ? each.value.annotation : var.annotation
  description = each.value.description
  name        = each.key
  cost        = each.value.cost_of_interface == 0 ? "unspecified" : each.value.cost_of_interface
  ctrl = anytrue(
    [
      each.value.interface_controls[0].advertise_subnet,
      each.value.interface_controls[0].bfd,
      each.value.interface_controls[0].mtu_ignore,
      each.value.interface_controls[0].passive_participation
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.interface_controls[0].advertise_subnet)) > 0 ? "advert-subnet" : ""], [
      length(regexall(true, each.value.interface_controls[0].bfd)) > 0 ? "bfd" : ""], [
      length(regexall(true, each.value.interface_controls[0].mtu_ignore)) > 0 ? "mtu-ignore" : ""], [
      length(regexall(true, each.value.interface_controls[0].passive_participation)) > 0 ? "passive" : ""]
  )) : ["unspecified"]
  dead_intvl  = each.value.dead_interval
  hello_intvl = each.value.hello_interval
  nw_t        = each.value.network_type
  # pfx_suppress  = each.value.pfx_suppress
  prio         = each.value.priority
  rexmit_intvl = each.value.retransmit_interval
  xmit_delay   = each.value.transmit_delay
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ospfRtSummPol"
 - Distinguished Name: "/uni/tn-{tenant}/ospfrtsumm-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > OSPF >  OSPF Route Summarization > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_ospf_route_summarization" "policies_ospf_route_summarization" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each           = local.policies_ospf_route_summarization
  annotation         = each.value.annotation != "" ? each.value.annotation : var.annotation
  cost               = each.value.cost == 0 ? "unspecified" : each.value.cost # 0 to 16777215
  description        = each.value.description
  inter_area_enabled = each.value.inter_area_enabled == true ? "yes" : "no"
  name               = each.key
  tag                = 0
  tenant_dn          = aci_tenant.tenants[each.value.tenant].id
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ospfCtxPol"
 - Distinguished Name: "/uni/tn-{tenant}/ospfCtxP-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > OSPF >  OSPF Timers > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_ospf_timers" "policies_ospf_timers" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each   = local.policies_ospf_timers
  annotation = each.value.annotation != "" ? each.value.annotation : var.annotation
  bw_ref     = each.value.bandwidth_reference
  ctrl = anytrue(
    [
      each.value.control_knobs[0].enable_name_lookup_for_router_ids,
      each.value.control_knobs[0].prefix_suppress
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.control_knobs[0].enable_name_lookup_for_router_ids)
      ) > 0 ? "name-lookup" : ""], [
      length(regexall(true, each.value.control_knobs[0].prefix_suppress)
      ) > 0 ? "pfx-suppress" : ""]
  )) : []
  description         = each.value.description
  dist                = each.value.admin_distance_preference
  gr_ctrl             = each.value.graceful_restart_helper == true ? "helper" : "none"
  lsa_arrival_intvl   = each.value.minimum_interval_between_arrival_of_a_lsa
  lsa_gp_pacing_intvl = each.value.lsa_group_pacing_interval
  lsa_hold_intvl      = each.value.lsa_generation_throttle_hold_interval
  lsa_max_intvl       = each.value.lsa_generation_throttle_maximum_interval
  lsa_start_intvl     = each.value.lsa_generation_throttle_start_wait_interval
  max_ecmp            = each.value.maximum_ecmp
  max_lsa_action      = each.value.lsa_maximum_action
  max_lsa_num         = each.value.maximum_number_of_not_self_generated_lsas
  max_lsa_reset_intvl = each.value.maximum_lsa_reset_interval
  max_lsa_sleep_cnt   = each.value.maximum_lsa_sleep_count
  max_lsa_sleep_intvl = each.value.maximum_lsa_sleep_interval
  max_lsa_thresh      = each.value.lsa_threshold
  name                = each.key
  spf_hold_intvl      = each.value.minimum_hold_time_between_spf_calculations
  spf_init_intvl      = each.value.initial_spf_scheduled_delay_interval
  spf_max_intvl       = each.value.maximum_wait_time_between_spf_calculations
  tenant_dn           = aci_tenant.tenants[each.value.tenant].id
}
