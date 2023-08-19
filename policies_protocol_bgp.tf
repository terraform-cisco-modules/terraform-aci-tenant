/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpCtxAfPol"
 - Distinguised Name: "uni/tn-{name}/bgpCtxAfP-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > BGP > BGP Address Family Context > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bgp_address_family_context" "map" {
  depends_on = [aci_tenant.map]
  # Missing Local Max ECMP
  for_each      = local.bgp_address_family_context
  ctrl          = each.value.enable_host_route_leak == true ? "host-rt-leak" : "none"
  description   = each.value.description
  e_dist        = each.value.ebgp_distance
  i_dist        = each.value.ibgp_distance
  local_dist    = each.value.local_distance
  max_ecmp      = each.value.ebgp_max_ecmp
  max_ecmp_ibgp = each.value.ibgp_max_ecmp
  name          = each.key
  tenant_dn     = "uni/tn-${each.value.tenant}"
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpBestPathCtrlPol"
 - Distinguised Name: "uni/tn-{name}/bestpath-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > BGP > BGP Best Path > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bgp_best_path_policy" "map" {
  depends_on  = [aci_tenant.map]
  for_each    = local.bgp_best_path
  ctrl        = each.value.relax_as_path_restriction == true ? "asPathMultipathRelax" : "0"
  description = each.value.description
  name        = each.key
  tenant_dn   = "uni/tn-${each.value.tenant}"
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpPeerPfxPol"
 - Distinguished Name: "uni/tn-{tenant}/bgpPfxP-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > BGP >  BGP Peer Prefix > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bgp_peer_prefix" "map" {
  depends_on   = [aci_tenant.map]
  for_each     = local.bgp_peer_prefix
  action       = each.value.action
  description  = each.value.description
  name         = each.key
  max_pfx      = each.value.maximum_number_of_prefixes
  restart_time = each.value.restart_time == 65535 ? "infinite" : each.value.restart_time
  tenant_dn    = "uni/tn-${each.value.tenant}"
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
resource "aci_bgp_route_summarization" "map" {
  depends_on = [aci_tenant.map]
  for_each   = local.bgp_route_summarization
  address_type_controls = anytrue(
    [
      each.value.af_mcast,
      each.value.af_ucast
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.address_type_controls.af_mcast)) > 0 ? "af-mcast" : ""], [
      length(regexall(true, each.value.address_type_controls.af_ucast)) > 0 ? "af-ucast" : ""]
  )) : ["af-ucast"]
  # attrmap     = each.value.attrmap
  ctrl = anytrue(
    [
      each.value.control_state.do_not_advertise_more_specifics,
      each.value.control_state.generate_as_set_information
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.control_state.do_not_advertise_more_specifics)) > 0 ? "summary-only" : ""], [
      length(regexall(true, each.value.control_state.generate_as_set_information)) > 0 ? "as-set" : ""]
  )) : ["none"]
  description = each.value.description
  name        = each.key
  tenant_dn   = "uni/tn-${each.value.tenant}"
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpCtxPol"
 - Distinguised Name: "uni/tn-{name}/bgpCtxP-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > BGP > BGP Timers > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bgp_timers" "map" {
  depends_on   = [aci_tenant.map]
  for_each     = local.bgp_timers
  description  = each.value.description
  gr_ctrl      = each.value.graceful_restart_helper == true ? "helper" : "none"
  hold_intvl   = each.value.hold_interval
  ka_intvl     = each.value.keepalive_interval
  max_as_limit = each.value.maximum_as_limit
  name         = each.key
  stale_intvl  = each.value.stale_interval == 300 ? "default" : each.value.stale_interval
  tenant_dn    = "uni/tn-${each.value.tenant}"
}
