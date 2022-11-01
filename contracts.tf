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
resource "aci_contract" "contracts" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each    = { for k, v in local.contracts : k => v if local.controller_type == "apic" && v.contract_type == "standard" }
  tenant_dn   = aci_tenant.tenants[each.value.tenant].id
  annotation  = each.value.annotation
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
 - Distinguished Name: "uni/tn-{tenant}/oobbrc-{contract}"
GUI Location:
 - Tenants > {tenant} > Contracts > Out-Of-Band Contracts: {contract}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "oob_contracts" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each   = { for k, v in local.contracts : k => v if local.controller_type == "apic" && v.contract_type == "oob" }
  dn         = "uni/tn-${each.value.tenant}/oobbrc-${each.key}"
  class_name = "vzOOBBrCP"
  content = {
    # annotation = each.value.annotation
    descr      = each.value.description
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
 - Class: "vzBrCP"
 - Distinguished Name: "uni/tn-{tenant}/taboo-{contract}"
GUI Location:
 - Tenants > {tenant} > Contracts > Taboos: {contract}
_______________________________________________________________________________________________________________________
*/
resource "aci_taboo_contract" "contracts" {
  depends_on = [
    aci_tenant.tenants,
  ]
  for_each    = { for k, v in local.contracts : k => v if local.controller_type == "apic" && v.contract_type == "taboo" }
  tenant_dn   = aci_tenant.tenants[each.value.tenant].id
  annotation  = each.value.annotation
  description = each.value.description
  name        = each.key
  name_alias  = each.value.alias
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzSubj"
 - Distinguished Name: "uni/tn-{tenant}/brc-{contract}/subj-{subject}"
GUI Locations:
 - Tenants > mgmt > Contracts > Standard: {contract} > {subject}
_______________________________________________________________________________________________________________________
*/
resource "aci_contract_subject" "contract_subjects" {
  depends_on = [
    aci_contract.contracts,
    aci_filter.filters,
    aci_rest_managed.oob_contracts,
    aci_taboo_contract.contracts,
  ]
  for_each      = { for k, v in local.contract_subjects : k => v if v.contract_type == "standard" }
  annotation    = each.value.annotation
  contract_dn   = aci_contract.contracts[each.value.contract].id
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
 - Distinguished Name: "uni/tn-{tenant}/taboo-{Name}/subj-{subject}"
GUI Location:
 - Tenants > {tenant} > Contracts > Out-Of-Band Contracts: {name}: Subjects
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
 - Distinguished Name: "uni/tn-{tenant}/taboo-{Name}/subj-{subject}"
GUI Location:
 - Tenants > {tenant} > Contracts > Taboo Contracts: {name}: Subjects
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "taboo_contract_subjects" {
  depends_on = [
    aci_rest_managed.oob_contracts
  ]
  for_each   = { for k, v in local.contract_subjects : k => v if v.contract_type == "taboo" }
  dn         = "${aci_taboo_contract.contracts[each.value.contract].id}/tsubj-${each.value.name}"
  class_name = "vzTSubj"
  content = {
    descr = each.value.description
    name  = each.value.name
  }
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzRsSubjFiltAtt"
 - Distinguished Name: "uni/tn-{tenant}/oobbrc-{name}/subj-{subject}/rssubjFiltAtt-{filter}"
GUI Location:
 - Tenants > {tenant} > Contracts > Out-Of-Band Contracts: {contract}: Subjects
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "contract_subject_filter" {
  depends_on = [
    aci_contract_subject.contract_subjects,
    aci_rest_managed.oob_contract_subjects,
  ]
  for_each = { for k, v in local.subject_filters : k => v if v.contract_type != "taboo" }
  dn = length(regexall("standard", each.value.contract_type)
    ) > 0 ? "${aci_contract.contracts[each.value.contract].id}/subj-${each.value.subject}/rssubjFiltAtt-${each.value.filter}" : length(
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

resource "aci_rest_managed" "taboo_subject_filter" {
  depends_on = [
    aci_rest_managed.taboo_contract_subjects,
  ]
  for_each   = { for k, v in local.subject_filters : k => v if v.contract_type == "taboo" }
  dn         = "${aci_taboo_contract.contracts[each.value.contract].id}/tsubj-${each.value.subject}/rsdenyRule-${each.value.filter}"
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
resource "mso_schema_template_contract" "contracts" {
  provider = mso
  depends_on = [
    mso_schema.schemas,
  ]
  for_each      = { for k, v in local.contracts : k => v if local.controller_type == "ndo" }
  schema_id     = mso_schema.schemas[each.value.schema].id
  template_name = each.value.template
  contract_name = each.key
  display_name  = each.key
  filter_type   = each.value.apply_both_directions == true ? "bothWay" : "oneWay"
  scope         = each.value.scope
  dynamic "filter_relationship" {
    for_each = toset(each.value.filters)
    content {
      filter_schema_id     = mso_schema.schemas[each.value.schema].id
      filter_template_name = each.value.template
      filter_name          = filter_relationship.value
    }
  }
  directives = each.value.log == true ? ["log"] : ["none"]
}
