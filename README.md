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
| <a name="requirement_aci"></a> [aci](#requirement\_aci) | >= 2.1.0 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aci"></a> [aci](#provider\_aci) | >= 2.1.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_remote_password_1"></a> [remote\_password\_1](#input\_remote\_password\_1) | Remote Host Password 1. | `string` | `""` | no |
| <a name="input_remote_password_2"></a> [remote\_password\_2](#input\_remote\_password\_2) | Remote Host Password 2. | `string` | `""` | no |
| <a name="input_remote_password_3"></a> [remote\_password\_3](#input\_remote\_password\_3) | Remote Host Password 3. | `string` | `""` | no |
| <a name="input_remote_password_4"></a> [remote\_password\_4](#input\_remote\_password\_4) | Remote Host Password 4. | `string` | `""` | no |
| <a name="input_remote_password_5"></a> [remote\_password\_5](#input\_remote\_password\_5) | Remote Host Password 5. | `string` | `""` | no |
| <a name="input_ssh_key_contents"></a> [ssh\_key\_contents](#input\_ssh\_key\_contents) | SSH Private Key Based Authentication Contents. | `string` | `""` | no |
| <a name="input_ssh_key_passphrase"></a> [ssh\_key\_passphrase](#input\_ssh\_key\_passphrase) | SSH Private Key Based Authentication Passphrase. | `string` | `""` | no |
| <a name="input_radius_key_1"></a> [radius\_key\_1](#input\_radius\_key\_1) | RADIUS Key 1. | `string` | `""` | no |
| <a name="input_radius_key_2"></a> [radius\_key\_2](#input\_radius\_key\_2) | RADIUS Key 2. | `string` | `""` | no |
| <a name="input_radius_key_3"></a> [radius\_key\_3](#input\_radius\_key\_3) | RADIUS Key 3. | `string` | `""` | no |
| <a name="input_radius_key_4"></a> [radius\_key\_4](#input\_radius\_key\_4) | RADIUS Key 4. | `string` | `""` | no |
| <a name="input_radius_key_5"></a> [radius\_key\_5](#input\_radius\_key\_5) | RADIUS Key 5. | `string` | `""` | no |
| <a name="input_radius_monitoring_password_1"></a> [radius\_monitoring\_password\_1](#input\_radius\_monitoring\_password\_1) | RADIUS Monitoring Password 1. | `string` | `""` | no |
| <a name="input_radius_monitoring_password_2"></a> [radius\_monitoring\_password\_2](#input\_radius\_monitoring\_password\_2) | RADIUS Monitoring Password 2. | `string` | `""` | no |
| <a name="input_radius_monitoring_password_3"></a> [radius\_monitoring\_password\_3](#input\_radius\_monitoring\_password\_3) | RADIUS Monitoring Password 3. | `string` | `""` | no |
| <a name="input_radius_monitoring_password_4"></a> [radius\_monitoring\_password\_4](#input\_radius\_monitoring\_password\_4) | RADIUS Monitoring Password 4. | `string` | `""` | no |
| <a name="input_radius_monitoring_password_5"></a> [radius\_monitoring\_password\_5](#input\_radius\_monitoring\_password\_5) | RADIUS Monitoring Password 5. | `string` | `""` | no |
| <a name="input_tacacs_key_1"></a> [tacacs\_key\_1](#input\_tacacs\_key\_1) | TACACS Key 1. | `string` | `""` | no |
| <a name="input_tacacs_key_2"></a> [tacacs\_key\_2](#input\_tacacs\_key\_2) | TACACS Key 2. | `string` | `""` | no |
| <a name="input_tacacs_key_3"></a> [tacacs\_key\_3](#input\_tacacs\_key\_3) | TACACS Key 3. | `string` | `""` | no |
| <a name="input_tacacs_key_4"></a> [tacacs\_key\_4](#input\_tacacs\_key\_4) | TACACS Key 4. | `string` | `""` | no |
| <a name="input_tacacs_key_5"></a> [tacacs\_key\_5](#input\_tacacs\_key\_5) | TACACS Key 5. | `string` | `""` | no |
| <a name="input_tacacs_monitoring_password_1"></a> [tacacs\_monitoring\_password\_1](#input\_tacacs\_monitoring\_password\_1) | TACACS Monitoring Password 1. | `string` | `""` | no |
| <a name="input_tacacs_monitoring_password_2"></a> [tacacs\_monitoring\_password\_2](#input\_tacacs\_monitoring\_password\_2) | TACACS Monitoring Password 2. | `string` | `""` | no |
| <a name="input_tacacs_monitoring_password_3"></a> [tacacs\_monitoring\_password\_3](#input\_tacacs\_monitoring\_password\_3) | TACACS Monitoring Password 3. | `string` | `""` | no |
| <a name="input_tacacs_monitoring_password_4"></a> [tacacs\_monitoring\_password\_4](#input\_tacacs\_monitoring\_password\_4) | TACACS Monitoring Password 4. | `string` | `""` | no |
| <a name="input_tacacs_monitoring_password_5"></a> [tacacs\_monitoring\_password\_5](#input\_tacacs\_monitoring\_password\_5) | TACACS Monitoring Password 5. | `string` | `""` | no |
| <a name="input_model"></a> [model](#input\_model) | Model data. | `any` | n/a | yes |
## Outputs

No outputs.
## Resources

| Name | Type |
|------|------|
| [aci_authentication_properties.authentication_properties](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/authentication_properties) | resource |
| [aci_configuration_export_policy.configuration_export](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/configuration_export_policy) | resource |
| [aci_console_authentication.console](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/console_authentication) | resource |
| [aci_default_authentication.default](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/default_authentication) | resource |
| [aci_duo_provider_group.duo_provider_groups](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/duo_provider_group) | resource |
| [aci_file_remote_path.export_remote_hosts](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/file_remote_path) | resource |
| [aci_global_security.security](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/global_security) | resource |
| [aci_login_domain.login_domain](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/login_domain) | resource |
| [aci_login_domain.login_domain_tacacs](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/login_domain) | resource |
| [aci_login_domain_provider.aci_login_domain_provider_radius](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/login_domain_provider) | resource |
| [aci_login_domain_provider.aci_login_domain_provider_tacacs](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/login_domain_provider) | resource |
| [aci_radius_provider.radius_providers](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/radius_provider) | resource |
| [aci_radius_provider_group.radius_provider_groups](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/radius_provider_group) | resource |
| [aci_recurring_window.recurring_window](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/recurring_window) | resource |
| [aci_rsa_provider.rsa_providers](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rsa_provider) | resource |
| [aci_tacacs_accounting.tacacs_accounting](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/tacacs_accounting) | resource |
| [aci_tacacs_accounting_destination.tacacs_accounting_destinations](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/tacacs_accounting_destination) | resource |
| [aci_tacacs_provider.tacacs_providers](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/tacacs_provider) | resource |
| [aci_tacacs_provider_group.tacacs_provider_groups](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/tacacs_provider_group) | resource |
| [aci_tacacs_source.tacacs_sources](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/tacacs_source) | resource |
| [aci_trigger_scheduler.trigger_schedulers](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/trigger_scheduler) | resource |
<!-- END_TF_DOCS -->