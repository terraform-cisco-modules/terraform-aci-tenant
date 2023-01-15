#
# L4-L7 Device Configuration
#
/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vnsLDevVip"
 - Distinguished Name: "uni/tn-{tenant}/lDevVip-{device_name}"
GUI Location:
 - tenants > {tenant} > Services > L4-L7 > Devices
_______________________________________________________________________________________________________________________
*/
#resource "aci_l4_l7_device" "device" {
#  depends_on = [
#    aci_tenant.tenants
#  ]
#  for_each      = local.l4-l7-devices
#  annotation    = each.value.annotation
#  active        = length(regexall(true, each.value.active)) > 0 ? "yes" : "no" # default is no
#  context_aware = each.value.context_aware # multi-Context, single-Context
#  device_type   = each.value.device_type   # CLOUD, PHYSICAL, VIRTUAL
#  function_type = each.value.function_type # GoThrough, GoTo, L1, L2, None; default is GoTo
#  is_copy       = length(regexall(true, each.value.is_copy)) > 0 ? "yes" : "no" # default is no
#  #mode = "legacy-Mode"
#  name             = each.value.name
#  promiscuous_mode = length(regexall(true, each.value.promiscuous_mode)) > 0 ? "yes" : "no" # default is no
#  service_type     = each.value.service_type # ADC, COPY, FW, NATIVELB, OTHERS
#  relation_vns_rs_al_dev_to_phys_dom_p = length(regexall("PHYSICAL", each.value.device_type)
#  ) > 0 ? each.value.physical_domain : ""
#  tenant_dn = "uni/tn-${each.value.tenant}"
#  trunking  = length(regexall(true, each.value.trunking)) > 0 ? "yes" : "no" # default is no
#  dynamic "relation_vns_rs_al_dev_to_dom_p" {
#    for_each       = { for v in [each.value.vmm_domain] : v => v if each.value.device_type == "VIRTUAL" }
#    target_dn      = "uni/vmmp-VMware/dom-${relation_vns_rs_al_dev_to_dom_p.value}"
#    switching_mode = "native"
#  }
#}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vnsLDevVip"
 - Distinguished Name: "uni/tn-{tenant}/lDevVip-{device}/cDev-{concrete_device}"
GUI Location:
 - tenants > {tenant} > Services > L4-L7 > Devices: Devices
_______________________________________________________________________________________________________________________
*/
#resource "aci_concrete_device" "devices" {
#  depends_on = [
#    aci_l4_l7_device.device
#  ]
#  for_each        = local.concrete_devices
#  annotation      = each.value.annotation
#  l4_l7_device_dn = aci_l4_l7_device.device[each.value.l4-l7-device].id
#  name            = each.value.name
#  vmm_controller_dn = length(regexall("VIRTUAL", each.value.device_type)
#  ) > 0 ? "uni/vmmp-VMware/dom-${each.value.vmm_domain}/ctrlr-${each.value.vcenter_name}" : ""
#  vm_name = length(regexall("VIRTUAL", each.value.device_type)
#  ) > 0 ? each.value.vm_name : ""
#}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vnsCIf"
 - Distinguished Name: "uni/tn-{tenant}/lDevVip-{device}/cDev-{concrete_device}/clf-[{concrete_interface}]"
GUI Location:
 - tenants > {tenant} > Services > L4-L7 > Devices: Devices -> Interfaces
_______________________________________________________________________________________________________________________
*/
#resource "aci_concrete_interface" "interfaces" {
#  depends_on = [
#    aci_concrete_device.devices
#  ]
#  for_each           = local.concrete_interfaces
#  concrete_device_dn = aci_concrete_device.devices[each.value.concrete_device].id
#  encap              = length(regexall("VIRTUAL", each.value.device_type)) > 0 ? each.value.encapsulation : "unknown"
#  name               = each.value.name
#  relation_vns_rs_c_if_path_att = length([each.value.name]
#  ) > 0 ? "topology/pod-${each.value.pod_id}/paths-${each.value.node_id}/pathep-[${each.value.interface}]" : ""
#  vnic_name = length(regexall("VIRTUAL", each.value.device_type)) > 0 ? each.value.vnic : ""
#}


#
# L4-L7 Service Graph Templates
#
/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vnsCIf"
 - Distinguished Name: "uni/tn-{tenant}/lDevVip-{device}/cDev-{concrete_device}/clf-[{concrete_interface}]"
GUI Location:
 - tenants > {tenant} > Services > L4-L7 > Devices: Devices -> Interfaces
_______________________________________________________________________________________________________________________
*/
#resource "aci_l4_l7_service_graph_template" "templates" {
#  depends_on = [
#    aci_tenant.tenants
#  ]
#  for_each         = local.l4_l7_service_graph_templates
#  annotation       = each.value.annotation
#  description      = each.value.description
#  name             = each.key
#  tenant_dn        = "uni/tn-${each.value.tenant}"
#  term_prov_name   = each.value.terminal_node_consumer # Default is T1
#  term_cons_name   = each.value.terminal_node_provider # Default is T2
#  ui_template_type = each.value.ui_template_type
#  # ONE_NODE_ADC_ONE_ARM, ONE_NODE_ADC_ONE_ARM_L3EXT, ONE_NODE_ADC_TWO_ARM,
#  # ONE_NODE_FW_ROUTED, ONE_NODE_FW_TRANS, TWO_NODE_FW_ROUTED_ADC_ONE_ARM,
#  # TWO_NODE_FW_ROUTED_ADC_ONE_ARM_L3EXT, TWO_NODE_FW_ROUTED_ADC_TWO_ARM,
#  # TWO_NODE_FW_TRANS_ADC_ONE_ARM, TWO_NODE_FW_TRANS_ADC_ONE_ARM_L3EXT,
#  # TWO_NODE_FW_TRANS_ADC_TWO_ARM and UNSPECIFIED; default is UNSPECIFIED
#  l4_l7_service_graph_template_type = each.value.l4l7_sgt_type # legacy, cloud; default legacy
#}
#
#resource "aci_function_node" "function_nodes" {
#  depends_on = [
#    aci_l4_l7_service_graph_template.templates
#  ]
#  for_each           = local.concrete_interfaces
#  annotation         = each.value.annotation
#  description        = each.value.description
#  func_template_type = each.value.function_template
#  # ADC_ONE_ARM, ADC_TWO_ARM,
#  # CLOUD_NATIVE_FW, CLOUD_NATIVE_LB, CLOUD_VENDOR_FW, CLOUD_VENDOR_LB, 
#  # FW_ROUTED, FW_TRANS, OTHER; default is OTHER
#  func_type = each.value.function_type # GoThrough, GoTo, L1, L2, None; default is GoTo
#  is_copy   = length(regexall(true, each.value.is_copy)) > 0 ? "yes" : "no" # default is no
#  managed   = "no"
#  name      = each.value.name
#  l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.templates[
#    each.value.l4_l7_service_graph_template
#  ].id
#  routing_mode = each.value.routing_mode # Redirect, unspecified
#  share_encap  = length(regexall(true, each.value.share_encapsulation)) > 0 ? "yes" : "no" # default is no
#  #sequence_number    = "1"
#  #relation_vns_rs_node_to_abs_func_prof = ""
#  #relation_vns_rs_node_to_l_dev         = ""
#  #relation_vns_rs_node_to_m_func        = ""
#  #relation_vns_rs_default_scope_to_term = ""
#  #relation_vns_rs_node_to_cloud_l_dev   = ""
#}
#
#resource "aci_connection" "l4_l7_service_graph_connections" {
#  depends_on = [
#    aci_l4_l7_service_graph_template.templates
#  ]
#  for_each       = local.l4_l7_service_graph_connections
#  adj_type       = each.value.adjacency_type # L2, L3; default is L2
#  annotation     = each.value.annotation
#  conn_dir       = each.value.connection_direction # consumer, provider; default is provider
#  conn_type      = each.value.connection_type      # external, internal; default is external
#  description    = each.value.description
#  direct_connect = length(regexall(true, each.value.direct_connect)) > 0 ? "yes" : "no" # default is no
#  name           = each.value.name
#  unicast_route  = length(regexall(true, each.value.unicast_route)) > 0 ? "yes" : "no" # default is yes
#  l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.templates[
#    each.value.l4_l7_service_graph_template
#  ].id
#  relation_vns_rs_abs_connection_conns = [
#    aci_l4_l7_service_graph_template.example.term_cons_dn,
#    aci_function_node.example.conn_consumer_dn
#  ]
#}