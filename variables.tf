/*_____________________________________________________________________________________________________________________

Model Data from Top Level Module
_______________________________________________________________________________________________________________________
*/
variable "model" {
  description = "Model data."
  type        = any
}

variable "tenant" {
  description = "Name of the Tenant."
  type        = any
}


/*_____________________________________________________________________________________________________________________

Tenant Sensitive Variables
_______________________________________________________________________________________________________________________
*/
variable "tenant_sensitive" {
  default = {
    bgp = {
      password = {}
    }
    nexus_dashboard = {
      aws_secret_key      = {}
      azure_client_secret = {}
    }
    ospf = {
      authentication_key = {}
    }
    vrf = {
      snmp_community = {}
    }
  }
  description = <<EOT
    Note: Sensitive Variables cannot be added to a for_each loop so these are added seperately.
    * mcp_instance_policy_default: MisCabling Protocol Instance Settings.
      - key: The key or password used to uniquely identify this configuration object.
    * virtual_networking: ACI to Virtual Infrastructure Integration.
      - password: Username/Password combination to Authenticate to the Virtual Infrastructure.
  EOT
  sensitive   = true
  type = object({
    bgp = object({
      password = map(string)
    })
    nexus_dashboard = object({
      aws_secret_key      = map(string)
      azure_client_secret = map(string)
    })
    ospf = object({
      authentication_key = map(string)
    })
    vrf = object({
      snmp_community = map(string)
    })
  })
}
