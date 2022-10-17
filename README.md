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
| <a name="requirement_aci"></a> [aci](#requirement\_aci) | >= 2.5.2 |
| <a name="requirement_mso"></a> [mso](#requirement\_mso) | >=0.7.0 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aci"></a> [aci](#provider\_aci) | >= 2.5.2 |
| <a name="provider_mso"></a> [mso](#provider\_mso) | >=0.7.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_model"></a> [model](#input\_model) | Model data. | `any` | n/a | yes |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Name of the Tenant | `string` | n/a | yes |
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
| <a name="output_application_epgs"></a> [application\_epgs](#output\_application\_epgs) | n/a |
| <a name="output_application_profiles"></a> [application\_profiles](#output\_application\_profiles) | n/a |
| <a name="output_bridge_domains"></a> [bridge\_domains](#output\_bridge\_domains) | n/a |
| <a name="output_contracts"></a> [contracts](#output\_contracts) | n/a |
| <a name="output_endpoint_retention"></a> [endpoint\_retention](#output\_endpoint\_retention) | n/a |
| <a name="output_filters"></a> [filters](#output\_filters) | n/a |
| <a name="output_ndo_sites"></a> [ndo\_sites](#output\_ndo\_sites) | n/a |
| <a name="output_ndo_users"></a> [ndo\_users](#output\_ndo\_users) | n/a |
| <a name="output_ndo_schemas"></a> [ndo\_schemas](#output\_ndo\_schemas) | n/a |
| <a name="output_tenants"></a> [tenants](#output\_tenants) | n/a |
| <a name="output_vrfs"></a> [vrfs](#output\_vrfs) | n/a |
## Resources

| Name | Type |
|------|------|
| [aci_any.vz_any](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/any) | resource |
| [aci_application_epg.application_epgs](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/application_epg) | resource |
| [aci_application_profile.application_profiles](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/application_profile) | resource |
| [aci_bd_dhcp_label.bridge_domain_dhcp_labels](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bd_dhcp_label) | resource |
| [aci_bfd_interface_policy.bfd_interface](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bfd_interface_policy) | resource |
| [aci_bgp_address_family_context.bgp_address_family_context](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_address_family_context) | resource |
| [aci_bgp_best_path_policy.bgp_best_path](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_best_path_policy) | resource |
| [aci_bgp_peer_prefix.bgp_peer_prefix](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_peer_prefix) | resource |
| [aci_bgp_route_summarization.bgp_route_summarization](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_route_summarization) | resource |
| [aci_bgp_timers.bgp_timers](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bgp_timers) | resource |
| [aci_bridge_domain.bridge_domains](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/bridge_domain) | resource |
| [aci_contract.contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/contract) | resource |
| [aci_contract_subject.contract_subjects](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/contract_subject) | resource |
| [aci_dhcp_option_policy.dhcp_option](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/dhcp_option_policy) | resource |
| [aci_dhcp_relay_policy.dhcp_relay](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/dhcp_relay_policy) | resource |
| [aci_end_point_retention_policy.endpoint_retention](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/end_point_retention_policy) | resource |
| [aci_epg_to_domain.epg_to_domains](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/epg_to_domain) | resource |
| [aci_epgs_using_function.epg_to_aaeps](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/epgs_using_function) | resource |
| [aci_filter.filters](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/filter) | resource |
| [aci_filter_entry.filter_entries](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/filter_entry) | resource |
| [aci_hsrp_group_policy.hsrp_group](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/hsrp_group_policy) | resource |
| [aci_hsrp_interface_policy.hsrp_interface](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/hsrp_interface_policy) | resource |
| [aci_node_mgmt_epg.mgmt_epgs](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/node_mgmt_epg) | resource |
| [aci_ospf_interface_policy.ospf_interface](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/ospf_interface_policy) | resource |
| [aci_ospf_route_summarization.ospf_route_summarization](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/ospf_route_summarization) | resource |
| [aci_ospf_timers.ospf_timers](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/ospf_timers) | resource |
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
| [aci_rest_managed.oob_contract_subjects](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.oob_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.rogue_coop_exception_list](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.taboo_contract_subjects](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.taboo_subject_filter](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.tenant_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.tenant_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vrf_annotations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vrf_global_alias](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vzany_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.vzany_provider_contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_snmp_community.vrf_communities](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/snmp_community) | resource |
| [aci_static_node_mgmt_address.apics_inband](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/static_node_mgmt_address) | resource |
| [aci_subnet.bridge_domain_subnets](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/subnet) | resource |
| [aci_taboo_contract.contracts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/taboo_contract) | resource |
| [aci_tenant.tenants](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/tenant) | resource |
| [aci_vrf.vrfs](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/vrf) | resource |
| [aci_vrf_snmp_context.vrf_snmp_contexts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/vrf_snmp_context) | resource |
| [mso_schema.schemas](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema) | resource |
| [mso_schema_site.template_sites](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site) | resource |
| [mso_schema_site_anp.application_profiles](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site_anp) | resource |
| [mso_schema_site_bd.bridge_domains](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site_bd) | resource |
| [mso_schema_site_bd_l3out.bridge_domain_l3outs](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site_bd_l3out) | resource |
| [mso_schema_site_vrf.vrfs](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_site_vrf) | resource |
| [mso_schema_template_anp.application_profiles](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_anp) | resource |
| [mso_schema_template_anp_epg.application_epgs](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_anp_epg) | resource |
| [mso_schema_template_bd.bridge_domains](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_bd) | resource |
| [mso_schema_template_bd_subnet.bridge_domain_subnets](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_bd_subnet) | resource |
| [mso_schema_template_contract.contracts](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_contract) | resource |
| [mso_schema_template_filter_entry.filter_entries](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_filter_entry) | resource |
| [mso_schema_template_vrf.vrfs](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_vrf) | resource |
| [mso_schema_template_vrf_contract.vzany_contracts](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/schema_template_vrf_contract) | resource |
| [mso_tenant.tenants](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/resources/tenant) | resource |
| [mso_schema.schemas](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/schema) | data source |
| [mso_site.sites](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/site) | data source |
| [mso_user.users](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs/data-sources/user) | data source |
<!-- END_TF_DOCS -->