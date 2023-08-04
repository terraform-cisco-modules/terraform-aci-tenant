#------------------------------------------
# Create a Standard Contract
#------------------------------------------
/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzBrCP"
 - Distinguished Name: "uni/tn-{tenant}/brc-{contract}"
GUI Location:
 - Tenants > {tenant} > Contracts > Standard: {contract}
_______________________________________________________________________________________________________________________
*/
resource "aci_contract" "map" {
  depends_on  = [aci_tenant.map]
  for_each    = { for k, v in local.contracts : k => v if var.controller_type == "apic" && v.contract_type == "standard" }
  tenant_dn   = "uni/tn-${each.value.tenant}"
  description = each.value.description
  name        = each.key
  name_alias  = each.value.alias
  prio        = each.value.qos_class
  scope       = each.value.scope
  target_dscp = each.value.target_dscp
}

#------------------------------------------
# Create a Out-Of-Band Contract
#------------------------------------------

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzOOBBrCP"
 - Distinguished Name: "uni/tn-mgmt/oobbrc-{contract}"
GUI Location:
 - Tenants > mgmt > Contracts > Out-Of-Band Contracts: {contract}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "oob_contracts" {
  depends_on = [aci_tenant.map]
  for_each   = { for k, v in local.contracts : k => v if var.controller_type == "apic" && v.contract_type == "oob" }
  dn         = "uni/tn-${each.value.tenant}/oobbrc-${each.key}"
  class_name = "vzOOBBrCP"
  content = {
    #annotation = "orchestrator:terraform"
    #    descr      = each.value.description
    name       = each.key
    nameAlias  = each.value.alias
    prio       = each.value.qos_class
    scope      = each.value.scope
    targetDscp = each.value.target_dscp
  }
}

#------------------------------------------
# Create a Taboos Contract
#------------------------------------------

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzTaboo"
 - Distinguished Name: "uni/tn-{tenant}/taboo-{contract}"
GUI Location:
 - Tenants > {tenant} > Contracts > Taboos: {contract}
_______________________________________________________________________________________________________________________
*/
resource "aci_taboo_contract" "map" {
  depends_on  = [aci_tenant.map, ]
  for_each    = { for k, v in local.contracts : k => v if var.controller_type == "apic" && v.contract_type == "taboo" }
  tenant_dn   = "uni/tn-${each.value.tenant}"
  description = each.value.description
  name        = each.key
  name_alias  = each.value.alias
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzSubj"
 - Distinguished Name: "uni/tn-{tenant}/brc-{name}/subj-{subject}"
GUI Locations:
 - Tenants > mgmt > Contracts > Standard: {contract} > {subject}
_______________________________________________________________________________________________________________________
*/
resource "aci_contract_subject" "map" {
  depends_on = [
    aci_contract.map,
    aci_filter.map,
    aci_rest_managed.oob_contracts,
    aci_taboo_contract.map,
  ]
  for_each      = { for k, v in local.contract_subjects : k => v if v.contract_type == "standard" }
  contract_dn   = aci_contract.map[each.value.contract].id
  cons_match_t  = each.value.label_match_criteria
  description   = each.value.description
  name          = each.value.name
  prio          = each.value.qos_class
  prov_match_t  = each.value.label_match_criteria
  rev_flt_ports = each.value.apply_both_directions == true ? "yes" : "no"
  target_dscp   = each.value.target_dscp
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzSubj"
 - Distinguished Name: "uni/tn-mgmt/oobbrc-{name}/subj-{subject}"
GUI Location:
 - Tenants > mgmt > Contracts > Out-Of-Band Contracts: {name}: Subjects
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "oob_contract_subjects" {
  depends_on = [
    aci_rest_managed.oob_contracts
  ]
  for_each   = { for k, v in local.contract_subjects : k => v if v.contract_type == "oob" }
  dn         = "uni/tn-${each.value.tenant}/oobbrc-${each.value.contract}/subj-${each.value.name}"
  class_name = "vzSubj"
  content = {
    consMatchT  = each.value.label_match_criteria
    descr       = each.value.description
    name        = each.value.name
    prio        = each.value.qos_class
    provMatchT  = each.value.label_match_criteria
    revFltPorts = each.value.apply_both_directions == true ? "yes" : "no"
    targetDscp  = each.value.target_dscp
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzTSubj"
 - Distinguished Name: "uni/tn-{tenant}/taboo-{name}/subj-{subject}"
GUI Location:
 - Tenants > {tenant} > Contracts > Taboo Contracts: {name}: Subjects
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "taboo_contract_subjects" {
  depends_on = [
    aci_rest_managed.oob_contracts
  ]
  for_each   = { for k, v in local.contract_subjects : k => v if v.contract_type == "taboo" }
  dn         = "${aci_taboo_contract.map[each.value.contract].id}/tsubj-${each.value.name}"
  class_name = "vzTSubj"
  content = {
    descr = each.value.description
    name  = each.value.name
  }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzRsSubjFiltAtt"
 - Distinguished Names:
     "uni/tn-{tenant}/oobbrc-{name}/subj-{subject}/rssubjFiltAtt-{filter}"
     "uni/tn-mgmt/oobbrc-{name}/subj-{subject}/rssubjFiltAtt-{filter}"
GUI Locations:
 - Tenants > {tenant} > Contracts > Standard: {contract}: Subjects
 - Tenants > mgmt > Contracts > Out-Of-Band Contracts: {contract}: Subjects
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "contract_subject_filter" {
  depends_on = [aci_contract_subject.map, aci_rest_managed.oob_contract_subjects, ]
  for_each   = { for k, v in local.subject_filters : k => v if v.contract_type != "taboo" }
  dn = length(regexall("standard", each.value.contract_type)
    ) > 0 ? "${aci_contract.map[each.value.contract].id}/subj-${each.value.subject}/rssubjFiltAtt-${each.value.filter}" : length(
    regexall("oob", each.value.contract_type)
  ) > 0 ? "${aci_rest_managed.oob_contracts[each.value.contract].id}/subj-${each.value.subject}/rssubjFiltAtt-${each.value.filter}" : ""
  class_name = "vzRsSubjFiltAtt"
  content = {
    action = each.value.action
    directives = anytrue(
      [each.value.directives.enable_policy_compression, each.value.directives.log]
      ) ? replace(trim(join(",", concat([
        length(regexall(true, each.value.directives.enable_policy_compression)) > 0 ? "no_stats" : ""], [
        length(regexall(true, each.value.directives.log)) > 0 ? "log" : ""]
    )), ","), ",,", ",") : ""
    # tDn            = each.value.filter
    tnVzFilterName = each.value.filter
  }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzRsDenyRule"
 - Distinguished Name: "uni/tn-{tenant}/taboo-{name}/subj-{subject}/rsdenyRule-{filter}"
GUI Location:
 - Tenants > {tenant} > Contracts > Out-Of-Band Contracts: {contract}: Subjects
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "taboo_subject_filter" {
  depends_on = [aci_rest_managed.taboo_contract_subjects, ]
  for_each   = { for k, v in local.subject_filters : k => v if v.contract_type == "taboo" }
  dn         = "${aci_taboo_contract.map[each.value.contract].id}/tsubj-${each.value.subject}/rsdenyRule-${each.value.filter}"
  class_name = "vzRsDenyRule"
  content = {
    directives = anytrue(
      [each.value.directives.enable_policy_compression, each.value.directives.log]
      ) ? replace(trim(join(",", concat([
        length(regexall(true, each.value.directives.enable_policy_compression)) > 0 ? "no_stats" : ""], [
        length(regexall(true, each.value.directives.log)) > 0 ? "log" : ""]
    )), ","), ",,", ",") : ""
    # tDn            = each.value.filter
    tnVzFilterName = each.value.filter
  }
}


/*_____________________________________________________________________________________________________________________

Nexus Dashboard — Contracts
_______________________________________________________________________________________________________________________
*/
resource "mso_schema_template_contract" "map" {
  provider      = mso
  depends_on    = [mso_schema.map, mso_schema_template_filter_entry.map]
  for_each      = { for k, v in local.contracts : k => v if var.controller_type == "ndo" }
  contract_name = each.key
  directives    = each.value.log == true ? ["log"] : ["none"]
  display_name  = each.key
  filter_type   = each.value.apply_both_directions == true ? "bothWay" : "oneWay"
  schema_id     = data.mso_schema.map[each.value.schema].id
  scope         = each.value.scope
  template_name = each.value.template
  dynamic "filter_relationship" {
    for_each = toset(each.value.filters)
    content {
      filter_schema_id     = mso_schema.map[each.value.schema].id
      filter_template_name = each.value.template
      filter_name          = filter_relationship.value
    }
  }
  lifecycle { ignore_changes = [schema_id] }
}
