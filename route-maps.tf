/*_____________________________________________________________________________________________________________________

Tenant — Policies — Route-Map Match Rules — Variables
_______________________________________________________________________________________________________________________
*/
resource "aci_match_rule" "route_map_match_rules" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each    = local.route_map_match_rules
  annotation  = each.value.annotation
  description = each.value.description
  name        = each.key
  alias  = each.value.alias
  tenant_dn   = aci_tenant.tenants[each.value.tenant].id
}

resource "aci_rest_managed" "match_community_terms" {
  depends_on = [
    aci_match_rule.route_map_match_rules
  ]
  for_each   = { for k, v in local.match_community_terms : k => v }
  dn         = "uni/tn-${each.value.tenant}/subj-${each.value.match_rule}/commtrm-${each.value.name}"
  class_name = "rtctrlMatchCommTerm"
  content = {
    descr = each.value.description
    name  = each.value.name
    type  = "community"
  }
}

resource "aci_rest_managed" "match_community_factors" {
  depends_on = [
    aci_match_rule.route_map_match_rules
  ]
  for_each   = { for k, v in local.match_community_factors : k => v }
  dn         = "uni/tn-${each.value.tenant}/subj-${each.value.match_rule}/commtrm-${each.value.name}/commfct-${each.value.community}"
  class_name = "rtctrlMatchCommTerm"
  content = {
    descr = each.value.description
    name  = each.value.name
    scope = each.value.scope
    type  = "community"
  }
}

resource "aci_rest_managed" "match_regex_community_terms" {
  depends_on = [
    aci_match_rule.route_map_match_rules
  ]
  for_each   = { for k, v in local.match_regex_community_terms : k => v }
  dn         = "uni/tn-${each.value.tenant}/subj-${each.value.match_rule}/commrxtrm-${each.value.community_type}"
  class_name = "rtctrlMatchCommRegexTerm"
  content = {
    commType = each.value.community_type # regular|extended
    descr    = each.value.description
    name     = each.value.name
    regex    = each.value.regular_expression
    type     = "community-regex"
  }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "rtctrlMatchRtDest"
 - Distinguished Name: "/uni/tn-{tenant}/subj-{match_rule}/dest-[{network}]"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > Match Rules > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_match_route_destination_rule" "match_route_destination_rule" {
  depends_on = [
    aci_match_rule.route_map_match_rules
  ]
  for_each          = { for k, v in local.match_route_destination_rule : k => v }
  aggregate         = each.value.greater_than_mask == 0 && each.value.less_than_mask == 0 ? "no" : "yes"
  annotation        = each.value.annotation
  match_rule_dn     = aci_match_rule.route_map_match_rules[each.value.match_rule].id
  greater_than_mask = each.value.greater_than_mask
  ip                = each.value.ip
  less_than_mask    = each.value.less_than_mask
}
/*_____________________________________________________________________________________________________________________

Tenant — Policies — Route-Map Set Rules — Variables
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "route_map_set_rules" {
  for_each   = local.route_map_set_rules
  dn         = "uni/tn-${each.value.tenant}/attr-${each.key}"
  class_name = "rtctrlAttrP"
  content = {
    # annotation = each.value.annotation
    descr     = each.value.description
    name      = each.key
    nameAlias = each.value.alias
  }
}

resource "aci_rest_managed" "route_map_set_rules_set_community_none" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { 
    for k, v in local.set_rule_set_community : k => v if length(regexall("(none|replace)", v.criteria)) > 0 
    }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/scomm"
  class_name = "rtctrlSetAddComm"
  content = {
    community   = each.value.criteria == "none" ? "unknown:unknown:0:0" : each.value.community
    descr       = each.value.description
    setCriteria = each.value.criteria
    type        = "community"
  }
}

resource "aci_rest_managed" "route_map_set_rules_set_community" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_communities : k => v }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/saddcomm-${each.value.community}"
  class_name = "rtctrlSetAddComm"
  content = {
    community   = each.value.community
    descr       = each.value.description
    setCriteria = each.value.criteria # append|none|replace
    type        = "community"
  }
}

resource "aci_rest_managed" "route_map_rules_multipath" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_rules : k => v if v.type == "multipath" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/redistmpath"
  class_name = "rtctrlSetRedistMultipath"
  content = {
    type = "redist-multipath"
  }
}

resource "aci_rest_managed" "route_map_rules_set_as_path" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_asn_rules : k => v if v.type == "set_as_path" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/saspath-${each.value.set_criteria}"
  class_name = "rtctrlSetASPath"
  content = {
    criteria = each.value.criteria # prepend|prepend-last-as
    lastnum  = each.value.criteria == "prepend-last-as" ? each.value.last_as_count : 0
    type     = "as-path"
  }
  dynamic "child" {
    for_each = each.value.autonomous_systems
    content {
      class_name = "rtctrlSetASPathASN"
      rn         = "asn-${child.value.order}"
      content = {
        asn   = child.value.asn
        order = child.value.order
      }
    }
  }
}

resource "aci_rest_managed" "route_map_rules_set_communities" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_communities : k => v if v.type == "set_communities" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/scomm"
  class_name = "rtctrlSetComm"
  content = {
    community   = each.value.community
    setCriteria = each.value.set_criteria # append|none|replace
    type        = "community"
  }
}

resource "aci_rest_managed" "route_map_rules_set_dampening" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_rules : k => v if v.type == "set_dampening" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/sdamp"
  class_name = "rtctrlSetDamp"
  content = {
    halfLife        = each.value.half_life         # 15 1-60
    maxSuppressTime = each.value.max_suppress_time # 60 1-255
    reuse           = each.value.reuse_limit       # 750 1-20000
    suppress        = each.value.suppress_limit    # 2000 1-20000
    type            = "dampening-pol"
  }
}

resource "aci_rest_managed" "route_map_rules_set_metric" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_rules : k => v if v.type == "set_metric" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/smetric"
  class_name = "rtctrlSetRtMetric"
  content = {
    metric = each.value.metric # 1 minimum
    type   = "metric"
  }
}

resource "aci_rest_managed" "route_map_rules_set_metric_type" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_rules : k => v if v.type == "set_metric_type" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/smetrict"
  class_name = "rtctrlSetRtMetricType"
  content = {
    metricType = each.value.metric_type # ospf-type1|ospf-type2
    type       = "metric-type"
  }
}

resource "aci_rest_managed" "route_map_rules_set_next_hop" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_rules : k => v if v.type == "set_next_hop" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/nh"
  class_name = "rtctrlSetNh"
  content = {
    addr = each.value.address
    type = "ip-nh"
  }
}

resource "aci_rest_managed" "route_map_rules_set_next_hop_unchanged" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_rules : k => v if v.type == "set_next_hop_unchanged" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/nhunchanged"
  class_name = "rtctrlSetNhUnchanged"
  content = {
    type = "nh-unchanged"
  }
}

resource "aci_rest_managed" "route_map_rules_set_preference" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_rules : k => v if v.type == "set_preference" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/spref"
  class_name = "rtctrlSetPref"
  content = {
    localPref = each.value.preference
    type      = "local-pref"
  }
}

resource "aci_rest_managed" "route_map_rules_set_route_tag" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_rules : k => v if v.type == "set_route_tag" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/srttag"
  class_name = "rtctrlSetTag"
  content = {
    tag  = each.value.route_tag
    type = "rt-tag"
  }
}

resource "aci_rest_managed" "route_map_set_weight" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.set_rule_rules : k => v if v.type == "set_weight" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/sweight"
  class_name = "rtctrlSetWeight"
  content = {
    weight = each.value.weight
    type   = "rt-weight"
  }
}

/*_____________________________________________________________________________________________________________________

Tenant — Policies — Route-Maps for Route Control — Variables
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "route_maps_for_route_control" {
  for_each   = local.route_maps_for_route_control
  dn         = "uni/tn-${each.value.tenant}/prof-${each.key}"
  class_name = "rtctrlProfile"
  content = {
    # annotation   = each.value.annotation
    autoContinue = each.value.route_map_continue == true ? "yes" : "no"
    descr        = each.value.description
    name         = each.key
  }
}

resource "aci_rest_managed" "route_maps_contexts" {
  depends_on = [
    aci_match_rule.route_map_match_rules
  ]
  for_each   = local.route_maps_context_rules
  dn         = "uni/tn-${each.value.tenant}/prof-${each.value.route_map}/ctx-${each.value.ctx_name}"
  class_name = "rtctrlCtxP"
  content = {
    action = each.value.action
    # annotation = each.value.annotation
    descr = each.value.description
    name  = each.value.name
    order = each.value.order
  }
  child {
    class_name = "rtctrlRsCtxPToSubjP"
    rn         = "rsctxPToSubjP-${each.value.name}"
    content = {
      tnRtctrlSubjPName = each.value.name
    }
  }
}

resource "aci_rest_managed" "route_maps_context_set_rules" {
  depends_on = [
    aci_rest_managed.route_map_set_rules,
    aci_rest_managed.route_maps_contexts
  ]
  for_each   = { for k, v in local.route_maps_context_rules : k => v if v.set_rule != "" }
  dn         = "uni/tn-${each.value.tenant}/prof-${each.value.route_map}/ctx-${each.value.ctx_name}/scp"
  class_name = "rtctrlScope"
  content = {
  }
  child {
    class_name = "rtctrlRsScopeToAttrP"
    rn         = "rsScopeToAttrP"
    content = {
      tnRtctrlAttrPName = each.value.set_rule
    }
  }
}
