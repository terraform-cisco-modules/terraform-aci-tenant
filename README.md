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

No providers.
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_model"></a> [model](#input\_model) | Model data. | `any` | n/a | yes |
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
| <a name="output_bridge_domains"></a> [bridge\_domains](#output\_bridge\_domains) | n/a |
| <a name="output_ndo_sites"></a> [ndo\_sites](#output\_ndo\_sites) | n/a |
| <a name="output_ndo_users"></a> [ndo\_users](#output\_ndo\_users) | n/a |
| <a name="output_tenants"></a> [tenants](#output\_tenants) | n/a |
## Resources

No resources.
<!-- END_TF_DOCS -->