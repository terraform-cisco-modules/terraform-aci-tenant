<!-- BEGIN_TF_DOCS -->
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Developed by: Cisco](https://img.shields.io/badge/Developed%20by-Cisco-blue)](https://developer.cisco.com)

# Terraform ACI - Admin Module

A Terraform module to configure ACI Admin Policies.

This module is part of the Cisco [*Intersight as Code*](https://cisco.com/go/intersightascode) project. Its goal is to allow users to instantiate network fabrics in minutes using an easy to use, opinionated data model. It takes away the complexity of having to deal with references, dependencies or loops. By completely separating data (defining variables) from logic (infrastructure declaration), it allows the user to focus on describing the intended configuration while using a set of maintained and tested Terraform Modules without the need to understand the low-level Intersight object model.

A comprehensive example using this module is available here: https://github.com/terraform-cisco-modules/easy-aci-complete

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aci"></a> [aci](#requirement\_aci) | >=2.9.0 |
| <a name="requirement_mso"></a> [mso](#requirement\_mso) | >=0.11.0 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aci"></a> [aci](#provider\_aci) | 2.9.0 |
| <a name="provider_mso"></a> [mso](#provider\_mso) | 0.11.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_model"></a> [model](#input\_model) | Model data. | `any` | n/a | yes |
| <a name="input_templates"></a> [templates](#input\_templates) | Name of the Tenant | `any` | n/a | yes |
| <a name="input_aaep_to_epgs"></a> [aaep\_to\_epgs](#input\_aaep\_to\_epgs) | AAEP to EPGs VLAN Mapping from Access Module. | `any` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Name of the Tenant | `any` | n/a | yes |
| <a name="input_annotations"></a> [annotations](#input\_annotations) | The Version of this Script. | <pre>list(object(<br>    {<br>      key   = string<br>      value = string<br>    }<br>  ))</pre> | <pre>[<br>  {<br>    "key": "orchestrator",<br>    "value": "terraform:easy-aci:v2.0"<br>  }<br>]</pre> | no |
| <a name="input_controller_type"></a> [controller\_type](#input\_controller\_type) | The Type of Controller for this Site.<br>- apic<br>- ndo | `string` | `"apic"` | no |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | AWS Secret Key Id. It must be provided if the AWS account is not trusted. This parameter will only have effect with vendor = aws. | `string` | `""` | no |
| <a name="input_azure_client_secret"></a> [azure\_client\_secret](#input\_azure\_client\_secret) | Azure Client Secret. It must be provided when azure\_access\_type to credentials. This parameter will only have effect with vendor = azure. | `string` | `"1"` | no |
| <a name="input_bgp_password_1"></a> [bgp\_password\_1](#input\_bgp\_password\_1) | BGP Password 1. | `string` | `""` | no |
| <a name="input_bgp_password_2"></a> [bgp\_password\_2](#input\_bgp\_password\_2) | BGP Password 2. | `string` | `""` | no |
| <a name="input_bgp_password_3"></a> [bgp\_password\_3](#input\_bgp\_password\_3) | BGP Password 3. | `string` | `""` | no |
| <a name="input_bgp_password_4"></a> [bgp\_password\_4](#input\_bgp\_password\_4) | BGP Password 4. | `string` | `""` | no |
| <a name="input_bgp_password_5"></a> [bgp\_password\_5](#input\_bgp\_password\_5) | BGP Password 5. | `string` | `""` | no |
| <a name="input_ospf_key_1"></a> [ospf\_key\_1](#input\_ospf\_key\_1) | OSPF Key 1. | `string` | `""` | no |
| <a name="input_ospf_key_2"></a> [ospf\_key\_2](#input\_ospf\_key\_2) | OSPF Key 2. | `string` | `""` | no |
| <a name="input_ospf_key_3"></a> [ospf\_key\_3](#input\_ospf\_key\_3) | OSPF Key 3. | `string` | `""` | no |
| <a name="input_ospf_key_4"></a> [ospf\_key\_4](#input\_ospf\_key\_4) | OSPF Key 4. | `string` | `""` | no |
| <a name="input_ospf_key_5"></a> [ospf\_key\_5](#input\_ospf\_key\_5) | OSPF Key 5. | `string` | `""` | no |
| <a name="input_vrf_snmp_community_1"></a> [vrf\_snmp\_community\_1](#input\_vrf\_snmp\_community\_1) | SNMP Community 1. | `string` | `""` | no |
| <a name="input_vrf_snmp_community_2"></a> [vrf\_snmp\_community\_2](#input\_vrf\_snmp\_community\_2) | SNMP Community 2. | `string` | `""` | no |
| <a name="input_vrf_snmp_community_3"></a> [vrf\_snmp\_community\_3](#input\_vrf\_snmp\_community\_3) | SNMP Community 3. | `string` | `""` | no |
| <a name="input_vrf_snmp_community_4"></a> [vrf\_snmp\_community\_4](#input\_vrf\_snmp\_community\_4) | SNMP Community 4. | `string` | `""` | no |
| <a name="input_vrf_snmp_community_5"></a> [vrf\_snmp\_community\_5](#input\_vrf\_snmp\_community\_5) | SNMP Community 5. | `string` | `""` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_profiles"></a> [application\_profiles](#output\_application\_profiles) | n/a |
| <a name="output_contracts"></a> [contracts](#output\_contracts) | n/a |
| <a name="output_networking"></a> [networking](#output\_networking) | n/a |
| <a name="output_nexus_dashboard_orchestrator"></a> [nexus\_dashboard\_orchestrator](#output\_nexus\_dashboard\_orchestrator) | n/a |
| <a name="output_policies"></a> [policies](#output\_policies) | n/a |
| <a name="output_tenants"></a> [tenants](#output\_tenants) | n/a |
## Resources

| Name | Type |
|------|------|
| [aci_any.vz_any](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/any) | resource |
| [aci_application_epg.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/application_epg) | resource |
| [aci_application_profile.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/application_profile) | resource |
| [aci_bd_dhcp_label.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bd_dhcp_label) | resource |
| [aci_bfd_interface_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bfd_interface_policy) | resource |
| [aci_bgp_address_family_context.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_address_family_context) | resource |
| [aci_bgp_best_path_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_best_path_policy) | resource |
| [aci_bgp_peer_connectivity_profile.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_prefix.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_peer_prefix) | resource |
| [aci_bgp_route_summarization.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_route_summarization) | resource |
| [aci_bgp_timers.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_timers) | resource |
| [aci_bridge_domain.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bridge_domain) | resource |
| [aci_concrete_device.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/concrete_device) | resource |
| [aci_concrete_interface.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/concrete_interface) | resource |
| [aci_connection.l4_l7_service_graph_connections](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/connection) | resource |
| [aci_contract.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/contract) | resource |
| [aci_contract_subject.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/contract_subject) | resource |
| [aci_destination_of_redirected_traffic.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/destination_of_redirected_traffic) | resource |
| [aci_dhcp_option_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/dhcp_option_policy) | resource |
| [aci_dhcp_relay_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/dhcp_relay_policy) | resource |
| [aci_end_point_retention_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/end_point_retention_policy) | resource |
| [aci_epg_to_domain.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/epg_to_domain) | resource |
| [aci_epgs_using_function.epg_to_aaeps](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/epgs_using_function) | resource |
| [aci_external_network_instance_profile.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/external_network_instance_profile) | resource |
| [aci_filter.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/filter) | resource |
| [aci_filter_entry.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/filter_entry) | resource |
| [aci_function_node.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/function_node) | resource |
| [aci_hsrp_group_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/hsrp_group_policy) | resource |
| [aci_hsrp_interface_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/hsrp_interface_policy) | resource |
| [aci_ip_sla_monitoring_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/ip_sla_monitoring_policy) | resource |
| [aci_l3_ext_subnet.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3_ext_subnet) | resource |
| [aci_l3_outside.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3_outside) | resource |
| [aci_l3out_bgp_external_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_bgp_external_policy) | resource |
| [aci_l3out_hsrp_interface_group.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_hsrp_interface_group) | resource |
| [aci_l3out_hsrp_interface_profile.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_hsrp_interface_profile) | resource |
| [aci_l3out_hsrp_secondary_vip.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_hsrp_secondary_vip) | resource |
| [aci_l3out_ospf_external_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_ospf_external_policy) | resource |
| [aci_l3out_ospf_interface_profile.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_path_attachment.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_path_attachment) | resource |
| [aci_l3out_path_attachment_secondary_ip.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_static_route.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_static_route) | resource |
| [aci_l3out_static_route_next_hop.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_static_route_next_hop) | resource |
| [aci_l3out_vpc_member.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l3out_vpc_member) | resource |
| [aci_l4_l7_device.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l4_l7_device) | resource |
| [aci_l4_l7_logical_interface.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l4_l7_logical_interface) | resource |
| [aci_l4_l7_redirect_health_group.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l4_l7_redirect_health_group) | resource |
| [aci_l4_l7_service_graph_template.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/l4_l7_service_graph_template) | resource |
| [aci_logical_interface_profile.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/logical_interface_profile) | resource |
| [aci_logical_node_profile.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/logical_node_profile) | resource |
| [aci_logical_node_to_fabric_node.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/logical_node_to_fabric_node) | resource |
| [aci_match_route_destination_rule.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/match_route_destination_rule) | resource |
| [aci_match_rule.route_map_match_rules](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/match_rule) | resource |
| [aci_node_mgmt_epg.mgmt_epgs](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/node_mgmt_epg) | resource |
| [aci_ospf_interface_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/ospf_interface_policy) | resource |
| [aci_ospf_route_summarization.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/ospf_route_summarization) | resource |
| [aci_ospf_timers.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/ospf_timers) | resource |
| [aci_rest_managed.application_epgs_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.application_epgs_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.application_profiles_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.application_profiles_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.bridge_domain_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.bridge_domain_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.contract_subject_filter](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.contract_to_epgs](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.contract_to_inb_epgs](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.contract_to_oob_epgs](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.epg_to_static_paths](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.external_epg_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.external_epg_contracts_taboo](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.external_epg_intra_epg_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.external_management_network_instance_profiles](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_consumer_label](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_multicast](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_route_profiles_for_redistribution](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.match_rules_match_community_terms](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.match_rules_match_regex_community_terms](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.oob_contract_subjects](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.oob_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.rogue_coop_exception_list](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_communities](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_dampening](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_external_epg](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_metric](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_metric_type](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_next_hop_address](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_preference](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_route_tag](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_weight](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_maps_context_set_rules](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_maps_contexts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_maps_for_route_control](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.set_rules_additional_communities](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.set_rules_multipath](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.set_rules_next_hop_propegation](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.set_rules_set_as_path](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.taboo_contract_subjects](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.taboo_subject_filter](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.tenant_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.tenant_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vrf_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vrf_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vzany_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vzany_provider_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_service_redirect_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/service_redirect_policy) | resource |
| [aci_snmp_community.vrf_communities](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/snmp_community) | resource |
| [aci_static_node_mgmt_address.apics_inband](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/static_node_mgmt_address) | resource |
| [aci_subnet.bridge_domain_subnets](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/subnet) | resource |
| [aci_taboo_contract.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/taboo_contract) | resource |
| [aci_tenant.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/tenant) | resource |
| [aci_vrf.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/vrf) | resource |
| [aci_vrf_snmp_context.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/vrf_snmp_context) | resource |
| [mso_schema.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema) | resource |
| [mso_schema_site.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site) | resource |
| [mso_schema_site_anp_epg_domain.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site_anp_epg_domain) | resource |
| [mso_schema_site_bd.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site_bd) | resource |
| [mso_schema_site_bd_l3out.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site_bd_l3out) | resource |
| [mso_schema_site_vrf.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site_vrf) | resource |
| [mso_schema_template_anp.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_anp) | resource |
| [mso_schema_template_anp_epg.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_anp_epg) | resource |
| [mso_schema_template_anp_epg_contract.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_anp_epg_contract) | resource |
| [mso_schema_template_bd.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_bd) | resource |
| [mso_schema_template_bd_subnet.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_bd_subnet) | resource |
| [mso_schema_template_contract.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_contract) | resource |
| [mso_schema_template_filter_entry.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_filter_entry) | resource |
| [mso_schema_template_l3out.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_l3out) | resource |
| [mso_schema_template_vrf.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_vrf) | resource |
| [mso_schema_template_vrf_contract.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_vrf_contract) | resource |
| [mso_tenant.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/tenant) | resource |
| [mso_schema.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/schema) | data source |
| [mso_schema_template_anp.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/schema_template_anp) | data source |
| [mso_site.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/site) | data source |
| [mso_tenant.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/tenant) | data source |
| [mso_user.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/user) | data source |
<!-- END_TF_DOCS -->