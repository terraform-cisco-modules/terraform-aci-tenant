/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extOut"
 - Distinguished Name: "/uni/tn-{tenant}/out-{l3out}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out}
_______________________________________________________________________________________________________________________
*/
resource "aci_l3_outside" "l3outs" {
  depends_on = [
    aci_tenant.tenants,
    aci_vrf.vrfs
  ]
  for_each               = { for k, v in local.l3outs : k => v if local.controller_type == "apic" }
  annotation             = each.value.annotation
  description            = each.value.description
  enforce_rtctrl         = each.value.route_control_enforcement.import == true ? ["export", "import"] : ["export"]
  name                   = each.key
  name_alias             = each.value.alias
  target_dscp            = each.value.target_dscp
  tenant_dn              = aci_tenant.tenants[each.value.tenant].id
  relation_l3ext_rs_ectx = aci_vrf.vrfs[each.value.vrf].id
  relation_l3ext_rs_l3_dom_att = length(compact([each.value.l3_domain])
  ) > 0 ? "uni/l3dom-${each.value.l3_domain}" : ""
  dynamic "relation_l3ext_rs_dampening_pol" {
    for_each = each.value.route_control_for_dampening
    content {
      af                     = "${relation_l3ext_rs_dampening_pol.value.address_family}-ucast"
      tn_rtctrl_profile_name = "uni/tn-${local.policy_tenant}/prof-${relation_l3ext_rs_dampening_pol.value.route_map}"
    }
  }
  # Class l3extRsInterleakPol
  relation_l3ext_rs_interleak_pol = length(compact([each.value.route_profile_for_interleak])
  ) > 0 ? "uni/tn-${local.policy_tenant}/prof-${each.value.route_profile_for_interleak}" : ""
  # relation_l3ext_rs_out_to_bd_public_subnet_holder = ["{fvBDPublicSubnetHolder}"]
}

resource "aci_l3out_bgp_external_policy" "external_bgp" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each      = { for k, v in local.l3outs : k => v if local.controller_type == "apic" && v.enable_bgp == true }
  l3_outside_dn = aci_l3_outside.l3outs[each.key].id
  annotation    = each.value.annotation
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAnnotation"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/annotationKey-[{key}]"
GUI Location:
 - Tenants > {tenant} > Networking > > L3Outs > {l3out}: {annotations}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "l3out_annotations" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each = {
    for i in flatten([
      for a, b in local.l3outs : [
        for v in b.annotations : {
          key    = v.key
          tenant = b.tenant
          l3out  = a
          value  = v.value
        }
      ]
    ]) : "${i.tenant}:${i.l3out}:${i.key}" => i if local.controller_type == "apic"
  }
  dn         = "uni/tn-${each.value.tenant}/out-${each.value.l3out}/annotationKey-[${each.value.key}]"
  class_name = "tagAnnotation"
  content = {
    key   = each.value.key
    value = each.value.value
  }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAliasInst"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}//alias"
GUI Location:
 - Tenants > {tenant} > Networking > L3Outs > {l3out}: global_alias

_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "l3out_global_alias" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each   = { for k, v in local.l3outs : k => v if v.global_alias != "" && local.controller_type == "apic" }
  class_name = "tagAliasInst"
  dn         = "uni/tn-${each.value.tenant}/out-${each.value.l3out}/alias"
  content = {
    name = each.value.global_alias
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extRsRedistributePol"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/pimextp"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "l3out_route_profiles_for_redistribution" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each   = local.l3out_route_profiles_for_redistribution
  dn         = "uni/tn-${each.value.tenant}/out-${each.value.l3out}/rsredistributePol-[${each.value.route_map}]-${each.value.source}"
  class_name = "l3extRsRedistributePol"
  content = {
    annotation = each.value.annotation
    src        = each.value.source
    tDn = length(compact([each.value.rm_l3out])
    ) > 0 ? "uni/tn-${each.value.tenant}/out-${each.value.rm_l3out}/prof-${each.value.route_map}" : "uni/tn-${each.value.tenant}/prof-${each.value.route_map}"
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "pimExtP"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/pimextp"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "l3out_multicast" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each   = { for k, v in local.l3outs : k => v if local.controller_type == "apic" && (v.pim == true || v.pimv6 == true) }
  dn         = "uni/tn-${each.value.tenant}/out-${each.key}/pimextp"
  class_name = "pimExtP"
  content = {
    annotation = each.value.annotation
    enableAf = anytrue(
      [each.value.pim, each.value.pimv6]
      ) ? replace(trim(join(",", concat([
        length(regexall(true, each.value.pim)) > 0 ? "ipv4-mcast" : ""], [
        length(regexall(true, each.value.pimv6)) > 0 ? "ipv6-mcast" : ""]
    )), ","), ",,", ",") : "none"
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extConsLbl"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/conslbl-hcloudGolfLabel"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "l3out_consumer_label" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each   = { for k, v in local.l3outs : k => v if local.controller_type == "apic" && v.consumer_label == "hcloudGolfLabel" }
  dn         = "uni/tn-${each.value.tenant}/out-${each.key}/conslbl-hcloudGolfLabel"
  class_name = "l3extConsLbl"
  content = {
    annotation = each.value.annotation
    name       = "hcloudGolfLabel"
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extInstP"
 - Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{Ext_EPG}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {Ext_EPG}
_______________________________________________________________________________________________________________________
*/
resource "aci_external_network_instance_profile" "l3out_external_epgs" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each       = { for k, v in local.l3out_external_epgs : k => v }
  l3_outside_dn  = aci_l3_outside.l3outs[each.value.l3out].id
  annotation     = each.value.annotation
  description    = each.value.description
  exception_tag  = each.value.contract_exception_tag
  flood_on_encap = each.value.flood_on_encapsulation
  match_t        = each.value.label_match_criteria
  name_alias     = each.value.alias
  name           = each.value.name
  pref_gr_memb   = each.value.preferred_group_member == true ? "include" : "exclude"
  prio           = each.value.qos_class
  target_dscp    = each.value.target_dscp
  relation_fv_rs_sec_inherited = length(each.value.l3out_contract_masters) > 0 ? [
    for s in each.value.l3out_contract_masters : "uni/tn-${each.value.tenant}/out-${s.l3out}/intP-${s.external_epg}"
  ] : []
  dynamic "relation_l3ext_rs_inst_p_to_profile" {
    for_each = each.value.route_control_profiles
    content {
      direction              = each.value.direction
      tn_rtctrl_profile_name = "uni/tn-${local.policy_tenant}/prof-${relation_l3ext_rs_inst_p_to_profile.value.route_map}"
    }
  }
  # relation_l3ext_rs_l3_inst_p_to_dom_p        = each.value.l3_domain
  # relation_fv_rs_cust_qos_pol = each.value.custom_qos_policy
  # relation_fv_rs_sec_inherited                = [each.value.l3out_contract_masters]
  # relation_l3ext_rs_inst_p_to_nat_mapping_epg = "aci_bridge_domain.{NAT_fvEPg}.id"
}

#------------------------------------------------
# Assign Contracts to an External EPG
#------------------------------------------------

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvRsIntraEpg"
 - Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsintraEpg-{contract}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {external_epg}: Contracts
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "external_epg_intra_epg_contracts" {
  depends_on = [
    aci_external_network_instance_profile.l3out_external_epgs,
  ]
  for_each = {
    for k, v in local.l3out_ext_epg_contracts : k => v if local.controller_type == "apic" && v.contract_type == "intra_epg"
  }
  dn         = "uni/tn-${var.tenant}/out-${each.value.l3out}/instP-${each.value.epg}/rsintraEpg-${each.value.contract}"
  class_name = "fvRsIntraEpg"
  content = {
    tnVzBrCPName = each.value.contract
  }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Consumer Class: "fvRsCons"
 - Interface Class: "vzRsAnyToConsIf"
 - Provider Class: "fvRsProv"
 - Taboo Class: "fvRsProtBy"
 - Consumer Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsintraEpg-{contract}"
 - Interface Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsconsIf-{contract}"
 - Provider Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsprov-{contract}"
 - Taboo Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsprotBy-{contract}"
GUI Location:
 - All Contracts: tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {external_epg}: Contracts
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "external_epg_contracts" {
  depends_on = [
    aci_external_network_instance_profile.l3out_external_epgs,
  ]
  for_each = {
    for k, v in local.l3out_ext_epg_contracts : k => v if length(regexall("(intra_epg|taboo)", v.contract_type)
    ) > 0 && local.controller_type == "apic"
  }
  dn = length(regexall(
    "consumed", each.value.contract_type)
    ) > 0 ? "uni/tn-${var.tenant}/out-${each.value.l3out}/instP-${each.value.external_epg}/rscons-${each.value.contract}" : length(
    regexall("interface", each.value.contract_type)
    ) > 0 ? "uni/tn-${var.tenant}/out-${each.value.l3out}/instP-${each.value.external_epg}/rsconsIf-${each.value.contract}" : length(
    regexall("provided", each.value.contract_type)
  ) > 0 ? "uni/tn-${var.tenant}/out-${each.value.l3out}/instP-${each.value.external_epg}/rsprov-${each.value.contract}" : ""
  class_name = length(regexall(
    "consumed", each.value.contract_type)
    ) > 0 ? "fvRsCons" : length(regexall(
    "interface", each.value.contract_type)
    ) > 0 ? "vzRsAnyToConsIf" : length(regexall(
    "provided", each.value.contract_type)
  ) > 0 ? "fvRsProv" : ""
  content = {
    tDn          = "uni/tn-${each.value.tenant}/brc-${each.value.contract}"
    tnVzBrCPName = each.value.contract
    prio         = each.value.qos_class
  }
}

resource "aci_rest_managed" "external_epg_contracts_taboo" {
  depends_on = [
    aci_external_network_instance_profile.l3out_external_epgs,
  ]
  for_each = {
    for k, v in local.l3out_ext_epg_contracts : k => v if length(regexall("taboo", v.contract_type)
    ) > 0 && local.controller_type == "apic"
  }
  dn         = "uni/tn-${var.tenant}/out-${each.value.l3out}/instP-${each.value.external_epg}/rsprotBy-${each.value.contract}"
  class_name = "fvRsProtBy"
  content = {
    tDn           = "uni/tn-${each.value.tenant}/taboo-${each.value.contract}"
    tnVzTabooName = each.value.contract
  }
}


#------------------------------------------------
# Assign a Subnet to an External EPG
#------------------------------------------------

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extSubnet"
 - Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/extsubnet-[{subnet}]"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {external_epg}
_______________________________________________________________________________________________________________________
*/
resource "aci_l3_ext_subnet" "external_epg_subnets" {
  depends_on = [
    aci_external_network_instance_profile.l3out_external_epgs
  ]
  for_each = { for k, v in local.l3out_external_epg_subnets : k => v }
  aggregate = anytrue(
    [
      each.value.aggregate.aggregate_export,
      each.value.aggregate.aggregate_import,
      each.value.aggregate.aggregate_shared_routes
    ]
    ) ? replace(trim(join(",", concat([
      length(regexall(true, each.value.aggregate.aggregate_export)) > 0 ? "export-rtctrl" : ""], [
      length(regexall(true, each.value.aggregate.aggregate_import)) > 0 ? "import-rtctrl" : ""], [
      length(regexall(true, each.value.aggregate.aggregate_shared_routes)) > 0 ? "shared-rtctrl" : ""]
  )), ","), ",,", ",") : "none"
  annotation                           = each.value.annotation
  description                          = each.value.description
  external_network_instance_profile_dn = aci_external_network_instance_profile.l3out_external_epgs[each.value.external_epg].id
  ip                                   = each.value.subnet
  scope = anytrue(
    [
      each.value.external_epg_classification.external_subnets_for_external_epg,
      each.value.external_epg_classification.shared_security_import_subnet,
      each.value.route_control.export_route_control_subnet,
      each.value.route_control.import_route_control_subnet,
      each.value.route_control.shared_route_control_subnet
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.external_epg_classification.external_subnets_for_external_epg)
      ) > 0 ? "import-security" : ""], [
      length(regexall(true, each.value.external_epg_classification.shared_security_import_subnet)
      ) > 0 ? "shared-security" : ""], [
      length(regexall(true, each.value.route_control.export_route_control_subnet)) > 0 ? "export-rtctrl" : ""], [
      length(regexall(true, each.value.route_control.import_route_control_subnet)) > 0 ? "import-rtctrl" : ""], [
      length(regexall(true, each.value.route_control.shared_route_control_subnet)) > 0 ? "shared-rtctrl" : ""]
  )) : ["import-security"]
  dynamic "relation_l3ext_rs_subnet_to_profile" {
    for_each = each.value.route_control_profiles
    content {
      direction            = relation_l3ext_rs_subnet_to_profile.value.direction
      tn_rtctrl_profile_dn = "uni/tn-${relation_l3ext_rs_subnet_to_profile.value.tenant}/prof-${relation_l3ext_rs_subnet_to_profile.value.route_map}"
    }
  }
  relation_l3ext_rs_subnet_to_rt_summ = length(
    compact([each.value.route_summarization_policy])) > 0 && length(
    regexall(true, each.value.route_control.export_route_control_subnet)
  ) > 0 ? "uni/tn-${local.policy_tenant}/bgprtsum-${each.value.route_summarization_policy}" : ""
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ospfExtP"
 - Distinguished Name: "/uni/tn-{tenant}/out-{l3out}/ospfExtP"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out}: OSPF
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Assign a OSPF Routing Policy to the L3Out
#------------------------------------------------
resource "aci_l3out_ospf_external_policy" "l3out_ospf_external_profile" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each   = local.l3out_ospf_external_profile
  annotation = each.value.annotation
  area_cost  = each.value.ospf_area_cost
  area_ctrl = anytrue([
    each.value.ospf_area_control.send_redistribution_lsas_into_nssa_area,
    each.value.ospf_area_control.originate_summary_lsa,
    each.value.ospf_area_control.suppress_forwarding_address
    ]) ? compact(concat([
      length(regexall(true, each.value.ospf_area_control.send_redistribution_lsas_into_nssa_area)) > 0 ? "redistribute" : ""], [
      length(regexall(true, each.value.ospf_area_control.originate_summary_lsa)) > 0 ? "summary" : ""], [
    length(regexall(true, each.value.ospf_area_control.suppress_forwarding_address)) > 0 ? "suppress-fa" : ""]
  )) : ["redistribute", "summary"]
  area_id       = each.value.ospf_area_id
  area_type     = each.value.ospf_area_type
  l3_outside_dn = aci_l3_outside.l3outs[each.value.l3out].id
  # multipod_internal = "no"
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extLNodeP"
 - Distinguished Name: "/uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}"
GUI Location:
tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile}
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Create Logical Node Profiles
#------------------------------------------------
resource "aci_logical_node_profile" "l3out_node_profiles" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each      = local.l3out_node_profiles
  l3_outside_dn = aci_l3_outside.l3outs[each.value.l3out].id
  annotation    = each.value.annotation
  description   = each.value.description
  name          = each.value.name
  name_alias    = each.value.alias
  tag           = each.value.color_tag
  target_dscp   = each.value.target_dscp
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extRsNodeL3OutAtt"
 - Distinguished Name: "/uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}/rsnodeL3OutAtt-[topology/pod-{pod_id}/node-{node_id}]"
GUI Location:
tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile}: Nodes > {node_id}
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Assign a Node to a Logical Node Profiles
#------------------------------------------------
resource "aci_logical_node_to_fabric_node" "l3out_node_profiles_nodes" {
  depends_on = [
    aci_logical_node_profile.l3out_node_profiles
  ]
  for_each                = local.l3out_node_profiles_nodes
  annotation              = each.value.annotation
  logical_node_profile_dn = aci_logical_node_profile.l3out_node_profiles[each.value.node_profile].id
  tdn                     = "topology/pod-${each.value.pod_id}/node-${each.value.node_id}"
  rtr_id                  = each.value.router_id
  rtr_id_loop_back        = each.value.use_router_id_as_loopback == true ? "yes" : "no"
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extLIfP"
 - Distinguished Name: "/uni/tn-{tenant}/out-{l3out}/lnodep-{name}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile > {node_profile} > Logical Interface Profiles {interface_profile}
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Create Logical Interface Profile
#------------------------------------------------
resource "aci_logical_interface_profile" "l3out_interface_profiles" {
  depends_on = [
    aci_logical_node_profile.l3out_node_profiles
  ]
  for_each                = local.l3out_interface_profiles
  logical_node_profile_dn = aci_logical_node_profile.l3out_node_profiles[each.value.node_profile].id
  annotation              = each.value.annotation
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
      flt_type                    = relation_l3ext_rs_l_if_p_to_netflow_monitor_pol.value.filter_type # ipv4|ipv6|ce
      tn_netflow_monitor_pol_name = relation_l3ext_rs_l_if_p_to_netflow_monitor_pol.value.netflow_policy
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
resource "aci_l3out_path_attachment" "l3out_path_attachments" {
  depends_on = [
    aci_logical_interface_profile.l3out_interface_profiles
  ]
  for_each                     = local.l3out_interface_profiles
  logical_interface_profile_dn = aci_logical_interface_profile.l3out_interface_profiles[each.key].id
  target_dn = length(regexall(
    "ext-svi", each.value.interface_type)
    ) > 0 ? "topology/pod-${each.value.pod_id}/protpaths-${element(each.value.nodes, 0)}-${element(each.value.nodes, 1)}/pathep-[${each.value.interface_or_policy_group}]" : length(regexall(
    "[[:alnum:]]+", each.value.interface_type)
  ) > 0 ? "topology/pod-${each.value.pod_id}/paths-${element(each.value.nodes, 0)}/pathep-[${each.value.interface_or_policy_group}]" : ""
  if_inst_t   = each.value.interface_type
  addr        = each.value.interface_type != "ext-svi" ? each.value.primary_preferred_address : ""
  annotation  = each.value.annotation
  autostate   = each.value.interface_type == "ext-svi" ? each.value.auto_state : "disabled"
  encap       = each.value.interface_type != "l3-port" ? "vlan-${each.value.encap_vlan}" : "unknown"
  mode        = each.value.mode == "trunk" ? "regular" : "native"
  encap_scope = each.value.interface_type != "l3-port" ? each.value.encap_scope : "local"
  ipv6_dad    = each.value.ipv6_dad
  ll_addr     = each.value.interface_type != "ext-svi" ? each.value.link_local_address : "::"
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
resource "aci_l3out_vpc_member" "l3out_vpc_member" {
  depends_on = [
    aci_l3out_path_attachment.l3out_path_attachments
  ]
  for_each     = local.l3out_paths_svi_addressing
  addr         = each.value.primary_preferred_address
  annotation   = each.value.annotation
  description  = ""
  ipv6_dad     = each.value.ipv6_dad
  leaf_port_dn = aci_l3out_path_attachment.l3out_path_attachments[each.value.l3out_interface_profile].id
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
resource "aci_l3out_path_attachment_secondary_ip" "l3out_paths_secondary_ips" {
  depends_on = [
    aci_l3out_path_attachment.l3out_path_attachments
  ]
  for_each                 = local.l3out_paths_secondary_ips
  l3out_path_attachment_dn = aci_l3out_path_attachment.l3out_path_attachments[each.value.l3out_path].id
  addr                     = each.value.secondary_ip_address
  annotation               = each.value.annotation
  ipv6_dad                 = each.value.ipv6_dad
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
resource "aci_bgp_peer_connectivity_profile" "bgp_peer_connectivity_profiles" {
  depends_on = [
    aci_logical_node_profile.l3out_node_profiles,
    aci_logical_interface_profile.l3out_interface_profiles,
    aci_bgp_peer_prefix.bgp_peer_prefix
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
    ) > 0 ? aci_l3out_path_attachment.l3out_path_attachments[each.value.l3out_interface_profile].id : length(
    regexall("loopback", each.value.peer_level)
  ) > 0 ? aci_logical_node_profile.l3out_node_profiles[each.value.node_profile].id : ""
  password = length(
    regexall(5, each.value.password)) > 0 ? var.bgp_password_5 : length(
    regexall(4, each.value.password)) > 0 ? var.bgp_password_4 : length(
    regexall(3, each.value.password)) > 0 ? var.bgp_password_3 : length(
    regexall(2, each.value.password)) > 0 ? var.bgp_password_2 : length(
  regexall(1, each.value.password)) > 0 ? var.bgp_password_1 : ""
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
  local_asn_propagate          = each.value.local_as_number != 0 ? each.value.local_as_number_config : null
  relation_bgp_rs_peer_pfx_pol = "uni/tn-${local.policy_tenant}/bgpPfxP-${each.value.bgp_peer_prefix_policy}"
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
#   annotation                   = each.value.annotation
#   autostate                    = each.value.auto_state
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
resource "aci_l3out_hsrp_interface_profile" "hsrp_interface_profile" {
  depends_on = [
    aci_logical_interface_profile.l3out_interface_profiles
  ]
  for_each = local.hsrp_interface_profile
  logical_interface_profile_dn = length(compact([each.value.interface_profile])
  ) > 0 ? aci_logical_interface_profile.l3out_interface_profiles[each.value.interface_profile].id : ""
  annotation              = each.value.annotation
  description             = each.value.description
  name_alias              = each.value.alias
  relation_hsrp_rs_if_pol = "uni/tn-${local.policy_tenant}/hsrpIfPol-${each.value.hsrp_interface_policy}"
  version                 = each.value.version
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
resource "aci_l3out_hsrp_interface_group" "hsrp_interface_profile_groups" {
  depends_on = [
    aci_l3out_hsrp_interface_profile.hsrp_interface_profile
  ]
  for_each                        = local.hsrp_interface_profile_groups
  l3out_hsrp_interface_profile_dn = aci_l3out_hsrp_interface_profile.hsrp_interface_profile[each.value.key1].id
  name_alias                      = each.value.alias
  annotation                      = each.value.annotation
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
resource "aci_l3out_hsrp_secondary_vip" "hsrp_interface_profile_group_secondaries" {
  depends_on = [
    aci_l3out_hsrp_interface_group.hsrp_interface_profile_groups
  ]
  for_each                      = local.hsrp_interface_profile_group_secondaries
  l3out_hsrp_interface_group_dn = aci_l3out_hsrp_interface_group.hsrp_interface_profile_groups[each.value.key1].id
  ip                            = each.value.secondary_ip
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ospfIfP"
 - Distinguished Name: "/uni/tn-{tenant}/out-{l3out}/nodep-{node_profile}/lifp-{interface_profile}/ospfIfP"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile {node_profile} > Logical Interface Profile > {interface_profile} > OSPF Interface Profile
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Assign a OSPF Routing Policy to the L3Out
#------------------------------------------------
resource "aci_l3out_ospf_interface_profile" "l3out_ospf_interface_profiles" {
  depends_on = [
    aci_logical_interface_profile.l3out_interface_profiles,
    aci_ospf_interface_policy.ospf_interface,
  ]
  for_each   = local.l3out_ospf_interface_profiles
  annotation = each.value.annotation
  auth_key = length(regexall(
    "(md5|simple)", each.value.authentication_type)
    ) > 0 && each.value.ospf_key == 5 ? var.ospf_key_5 : length(regexall(
    "(md5|simple)", each.value.authentication_type)
    ) > 0 && each.value.ospf_key == 4 ? var.ospf_key_4 : length(regexall(
    "(md5|simple)", each.value.authentication_type)
    ) > 0 && each.value.ospf_key == 3 ? var.ospf_key_3 : length(regexall(
    "(md5|simple)", each.value.authentication_type)
    ) > 0 && each.value.ospf_key == 2 ? var.ospf_key_2 : length(regexall(
    "(md5|simple)", each.value.authentication_type)
  ) > 0 && each.value.ospf_key == 1 ? var.ospf_key_1 : ""
  auth_key_id                  = each.value.authentication_type == "md5" ? each.value.ospf_key : ""
  auth_type                    = each.value.authentication_type
  description                  = each.value.description
  logical_interface_profile_dn = aci_logical_interface_profile.l3out_interface_profiles[each.value.l3out_interface_profile].id
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
# resource "aci_l3out_static_route" "l3out_node_profile_static_routes" {
#   depends_on = [
#     aci_logical_node_to_fabric_node.l3out_node_profiles_nodes
#   ]
#   for_each = local.l3out_node_profile_static_routes
#   # aggregate      = each.value.aggregate == true ? "yes" : "no"
#   annotation     = each.value.annotation
#   description    = each.value.description
#   fabric_node_dn = aci_logical_node_to_fabric_node.l3out_node_profiles_nodes[each.value.node].id
#   name_alias     = each.value.alias
#   ip             = each.value.prefix
#   pref           = each.value.preference
#   rt_ctrl        = each.value.route_control_bfd == true ? "bfd" : "unspecified"
#   # class fvTrackList
#   relation_ip_rs_route_track = ""
# }

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ipNexthopP"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/lnodep-{node_profile}/rsnodeL3OutAtt-[topology/pod-{pod_id}/node-{node_id}]/rt-[{route}]/nh-[{next_hop_ip}]"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > Logical Node Profile {node_profile} > Logical Interface Profile > {interface_profile} > Nodes > {node_id} > Static Routes
_______________________________________________________________________________________________________________________
*/
# resource "aci_l3out_static_route_next_hop" "l3out_static_routes_next_hop" {
#   depends_on = [
#     aci_l3out_static_route.l3out_node_profile_static_routes
#   ]
#   for_each             = local.l3out_static_routes_next_hop
#   annotation           = each.value.annotation
#   description          = each.value.description
#   name_alias           = each.value.alias
#   nexthop_profile_type = each.value.next_hop_type
#   nh_addr              = each.value.next_hop_ip
#   pref                 = each.value.preference
#   static_route_dn      = aci_l3out_static_route.l3out_node_profile_static_routes[each.value.static_route].id
#   # class fvTrackList
#   # relation_ip_rs_nexthop_route_track = ""
#   # # Class "ipRsNHTrackMember"
#   # relation_ip_rs_nh_track_member = length(compact([each.value.ip_sla_policy])
#   # ) > 0 ? "" : ""
# }
