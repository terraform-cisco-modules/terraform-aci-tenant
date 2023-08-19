/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "hsrpGroupPol"
 - Distinguished Name: "uni/tn-{tenant}/hsrpGroupPol-{name}"
GUI Location:
tenants > {tenant} > Policies > Protocol > HSRP > Group Policies > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_hsrp_group_policy" "map" {
  depends_on             = [aci_tenant.map]
  for_each               = local.hsrp_group
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
  tenant_dn              = "uni/tn-${each.value.tenant}"
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "hsrpIfPol"
 - Distinguished Name: "uni/tn-{tenant}/hsrpIfPol-{name}"
GUI Location:
tenants > {tenant} > Policies > Protocol > HSRP > Interface Policies > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_hsrp_interface_policy" "map" {
  depends_on = [aci_tenant.map]
  for_each   = local.hsrp_interface
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
  tenant_dn    = "uni/tn-${each.value.tenant}"
}
