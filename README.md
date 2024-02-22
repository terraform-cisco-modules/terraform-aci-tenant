<!-- BEGIN_TF_DOCS -->
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Developed by: Cisco](https://img.shields.io/badge/Developed%20by-Cisco-blue)](https://developer.cisco.com)

# Terraform ACI - Tenant Module

A Terraform module to configure ACI Tenant Policies.

### NOTE: THIS MODULE IS DESIGNED TO BE CONSUMED USING "EASY ACI"

### A comprehensive example using this module is available below:

## [Easy ACI](https://github.com/terraform-cisco-modules/easy-aci)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aci"></a> [aci](#requirement\_aci) | >=2.13.0 |
| <a name="requirement_mso"></a> [mso](#requirement\_mso) | >=1.0.0 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aci"></a> [aci](#provider\_aci) | 2.13.2 |
| <a name="provider_mso"></a> [mso](#provider\_mso) | 1.0.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_model"></a> [model](#input\_model) | Model data. | `any` | n/a | yes |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Name of the Tenant. | `any` | n/a | yes |
| <a name="input_tenant_sensitive"></a> [tenant\_sensitive](#input\_tenant\_sensitive) | Note: Sensitive Variables cannot be added to a for\_each loop so these are added seperately.<br>    * mcp\_instance\_policy\_default: MisCabling Protocol Instance Settings.<br>      - key: The key or password used to uniquely identify this configuration object.<br>    * virtual\_networking: ACI to Virtual Infrastructure Integration.<br>      - password: Username/Password combination to Authenticate to the Virtual Infrastructure. | <pre>object({<br>    bgp = object({<br>      password = map(string)<br>    })<br>    nexus_dashboard = object({<br>      aws_secret_key      = map(string)<br>      azure_client_secret = map(string)<br>    })<br>    ospf = object({<br>      authentication_key = map(string)<br>    })<br>    vrf = object({<br>      snmp_community = map(string)<br>    })<br>  })</pre> | <pre>{<br>  "bgp": {<br>    "password": {}<br>  },<br>  "nexus_dashboard": {<br>    "aws_secret_key": {},<br>    "azure_client_secret": {}<br>  },<br>  "ospf": {<br>    "authentication_key": {}<br>  },<br>  "vrf": {<br>    "snmp_community": {}<br>  }<br>}</pre> | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_profiles"></a> [application\_profiles](#output\_application\_profiles) | Identifiers for Application Profiles:<br> * application\_profiles:<br>   - ACI: Tenants => {Tenant Name} => Application Profiles: {Name}<br>   - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name}<br>   - application\_epgs:<br>     * ACI: Tenants => {Tenant Name} => Application Profiles: {Name} => Application EPGs: {Name}<br>     * NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name} => EPGs: {Name}<br>     * epg\_to\_contracts:<br>       - ACI: Tenants => {Tenant Name} => Application Profiles: {Name} => Application EPGs: {Name} => Contracts<br>       - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name} => EPGs: {Name}: Contracts<br>     * epg\_to\_domains:<br>       - ACI: Tenants => {Tenant Name} => Application Profiles: {Name} => Application EPGs: {Name} => Domains<br>       - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name} => EPGs: {Name}: {Select Site}: Domains<br>     * epg\_to\_static\_paths:<br>       - ACI: Tenants => {Tenant Name} => Application Profiles: {Name} => Application EPGs: {Name} => Static Ports<br>       - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Application Profile: {Name} => EPGs: {Name}: {Select Site}: Static Ports |
| <a name="output_contracts"></a> [contracts](#output\_contracts) | Identifiers for Contracts:<br> * contracts:<br>   - oob\_contracts: Tenants => {Tenant Name} => Contracts => Out-of-Band Contracts: {Name}<br>   - standard\_contracts:<br>     * ACI: Tenants => {Tenant Name} => Contracts => Standard: {Name}<br>     * NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Contracts: {Name}<br>   - taboo\_contracts: Tenants => {Tenant Name} => Contracts => Taboos: {Name}<br> * filters:<br>   - filters: Tenants => {Tenant Name} => Contracts => Filters: {Name}<br>   - filter\_entries:<br>     * ACI: Tenants => {Tenant Name} => Contracts => Filters: {Name} => Entries<br>     * NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => Filter: {Name} |
| <a name="output_networking"></a> [networking](#output\_networking) | Identifiers for Tenant Networking:<br> * bridge\_domains:<br>   - ACI: Tenants => {Tenant Name} => Networking => Bridge Domains: {Name}<br>   - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => Bridge Domains: {Name}<br>   - bridge\_domain\_subnets: Tenants => {Tenant Name} => Networking => Bridge Domains: {Name} => Subnets<br> * l3outs:<br>   - ACI: Tenants => {Tenant Name} => Networking => L3Outs: {Name}<br>   - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => Bridge Domains: {Name}<br>   - l3out\_bgp\_external\_policy: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Policy => Enabled BGP/EIGRP/OSPF: BGP<br>   - l3out\_external\_epgs: Tenants => Tenants => {Tenant Name} => Networking => L3Outs: {Name} => External EPGs: {Name}<br>     * l3out\_external\_epg\_subnets: Tenants => Tenants => {Tenant Name} => Networking => L3Outs: {Name} => External EPGs: {Name} => Subnets<br>   - l3out\_node\_profiles: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name}<br>     * l3out\_interface\_profiles: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name} => Logical Interface Profiles: {Name}<br>       - l3out\_interface\_profile\_ospf\_interfaces: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name} => Logical Interface Profiles: {Name} => OSPF Interface Profile<br>       - l3out\_interface\_profile\_path\_attachment: Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name} => Logical Interface Profiles: {Name}: Routed Sub-Interfaces/Routed Interfaces/SVI/Floating SVI<br>     * l3out\_node\_profile\_bgp\_peers:  Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name}: BGP Peer Connectivity<br>     * l3out\_node\_profile\_static\_routes:  Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Logical Node Profiles: {Name}: (Double click node under Nodes): Static Routes<br>     * l3out\_ospf\_external\_policy:  Tenants => {Tenant Name} => Networking => L3Outs: {Name} => Policy => Enabled BGP/EIGRP/OSPF: OSPF<br> * vrf:<br>   - ACI: Tenants => {Tenant Name} => Networking => VRFs: {Name}<br>   - NDO: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => {Template} => VRFs |
| <a name="output_nd_orchestrator"></a> [nd\_orchestrator](#output\_nd\_orchestrator) | Identifiers for Nexus Dashboard Orchestrator:<br> * schema: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name}<br> * schema\_sites: Nexus Dashboard => Orchestrator => Configure => Tenant Templates => Applications: {Schema Name} => Sites<br> * sites: Nexus Dashboard => Sites: {Site Name}<br> * users:<br>   - External Users: Nexus Dashboard => Admin Console => Administrative => Authentication<br>   - Local Users: Nexus Dashboard => Admin Console => Administrative => Users |
| <a name="output_policies"></a> [policies](#output\_policies) | Identifiers for Tenant Policies:<br> * bfd: Tenants => {Tenant Name} => Policies => Protocol => BFD: {Name}<br> * bgp:<br>   - bgp\_address\_family\_context: Tenants => {Tenant Name} => Policies => Protocol => BGP => BGP Address Family Context: {Name}<br>   - bgp\_best\_path: Tenants => {Tenant Name} => Policies => Protocol => BGP => BGP Best Path Policy: {Name}<br>   - bgp\_route\_summarization: Tenants => {Tenant Name} => Policies => Protocol => BGP => BGP Route Summarization: {Name}<br>   - bgp\_timers: Tenants => {Tenant Name} => Policies => Protocol => BGP => BGP Timers: {Name}<br> * dhcp:<br>   - dhcp\_option: Tenants => {Tenant Name} => Policies => Protocol => DHCP => Option Policies: {Name}<br>   - dhcp\_relay: Tenants => {Tenant Name} => Policies => Protocol => DHCP => Relay Policies: {Name}<br> * endpoint\_retention: Tenants => {Tenant Name} => Policies => Protocol => End Point Retention: {Name}<br> * hsrp:<br>   - hsrp\_group: Tenants => {Tenant Name} => Policies => Protocol => HSRP => Interface Policies: {Name}<br>   - hsrp\_interface: Tenants => {Tenant Name} => Policies => Protocol => HSRP => Group Policies: {Name}<br> * ip\_sla:<br>   - ip\_sla\_monitoring: Tenants => {Tenant Name} => Policies => Protocol => IP SLA => IP SLA Monitoring Policies: {Name}<br>   - track\_lists: Tenants => {Tenant Name} => Policies => Protocol => IP SLA => Track Lists: {Name}<br>   - track\_members: Tenants => {Tenant Name} => Policies => Protocol => IP SLA => Track Members: {Name}<br> * l4\_l7\_pbr: Tenants => {Tenant Name} => Policies => Protocol => L4-L7 Policy-Based Redirect: {Name}<br> * l4\_l7\_redirect\_health\_groups: Tenants => {Tenant Name} => Policies => Protocol => L4-L7 Policy-Based Redirect Health Groups: {Name}<br> * l4\_l7\_pbr\_destinations: Tenants => {Tenant Name} => Policies => Protocol => L4-L7 Policy-Based Redirect Destinations: {Name}<br> * ospf:<br>   - ospf\_interface: Tenants => {Tenant Name} => Policies => Protocol => OSPF => OSPF Interface: {Name}<br>   - ospf\_route\_summarization: Tenants => {Tenant Name} => Policies => Protocol => OSPF => OSPF Route Summarization: {Name}<br>   - ospf\_timers: Tenants => {Tenant Name} => Policies => Protocol => OSPF => OSPF Timers: {Name} |
| <a name="output_tenants"></a> [tenants](#output\_tenants) | Tenant Identifiers. |
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
| [aci_bulk_epg_to_static_path.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bulk_epg_to_static_path) | resource |
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
| [aci_match_community_terms.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/match_community_terms) | resource |
| [aci_match_regex_community_terms.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/match_regex_community_terms) | resource |
| [aci_match_route_destination_rule.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/match_route_destination_rule) | resource |
| [aci_match_rule.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/match_rule) | resource |
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
| [aci_rest_managed.external_epg_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.external_epg_contracts_taboo](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.external_epg_intra_epg_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.external_management_network_instance_profiles](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_consumer_label](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_multicast](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_route_profiles_for_redistribution](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.oob_contract_subjects](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.oob_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.rogue_coop_exception_list](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.route_map_set_rules_set_community](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
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
| [aci_rest_managed.track_lists](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.track_members](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vrf_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vrf_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vzany_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vzany_provider_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_service_redirect_policy.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/service_redirect_policy) | resource |
| [aci_snmp_community.vrf_communities](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/snmp_community) | resource |
| [aci_static_node_mgmt_address.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/static_node_mgmt_address) | resource |
| [aci_subnet.bridge_domain_subnets](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/subnet) | resource |
| [aci_taboo_contract.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/taboo_contract) | resource |
| [aci_tenant.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/tenant) | resource |
| [aci_vrf.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/vrf) | resource |
| [aci_vrf_snmp_context.map](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/vrf_snmp_context) | resource |
| [mso_schema.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema) | resource |
| [mso_schema_site.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site) | resource |
| [mso_schema_site_anp_epg_bulk_staticport.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site_anp_epg_bulk_staticport) | resource |
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
| [mso_site.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/site) | data source |
| [mso_tenant.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/tenant) | data source |
| [mso_user.map](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/user) | data source |
<!-- END_TF_DOCS -->