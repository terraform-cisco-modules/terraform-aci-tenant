/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vnsSvcRedirectPol"
 - Distinguished Name: "uni/tn-{tenant}/svcCont/svcRedirectPol-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > L4-L7 Policy-Based Redirect > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_service_redirect_policy" "map" {
  depends_on = [
    aci_tenant.map,
    aci_ip_sla_monitoring_policy.map
  ]
  for_each              = local.l4_l7_policy_based_redirect
  anycast_enabled       = length(regexall(true, each.value.enable_anycast)) > 0 ? "yes" : "no" # default is no
  description           = each.value.description
  dest_type             = each.value.destination_type # L1,L2,L3, default L3
  name                  = each.key
  max_threshold_percent = each.value.max_threshold_percentage # 1-100, default 0
  min_threshold_percent = each.value.min_threshold_percentage # 1-100, default 0
  hashing_algorithm     = each.value.hashing_algorithm        # dip,sip, sip-dip-prototype, default is sip-dip-prototype
  relation_vns_rs_ipsla_monitoring_pol = length(compact([each.value.ip_sla_monitoring_poilcy])
  ) > 0 ? aci_ip_sla_monitoring_policy.map[each.value.ip_sla_monitoring_poilcy].id : ""
  resilient_hash_enabled = length(regexall(
    true, each.value.resilient_hashing_enabled)
  ) > 0 ? "yes" : "no" # default is no
  tenant_dn = "uni/tn-${each.value.tenant}"
  threshold_enable = length(regexall(
    true, each.value.threshold_enable)
  ) > 0 ? "yes" : "no" # default is no
  program_local_pod_only = length(regexall(
    true, each.value.enable_pod_id_aware_redirection)
  ) > 0 ? "yes" : "no"                                     # default is no
  threshold_down_action = each.value.threshold_down_action # bypass, deny, permit, default is permit
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vnsRedirectHealthGroup"
 - Distinguished Name: "uni/tn-{tenant}/svcCont/redirectHealthGroup-{name}""
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > L4-L7 Redirect Health Group > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_l4_l7_redirect_health_group" "map" {
  depends_on  = [aci_tenant.map]
  for_each    = local.l4_l7_redirect_health_groups
  description = each.value.description
  name        = each.key
  tenant_dn   = "uni/tn-${each.value.tenant}"
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vnsRedirectDest"
 - Distinguished Name: "uni/tn-{tenant}/svcCont/svcRedirectPol-{name}/RedirectDest_ip-[{ip}]"
 - Distinguished Name: "uni/tn-{tenant}/svcCont/svcRedirectPol-{name}/RedirectDest_mac-[{mac}]"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > L4-L7 Policy-Based Redirect > {name} > {L1/L2|L3} Destinations
_______________________________________________________________________________________________________________________
*/
resource "aci_destination_of_redirected_traffic" "map" {
  depends_on = [
    aci_l4_l7_redirect_health_group.map,
    aci_service_redirect_policy.map
  ]
  for_each = local.l4_l7_pbr_destinations
  ip       = each.value.ip
  ip2 = length(compact([each.value.additional_ipv4_ipv6])
  ) > 0 ? each.value.additional_ipv4_ipv6 : "0.0.0.0"
  mac    = each.value.mac
  pod_id = each.value.pod_id
  relation_vns_rs_redirect_health_group = length(compact([each.value.redirect_health_group])
  ) > 0 ? aci_l4_l7_redirect_health_group.map[each.value.redirect_health_group].id : ""
  service_redirect_policy_dn = aci_service_redirect_policy.map[each.value.l4_l7_pbr_policy].id
}
