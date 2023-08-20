/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extLNodeP"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}"
GUI Location:
tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile}
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Create Logical Node Profiles
#------------------------------------------------
resource "aci_logical_node_profile" "map" {
  depends_on    = [aci_l3_outside.map]
  for_each      = local.l3out_node_profiles
  l3_outside_dn = aci_l3_outside.map[each.value.l3out].id
  description   = each.value.description
  name          = each.value.name
  name_alias    = each.value.alias
  tag           = each.value.color_tag
  target_dscp   = each.value.target_dscp
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extRsNodeL3OutAtt"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}/rsnodeL3OutAtt-[topology/pod-{pod_id}/node-{node_id}]"
GUI Location:
tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile}: Nodes > {node_id}
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Assign a Node to a Logical Node Profiles
#------------------------------------------------
resource "aci_logical_node_to_fabric_node" "map" {
  depends_on              = [aci_logical_node_profile.map]
  for_each                = local.l3out_node_profiles_nodes
  logical_node_profile_dn = aci_logical_node_profile.map[each.value.node_profile].id
  tdn                     = "topology/pod-${each.value.pod_id}/node-${each.value.node_id}"
  rtr_id                  = each.value.router_id
  rtr_id_loop_back        = each.value.use_router_id_as_loopback == true ? "yes" : "no"
}

