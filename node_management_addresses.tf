/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "mgmtRsInBStNode" or "mgmtRsOoBStNode"
 - Distinguished Name: "uni/tn-mgmt/mgmtp-default/inb-{management_epg}/rsinBStNode-[topology/pod-{pod_id}/node-{node_id}]"
 or
 - Distinguished Name: "uni/tn-mgmt/mgmtp-default/oob-{management_epg}/rsooBStNode-[topology/pod-{pod_id}/node-{node_id}]"
GUI Location:
 - Tenants > mgmt > Node Management Addresses > Static Node Management Addresses
_______________________________________________________________________________________________________________________
*/
resource "aci_static_node_mgmt_address" "map" {
  depends_on = [
    aci_application_epg.map,
    aci_node_mgmt_epg.mgmt_epgs
  ]
  for_each          = local.static_node_management_addresses
  management_epg_dn = "uni/tn-mgmt/mgmtp-default/${each.value.mgmt_epg_type}-${each.value.management_epg}"
  t_dn              = "topology/pod-${each.value.pod_id}/node-${each.value.node_id}"
  type              = each.value.mgmt_epg_type == "inb" ? "in_band" : "out_of_band"
  addr = length(compact([each.value.ipv4_address])) > 0 && length(compact([each.value.ipv4_gateway])
  ) > 0 ? each.value.ipv4_address : ""
  gw = length(compact([each.value.ipv4_address])) > 0 && length(compact([each.value.ipv4_gateway])
  ) > 0 ? each.value.ipv4_gateway : ""
  v6_addr = length(compact([each.value.ipv6_address])) > 0 && length(compact([each.value.ipv6_gateway])
  ) > 0 ? each.value.ipv6_address : ""
  v6_gw = length(compact([each.value.ipv6_address])) > 0 && length(compact([each.value.ipv6_gateway])
  ) > 0 ? each.value.ipv6_gateway : ""
}
