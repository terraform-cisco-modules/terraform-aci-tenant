/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extInstP"
 - Distinguised Name: "uni/tn-{tenant}/out-{l3out}/instP-{external_epg}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {external_epg}
_______________________________________________________________________________________________________________________
*/
resource "aci_external_network_instance_profile" "map" {
  depends_on     = [aci_l3_outside.map]
  for_each       = { for k, v in local.l3out_external_epgs : k => v }
  l3_outside_dn  = aci_l3_outside.map[each.value.l3out].id
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
 - Distinguised Name: "uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsintraEpg-{contract}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {external_epg}: Contracts
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "external_epg_intra_epg_contracts" {
  depends_on = [
    aci_external_network_instance_profile.map,
  ]
  for_each = {
    for k, v in local.l3out_ext_epg_contracts : k => v if local.controller.type == "apic" && v.contract_type == "intra_epg"
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
 - Consumer Distinguised Name: "uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsintraEpg-{contract}"
 - Interface Distinguised Name: "uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsconsIf-{contract}"
 - Provider Distinguised Name: "uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsprov-{contract}"
 - Taboo Distinguised Name: "uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/rsprotBy-{contract}"
GUI Location:
 - All Contracts: tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {external_epg}: Contracts
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "external_epg_contracts" {
  depends_on = [
    aci_external_network_instance_profile.map,
  ]
  for_each = {
    for k, v in local.l3out_ext_epg_contracts : k => v if length(regexall("(intra_epg|taboo)", v.contract_type)
    ) == 0 && local.controller.type == "apic"
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
    #tDn          = "uni/tn-${each.value.tenant}/brc-${each.value.contract}"
    tnVzBrCPName = each.value.contract
    prio         = each.value.qos_class
  }
}

resource "aci_rest_managed" "external_epg_contracts_taboo" {
  depends_on = [
    aci_external_network_instance_profile.map,
  ]
  for_each = {
    for k, v in local.l3out_ext_epg_contracts : k => v if length(regexall("taboo", v.contract_type)
    ) > 0 && local.controller.type == "apic"
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
 - Distinguised Name: "uni/tn-{tenant}/out-{l3out}/instP-{external_epg}/extsubnet-[{subnet}]"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {external_epg}
_______________________________________________________________________________________________________________________
*/
resource "aci_l3_ext_subnet" "map" {
  depends_on = [aci_external_network_instance_profile.map]
  for_each   = { for k, v in local.l3out_external_epg_subnets : k => v }
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
  description                          = each.value.description
  external_network_instance_profile_dn = aci_external_network_instance_profile.map[each.value.external_epg].id
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

