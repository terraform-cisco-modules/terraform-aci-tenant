/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "dhcpOptionPol"
 - Distinguised Name: "uni/tn-{name}/dhcpoptpol-{name}"
GUI Location:
 - Tenants > {tenant} > Policies > Protocol > DHCP > Options Policies > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_dhcp_option_policy" "map" {
  depends_on  = [aci_tenant.map]
  for_each    = local.dhcp_option
  description = each.value.description
  name        = each.key
  tenant_dn   = "uni/tn-${each.value.tenant}"
  dynamic "dhcp_option" {
    for_each = each.value.options
    content {
      data           = dhcp_option.value.data
      dhcp_option_id = dhcp_option.value.option_id
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
resource "aci_dhcp_relay_policy" "map" {
  depends_on  = [aci_tenant.map]
  for_each    = { for v in local.dhcp_relay : v.dhcp_server => v }
  description = each.value.description
  mode        = each.value.mode
  name        = each.key
  owner       = "tenant"
  tenant_dn   = "uni/tn-${each.value.tenant}"
  dynamic "relation_dhcp_rs_prov" {
    for_each = { for v in [each.value.dhcp_server] : v => v }
    content {
      addr = relation_dhcp_rs_prov.key
      tdn = length(
        regexall("external_epg", each.value.epg_type)
        ) > 0 ? "uni/tn-${each.value.tenant}/out-${each.value.l3out}/instP-${each.value.epg}" : length(
        regexall("application_epg", each.value.epg_type)
      ) > 0 ? "uni/tn-${each.value.tenant}/ap-${each.value.application_profile}/epg-${each.value.epg}" : ""
    }
  }
}
