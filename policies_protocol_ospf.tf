/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ospfIfPol"
 - Distinguished Name: "uni/tn-{tenant}/ospfIfPol-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > OSPF >  OSPF Interface > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_ospf_interface_policy" "map" {
  depends_on  = [aci_tenant.map]
  for_each    = local.ospf_interface
  tenant_dn   = "uni/tn-${each.value.tenant}"
  description = each.value.description
  name        = each.key
  cost        = each.value.cost_of_interface == 0 ? "unspecified" : each.value.cost_of_interface
  ctrl = anytrue(
    [
      each.value.interface_controls.advertise_subnet,
      each.value.interface_controls.bfd,
      each.value.interface_controls.mtu_ignore,
      each.value.interface_controls.passive_participation
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.interface_controls.advertise_subnet)) > 0 ? "advert-subnet" : ""], [
      length(regexall(true, each.value.interface_controls.bfd)) > 0 ? "bfd" : ""], [
      length(regexall(true, each.value.interface_controls.mtu_ignore)) > 0 ? "mtu-ignore" : ""], [
      length(regexall(true, each.value.interface_controls.passive_participation)) > 0 ? "passive" : ""]
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
 - Distinguished Name: "uni/tn-{tenant}/ospfrtsumm-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > OSPF >  OSPF Route Summarization > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_ospf_route_summarization" "map" {
  depends_on         = [aci_tenant.map]
  for_each           = local.ospf_route_summarization
  cost               = each.value.cost == 0 ? "unspecified" : each.value.cost # 0 to 16777215
  description        = each.value.description
  inter_area_enabled = each.value.inter_area_enabled == true ? "yes" : "no"
  name               = each.key
  tag                = 0
  tenant_dn          = "uni/tn-${each.value.tenant}"
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ospfCtxPol"
 - Distinguished Name: "uni/tn-{tenant}/ospfCtxP-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > OSPF >  OSPF Timers > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_ospf_timers" "map" {
  depends_on = [aci_tenant.map]
  for_each   = local.ospf_timers
  bw_ref     = each.value.bandwidth_reference
  ctrl = anytrue(
    [
      each.value.control_knobs.enable_name_lookup_for_router_ids,
      each.value.control_knobs.prefix_suppress
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.control_knobs.enable_name_lookup_for_router_ids)
      ) > 0 ? "name-lookup" : ""], [
      length(regexall(true, each.value.control_knobs.prefix_suppress)
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
  tenant_dn           = "uni/tn-${each.value.tenant}"
}
