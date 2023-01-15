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
  name_alias  = each.value.alias
  tenant_dn   = "uni/tn-${each.value.tenant}"
}

resource "aci_rest_managed" "match_rules_match_community_terms" {
  depends_on = [
    aci_match_rule.route_map_match_rules
  ]
  for_each   = local.match_rules_match_community_terms
  dn         = "uni/tn-${each.value.tenant}/subj-${each.value.match_rule}/commtrm-${each.value.name}"
  class_name = "rtctrlMatchCommTerm"
  content = {
    descr = each.value.description
    name  = each.value.name
    type  = "community"
  }
  dynamic "child" {
    for_each = each.value.match_community_factors
    content {
      class_name = "rtctrlMatchCommTerm"
      rn         = "commfct-${each.value.community}"
      content = {
        community = each.value.community
        descr     = each.value.description
        scope     = each.value.scope
        type      = "community"
      }
    }
  }
}

resource "aci_rest_managed" "match_rules_match_regex_community_terms" {
  depends_on = [
    aci_match_rule.route_map_match_rules
  ]
  for_each   = local.match_rules_match_regex_community_terms
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
 - Distinguished Name: "uni/tn-{tenant}/subj-{match_rule}/dest-[{network}]"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > Match Rules > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_match_route_destination_rule" "match_rules_match_route_destination_rule" {
  depends_on = [
    aci_match_rule.route_map_match_rules
  ]
  for_each          = local.match_rules_match_route_destination_rule
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

resource "aci_rest_managed" "set_rules_additional_communities" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = local.set_rules_additional_communities
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/saddcomm-${each.value.community}"
  class_name = "rtctrlSetAddComm"
  content = {
    community   = each.value.community
    descr       = each.value.description
    setCriteria = "append"
    type        = "community"
  }
}

resource "aci_rest_managed" "set_rules_multipath" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.route_map_set_rules : k => v if v.multipath == true }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/redistmpath"
  class_name = "rtctrlSetRedistMultipath"
  content = {
    type = "redist-multipath"
  }
}

resource "aci_rest_managed" "set_rules_next_hop_propegation" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.route_map_set_rules : k => v if v.next_hop_propegation == true }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/nhunchanged"
  class_name = "rtctrlSetNhUnchanged"
  content = {
    type = "nh-unchanged"
  }
}

resource "aci_rest_managed" "set_rules_set_as_path" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = local.set_rules_set_as_path
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

resource "aci_rest_managed" "route_map_set_rules_set_communities" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = local.set_rules_set_communities
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/scomm"
  class_name = "rtctrlSetAddComm"
  content = {
    community   = each.value.criteria == "none" ? "unknown:unknown:0:0" : each.value.community
    descr       = each.value.description
    setCriteria = each.value.criteria # append|none|replace
    type        = "community"
  }
}

resource "aci_rest_managed" "route_map_set_rules_set_external_epg" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = local.set_rules_set_external_epg
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/sptag"
  class_name = "rtctrlSetPolicyTag"
  content = {
    type = "policy-tag"
  }
  child {
    class_name = "rtctrlRsSetPolicyTagToInstP"
    rn         = "rssetPolicyTagToInstP"
    content = {
      # forceResolve = "yes"
      # rType        = "mo"
      # tCl          = "l3extInstP"
      tDn = "uni/tn-${each.value.epg_tenant}/out-${each.value.l3out}/instP-${each.value.external_epg}"
      # tType        = "mo"
    }
  }
}

resource "aci_rest_managed" "route_map_set_rules_set_dampening" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = local.set_rules_set_dampening
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

resource "aci_rest_managed" "route_map_set_rules_set_metric" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.route_map_set_rules : k => v if v.set_metric > 0 }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/smetric"
  class_name = "rtctrlSetRtMetric"
  content = {
    metric = each.value.metric # 1 minimum
    type   = "metric"
  }
}

resource "aci_rest_managed" "route_map_set_rules_set_metric_type" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.route_map_set_rules : k => v if v.set_metric_type != "" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/smetrict"
  class_name = "rtctrlSetRtMetricType"
  content = {
    metricType = each.value.metric_type # ospf-type1|ospf-type2
    type       = "metric-type"
  }
}

resource "aci_rest_managed" "route_map_set_rules_set_next_hop_address" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.route_map_set_rules : k => v if v.set_next_hop_address != "" }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/nh"
  class_name = "rtctrlSetNh"
  content = {
    addr = each.value.address
    type = "ip-nh"
  }
}

resource "aci_rest_managed" "route_map_set_rules_set_preference" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.route_map_set_rules : k => v if v.set_preference > 0 }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/spref"
  class_name = "rtctrlSetPref"
  content = {
    localPref = each.value.preference
    type      = "local-pref"
  }
}

resource "aci_rest_managed" "route_map_set_rules_set_route_tag" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.route_map_set_rules : k => v if v.set_route_tag > 0 }
  dn         = "uni/tn-${each.value.tenant}/attr-${each.value.set_rule}/srttag"
  class_name = "rtctrlSetTag"
  content = {
    tag  = each.value.route_tag
    type = "rt-tag"
  }
}

resource "aci_rest_managed" "route_map_set_rules_set_weight" {
  depends_on = [
    aci_rest_managed.route_map_set_rules
  ]
  for_each   = { for k, v in local.route_map_set_rules : k => v if v.set_weight > 0 }
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
  for_each   = local.route_map_contexts
  dn         = "uni/tn-${each.value.tenant}/prof-${each.value.route_map}/ctx-${each.value.ctx_name}"
  class_name = "rtctrlCtxP"
  content = {
    action = each.value.action
    # annotation = each.value.annotation
    descr = each.value.description
    name  = each.value.name
    order = each.value.order
  }
  dynamic "child" {
    for_each = { for v in each.value.match_rules : v.rule_name => v }
    content {
      class_name = "rtctrlRsCtxPToSubjP"
      rn         = "rsctxPToSubjP-${each.value.rule_name}"
      content = {
        tnRtctrlSubjPName = each.value.rule_name
      }
    }
  }
}

resource "aci_rest_managed" "route_maps_context_set_rules" {
  depends_on = [
    aci_rest_managed.route_maps_contexts
  ]
  for_each   = { for k, v in local.route_map_contexts : k => v if v.set_rule != "" }
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
