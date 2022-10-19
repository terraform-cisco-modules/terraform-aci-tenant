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
  enforce_rtctrl         = each.value.import == true ? ["export", "import"] : ["export"]
  name                   = each.key
  name_alias             = each.value.alias
  target_dscp            = each.value.target_dscp
  tenant_dn              = aci_tenant.tenants[each.value.tenant].id
  relation_l3ext_rs_ectx = aci_vrf.vrfs[each.value.vrf].id
  relation_l3ext_rs_l3_dom_att = length(regexall(
    "[[:alnum:]]+", each.value.l3_domain)
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
output "ext_epgs" {
  value = local.l3out_external_epgs
}
resource "aci_external_network_instance_profile" "l3out_external_epgs" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each       = { for k, v in local.l3out_external_epgs : k => v if v.epg_type != "oob" }
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

#------------------------------------------
# Create an Out-of-Band External EPG
#------------------------------------------

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "mgmtInstP"
 - Distinguished Name: "uni/tn-mgmt/extmgmt-default/instp-{name}"
GUI Location:
 - tenants > mgmt > External Management Network Instance Profiles > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "oob_external_epgs" {
  depends_on = [
    aci_l3_outside.l3outs
  ]
  for_each   = { for k, v in local.l3out_external_epgs : k => v if v.epg_type == "oob" }
  dn         = "uni/tn-mgmt/extmgmt-default/instp-{name}"
  class_name = "mgmtInstP"
  content = {
    annotation = each.value.annotation
    name       = each.value.name
  }
}

#------------------------------------------------
# Assign Contracts to an External EPG
#------------------------------------------------

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvRsIntraEpg"
 - Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{ext_epg}/rsintraEpg-{contract}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {ext_epg}: Contracts
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "external_epg_intra_epg_contracts" {
  depends_on = [
    aci_external_network_instance_profile.l3out_external_epgs,
    aci_rest_managed.oob_external_epgs
  ]
  for_each   = { for k, v in local.l3out_ext_epg_contracts : k => v if local.controller_type == "apic" && v.contract_type == "intra_epg" }
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
 - Consumer Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{ext_epg}/rsintraEpg-{contract}"
 - Interface Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{ext_epg}/rsconsIf-{contract}"
 - Provider Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{ext_epg}/rsprov-{contract}"
 - Taboo Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{ext_epg}/rsprotBy-{contract}"
GUI Location:
 - All Contracts: tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {ext_epg}: Contracts
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "external_epg_contracts" {
  depends_on = [
    aci_external_network_instance_profile.l3out_external_epgs,
    aci_rest_managed.oob_external_epgs
  ]
  for_each = {
    for k, v in local.l3out_ext_epg_contracts : k => v if length(regexall("(intra_epg|taboo)", v.contract_type)
    ) > 0 && local.controller_type == "apic"
  }
  dn = length(regexall(
    "consumed", each.value.contract_type)
    ) > 0 ? "uni/tn-${var.tenant}/out-${each.value.l3out}/instP-${each.value.external_epg}/rscons-${each.value.contract}" : length(regexall(
    "interface", each.value.contract_type)
    ) > 0 ? "uni/tn-${var.tenant}/out-${each.value.l3out}/instP-${each.value.external_epg}/rsconsIf-${each.value.contract}" : length(regexall(
    "provided", each.value.contract_type)
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
    aci_rest_managed.oob_external_epgs
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
 - Distinguised Name: "/uni/tn-{tenant}/out-{l3out}/instP-{ext_epg}/extsubnet-[{subnet}]"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out} > External EPGs > {ext_epg}
_______________________________________________________________________________________________________________________
*/
resource "aci_l3_ext_subnet" "external_epg_subnets" {
  depends_on = [
    aci_external_network_instance_profile.l3out_external_epgs
  ]
  for_each = { for k, v in local.l3out_external_epg_subnets : k => v if v.epg_type != "oob" }
  aggregate = anytrue(
    [
      each.value.aggregate_export,
      each.value.aggregate_import,
      each.value.aggregate_shared_routes
    ]
    ) ? replace(trim(join(",", concat([
      length(regexall(true, each.value.aggregate_export)) > 0 ? "export-rtctrl" : ""], [
      length(regexall(true, each.value.aggregate_import)) > 0 ? "import-rtctrl" : ""], [
      length(regexall(true, each.value.aggregate_shared_routes)) > 0 ? "shared-rtctrl" : ""]
  )), ","), ",,", ",") : "none"
  annotation                           = each.value.annotation
  description                          = each.value.description
  external_network_instance_profile_dn = aci_external_network_instance_profile.l3out_external_epgs[each.value.ext_epg].id
  ip                                   = each.value.subnet
  scope = anytrue(
    [
      each.value.export_route_control_subnet,
      each.value.external_subnets_for_external_epg,
      each.value.import_route_control_subnet,
      each.value.shared_security_import_subnet,
      each.value.shared_route_control_subnet
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.export_route_control_subnet)) > 0 ? "export-rtctrl" : ""], [
      length(regexall(true, each.value.external_subnets_for_external_epg)) > 0 ? "import-security" : ""], [
      length(regexall(true, each.value.import_route_control_subnet)) > 0 ? "import-rtctrl" : ""], [
      length(regexall(true, each.value.shared_security_import_subnet)) > 0 ? "shared-security" : ""], [
      length(regexall(true, each.value.shared_route_control_subnet)) > 0 ? "shared-rtctrl" : ""]
  )) : ["import-security"]
  dynamic "relation_l3ext_rs_subnet_to_profile" {
    for_each = each.value.route_control_profiles
    content {
      direction            = relation_l3ext_rs_subnet_to_profile.value.direction
      tn_rtctrl_profile_dn = "uni/tn-${relation_l3ext_rs_subnet_to_profile.value.tenant}/prof-${relation_l3ext_rs_subnet_to_profile.value.route_map}"
    }
  }
  relation_l3ext_rs_subnet_to_rt_summ = length(
    regexall("[:alnum:]", each.value.route_summarization_policy)) > 0 && length(
    regexall(true, each.value.export_route_control_subnet)
  ) > 0 ? "uni/tn-${local.policy_tenant}/bgprtsum-${each.value.route_summarization_policy}" : ""
}


#------------------------------------------------
# Assign a Subnet to an Out-of-Band External EPG
#------------------------------------------------

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "mgmtSubnet"
 - Distinguished Name: "uni/tn-mgmt/extmgmt-default/instp-{ext_epg}/subnet-[{subnet}]"
GUI Location:
 - tenants > mgmt > External Management Network Instance Profiles > {ext_epg}: Subnets:{subnet}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "oob_external_epg_subnets" {
  depends_on = [
    aci_rest_managed.oob_external_epgs
  ]
  for_each   = { for k, v in local.l3out_external_epg_subnets : k => v if v.epg_type == "oob" }
  dn         = "uni/tn-mgmt/extmgmt-default/instp-${each.value.epg}/subnet-[${each.value.subnet}]"
  class_name = "mgmtSubnet"
  content = {
    ip = each.value.subnet
  }
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
    each.value.send_redistribution_lsas_into_nssa_area,
    each.value.originate_summary_lsa,
    each.value.suppress_forwarding_address
    ]) ? compact(concat([
      length(regexall(true, each.value.send_redistribution_lsas_into_nssa_area)) > 0 ? "redistribute" : ""], [
      length(regexall(true, each.value.originate_summary_lsa)) > 0 ? "summary" : ""], [
    length(regexall(true, each.value.suppress_forwarding_address)) > 0 ? "suppress-fa" : ""]
  )) : ["redistribute", "summary"]
  area_id       = each.value.ospf_area_id
  area_type     = each.value.ospf_area_type
  l3_outside_dn = aci_l3_outside.l3outs[each.value.l3out].id
  # multipod_internal = "no"
}
