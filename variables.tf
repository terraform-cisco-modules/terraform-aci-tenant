#__________________________________________________________________
#
# Model Data and policy from domains and pools
#__________________________________________________________________

variable "model" {
  description = "Model data."
  type        = any
}

variable "switch" {
  default     = {}
  description = "List of Switch Objects."
  type        = any
}

variable "templates" {
  description = "List of Templates."
  type        = any
}

variable "aaep_to_epgs" {
  default     = {}
  description = "AAEP to EPGs VLAN Mapping from Access Module."
  type        = any
}
variable "tenant" {
  description = "Name of the Tenant."
  type        = any
}


/*_____________________________________________________________________________________________________________________

Global Shared Variables
_______________________________________________________________________________________________________________________
*/


variable "annotations" {
  default = [
    {
      key   = "orchestrator"
      value = "terraform:easy-aci:v2.0"
    }
  ]
  description = "The Version of this Script."
  type = list(object(
    {
      key   = string
      value = string
    }
  ))
}

variable "controller_type" {
  default     = "apic"
  description = <<-EOT
    The Type of Controller for this Site.
    - apic
    - ndo
  EOT
  type        = string
}


variable "management_epgs" {
  default = [
    {
      name = "default"
      type = "oob"
    }
  ]
  description = <<-EOT
    The Management EPG's that will be used by the script.
    - name: Name of the EPG
    - type: Type of EPG
      * inb
      * oob
  EOT
  type = list(object(
    {
      name = string
      type = string
    }
  ))
}


/*_____________________________________________________________________________________________________________________

Tenants - Nexus Dashboard Orchestrator - Cloud Connector - Sensitive Variables
_______________________________________________________________________________________________________________________
*/

variable "aws_secret_key" {
  default     = ""
  description = "AWS Secret Key Id. It must be provided if the AWS account is not trusted. This parameter will only have effect with vendor = aws."
  sensitive   = true
  type        = string
}

variable "azure_client_secret" {
  default     = "1"
  description = "Azure Client Secret. It must be provided when azure_access_type to credentials. This parameter will only have effect with vendor = azure."
  sensitive   = true
  type        = string
}

/*_____________________________________________________________________________________________________________________

Tenants -> {tenant_name}: Networking -> L3Out -> Logical Node Profile: Routing Protocols - Sensitive Variables
_______________________________________________________________________________________________________________________
*/

variable "bgp_password_1" {
  default     = ""
  description = "BGP Password 1."
  sensitive   = true
  type        = string
}

variable "bgp_password_2" {
  default     = ""
  description = "BGP Password 2."
  sensitive   = true
  type        = string
}

variable "bgp_password_3" {
  default     = ""
  description = "BGP Password 3."
  sensitive   = true
  type        = string
}

variable "bgp_password_4" {
  default     = ""
  description = "BGP Password 4."
  sensitive   = true
  type        = string
}

variable "bgp_password_5" {
  default     = ""
  description = "BGP Password 5."
  sensitive   = true
  type        = string
}

variable "ospf_key_1" {
  default     = ""
  description = "OSPF Key 1."
  sensitive   = true
  type        = string
}

variable "ospf_key_2" {
  default     = ""
  description = "OSPF Key 2."
  sensitive   = true
  type        = string
}

variable "ospf_key_3" {
  default     = ""
  description = "OSPF Key 3."
  sensitive   = true
  type        = string
}

variable "ospf_key_4" {
  default     = ""
  description = "OSPF Key 4."
  sensitive   = true
  type        = string
}

variable "ospf_key_5" {
  default     = ""
  description = "OSPF Key 5."
  sensitive   = true
  type        = string
}

/*_____________________________________________________________________________________________________________________

Tenants -> {tenant_name}: Networking -> VRFs - SNMP Context - Sensitive Variables
_______________________________________________________________________________________________________________________
*/
variable "vrf_snmp_community_1" {
  default     = ""
  description = "SNMP Community 1."
  sensitive   = true
  type        = string
}

variable "vrf_snmp_community_2" {
  default     = ""
  description = "SNMP Community 2."
  sensitive   = true
  type        = string
}

variable "vrf_snmp_community_3" {
  default     = ""
  description = "SNMP Community 3."
  sensitive   = true
  type        = string
}

variable "vrf_snmp_community_4" {
  default     = ""
  description = "SNMP Community 4."
  sensitive   = true
  type        = string
}

variable "vrf_snmp_community_5" {
  default     = ""
  description = "SNMP Community 5."
  sensitive   = true
  type        = string
}
