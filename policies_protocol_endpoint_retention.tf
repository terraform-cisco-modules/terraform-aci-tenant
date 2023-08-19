/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvEpRetPol"
 - Distinguised Name: "uni/tn-{name}/epRPol-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > End Point Retention > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_end_point_retention_policy" "map" {
  depends_on          = [aci_tenant.map]
  for_each            = local.endpoint_retention
  bounce_age_intvl    = each.value.bounce_entry_aging_interval
  bounce_trig         = each.value.bounce_trigger
  description         = each.value.description
  hold_intvl          = each.value.hold_interval
  local_ep_age_intvl  = each.value.local_endpoint_aging_interval
  move_freq           = each.value.move_frequency
  name                = each.key
  remote_ep_age_intvl = each.value.remote_endpoint_aging_interval == 0 ? "infinite" : each.value.remote_endpoint_aging_interval
  tenant_dn           = "uni/tn-${each.value.tenant}"
}
