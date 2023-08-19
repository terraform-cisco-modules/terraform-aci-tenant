/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bfdIfPol"
 - Distinguised Name: "uni/tn-{name}/bfdIfPol-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > BFD > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_bfd_interface_policy" "map" {
  depends_on = [aci_tenant.map]
  for_each   = local.bfd_interface
  admin_st   = each.value.admin_state
  # Bug 803 Submitted
  # ctrl          = each.value.enable_sub_interface_optimization == true ? "opt-subif" : "none"
  description   = each.value.description
  detect_mult   = each.value.detection_multiplier
  echo_admin_st = each.value.echo_admin_state
  echo_rx_intvl = each.value.echo_recieve_interval
  min_rx_intvl  = each.value.minimum_recieve_interval
  min_tx_intvl  = each.value.minimum_transmit_interval
  name          = each.key
  tenant_dn     = "uni/tn-${each.value.tenant}"
}
