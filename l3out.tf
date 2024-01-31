/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extOut"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out}
_______________________________________________________________________________________________________________________
*/
resource "aci_l3_outside" "map" {
  depends_on             = [aci_tenant.map, aci_vrf.map]
  for_each               = { for k, v in local.l3outs : k => v if local.controller.type == "apic" }
  description            = each.value.description
  enforce_rtctrl         = each.value.route_control_enforcement.import == true ? ["export", "import"] : ["export"]
  name                   = each.key
  name_alias             = each.value.alias
  target_dscp            = each.value.target_dscp
  tenant_dn              = "uni/tn-${each.value.tenant}"
  relation_l3ext_rs_ectx = "uni/tn-${each.value.tenant}/ctx-${each.value.vrf}"
  relation_l3ext_rs_l3_dom_att = length(compact([each.value.l3_domain])
  ) > 0 ? "uni/l3dom-${each.value.l3_domain}" : ""
  dynamic "relation_l3ext_rs_dampening_pol" {
    for_each = each.value.route_control_for_dampening
    content {
      af                   = "${relation_l3ext_rs_dampening_pol.value.address_family}-ucast"
      tn_rtctrl_profile_dn = "uni/tn-${local.policy_tenant}/prof-${relation_l3ext_rs_dampening_pol.value.route_map}"
    }
  }
  # Class l3extRsInterleakPol
  relation_l3ext_rs_interleak_pol = length(compact([each.value.route_profile_for_interleak])
  ) > 0 ? "uni/tn-${local.policy_tenant}/prof-${each.value.route_profile_for_interleak}" : ""
  # relation_l3ext_rs_out_to_bd_public_subnet_holder = ["{fvBDPublicSubnetHolder}"]
}

resource "aci_l3out_bgp_external_policy" "map" {
  depends_on    = [aci_l3_outside.map]
  for_each      = { for k, v in local.l3outs : k => v if local.controller.type == "apic" && v.enable_bgp == true }
  l3_outside_dn = aci_l3_outside.map[each.key].id
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
  depends_on = [aci_l3_outside.map]
  for_each = {
    for i in flatten([
      for a, b in local.l3outs : [
        for v in b.annotations : { key = v.key, tenant = b.tenant, l3out = a, value = v.value }
      ]
    ]) : "${i.tenant}:${i.l3out}:${i.key}" => i if local.controller.type == "apic"
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
  depends_on = [aci_l3_outside.map]
  for_each   = { for k, v in local.l3outs : k => v if v.global_alias != "" && local.controller.type == "apic" }
  class_name = "tagAliasInst"
  dn         = "uni/tn-${each.value.tenant}/out-${each.value.l3out}/alias"
  content = {
    name = each.value.global_alias
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "l3extRsRedistributePol"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/rsredistributePol-[{route_profile}]-{src}"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "l3out_route_profiles_for_redistribution" {
  depends_on = [aci_l3_outside.map]
  for_each   = local.l3out_route_profiles_for_redistribution
  dn         = "uni/tn-${each.value.tenant}/out-${each.value.l3out}/rsredistributePol-[${each.value.route_map}]-${each.value.source}"
  class_name = "l3extRsRedistributePol"
  content = {
    src = each.value.source
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
  depends_on = [aci_l3_outside.map]
  for_each   = { for k, v in local.l3outs : k => v if local.controller.type == "apic" && (v.pim == true || v.pimv6 == true) }
  dn         = "uni/tn-${each.value.tenant}/out-${each.key}/pimextp"
  class_name = "pimExtP"
  content = {
    #annotation = each.value.annotation
    enabledAf = anytrue(
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
  depends_on = [aci_l3_outside.map]
  for_each   = { for k, v in local.l3outs : k => v if local.controller.type == "apic" && v.consumer_label == "hcloudGolfLabel" }
  dn         = "uni/tn-${each.value.tenant}/out-${each.key}/conslbl-hcloudGolfLabel"
  class_name = "l3extConsLbl"
  content    = { name = "hcloudGolfLabel" }
}



/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "ospfExtP"
 - Distinguished Name: "uni/tn-{tenant}/out-{l3out}/ospfExtP"
GUI Location:
 - tenants > {tenant} > Networking > L3Outs > {l3out}: OSPF
_______________________________________________________________________________________________________________________
*/
#------------------------------------------------
# Assign a OSPF Routing Policy to the L3Out
#------------------------------------------------
resource "aci_l3out_ospf_external_policy" "map" {
  depends_on = [aci_l3_outside.map]
  for_each   = local.l3out_ospf_external_profile
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
  l3_outside_dn = aci_l3_outside.map[each.value.l3out].id
  # multipod_internal = "no"
}



resource "mso_schema_template_l3out" "map" {
  provider          = mso
  depends_on        = [mso_schema.map]
  for_each          = { for k, v in local.l3outs : k => v if local.controller.type == "ndo" }
  display_name      = each.key
  l3out_name        = each.key
  schema_id         = mso_schema.map[each.value.ndo.schema].id
  template_name     = each.value.ndo.template
  vrf_name          = each.value.vrf
  vrf_schema_id     = mso_schema.map[each.value.ndo.schema].id
  vrf_template_name = each.value.vrf_template
}