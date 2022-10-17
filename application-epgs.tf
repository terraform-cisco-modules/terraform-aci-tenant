/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvAEPg"
 - Distinguished Name: /uni/tn-{tenant}/ap-{application_profile}/epg-{application_epg}
GUI Location:
Tenants > {tenant} > Application Profiles > {application_profile} > Application EPGs > {application_epg}
_______________________________________________________________________________________________________________________
*/
resource "aci_application_epg" "application_epgs" {
  depends_on = [
    aci_tenant.tenants,
    aci_application_profile.application_profiles,
    aci_bridge_domain.bridge_domains
  ]
  for_each = {
    for k, v in local.application_epgs : k => v if v.epg_type == "standard" && local.controller_type == "apic"
  }
  annotation             = each.value.annotation
  application_profile_dn = aci_application_profile.application_profiles[each.value.application_profile].id
  description            = each.value.description
  exception_tag          = each.value.contract_exception_tag
  flood_on_encap         = each.value.flood_in_encapsulation
  fwd_ctrl               = each.value.intra_epg_isolation == true ? "proxy-arp" : "none"
  has_mcast_source       = each.value.has_multicast_source == true ? "yes" : "no"
  is_attr_based_epg      = each.value.useg_epg == true ? "yes" : "no"
  match_t                = each.value.label_match_criteria
  name                   = each.key
  name_alias             = each.value.alias
  pc_enf_pref            = each.value.intra_epg_isolation
  pref_gr_memb           = each.value.preferred_group_member == true ? "include" : "exclude"
  prio                   = each.value.qos_class
  shutdown               = each.value.epg_admin_state == "admin_shut" ? "yes" : "no"
  relation_fv_rs_bd      = "uni/tn-${each.value.tenant}/BD-${each.value.bridge_domain}"
  relation_fv_rs_sec_inherited = each.value.epg_contract_masters != [] ? [
    for s in each.value.epg_contract_masters : "uni/tn-${each.value.tenant}/ap-${s.application_profile}/epg-${s.application_epg}"
  ] : []
  relation_fv_rs_cust_qos_pol = length(compact([each.value.custom_qos_policy])
  ) > 0 ? "uni/tn-${local.policy_tenant}/qoscustom-${each.value.custom_qos_policy}" : ""
  relation_fv_rs_dpp_pol = each.value.data_plane_policer
  relation_fv_rs_aepg_mon_pol = length(compact([each.value.monitoring_policy])
  ) > 0 ? "uni/tn-${local.policy_tenant}/monepg-${each.value.monitoring_policy}" : ""
  relation_fv_rs_trust_ctrl = length(compact([each.value.fhs_trust_control_policy])
  ) > 0 ? "uni/tn-${local.policy_tenant}/trustctrlpol-${each.value.fhs_trust_control_policy}" : ""
  # relation_fv_rs_graph_def     = each.value.vzGraphCont
}


/*_____________________________________________________________________________________________________________________

* Inband
API Information:
 - Class: "mgmtInB"
 - Distinguished Name: "uni/tn-mgmt/mgmtp-default/inb-{epg}"
GUI Location:
 - Tenants > mgmt > Node Management EPGs > In-Band EPG - {epg}

* Out-of-Band
API Information:
 - Class: "mgmtOoB"
 - Distinguished Name: "uni/tn-mgmt/mgmtp-default/oob-{epg}"
GUI Location:
 - Tenants > mgmt > Node Management EPGs > Out-of-Band EPG - {epg}
_______________________________________________________________________________________________________________________
*/
resource "aci_node_mgmt_epg" "mgmt_epgs" {
  depends_on = [
    aci_bridge_domain.bridge_domains,
  ]
  for_each                 = { for k, v in local.application_epgs : k => v if length(regexall("(inb|oob)", v.epg_type)) > 0 && local.controller_type == "apic" }
  management_profile_dn    = "uni/tn-mgmt/mgmtp-default"
  name                     = each.key
  annotation               = each.value.annotation
  encap                    = each.value.epg_type == "inb" ? "vlan-${each.value.vlan}" : ""
  match_t                  = each.value.epg_type == "inb" ? each.value.label_match_criteria : "AtleastOne"
  name_alias               = each.value.alias
  pref_gr_memb             = "exclude"
  prio                     = each.value.qos_class
  type                     = each.value.epg_type == "inb" ? "in_band" : "out_of_band"
  relation_mgmt_rs_mgmt_bd = each.value.epg_type == "inb" ? "uni/tn-mgmt/BD-${each.value.bridge_domain}" : ""
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAnnotation"
 - Distinguished Name: "uni/tn-{tenant}/ap-{application_profile}/epg-{application_epg}/annotationKey-[{key}]"
GUI Location:
 - Tenants > {tenant} > Application Profiles > {application_profile} > Application EPGs > {application_epg}: {annotations}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "application_epgs_annotations" {
  depends_on = [
    aci_application_epg.application_epgs
  ]
  for_each = {
    for i in flatten([
      for a, b in local.application_epgs : [
        for v in b.annotations : {
          application_profile = b.application_profile
          application_epg     = a
          key                 = v.key
          tenant              = b.tenant
          value               = v.value
        }
      ]
    ]) : "${i.application_profile}-${i.key}" => i if local.controller_type == "apic"
  }
  dn         = "uni/tn-${each.value.tenant}/ap-${each.value.application_profile}/epg-${each.value.application_epg}/annotationKey-[${each.value.key}]"
  class_name = "tagAnnotation"
  content = {
    key   = each.value.key
    value = each.value.value
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "tagAliasInst"
 - Distinguished Name: "uni/tn-{tenant}/ap-{application_profile}/epg-{application_epg}/alias"
GUI Location:
 - Tenants > {tenant} > Application Profiles > {application_profile} > Application EPGs > {application_epg}: global_alias

_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "application_epgs_global_alias" {
  depends_on = [
    aci_application_epg.application_epgs
  ]
  for_each   = { for k, v in local.application_epgs : k => v if v.global_alias != "" && local.controller_type == "apic" }
  class_name = "tagAliasInst"
  dn         = "uni/tn-${each.key}/ap-${each.value.application_profile}/epg-${each.value.application_epg}/alias"
  content = {
    name = each.value.global_alias
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvRsDomAtt"
 - Distinguished Name: /uni/tn-{Tenant}/ap-{App_Profile}/epg-{EPG}/rsdomAtt-[uni/{domain}]
GUI Location:
Tenants > {Tenant} > Application Profiles > {App_Profile} > Application EPGs > {EPG} > Domains (VMs and Bare-Metals)
_______________________________________________________________________________________________________________________
*/
resource "aci_epg_to_domain" "epg_to_domains" {
  depends_on = [
    aci_application_epg.application_epgs
  ]
  for_each           = { for k, v in local.epg_to_domains : k => v if local.controller_type == "apic" && v.epg_type == "standard" }
  application_epg_dn = aci_application_epg.application_epgs[each.value.application_epg].id
  tdn = length(
    regexall("physical", each.value.domain_type)
    ) > 0 ? "uni/phys-${each.value.domain}" : length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? "uni/vmmp-${each.value.switch_provider}/dom-${each.value.domain}" : ""
  annotation = each.value.annotation
  binding_type = length(
    regexall("physical", each.value.domain_type)
    ) > 0 ? "none" : length(regexall(
      "dynamic_binding", each.value.port_binding)) > 0 ? "dynamicBinding" : length(regexall(
      "default", each.value.port_binding)) > 0 ? "none" : length(regexall(
  "static_binding", each.value.port_binding)) > 0 ? "staticBinding" : each.value.port_binding
  allow_micro_seg = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? each.value.allow_micro_segmentation : false
  delimiter = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? each.value.delimiter : ""
  encap = each.value.vlan_mode != "dynamic" && length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? "vlan-${element(each.value.vlans, 0)}" : "unknown"
  encap_mode = each.value.vlan_mode == "static" && length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? "vlan" : "auto"
  epg_cos = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? "Cos0" : "Cos0"
  epg_cos_pref = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? "disabled" : "disabled"
  instr_imedcy = each.value.deploy_immediacy == "on-demand" ? "lazy" : each.value.deploy_immediacy
  enhanced_lag_policy = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? each.value.enhanced_lag_policy : ""
  netflow_dir = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? "both" : "both"
  netflow_pref = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? "disabled" : "disabled"
  num_ports = length(
    regexall("vmm", each.value.domain_type)) > 0 && (length(regexall(
      "dynamic_binding", each.value.port_binding)) > 0 || length(regexall(
    "static_binding", each.value.port_binding)) > 0
  ) ? each.value.number_of_ports : 0
  port_allocation = length(
    regexall("vmm", each.value.domain_type)) > 0 && length(regexall(
    "static_binding", each.value.port_binding)
  ) > 0 ? each.value.port_allocation : "none"
  primary_encap = length(
    regexall("vmm", each.value.domain_type)) > 0 && length(regexall(
    "static", each.value.vlan_mode)) > 0 && length(each.value.vlans
  ) > 1 ? "vlan-${element(each.value.vlans, 1)}" : "unknown"
  primary_encap_inner = length(
    regexall("vmm", each.value.domain_type)) > 0 && length(regexall(
    "static", each.value.vlan_mode)) > 0 && length(each.value.vlans
  ) > 2 ? "vlan-${element(each.value.vlans, 2)}" : "unknown"
  res_imedcy = each.value.resolution_immediacy == "on-demand" ? "lazy" : each.value.resolution_immediacy
  secondary_encap_inner = length(
    regexall("vmm", each.value.domain_type)) > 0 && length(regexall(
    "static", each.value.vlan_mode)) > 0 && length(each.value.vlans
  ) > 3 ? "vlan-${element(each.value.vlans, 3)}" : "unknown"
  switching_mode = "native"
  vmm_allow_promiscuous = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? each.value.security[0]["allow_promiscuous"] : ""
  vmm_forged_transmits = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? each.value.security[0]["forged_transmits"] : ""
  vmm_mac_changes = length(
    regexall("vmm", each.value.domain_type)
  ) > 0 ? each.value.security[0]["mac_changes"] : ""
}


#------------------------------------------
# Assign Contract to EPG
#------------------------------------------

/*_____________________________________________________________________________________________________________________

API Information:
* Consumer Contract
 - Class: "fvRsCons"
 - Distinguished Name: "uni/tn-{tenant}/ap-{application_profile}/epg-{epg}/rscons-{contract}"
* Provider Contract
 - Class: "fvRsProv"
 - Distinguished Name: "uni/tn-{tenant}/ap-{application_profile}/epg-{epg}/rsprov-{contract}"
GUI Location:
 - Tenants > {tenant} > Application Profiles > {application_profile} > Application EPGs > {epg} > Contracts
_______________________________________________________________________________________________________________________
*/
# resource "aci_epg_to_contract" "contract_to_epg" {
#     depends_on          = [
#         aci_tenant.tenants,
#         aci_application_epg.application_epgs,
#         aci_contract.contracts
#     ]
#     application_epg_dn  = aci_application_epg.application_epgs[each.value.application_epg].id
#     contract_dn         = length(regexall(
#       "oob", each.value.type)
#       ) > 0 ? aci_rest_managed.oob_contracts[each.value.contract].id : length(regexall(
#       "standard", each.value.type)
#       ) > 0 ? aci_contract.contracts[each.value.contract].id : length(regexall(
#       "taboo", each.value.type)
#     ) > 0 ? apic_taboo_contracts.contracts[each.value.contract].id : ""
#     contract_type       = each.value.type
# }

resource "aci_rest_managed" "contract_to_epgs" {
  depends_on = [
    aci_contract.contracts,
    aci_taboo_contract.contracts,
  ]
  for_each   = { for k, v in local.contract_to_epgs : k => v if v.epg_type == "standard" }
  dn         = "uni/tn-${each.value.tenant}/ap-${each.value.application_profile}/epg-${each.value.application_epg}/${each.value.contract_dn}-${each.value.contract}"
  class_name = each.value.contract_class
  content = {
    annotation = each.value.annotation
    # matchT = each.value.match_type
    prio = each.value.qos_class
  }
}

resource "aci_rest_managed" "contract_to_oob_epgs" {
  depends_on = [
    aci_contract.contracts,
    aci_rest_managed.oob_contracts,
    aci_taboo_contract.contracts,
  ]
  for_each   = { for k, v in local.contract_to_epgs : k => v if v.epg_type == "oob" && v.contract_type == "provided" }
  dn         = "uni/tn-${each.value.tenant}/mgmtp-default/oob-${each.value.application_epg}/${each.value.contract_dn}-${each.value.contract}"
  class_name = each.value.contract_class
  content = {
    # annotation = each.value.annotation
    # matchT = each.value.match_type
    prio = each.value.qos_class
  }
}

resource "aci_rest_managed" "contract_to_inb_epgs" {
  depends_on = [
    aci_contract.contracts,
    aci_rest_managed.oob_contracts,
    aci_taboo_contract.contracts,
  ]
  for_each   = { for k, v in local.contract_to_epgs : k => v if v.epg_type == "inb" }
  dn         = "uni/tn-${each.value.tenant}/mgmtp-default/inb-${each.value.application_epg}/${each.value.contract_dn}-${each.value.contract}"
  class_name = each.value.contract_class
  content = {
    # annotation = each.value.annotation
    # matchT = each.value.match_type
    prio = each.value.qos_class
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvRsPathAtt"
 - Distinguished Name: "uni/tn-{tenant}/ap-{application_profile}/epg-{application_epg}/{static_path}"
GUI Location:
Tenants > {tenant} > Application Profiles > {application_profile} > Application EPGs > {application_epg} > Static Ports > {GUI_Static}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "epg_to_static_paths" {
  depends_on = [
    aci_application_epg.application_epgs
  ]
  for_each = local.epg_to_static_paths
  dn = length(
    regexall("^pc$", each.value.path_type)
    ) > 0 ? "${aci_application_epg.application_epgs[each.value.epg].id}/rspathAtt-[topology/pod-${each.value.pod}/paths-${element(each.value.nodes, 0)}/pathep-[${each.value.name}]]" : length(
    regexall("^port$", each.value.path_type)
    ) > 0 ? "${aci_application_epg.application_epgs[each.value.epg].id}/rspathAtt-[topology/pod-${each.value.pod}/paths-${element(each.value.nodes, 0)}/pathep-[eth${each.value.name}]]" : length(
    regexall("^vpc$", each.value.path_type)
  ) > 0 ? "${aci_application_epg.application_epgs[each.value.epg].id}/rspathAtt-[topology/pod-${each.value.pod}/protpaths-${element(each.value.nodes, 0)}-${element(each.value.nodes, 1)}/pathep-[${each.value.name}]]" : ""
  class_name = "fvRsPathAtt"
  content = {
    annotation = each.value.annotation
    encap = length(
      regexall("micro_seg", each.value.encapsulation_type)
      ) > 0 ? "vlan-${element(each.value.vlans, 0)}" : length(
      regexall("qinq", each.value.encapsulation_type)
      ) > 0 ? "qinq-${element(each.value.vlans, 0)}-${element(each.value.vlans, 1)}" : length(
      regexall("vlan", each.value.encapsulation_type)
      ) > 0 ? "vlan-${element(each.value.vlans, 0)}" : length(
      regexall("vxlan", each.value.encapsulation_type)
    ) > 0 ? "vxlan-${element(each.value.vlans, 0)}" : ""
    mode = length(
      regexall("dot1p", each.value.mode)
      ) > 0 ? "native" : length(
      regexall("access", each.value.mode)
    ) > 0 ? "untagged" : "regular"
    primaryEncap = each.value.encapsulation_type == "micro_seg" ? "vlan-${element(each.value.vlans, 1)}" : "unknown"
    tDn = length(
      regexall("^pc$", each.value.path_type)
      ) > 0 ? "topology/pod-${each.value.pod}/paths-${element(each.value.nodes, 0)}/pathep-[${each.value.name}]" : length(
      regexall("^port$", each.value.path_type)
      ) > 0 ? "topology/pod-${each.value.pod}/paths-${element(each.value.nodes, 0)}/pathep-[eth${each.value.name}]" : length(
      regexall("^vpc$", each.value.path_type)
    ) > 0 ? "topology/pod-${each.value.pod}/protpaths-${element(each.value.nodes, 0)}-${element(each.value.nodes, 1)}/pathep-[${each.value.name}]" : ""
  }
}


#------------------------------------------------------
# Create Attachable Access Entity Generic Encap Policy
#------------------------------------------------------

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "infraAttEntityP"
 - Distinguished Name: "uni/infra/attentp-{AAEP}"
GUI Location:
 - Fabric > Access Policies > Policies > Global > Attachable Access Entity Profiles : {AAEP}
_______________________________________________________________________________________________________________________
*/
resource "aci_epgs_using_function" "epg_to_aaeps" {
  depends_on = [
    aci_application_epg.application_epgs
  ]
  for_each          = local.epg_to_aaeps
  access_generic_dn = "uni/infra/attentp-${each.value.aaep}/gen-default"
  encap             = length(each.value.vlans) > 0 ? "vlan-${element(each.value.vlans, 0)}" : "unknown"
  instr_imedcy      = each.value.instrumentation_immediacy == "on-demand" ? "lazy" : each.value.instrumentation_immediacy
  mode              = each.value.mode == "trunk" ? "regular" : each.value.mode == "access" ? "untagged" : "native"
  primary_encap     = length(each.value.vlans) > 1 ? "vlan-${element(each.value.vlans, 1)}" : "unknown"
  tdn               = aci_application_epg.application_epgs[each.value.epg].id
}


/*_____________________________________________________________________________________________________________________

Nexus Dashboard — Application Profiles
_______________________________________________________________________________________________________________________
*/
resource "mso_schema_template_anp_epg" "application_epgs" {
  provider = mso
  depends_on = [
    mso_schema_template_anp.application_profiles
  ]
  for_each                   = { for k, v in local.application_epgs : k => v if local.controller_type == "ndo" }
  anp_name                   = each.value.application_profile
  bd_name                    = each.value.bridge_domain
  bd_schema_id               = mso_schema.schemas[each.value.bd_schema].id
  bd_template_name           = each.value.bd_template
  display_name               = each.key
  intra_epg                  = each.value.intra_epg_isolation
  intersite_multicast_source = false
  name                       = each.key
  preferred_group            = each.value.preferred_group_member
  proxy_arp                  = each.value.intra_epg_isolation == true ? true : false
  schema_id                  = mso_schema.schemas[each.value.schema].id
  template_name              = each.value.template
  useg_epg                   = each.value.useg_epg
  vrf_name                   = each.value.vrf
  vrf_schema_id              = mso_schema.schemas[each.value.vrf_schema].id
  vrf_template_name          = each.value.vrf_template
}
