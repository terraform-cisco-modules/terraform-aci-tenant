/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzFilter"
 - Distinguished Name: "uni/tn-{Tenant}/flt{filter}"
GUI Location:
 - Tenants > {tenant} > Contracts > Filters: {filter}
_______________________________________________________________________________________________________________________
*/
resource "aci_filter" "filters" {
  depends_on = [
    aci_tenant.tenants
  ]
  for_each                       = { for k, v in local.filters : k => v if local.controller_type == "apic" }
  tenant_dn                      = aci_tenant.tenants[each.value.tenant].id
  annotation                     = each.value.annotation
  description                    = each.value.description
  name                           = each.key
  name_alias                     = each.value.alias
  relation_vz_rs_filt_graph_att  = ""
  relation_vz_rs_fwd_r_flt_p_att = ""
  relation_vz_rs_rev_r_flt_p_att = ""
}

/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "vzEntry"
 - Distinguished Name: "uni/tn-{tenant}/flt{filter}/e-{filter_entry}"
GUI Location:
 - Tenants > {tenant} > Contracts > Filters: {filter} > Filter Entry: {filter_entry}
_______________________________________________________________________________________________________________________
*/
resource "aci_filter_entry" "filter_entries" {
  depends_on = [
    aci_tenant.tenants,
    aci_filter.filters
  ]
  for_each      = { for k, v in local.filter_entries : k => v if local.controller_type == "apic" }
  filter_dn     = aci_filter.filters[each.value.filter_name].id
  description   = each.value.description
  name          = each.key
  name_alias    = each.value.alias
  ether_t       = each.value.ethertype
  prot          = each.value.ip_protocol
  arp_opc       = each.value.arp_flag == "request" ? "req" : each.value.arp_flag
  icmpv4_t      = each.value.icmpv4_type
  icmpv6_t      = each.value.icmpv6_type
  match_dscp    = each.value.match_dscp
  apply_to_frag = each.value.match_only_fragments == true ? "yes" : "no"
  s_from_port   = each.value.source_port_from
  s_to_port     = each.value.source_port_to
  d_from_port   = each.value.destination_port_from
  d_to_port     = each.value.destination_port_to
  stateful      = each.value.stateful == true ? "yes" : "no"
  tcp_rules = anytrue(
    [
      each.value.tcp_session_rules.acknowledgement,
      each.value.tcp_session_rules.established,
      each.value.tcp_session_rules.finish,
      each.value.tcp_session_rules.reset,
      each.value.tcp_session_rules.synchronize
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.tcp_session_rules.acknowledgement)) > 0 ? "ack" : ""], [
      length(regexall(true, each.value.tcp_session_rules.established)) > 0 ? "est" : ""], [
      length(regexall(true, each.value.tcp_session_rules.finish)) > 0 ? "fin" : ""], [
      length(regexall(true, each.value.tcp_session_rules.reset)) > 0 ? "rst" : ""], [
      length(regexall(true, each.value.tcp_session_rules.synchronize)) > 0 ? "syn" : ""]
  )) : ["unspecified"]
}

resource "mso_schema_template_filter_entry" "filter_entries" {
  provider = mso
  depends_on = [
    mso_schema.schemas
  ]
  for_each             = { for k, v in local.filter_entries : k => v if local.controller_type == "ndo" }
  schema_id            = mso_schema.schemas[each.value.schema].id
  template_name        = each.value.template
  display_name         = each.value.filter_name
  entry_name           = each.value.name
  name                 = each.value.filter_name
  entry_display_name   = each.value.name
  ether_type           = each.value.ethertype
  arp_flag             = each.value.arp_flag
  ip_protocol          = each.value.ip_protocol
  match_only_fragments = each.value.match_only_fragments
  source_from          = each.value.source_port_from
  source_to            = each.value.source_port_to
  destination_from     = each.value.destination_port_from
  destination_to       = each.value.destination_port_to
  stateful             = each.value.stateful
  tcp_session_rules = anytrue(
    [
      each.value.tcp_session_rules.acknowledgement,
      each.value.tcp_session_rules.established,
      each.value.tcp_session_rules.finish,
      each.value.tcp_session_rules.reset,
      each.value.tcp_session_rules.synchronize
    ]
    ) ? compact(concat([
      length(regexall(true, each.value.tcp_session_rules.acknowledgement)) > 0 ? "acknowledgement" : ""], [
      length(regexall(true, each.value.tcp_session_rules.established)) > 0 ? "established" : ""], [
      length(regexall(true, each.value.tcp_session_rules.finish)) > 0 ? "finish" : ""], [
      length(regexall(true, each.value.tcp_session_rules.reset)) > 0 ? "reset" : ""], [
      length(regexall(true, each.value.tcp_session_rules.synchronize)) > 0 ? "synchronize" : ""]
  )) : ["unspecified"]
}

