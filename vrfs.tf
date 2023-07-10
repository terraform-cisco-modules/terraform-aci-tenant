/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvCtx"
 - Distinguished Name: "uni/tn-{tenant}/ctx-{vrf}"
GUI Location:
 - Tenants > {tenant} > Networking > VRFs > {vrf}
_______________________________________________________________________________________________________________________
*/
resource "aci_vrf" "map" {
  depends_on = [aci_tenant.map]
  for_each   = { for k, v in local.vrfs : k => v if var.controller_type == "apic" && v.create == true }
  #  bd_enforced_enable     = each.value.bd_enforcement_status == true ? "yes" : "no"
  description            = each.value.description
  ip_data_plane_learning = each.value.ip_data_plane_learning
  knw_mcast_act          = each.value.layer3_multicast == true ? "permit" : "deny"
  name                   = each.key
  name_alias             = each.value.alias
  pc_enf_dir             = each.value.policy_control_enforcement_direction
  pc_enf_pref            = each.value.policy_control_enforcement_preference
  # relation_fv_rs_ctx_to_ep_ret = length(regexall(
  #   "[[:alnum:]]", each.value.endpoint_retention_policy)
  # ) > 0 ? aci_end_point_retention_policy.endpoint_retention_policies[each.value.endpoint_retention_policy].id : ""
  relation_fv_rs_ctx_mon_pol = length(regexall(
    "uni\\/tn\\-", each.value.monitoring_policy)
    ) > 0 ? each.value.monitoring_policy : length(regexall(
    "[[:alnum:]]", each.value.monitoring_policy)
  ) > 0 ? "uni/tn-${each.value.policy_tenant}/monepg-${each.value.monitoring_policy}" : ""
  relation_fv_rs_bgp_ctx_pol = length(regexall(
    "uni\\/tn\\-", each.value.bgp_timers)
    ) > 0 ? each.value.bgp_timers : length(regexall(
    "[[:alnum:]]", each.value.bgp_timers)
  ) > 0 ? "uni/tn-${each.value.policy_tenant}/bgpCtxP-${each.value.bgp_timers}" : ""
  dynamic "relation_fv_rs_ctx_to_bgp_ctx_af_pol" {
    for_each = each.value.bgp_timers_per_address_family
    content {
      af = "${relation_fv_rs_ctx_to_bgp_ctx_af_pol.value.address_family}-ucast"
      tn_bgp_ctx_af_pol_name = length(regexall(
        "uni\\/tn\\-", relation_fv_rs_ctx_to_bgp_ctx_af_pol.value.policy)
        ) > 0 ? relation_fv_rs_ctx_to_bgp_ctx_af_pol.value.policy : length(regexall(
        "[[:alnum:]]", relation_fv_rs_ctx_to_bgp_ctx_af_pol.value.policy)
      ) > 0 ? "uni/tn-${each.value.policy_tenant}/bgpCtxAfP-${relation_fv_rs_ctx_to_bgp_ctx_af_pol.value.policy}" : ""
    }
  }
  dynamic "relation_fv_rs_ctx_to_eigrp_ctx_af_pol" {
    for_each = each.value.eigrp_timers_per_address_family
    content {
      af = "${relation_fv_rs_ctx_to_eigrp_ctx_af_pol.value.address_family}-ucast"
      tn_eigrp_ctx_af_pol_name = length(regexall(
        "uni\\/tn\\-", relation_fv_rs_ctx_to_eigrp_ctx_af_pol.value.policy)
        ) > 0 ? relation_fv_rs_ctx_to_eigrp_ctx_af_pol.value.policy : length(regexall(
        "[[:alnum:]]", relation_fv_rs_ctx_to_eigrp_ctx_af_pol.value.policy)
      ) > 0 ? "uni/tn-${each.value.policy_tenant}/eigrpCtxAfP-${relation_fv_rs_ctx_to_eigrp_ctx_af_pol.value.policy}" : ""
    }
  }
  relation_fv_rs_ospf_ctx_pol = length(regexall(
    "uni\\/tn\\-", each.value.ospf_timers)
    ) > 0 ? each.value.ospf_timers : length(regexall(
    "[[:alnum:]]", each.value.ospf_timers)
  ) > 0 ? "uni/tn-${each.value.policy_tenant}/ospfCtxP-${each.value.ospf_timers}" : ""
  dynamic "relation_fv_rs_ctx_to_ospf_ctx_pol" {
    for_each = each.value.ospf_timers_per_address_family
    content {
      af = "${relation_fv_rs_ctx_to_ospf_ctx_pol.value.address_family}-ucast"
      tn_ospf_ctx_pol_name = length(regexall(
        "uni\\/tn\\-", relation_fv_rs_ctx_to_ospf_ctx_pol.value.policy)
        ) > 0 ? relation_fv_rs_ctx_to_ospf_ctx_pol.value.policy : length(regexall(
        "[[:alnum:]]", relation_fv_rs_ctx_to_ospf_ctx_pol.value.policy)
      ) > 0 ? "uni/tn-${each.value.policy_tenant}/ospfCtxP-${relation_fv_rs_ctx_to_ospf_ctx_pol.value.policy}" : ""
    }
  }
  relation_fv_rs_ctx_to_ext_route_tag_pol = length(regexall(
    "uni\\/tn\\-", each.value.transit_route_tag_policy)
    ) > 0 ? each.value.transit_route_tag_policy : length(regexall(
    "[[:alnum:]]", each.value.transit_route_tag_policy)
  ) > 0 ? "uni/tn-${each.value.policy_tenant}/rttag-${each.value.transit_route_tag_policy}" : ""
  # relation_fv_rs_ctx_mcast_to             = ["{vzFilter}"]
  tenant_dn = "uni/tn-${each.value.tenant}"
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "snmpCtxP"
 - Distinguished Name: "uni/tn-{tenant}/ctx-{vrf}/any"
GUI Location:
 - Tenants > {tenant} > Networking > VRFs > {vrf}: Policy >  Preferred Group
 - Tenants > {tenant} > Networking > VRFs > {vrf} > EPG|ESG Collection for VRF
_______________________________________________________________________________________________________________________
*/
resource "aci_any" "vz_any" {
  depends_on   = [aci_vrf.map]
  for_each     = { for k, v in local.vrfs : k => v if var.controller_type == "apic" && v.create == true }
  description  = each.value.description
  pref_gr_memb = each.value.preferred_group == true ? "enabled" : "disabled"
  match_t      = each.value.epg_esg_collection_for_vrfs.label_match_criteria
  vrf_dn       = aci_vrf.map[each.key].id
  lifecycle { ignore_changes = [relation_vz_rs_any_to_cons, relation_vz_rs_any_to_prov] }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAnnotation"
 - Distinguished Name: "uni/tn-{tenant}/ctx-{vrf}/annotationKey-[{key}]"
GUI Location:
 - Tenants > {tenant} > Networking > VRFs > {vrf}: {annotations}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "vrf_annotations" {
  depends_on = [aci_vrf.map]
  for_each = {
    for i in flatten([
      for a, b in local.vrfs : [
        for v in b.annotations : { create = b.create, key = v.key, tenant = b.tenant, vrf = a, value = v.value }
      ]
    ]) : "${i.tenant}:${i.vrf}:${i.key}" => i if var.controller_type == "apic" && i.create == true
  }
  dn         = "uni/tn-${each.value.tenant}/ctx-${each.value.vrf}/annotationKey-[${each.value.key}]"
  class_name = "tagAnnotation"
  content = {
    key   = each.value.key
    value = each.value.value
  }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAliasInst"
 - Distinguished Name: "uni/tn-{tenant}/ctx-{vrf}/alias"
GUI Location:
 - Tenants > {tenant} > Networking > VRFs > {vrf}: global_alias

_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "vrf_global_alias" {
  depends_on = [aci_vrf.map]
  for_each   = { for k, v in local.vrfs : k => v if v.global_alias != "" && var.controller_type == "apic" && v.create == true }
  class_name = "tagAliasInst"
  dn         = "uni/tn-${each.value.tenant}/ctx-${each.value.vrf}/alias"
  content = {
    name = each.value.global_alias
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "snmpCtxP"
 - Distinguished Name: "uni/tn-{tenant}/ctx-{vrf}/snmpctx"
GUI Location:
 - Tenants > {tenant} > Networking > VRFs > {vrf} > Create SNMP Context
_______________________________________________________________________________________________________________________
*/
resource "aci_vrf_snmp_context" "map" {
  depends_on = [aci_vrf.map]
  for_each   = { for k, v in local.vrfs : k => v if var.controller_type == "apic" && v.create == true }
  name       = each.key
  vrf_dn     = aci_vrf.map[each.key].id
}


/*_____________________________________________________________________________________________________________________

GUI Location:
Tenants > {tenant} > Networking > VRFs > {vrf} > Create SNMP Context: Community Profiles
_______________________________________________________________________________________________________________________
*/
resource "aci_snmp_community" "vrf_communities" {
  depends_on = [aci_vrf_snmp_context.map]
  for_each = { for i in flatten([
    for k, v in local.vrfs : [
      for s in v.communities : {
        community_variable = s.community_variable
        description        = lookup(s, "description", "")
        vrf                = k
      }
    ]
    ]) : "${i.vrf}:${i.community_variable}" => i if var.controller_type == "apic"
  }
  description = each.value.description
  name = length(regexall(
    5, each.value.community_variable)) > 0 ? var.vrf_snmp_community_5 : length(regexall(
    4, each.value.community_variable)) > 0 ? var.vrf_snmp_community_4 : length(regexall(
    3, each.value.community_variable)) > 0 ? var.vrf_snmp_community_3 : length(regexall(
  2, each.value.community_variable)) > 0 ? var.vrf_snmp_community_2 : var.vrf_snmp_community_1
  parent_dn = aci_vrf_snmp_context.map[each.value.vrf].id
}
/*_____________________________________________________________________________________________________________________

GUI Location:
 - Tenants > {tenant} > Networking > VRFs > {vrf} > EPG Collection for VRF: [Provided/Consumed Contracts]
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "vzany_provider_contracts" {
  depends_on = [
    aci_contract.map
  ]
  for_each   = { for k, v in local.vzany_contracts : k => v if var.controller_type == "apic" && v.contract_type == "provided" }
  dn         = "uni/tn-${each.value.tenant}/ctx-${each.value.vrf}/any/rsanyToProv-${each.value.contract}"
  class_name = "vzRsAnyToProv"
  content = {
    #    matchT       = each.value.label_match_criteria
    prio         = each.value.qos_class
    tnVzBrCPName = each.value.contract
  }
}

resource "aci_rest_managed" "vzany_contracts" {
  depends_on = [aci_contract.map]
  for_each   = { for k, v in local.vzany_contracts : k => v if var.controller_type == "apic" && v.contract_type != "provided" }
  dn = length(regexall(
    "consumed", each.value.contract_type)
    ) > 0 ? "uni/tn-${each.value.tenant}/ctx-${each.value.vrf}/any/rsanyToCons-${each.value.contract}" : length(regexall(
    "interface", each.value.contract_type)
  ) > 0 ? "uni/tn-${each.value.tenant}/ctx-${each.value.vrf}/any/rsanyToConsif-${each.value.contract}" : ""
  class_name = length(regexall(
    "consumed", each.value.contract_type)
    ) > 0 ? "vzRsAnyToCons" : length(regexall(
    "interface", each.value.contract_type)
  ) > 0 ? "vzRsAnyToConsIf" : ""
  content = {
    #    prio         = each.value.qos_class
    tnVzBrCPName = each.value.contract
  }
}


/*_____________________________________________________________________________________________________________________

Nexus Dashboard — VRFs
_______________________________________________________________________________________________________________________
*/
resource "mso_schema_template_vrf" "map" {
  provider               = mso
  depends_on             = [mso_tenant.map, mso_schema.map]
  for_each               = { for k, v in local.vrfs : k => v if var.controller_type == "ndo" && v.create == true }
  display_name           = each.key
  ip_data_plane_learning = each.value.ip_data_plane_learning
  name                   = each.key
  layer3_multicast       = each.value.layer3_multicast
  preferred_group        = each.value.preferred_group
  schema_id              = data.mso_schema.map[each.value.ndo.schema].id
  template               = each.value.ndo.template
  vzany                  = length(each.value.epg_esg_collection_for_vrfs.contracts) > 0 ? true : false
  lifecycle { ignore_changes = [schema_id] }
}

resource "mso_schema_site_vrf" "map" {
  provider      = mso
  depends_on    = [mso_schema_template_vrf.map, ]
  for_each      = { for k, v in local.vrf_sites : k => v if var.controller_type == "ndo" && v.create == true }
  schema_id     = data.mso_schema.map[each.value.schema].id
  site_id       = data.mso_site.map[each.value.site].id
  template_name = each.value.template
  vrf_name      = each.value.vrf
  lifecycle { ignore_changes = [schema_id, site_id] }
}

resource "mso_schema_template_vrf_contract" "map" {
  provider          = mso
  depends_on        = [mso_schema_template_vrf.map]
  for_each          = { for k, v in local.vzany_contracts : k => v if var.controller_type == "ndo" }
  schema_id         = data.mso_schema.map[each.value.schema].id
  template_name     = each.value.template
  vrf_name          = each.value.vrf
  relationship_type = each.value.contract_type
  contract_name     = each.value.contract
  contract_schema_id = length(regexall(
    each.value.tenant, each.value.contract_tenant)
    ) > 0 ? data.mso_schema.map[each.value.contract_schema].id : length(regexall(
    "[[:alnum:]]+", each.value.contract_tenant)
  ) > 0 ? data.mso_schema.map[each.value.contract_schema].id : ""
  contract_template_name = each.value.contract_template
  lifecycle { ignore_changes = [contract_schema_id, schema_id] }
}

