/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extLIfP"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/lnodep-{name}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile} > Logical Interface Profiles {interface_profile}
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Create Logical Interface Profile
#------------------------------------------------
resource "aci_logical_interface_profile" "map" {
  depends_on              = [aci_logical_node_profile.map]
  for_each                = local.l3out_interface_profiles
  logical_node_profile_dn = aci_logical_node_profile.map[each.value.node_profile].id
  description             = each.value.description
  name                    = each.value.name
  prio                    = each.value.qos_class
  tag                     = each.value.color_tag
  relation_l3ext_rs_arp_if_pol = length(regexall(
    "[[:alnum:]]+", each.value.arp_policy)
  ) > 0 ? "uni/tn-${local.policy_tenant}/arpifpol-${each.value.arp_policy}" : ""
  relation_l3ext_rs_egress_qos_dpp_pol = length(regexall(
    "[[:alnum:]]+", each.value.data_plane_policing_egress)
  ) > 0 ? "uni/tn-${local.policy_tenant}/qosdpppol-${each.value.data_plane_policing_egress}" : ""
  relation_l3ext_rs_ingress_qos_dpp_pol = length(regexall(
    "[[:alnum:]]+", each.value.data_plane_policing_ingress)
  ) > 0 ? "uni/tn-${local.policy_tenant}/qosdpppol-${each.value.data_plane_policing_ingress}" : ""
  relation_l3ext_rs_l_if_p_cust_qos_pol = length(regexall(
    "[[:alnum:]]+", each.value.custom_qos_policy)
  ) > 0 ? "uni/tn-${local.policy_tenant}/qoscustom-${each.value.custom_qos_policy}" : ""
  relation_l3ext_rs_nd_if_pol = length(regexall(
    "[[:alnum:]]+", each.value.nd_policy)
  ) > 0 ? "uni/tn-${local.policy_tenant}/ndifpol-${each.value.nd_policy}" : ""
  dynamic "relation_l3ext_rs_l_if_p_to_netflow_monitor_pol" {
    for_each = each.value.netflow_monitor_policies
    content {
      flt_type                  = relation_l3ext_rs_l_if_p_to_netflow_monitor_pol.value.filter_type
      tn_netflow_monitor_pol_dn = relation_l3ext_rs_l_if_p_to_netflow_monitor_pol.value.netflow_policy
    }
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extRsPathL3OutAtt"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}/lifp-{interface_profile}/rspathL3OutAtt-[topology/pod-{pod_id}/{PATH}/pathep-[{interface_or_pg}]]"
GUI Location:
{%- if Interface_Type == 'ext-svi' %}
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile} > Logical Interface Profiles {interface_profile}: SVI
{%- elif Interface_Type == 'l3-port' %}
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile} > Logical Interface Profiles {interface_profile}: Routed Interfaces
{%- elif Interface_Type == 'sub-interface' %}
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile} > Logical Interface Profiles {interface_profile}: Routed Sub-Interfaces

 - Assign all the default Policies to this Policy Group
_______________________________________________________________________________________________________________________
*/
#-------------------------------------------------------------
# Attach a Node Interface Path to a Logical Interface Profile
#-------------------------------------------------------------
resource "aci_l3out_path_attachment" "map" {
  depends_on                   = [aci_logical_interface_profile.map]
  for_each                     = local.l3out_interface_profiles
  logical_interface_profile_dn = aci_logical_interface_profile.map[each.key].id
  target_dn = length(regexall("^eth[0-9]{1,2}/\\d{1,3}(/\\d{1,3})?$", each.value.interface_or_policy_group)) == 0 && length(
    regexall("ext-svi", each.value.interface_type)
    ) > 0 ? "topology/pod-${each.value.pod_id}/protpaths-${element(each.value.nodes, 0)}-${element(each.value.nodes, 1)}/pathep-[${each.value.interface_or_policy_group}]" : length(regexall(
    "[[:alnum:]]+", each.value.interface_type)
  ) > 0 ? "topology/pod-${each.value.pod_id}/paths-${element(each.value.nodes, 0)}/pathep-[${each.value.interface_or_policy_group}]" : ""
  if_inst_t = each.value.interface_type
  addr = length(regexall("^eth[0-9]{1,2}/\\d{1,3}(/\\d{1,3})?$", each.value.interface_or_policy_group)
  ) > 0 ? each.value.primary_preferred_address : ""
  autostate = length(regexall("^eth[0-9]{1,2}/\\d{1,3}(/\\d{1,3})?$", each.value.interface_or_policy_group)
  ) > 0 ? each.value.auto_state : "disabled"
  encap       = each.value.interface_type != "l3-port" ? "vlan-${each.value.encap_vlan}" : "unknown"
  mode        = each.value.interface_type != "l3-port" && each.value.mode == "access" ? "native" : "regular"
  encap_scope = each.value.interface_type != "l3-port" ? each.value.encap_scope : "local"
  ipv6_dad    = each.value.ipv6_dad
  ll_addr = length(regexall("^eth[0-9]{1,2}/\\d{1,3}(/\\d{1,3})?$", each.value.interface_or_policy_group)
  ) > 0 ? each.value.link_local_address : "::"
  mac         = each.value.mac_address
  mtu         = each.value.mtu
  target_dscp = each.value.target_dscp
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extRsPathL3OutAtt"
 - Distinguished Name: " uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}/lifp-{interface_profile}/rspathL3OutAtt-[topology/pod-{pod_id}/protpaths-{node1_id}-{node2_id}//pathep-[{policy_group}]]/mem-{side}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile} > Logical Interface Profiles {interface_profile}: SVI
_______________________________________________________________________________________________________________________
*/
#-------------------------------------------------------------
# Attach a Node Interface Path to a Logical Interface Profile
#-------------------------------------------------------------
resource "aci_l3out_vpc_member" "map" {
  depends_on   = [aci_l3out_path_attachment.map]
  for_each     = local.l3out_paths_svi_addressing
  addr         = each.value.primary_preferred_address
  description  = ""
  ipv6_dad     = each.value.ipv6_dad
  leaf_port_dn = aci_l3out_path_attachment.map[each.value.l3out_interface_profile].id
  ll_addr      = each.value.link_local_address
  side         = each.value.side
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extRsPathL3OutAtt"
 - Distinguished Name: " uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}/lifp-{interface_profile}/rspathL3OutAtt-[topology/pod-{pod_id}/{PATH}/pathep-[{interface_or_pg}]]"
GUI Location:
{%- if Interface_Type == 'ext-svi' %}
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile} > Logical Interface Profiles {interface_profile}: SVI
{%- elif Interface_Type == 'l3-port' %}
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile} > Logical Interface Profiles {interface_profile}: Routed Interfaces
{%- elif Interface_Type == 'sub-interface' %}
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile} > Logical Interface Profiles {interface_profile}: Routed Sub-Interfaces

_______________________________________________________________________________________________________________________
*/
#-------------------------------------------------------------
# Attach a Node Interface Path to a Logical Interface Profile
#-------------------------------------------------------------
resource "aci_l3out_path_attachment_secondary_ip" "map" {
  depends_on = [
    aci_l3out_path_attachment.map
  ]
  for_each = local.l3out_paths_secondary_ips
  l3out_path_attachment_dn = length(regexall("svi", each.value.path_type)
    ) > 0 ? aci_l3out_vpc_member.map[each.value.l3out_interface_profile
  ].id : aci_l3out_path_attachment.map[each.value.l3out_interface_profile].id
  addr     = each.value.secondary_ip_address
  ipv6_dad = each.value.ipv6_dad
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "bgpPeerP"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}/lifp-{Interface_Profile}/rspathL3OutAtt-[topology/pod-{Pod_ID}/{PATH}/pathep-[{Interface_or_PG}]]/peerP-[{Peer_IP}]"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile {node_profile} > Logical Interface Profile > {Interface_Profile} > OSPF Interface Profile

_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Create a BGP Peer Connectivity Profile
#------------------------------------------------
resource "aci_bgp_peer_connectivity_profile" "map" {
  depends_on = [
    aci_logical_node_profile.map,
    aci_logical_interface_profile.map,
    aci_bgp_peer_prefix.map
  ]
  for_each = local.bgp_peer_connectivity_profiles
  addr     = each.value.peer_address
  addr_t_ctrl = anytrue(
    [
      each.value.address_type_controls.af_mcast,
      each.value.address_type_controls.af_ucast
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.address_type_controls.af_mcast)) > 0 ? "af-mcast" : ""], [
      length(regexall(true, each.value.address_type_controls.af_ucast)) > 0 ? "af-ucast" : ""]
  )) : [""]
  admin_state         = each.value.admin_state
  allowed_self_as_cnt = each.value.allowed_self_as_count
  as_number           = each.value.peer_asn
  ctrl = anytrue(
    [
      each.value.bgp_controls.allow_self_as,
      each.value.bgp_controls.as_override,
      each.value.bgp_controls.disable_peer_as_check,
      each.value.bgp_controls.next_hop_self,
      each.value.bgp_controls.send_community,
      each.value.bgp_controls.send_domain_path,
      each.value.bgp_controls.send_extended_community
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.bgp_controls.allow_self_as)) > 0 ? "allow-self-as" : ""], [
      length(regexall(true, each.value.bgp_controls.as_override)) > 0 ? "as-override" : ""], [
      length(regexall(true, each.value.bgp_controls.disable_peer_as_check)) > 0 ? "dis-peer-as-check" : ""], [
      length(regexall(true, each.value.bgp_controls.next_hop_self)) > 0 ? "nh-self" : ""], [
      length(regexall(true, each.value.bgp_controls.send_community)) > 0 ? "send-com" : ""], [
      # Missing Attribute: Bug ID
      # length(regexall(true, each.value.bgp_controls.send_domain_path)) > 0 ? "" : ""], [
      length(regexall(true, each.value.bgp_controls.send_extended_community)) > 0 ? "send-ext-com" : ""]
  )) : ["unspecified"]
  description = each.value.description
  parent_dn = length(
    regexall("interface", each.value.peer_level)
    ) > 0 ? aci_l3out_path_attachment.map[each.value.l3out_interface_profile].id : length(
    regexall("loopback", each.value.peer_level)
  ) > 0 ? aci_logical_node_profile.map[each.value.node_profile].id : ""
  password = length(var.tenant_sensitive.bgp.password[each.value.password]
  ) > 0 ? var.tenant_sensitive.bgp.password[each.value.password] : ""
  peer_ctrl = anytrue(
    [
      each.value.peer_controls.bidirectional_forwarding_detection,
      each.value.peer_controls.disable_connected_check
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.peer_controls.bidirectional_forwarding_detection)) > 0 ? "bfd" : ""], [
      length(regexall(true, each.value.peer_controls.disable_connected_check)) > 0 ? "dis-conn-check" : ""]
  )) : []
  private_a_sctrl = anytrue(
    [
      each.value.private_as_control.remove_all_private_as,
      each.value.private_as_control.remove_private_as,
      each.value.private_as_control.replace_private_as_with_local_as
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.private_as_control.remove_all_private_as)) > 0 ? "remove-all" : ""], [
      length(regexall(true, each.value.private_as_control.remove_private_as)) > 0 ? "remove-exclusive" : ""], [
      length(regexall(true, each.value.private_as_control.replace_private_as_with_local_as)) > 0 ? "replace-as" : ""]
  )) : []
  ttl       = each.value.ebgp_multihop_ttl
  weight    = each.value.weight_for_routes_from_neighbor
  local_asn = each.value.local_as_number != 0 ? each.value.local_as_number : null
  # Submit Bug
  local_asn_propagate = each.value.local_as_number != 0 ? each.value.local_as_number_config : null
  relation_bgp_rs_peer_pfx_pol = length(compact([each.value.bgp_peer_prefix_policy])
  ) > 0 ? "uni/tn-${local.policy_tenant}/bgpPfxP-${each.value.bgp_peer_prefix_policy}" : ""
  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = each.value.route_control_profiles
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = "uni/tn-${local.policy_tenant}/prof-${relation_bgp_rs_peer_to_profile.value.route_map}"
    }
  }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "hsrpIfP"
 - Distinguished Name:  uni/tn-{tenant}/out-{l3out}/lnodep-{logical_node_profile}/lifp-{logical_interface_profile}/hsrpIfP
GUI Location:
Tenants > {tenant} > L3Outs > {l3out} > Logical Node Profiles > {logical_node_profile} > Logical Interface Profiles >
{logical_interface_profile} > Create HSRP Interface Profile
_______________________________________________________________________________________________________________________
*/
# resource "aci_l3out_floating_svi" "l3out_floating_svis" {
#   depends_on = [
#     aci_logical_interface_profile.l3out_interface_profiles
#   ]
#   for_each                     = local.l3out_floating_svis
#   addr                         = each.value.address
##   autostate                    = each.value.auto_state
#   description                  = each.value.description
#   encap_scope                  = each.value.encap_scope
#   if_inst_t                    = each.value.interface_type
#   ipv6_dad                     = each.value.ipv6_dad
#   ll_addr                      = each.value.link_local_address
#   logical_interface_profile_dn = aci_logical_interface_profile.l3out_interface_profiles[each.key].id
#   node_dn                      = "topology/pod-${each.value.pod_id}/node-${each.value.node_id}"
#   encap                        = "vlan-${each.value.vlan}"
#   mac                          = each.value.mac_address
#   mode                         = each.value.mode
#   mtu                          = each.value.mtu
#   target_dscp                  = each.value.target_dscp
# }


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "hsrpIfP"
 - Distinguished Name:  uni/tn-{tenant}/out-{l3out}/lnodep-{logical_node_profile}/lifp-{logical_interface_profile}/hsrpIfP
GUI Location:
Tenants > {tenant} > L3Outs > {l3out} > Logical Node Profiles > {logical_node_profile} > Logical Interface Profiles >
{logical_interface_profile} > Create HSRP Interface Profile
_______________________________________________________________________________________________________________________
*/
resource "aci_l3out_hsrp_interface_profile" "map" {
  depends_on = [
    aci_logical_interface_profile.map
  ]
  for_each                     = local.hsrp_interface_profile
  logical_interface_profile_dn = aci_logical_interface_profile.map[each.value.l3out_interface_profile].id
  description                  = each.value.description
  name_alias                   = each.value.alias
  relation_hsrp_rs_if_pol      = "uni/tn-${local.policy_tenant}/hsrpIfPol-${each.value.hsrp_interface_policy}"
  version                      = each.value.version
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "hsrpGroupP"
 - Distinguished Name: uni/tn-{tenant}/out-{l3out}/lnodep-{logical_node_profile}/lifp-{logical_interface_profile}/hsrpIfP/hsrpGroupP-{name}
GUI Location:
Tenants > {tenant} > L3Outs > {l3out} > Logical Node Profiles > {logical_node_profile} > Logical Interface Profiles >
{logical_interface_profile} > Create HSRP Interface Profile
_______________________________________________________________________________________________________________________
*/
resource "aci_l3out_hsrp_interface_group" "map" {
  depends_on                      = [aci_l3out_hsrp_interface_profile.map]
  for_each                        = local.hsrp_interface_profile_groups
  l3out_hsrp_interface_profile_dn = aci_l3out_hsrp_interface_profile.map[each.value.key1].id
  name_alias                      = each.value.alias
  group_af                        = each.value.address_family
  group_id                        = each.value.group_id
  group_name                      = each.value.group_name
  ip                              = each.value.ip_address
  ip_obtain_mode                  = each.value.ip_obtain_mode
  mac                             = each.value.mac_address
  name                            = each.value.name
  relation_hsrp_rs_group_pol      = "uni/tn-${local.policy_tenant}/hsrpGroupPol-${each.value.hsrp_group_policy}"
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "hsrpSecVip"
 - Distinguished Name: uni/tn-{tenant}/out-{l3out}/lnodep-{logical_node_profile}/lifp-{logical_interface_profile}/hsrpIfP/hsrpGroupP-{name}/hsrpSecVip-[{secondar_ip}]
GUI Location:
Tenants > {tenant} > L3Outs > {l3out} > Logical Node Profiles > {logical_node_profile} > Logical Interface Profiles >
{logical_interface_profile} > Create HSRP Interface Profile
_______________________________________________________________________________________________________________________
*/
resource "aci_l3out_hsrp_secondary_vip" "map" {
  depends_on                    = [aci_l3out_hsrp_interface_group.map]
  for_each                      = local.hsrp_interface_profile_group_secondaries
  l3out_hsrp_interface_group_dn = aci_l3out_hsrp_interface_group.map[each.value.key1].id
  ip                            = each.value.secondary_ip
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ospfIfP"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/nodep-{node_profile}/lifp-{interface_profile}/ospfIfP"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile {node_profile} > Logical Interface Profile > {interface_profile} > OSPF Interface Profile
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Assign a OSPF Routing Policy to the L3Out
#------------------------------------------------
resource "aci_l3out_ospf_interface_profile" "map" {
  depends_on = [
    aci_logical_interface_profile.map,
    aci_ospf_interface_policy.map,
  ]
  for_each = local.l3out_ospf_interface_profiles
  auth_key = length(regexall("(md5|simple)", each.value.authentication_type)
  ) > 0 ? var.tenant_sensitive.ospf.authentication_key[each.value.authentication_key] : ""
  auth_key_id                  = each.value.authentication_type == "md5" ? each.value.authentication_key : ""
  auth_type                    = each.value.authentication_type
  description                  = each.value.description
  logical_interface_profile_dn = aci_logical_interface_profile.map[each.value.l3out_interface_profile].id
  relation_ospf_rs_if_pol      = "uni/tn-${local.policy_tenant}/ospfIfPol-${each.value.ospf_interface_policy}"
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ipRouteP"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}/rsnodeL3OutAtt-[topology/pod-{pod_id}/node-{node_id}]/rt-[{route}]/"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile {node_profile} > Logical Interface Profile > {interface_profile} > Nodes > {node_id} > Static Routes
_______________________________________________________________________________________________________________________
*/
resource "aci_l3out_static_route" "map" {
  depends_on = [
    aci_logical_node_to_fabric_node.map
  ]
  for_each       = local.l3out_node_profile_static_routes
  aggregate      = each.value.aggregate == true ? "yes" : "no"
  description    = each.value.description
  fabric_node_dn = aci_logical_node_to_fabric_node.map[each.value.key].id
  name_alias     = each.value.alias
  ip             = each.value.prefix
  pref           = each.value.fallback_preference
  rt_ctrl        = each.value.route_control.bfd == true ? "bfd" : "unspecified"
  # class fvTrackList
  relation_ip_rs_route_track = length(compact([each.value.track_list_policy])
  ) > 0 ? "uni/tn-${each.value.tenant}/tracklist-${each.value.track_list_policy}" : ""
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ipNexthopP"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}/rsnodeL3OutAtt-[topology/pod-{pod_id}/node-{node_id}]/rt-[{route}]/nh-[{next_hop_ip}]"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile {node_profile} > Logical Interface Profile > {interface_profile} > Nodes > {node_id} > Static Routes
_______________________________________________________________________________________________________________________
*/
resource "aci_l3out_static_route_next_hop" "map" {
  depends_on = [
    aci_ip_sla_monitoring_policy.map,
    aci_l3out_static_route.map,
    aci_rest_managed.track_lists,
    aci_rest_managed.track_members
  ]
  for_each             = local.l3out_static_routes_next_hop
  description          = each.value.description
  name_alias           = each.value.alias
  nexthop_profile_type = each.value.next_hop_type
  nh_addr              = each.value.next_hop_ip
  pref                 = each.value.preference == 0 ? "unspecified" : each.value.preference
  static_route_dn      = aci_l3out_static_route.map[each.value.prefix_dn].id
  # class fvTrackList
  relation_ip_rs_nexthop_route_track = length(compact([each.value.track_list_policy])
  ) > 0 ? aci_rest_managed.track_lists[each.value.track_list_policy].id : ""
  # Class "ipRsNHTrackMember"
  relation_ip_rs_nh_track_member = each.value.track_member
}
