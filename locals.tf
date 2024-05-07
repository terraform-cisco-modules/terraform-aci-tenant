locals {
  #__________________________________________________________
  #
  # Model Inputs
  #__________________________________________________________
  annotations      = var.model.global_settings.annotations
  controller       = var.model.global_settings.controller
  defaults         = yamldecode(file("${path.module}/defaults.yaml")).defaults.tenants
  mgmt_epgs        = var.model.global_settings.management_epgs
  npfx             = merge(local.defaults.name_prefix, lookup(var.model, "name_prefix", {}))
  nsfx             = merge(local.defaults.name_suffix, lookup(var.model, "name_suffix", {}))
  networking       = lookup(var.model, "networking", {})
  node_mgmt_add    = lookup(var.model, "node_management_addresses", {})
  protocol         = lookup(lookup(var.model, "policies", {}), "protocol", {})
  template_bds     = lookup(lookup(var.model, "templates", {}), "bridge_domains", {})
  template_epgs    = lookup(lookup(var.model, "templates", {}), "application_epgs", {})
  template_subnets = lookup(lookup(var.model, "templates", {}), "subnets", {})
  tenant_contracts = lookup(var.model, "contracts", {})

  # Defaults
  app         = local.defaults.application_profiles
  adv         = local.bd.advanced_troubleshooting
  bd          = local.defaults.networking.bridge_domains
  bfd         = local.defaults.policies.protocol.bfd_interface
  bgpa        = local.defaults.policies.protocol.bgp.bgp_address_family_context
  bgpb        = local.defaults.policies.protocol.bgp.bgp_best_path
  bgpp        = local.defaults.policies.protocol.bgp.bgp_peer_prefix
  bgppeer     = local.lip.bgp_peers
  bgps        = local.defaults.policies.protocol.bgp.bgp_route_summarization
  bgpt        = local.defaults.policies.protocol.bgp.bgp_timers
  contract    = local.defaults.contracts.contracts
  dhcpo       = local.defaults.policies.protocol.dhcp.option_policies
  dhcpr       = local.defaults.policies.protocol.dhcp.relay_policies
  ep          = local.defaults.policies.protocol.endpoint_retention
  epg         = local.app.application_epgs
  filter      = local.defaults.contracts.filters
  general     = local.bd.general
  hip         = local.lip.hsrp_interface_profiles
  hsrpg       = local.defaults.policies.protocol.hsrp.group_policies
  hsrpi       = local.defaults.policies.protocol.hsrp.interface_policies
  l3          = local.bd.l3_configurations
  l3ospf      = local.l3out.ospf_external_profile
  l3out       = local.defaults.networking.l3outs
  l4l7pbr     = local.defaults.policies.protocol.l4-l7_policy-based_redirect
  l4l7rhg     = local.defaults.policies.protocol.l4-l7_redirect_health_groups
  lnp         = local.l3out.logical_node_profiles
  lnpstrt     = local.l3out.logical_node_profiles.static_routes
  lnpsrnh     = local.l3out.logical_node_profiles.static_routes.next_hop_addresses
  lip         = local.lnp.logical_interface_profiles
  netflow     = local.defaults.netflow_monitor_policies
  ospfi       = local.defaults.policies.protocol.ospf.ospf_interface
  ospfs       = local.defaults.policies.protocol.ospf.ospf_route_summarization
  ospft       = local.defaults.policies.protocol.ospf.ospf_timers
  ospfip      = local.lnp.logical_interface_profiles.ospf_interface_profile
  sla         = local.defaults.policies.protocol.ip_sla.ip_sla_monitoring_policies
  static_mgmt = local.defaults.node_management_addresses.static_node_management_addresses
  subnet      = local.l3.subnets
  subnets     = local.l3out.external_epgs.subnets
  rm          = local.defaults.policies.protocol.route_maps_for_route_control
  rmmr        = local.defaults.policies.protocol.route_map_match_rules
  rmsr        = local.defaults.policies.protocol.route_map_set_rules
  tnt         = local.defaults
  vrf         = local.defaults.networking.vrfs

  # Local Values
  policy_tenant = local.tenants[var.tenant].policy_tenant

  #__________________________________________________________
  #
  # Tenant Variables
  #__________________________________________________________

  tenants = {
    for v in [var.model] : v.name => merge(
      local.tnt, v,
      {
        annotations = length(lookup(v, "annotations", local.tnt.annotations)
        ) > 0 ? lookup(v, "annotations", local.tnt.annotations) : local.annotations
        sites = [
          for i in lookup(lookup(v, "ndo", {}), "sites", []) : merge(
            local.tnt.ndo.sites, i,
            { aws = merge(local.tnt.ndo.sites.aws, lookup(i, "aws", {})) },
            { azure = merge(local.tnt.ndo.sites.azure, lookup(i, "azure", {})) },
            { gcp = merge(local.tnt.ndo.sites.gcp, lookup(i, "gcp", {})) }
          )
        ]
        schemas = lookup(lookup(v, "ndo", {}), "schemas", [])
        users   = lookup(lookup(v, "ndo", {}), "users", [])
      }
    ) if v.name == var.tenant
  }

  schemas = { for i in flatten([
    for key, value in local.tenants : [
      for v in value.schemas : {
        create      = lookup(v, "create", true)
        description = lookup(v, "description", "")
        name        = v.name
        templates = [
          for t in lookup(v, "templates", []) : {
            name   = t.name
            sites  = lookup(t, "sites", [])
            tenant = key
        }]
      }
  ]]) : i.name => i }
  schema = length(local.schemas) > 0 ? flatten([for k, v in local.schemas : k])[0] : ""
  sites  = [for i in local.tenants[var.tenant].sites : i.name]
  users  = local.tenants[var.tenant].users

  template_sites = { for i in flatten([
    for key, value in local.schemas : [
      for v in value.templates : [
        for s in v.sites : {
          create   = value.create
          schema   = key
          template = v.name
          site     = s
        }
      ]
    ]
  ]) : "${i.schema}/${i.template}/${i.site}" => i }

  static_node_management_addresses = {
    for v in lookup(local.node_mgmt_add, "static_node_management_addresses", []) : v.node_id => merge(
      local.static_mgmt, v, { mgmt_epg_type = local.mgmt_epgs[index(local.mgmt_epgs[*].name, lookup(
      v, "management_epg", local.static_mgmt.management_epg))].type }
    )
  }
  #__________________________________________________________
  #
  # VRF Variables
  #__________________________________________________________

  vrfs = {
    for v in lookup(local.networking, "vrfs", []
      ) : "${local.npfx.vrfs}${v.name}${local.nsfx.vrfs}" => merge(
      local.vrf, v,
      { annotations = length(lookup(v, "annotations", local.vrf.annotations)
      ) > 0 ? lookup(v, "annotations", local.vrf.annotations) : local.annotations },
      { bgp_timers_per_address_family = [for e in lookup(v, "bgp_timers_per_address_family", []
      ) : merge(local.vrf.bgp_timers_per_address_family, e)] },
      { eigrp_timers_per_address_family = [for e in lookup(v, "eigrp_timers_per_address_family", []
      ) : merge(local.vrf.eigrp_timers_per_address_family, e)] },
      { epg_esg_collection_for_vrfs = {
        contracts = lookup(lookup(v, "epg_esg_collection_for_vrfs", {}), "contracts", [])
        label_match_criteria = lookup(lookup(v, "epg_esg_collection_for_vrfs", {}
          ), "label_match_criteria", local.vrf.epg_esg_collection_for_vrfs.label_match_criteria
        ) }
      }, { name = "${local.npfx.vrfs}${v.name}${local.nsfx.vrfs}" },
      { ospf_timers_per_address_family = [for e in lookup(v, "ospf_timers_per_address_family", []
      ) : merge(local.vrf.ospf_timers_per_address_family, e)] },
      { policy_tenant = local.policy_tenant }, { tenant = var.tenant }
    )
  }
  vzany_contracts = { for i in flatten([
    for key, value in local.vrfs : [
      for v in value.epg_esg_collection_for_vrfs.contracts : {
        contract             = v.name
        contract_type        = lookup(v, "contract_type", local.vrf.epg_esg_collection_for_vrfs.contracts.contract_type)
        contract_schema      = lookup(lookup(v, "ndo", {}), "schema", value.ndo.schema)
        contract_template    = lookup(lookup(v, "ndo", {}), "template", value.ndo.template)
        contract_tenant      = lookup(v, "tenant", value.tenant)
        label_match_criteria = value.epg_esg_collection_for_vrfs.label_match_criteria
        qos_class            = lookup(v, "template", local.vrf.epg_esg_collection_for_vrfs.contracts.qos_class)
        ndo                  = value.ndo
        tenant               = value.tenant
        vrf                  = key
      }
    ]
  ]) : "${i.vrf}/${i.contract}/${i.contract_type}" => i }

  vrf_sites = { for i in flatten([
    for k, v in local.vrfs : [
      for s in v.ndo.sites : {
        create   = v.create
        schema   = v.ndo.schema
        site     = s
        template = v.ndo.template
        vrf      = k
      }
    ] if local.controller.type == "ndo"
  ]) : "${i.vrf}/${i.site}" => i }

  #__________________________________________________________
  #
  # Bridge Domain Variables
  #__________________________________________________________

  bds_with_template = [
    for v in lookup(local.networking, "bridge_domains", []) : {
      name     = v.name
      template = lookup(v, "template", "")
    } if lookup(v, "template", "") != ""
  ]
  merge_bds_template = { for i in flatten([
    for v in local.bds_with_template : [
      merge(local.networking.bridge_domains[index(local.networking.bridge_domains[*].name, v.name)
      ], local.template_bds[index(local.template_bds[*].template_name, v.template)])
    ] if length(local.template_bds) > 0
  ]) : i.name => i }

  bds = { for v in lookup(local.networking, "bridge_domains", []) : v.name => v }

  merged_bds = merge(local.bds, local.merge_bds_template)

  bridge_domains = {
    for k, v in local.merged_bds : "${local.npfx.bridge_domains}${v.name}${local.nsfx.bridge_domains}" => {
      advanced_troubleshooting = merge(local.adv, lookup(v, "advanced_troubleshooting", {}),
        { netflow_monitor_policies = [
          for e in lookup(lookup(v, "advanced_troubleshooting", {}
            ), "netflow_monitor_policies", []) : {
            ip_filter_type         = lookup(e, "ip_filter_type", local.netflow.ip_filter_type)
            netflow_monitor_policy = e.netflow_monitor_policy
          }]
      })
      application_epg     = lookup(v, "application_epg", {})
      combine_description = lookup(v, "combine_description", local.bd.combine_description)
      dhcp_relay_labels = flatten([
        for s in lookup(v, "dhcp_relay_labels", {}) : [
          for i in lookup(s, "dhcp_servers", []) : merge(local.bd.dhcp_relay_labels, s, { name = i })
        ]
      ])
      general = merge(
        local.general, lookup(v, "general", {}), {
          description = lookup(lookup(v, "general", {}), "description", lookup(v, "description", ""))
          tenant      = var.tenant
          vrf = [for s in [lookup(lookup(v, "general", {}), "vrf", {})] : merge(
            local.general.vrf, lookup(lookup(v, "general", {}), "vrf", {}), {
              name   = "${local.npfx.vrfs}${s.name}${local.nsfx.vrfs}"
              tenant = lookup(s, "tenant", var.tenant)
            }
          )][0]
        }
      )
      l3_configurations = merge(local.l3, lookup(v, "l3_configurations", {}), {
        associated_l3outs = flatten([for e in lookup(lookup(v, "l3_configurations", {}), "associated_l3outs", {}) : [
          for s in lookup(e, "l3outs", []) : {
            l3out         = "${local.npfx.l3outs}${s}${local.npfx.l3outs}"
            route_profile = lookup(e, "route_profile", "")
            tenant        = lookup(e, "tenant", var.tenant)
          }]
        ])
        subnets = [
          for i in lookup(v, "subnets", []) : length(compact([lookup(i, "template", "")])
            ) > 0 && length(local.template_subnets) > 0 ? merge(local.subnet, merge(i, local.template_subnets[
              index(local.template_subnets[*
          ].template_name, i.template)])) : merge(local.subnet, i)
        ]
      })
      name   = "${local.npfx.bridge_domains}${v.name}${local.nsfx.bridge_domains}"
      ndo    = merge({ sites = local.sites }, lookup(v, "ndo", {}))
      tenant = var.tenant
    }
  }
  ndo_bd_sites = { for i in flatten([
    for k, v in local.bridge_domains : [
      for s in range(length(v.ndo.sites)) : {
        advertise_host_routes = s % 2 != 0 ? false : v.general.advertise_host_routes
        bridge_domain         = k
        l3out                 = element(v.l3_configurations.associated_l3outs, s + 1).l3out
        l3out_schema          = v.general.vrf.ndo.schema
        l3out_template        = v.general.vrf.ndo.template
        schema                = v.ndo.schema
        site                  = element(v.ndo.sites, s + 1)
        template              = v.ndo.template
      }
    ]
  ]) : "${i.bridge_domain}/${i.site}" => i if local.controller.type == "ndo" }

  bridge_domain_dhcp_labels = { for i in flatten([
    for key, value in local.bridge_domains : [
      for v in value.dhcp_relay_labels : merge(v, { bridge_domain = key, tenant = value.tenant })
    ]
  ]) : "${i.bridge_domain}/${i.name}" => i }

  bridge_domain_subnets = { for i in flatten([
    for key, value in local.bridge_domains : [
      for v in value.l3_configurations.subnets : merge(
        local.subnet, v,
        {
          bridge_domain  = key, ndo = value.ndo,
          scope          = merge(local.subnet.scope, lookup(v, "scope", {})),
          subnet_control = merge(local.subnet.subnet_control, lookup(v, "subnet_control", {}))
        }
      )
    ]
  ]) : "${i.bridge_domain}/${i.gateway_ip}" => i }

  rogue_coop_exception_list = { for i in flatten([
    for k, v in local.bridge_domains : [
      for s in v.advanced_troubleshooting.rogue_coop_exception_list : {
        bridge_domain = k
        mac_address   = s
        tenant        = v.tenant
      }
    ] if local.controller.type == "apic"
  ]) : "${i.bridge_domain}/${i.mac_address}" => i }


  #__________________________________________________________
  #
  # Application Profile(s) and Endpoint Group(s) - Variables
  #__________________________________________________________

  application_profiles = {
    for v in lookup(var.model, "application_profiles", {}
      ) : "${local.npfx.application_profiles}${v.name}${local.nsfx.application_profiles}" => merge(
      local.app, v,
      {
        annotations = length(lookup(v, "annotations", local.app.annotations)
        ) > 0 ? lookup(v, "annotations", local.app.annotations) : local.annotations
        application_epgs = lookup(v, "application_epgs", [])
        name             = "${local.npfx.application_profiles}${v.name}${local.nsfx.application_profiles}"
        ndo = merge(
          local.app.ndo, lookup(v, "ndo", {}),
          { sites = lookup(lookup(v, "ndo", {}), "sites", local.sites) }
        )
        tenant = var.tenant
      }
    )
  }

  bd_with_epgs = flatten([
    for k, v in local.bridge_domains : [
      for e in [v.application_epg] : {
        application_epg = e
        name            = k
        template        = lookup(e, "template", "")
      } if length(v.application_epg) > 0
    ]
  ])
  bd_to_epg = { for i in flatten([
    for v in local.bd_with_epgs : [
      merge(
        local.bridge_domains[v.name],
        local.template_epgs[index(local.template_epgs[*].template_name, v.template)], {
          application_profile = v.application_epg.application_profile
          bridge_domain       = v.name
          name                = replace(replace(v.name, local.npfx.bridge_domains, ""), local.nsfx.bridge_domains, "")
          vlans               = lookup(v.application_epg, "vlans", [])
        }
      )
    ]
  ]) : i.name => i }

  epgs = { for i in flatten([
    for value in local.application_profiles : [
      for v in value.application_epgs : merge(v, { application_profile = value.name })
    ] if length(value.application_epgs) > 0
  ]) : i.name => i }

  epgs_with_template = [
    for k, v in local.epgs : {
      name     = k
      template = lookup(v, "template", "")
    } if length(compact([lookup(v, "template", "")])) > 0
  ]
  merge_templates = { for i in flatten([
    for v in local.epgs_with_template : [
      merge(local.template_epgs[index(local.template_epgs[*].template_name, v.template)], local.epgs[v.name])
    ]
  ]) : i.name => i }

  merged_epgs = merge(local.bd_to_epg, local.epgs, local.merge_templates)

  application_epgs = { for i in flatten([
    for k, v in local.merged_epgs : merge(local.epg, v, {
      annotations = length(lookup(v, "annotations", local.epg.annotations)
      ) > 0 ? lookup(v, "annotations", local.epg.annotations) : local.annotations
      application_profile = "${local.npfx.application_profiles}${v.application_profile}${local.nsfx.application_profiles}"
      bd = length(compact([lookup(v, "bridge_domain", "")])) > 0 ? {
        name = local.bridge_domains[v.bridge_domain].name
        ndo = merge({ schema = "", sites = [], template = "" },
        local.bridge_domains[v.bridge_domain].ndo)
      } : { name = "", ndo = { schema = "", sites = [], template = "" } }
      contracts   = lookup(v, "contracts", [])
      description = length(lookup(v, "description", "")) > 0 ? lookup(v, "description", "") : lookup(lookup(v, "general", {}), "description", "")
      domains     = lookup(v, "domains", [])
      epg_contract_masters = [
        for s in lookup(v, "epg_contract_masters", []) : {
          application_profile = "${local.npfx.application_profiles}${lookup(s, "application_profile", v.application_profile)}${local.nsfx.application_profiles}"
          application_epg     = s.application_epg
        }
      ]
      name         = "${local.npfx.application_epgs}${v.name}${local.nsfx.application_epgs}"
      ndo          = merge({ sites = local.sites }, lookup(v, "ndo", {}))
      static_paths = lookup(v, "static_paths", [])
      tenant       = var.tenant
      vrf = length(compact([lookup(v, "bridge_domain", "")])) > 0 ? {
        name   = local.bridge_domains[v.bridge_domain].general.vrf.name
        ndo    = merge({ schema = "", sites = [], template = "" }, local.bridge_domains[v.bridge_domain].general.vrf.ndo)
        tenant = local.bridge_domains[v.bridge_domain].general.vrf.tenant
      } : { name = "", ndo = { schema = "", sites = [], template = "" }, tenant = "" }
    })
  ]) : "${i.application_profile}/${i.name}" => i }

  epg_to_domains = { for i in flatten([
    for key, value in local.application_epgs : [
      for v in value.domains : merge(
        local.epg.domains, v,
        { security = merge(local.epg.domains.security, lookup(v, "security", {})) },
        {
          application_profile = value.application_profile
          application_epg     = value.name
          domain              = v.name
          epg_type            = value.epg_type
          key                 = key
          ndo                 = value.ndo
        }
      )
    ]
  ]) : "${i.application_profile}/${i.application_epg}/${i.domain}" => i }
  ndo_epg_to_domains = { for i in flatten([
    for k, v in local.epg_to_domains : [
      for s in range(length(v.sites)) : merge(v, { site = element(v.sites, s) })
    ]
  ]) : "${i.application_profile}/${i.application_epg}/${i.domain}/${i.site}" => i if local.controller.type == "ndo" }

  aaep_to_epgs_loop = [
    for k, v in lookup(var.model, "aaep_to_epgs", {}) : {
      aaep                      = v.name
      access                    = lookup(v, "access_or_native_vlan", 0)
      allowed_vlans             = lookup(v, "allowed_vlans", "")
      instrumentation_immediacy = lookup(v, "instrumentation_immediacy", "on-demand")
      mode = length(regexall("(,|-)", jsonencode(lookup(v, "allowed_vlans", "")))
      ) > 0 ? "trunk" : "native"
      vlan_split = length(regexall("-", lookup(v, "allowed_vlans", ""))
        ) > 0 ? tolist(split(",", lookup(v, "allowed_vlans", ""))) : length(
        regexall(",", lookup(v, "allowed_vlans", ""))) > 0 ? tolist(split(",", lookup(v, "allowed_vlans", ""))
      ) : [lookup(v, "allowed_vlans", "")]
    } if length(compact([lookup(v, "allowed_vlans", "")])) > 0
  ]
  aaep_to_epgs_loop_2 = [for v in local.aaep_to_epgs_loop : merge(v, {
    vlan_list = length(regexall("(,|-)", jsonencode(v.allowed_vlans))) > 0 ? flatten([
      for s in v.vlan_split : length(regexall("-", s)) > 0 ? [for v in range(tonumber(
      element(split("-", s), 0)), (tonumber(element(split("-", s), 1)) + 1)) : tonumber(v)] : [tonumber(s)]
    ]) : [for s in v.vlan_split : tonumber(s)]
  })]
  epg_to_aaeps = { for i in flatten([
    for k, v in local.application_epgs : [
      for e in local.aaep_to_epgs_loop_2 : {
        aaep                      = e.aaep
        access                    = e.access
        application_epg           = v.name
        application_profile       = v.application_profile
        instrumentation_immediacy = e.instrumentation_immediacy
        key                       = k
        mode                      = contains(v.vlans, tonumber(e.access)) ? "native" : e.mode
        vlans                     = lookup(v, "vlans", [])
        } if length(v.vlans) == 2 ? contains(e.vlan_list, tonumber(element(v.vlans, 0))) && contains(
        e.vlan_list, tonumber(element(v.vlans, 1))) : length(v.vlans) == 1 ? contains(
        e.vlan_list, tonumber(element(v.vlans, 0))
      ) : false
    ] if v.epg_type == "standard"
  ]) : "${i.aaep}/${i.application_profile}/${i.application_epg}" => i }

  switch_loop_1 = flatten([
    for v in lookup(var.model.switch, "switch_profiles", []) : [
      for i in lookup(v, "interfaces", []) : {
        access                    = lookup(i, "access_or_native_vlan", 0)
        allowed_vlans             = lookup(i, "allowed_vlans", "")
        encapsulation_type        = lookup(i, "encapsulation_type", "vlan")
        interface                 = lookup(i, "policy_group_type", "access") == "bundle" ? i.policy_group : i.interface
        interface_type            = lookup(i, "policy_group_type", "access")
        node_id                   = v.node_id
        pod_id                    = lookup(v, "pod_id", 1)
        site                      = lookup(v, "site", "")
        instrumentation_immediacy = lookup(i, "instrumentation_immediacy", lookup(v, "instrumentation_immediacy", "immediate"))
        vpc_pair = distinct(flatten([for e in lookup(var.model.switch, "vpc_domains", []
        ) : e.switches if contains([for d in e.switches : tostring(d)], tostring(v.node_id))]))
        mode = length(regexall("(,|-)", jsonencode(lookup(i, "allowed_vlans", "")))
        ) > 0 ? "trunk" : "native"
        vlan_split = length(regexall("-", lookup(i, "allowed_vlans", ""))
          ) > 0 ? tolist(split(",", lookup(i, "allowed_vlans", ""))) : length(
          regexall(",", lookup(i, "allowed_vlans", ""))) > 0 ? tolist(split(",", lookup(i, "allowed_vlans", ""))
        ) : [lookup(i, "allowed_vlans", "")]
      } if v.node_type != "spine" && length(compact([lookup(i, "allowed_vlans", "")])) > 0
    ]
  ])
  switch_loop_2 = [for v in local.switch_loop_1 : merge(v, { path_type = length(v.vpc_pair
    ) == 2 && v.interface_type == "bundle" ? "vpc" : v.interface_type == "bundle" ? "dpc" : "port" }
    ) if length(v.vpc_pair) == 2 ? element(
    v.vpc_pair, 1) == v.node_id && v.interface_type == "bundle" ? false : true : true
  ]
  switch_loop_3 = [for v in local.switch_loop_2 : merge(v, {
    vlan_list = length(regexall("(,|-)", jsonencode(v.allowed_vlans))) > 0 ? flatten([
      for s in v.vlan_split : length(regexall("-", s)) > 0 ? [for v in range(tonumber(
      element(split("-", s), 0)), (tonumber(element(split("-", s), 1)) + 1)) : tonumber(v)] : [tonumber(s)]
    ]) : tonumber(v.vlan_split)
  })]
  epg_to_static_paths = {
    for k, v in local.application_epgs : k => {
      application_profile = v.application_profile
      application_epg     = v.name
      ndo                 = v.ndo
      sites               = distinct(compact([for e in local.switch_loop_3 : lookup(e, "site", "")]))
      static_paths = [
        for e in local.switch_loop_3 : {
          access = e.access
          distinguished_name = length(regexall("apic", local.controller.type)
          ) > 0 ? "${aci_application_epg.map[k].id}/rspathAtt-" : ""
          encapsulation_type        = e.encapsulation_type
          instrumentation_immediacy = e.instrumentation_immediacy == "on-demand" ? "lazy" : "immediate"
          interface                 = e.interface
          leaf = length(regexall("^vpc$", e.path_type)
          ) > 0 ? "${element(e.vpc_pair, 0)}-${element(e.vpc_pair, 1)}" : e.node_id
          mode      = contains(v.vlans, tonumber(e.access)) ? "native" : e.mode
          node_id   = e.node_id
          path_type = e.path_type
          pod_id    = e.pod_id
          tdn = length(regexall("^vpc$", e.path_type)
            ) > 0 ? "topology/pod-${e.pod_id}/protpaths-${element(e.vpc_pair, 0)}-${element(e.vpc_pair, 1)}/pathep-[${e.interface}]" : length(
            regexall("^dpc$", e.path_type)
            ) > 0 ? "topology/pod-${e.pod_id}/paths-${e.node_id}/pathep-[${e.interface}]" : length((regexall("^port$", e.path_type))
          ) > 0 ? "topology/pod-${e.pod_id}/paths-${e.node_id}/pathep-[eth${e.interface}]" : ""
          vpc_pair = length(e.vpc_pair) == 2 ? "${element(e.vpc_pair, 0)}-${element(e.vpc_pair, 1)}" : ""
          vlans    = v.vlans
          } if length(v.vlans) == 2 ? contains(e.vlan_list, tonumber(element(v.vlans, 0))) && contains(
          e.vlan_list, tonumber(element(v.vlans, 1))) : length(v.vlans) == 1 ? contains(
          e.vlan_list, tonumber(element(v.vlans, 0))
        ) : false
      ]
    } if v.epg_type == "standard"
  }

  ndo_epg_to_static_paths = { for i in flatten([
    for k, v in local.epg_to_static_paths : [
      for e in v.sites : merge({ site = e }, v)
    ] if local.controller.type == "ndo"
    ]
  ) : "${i.application_profile}/${i.application_epg}/${i.site}" => i }

  contract_to_epgs = { for i in flatten([
    for key, value in local.application_epgs : [
      for v in value.contracts : {
        application_epg     = value.name
        application_profile = value.application_profile
        contract            = "${local.npfx.contracts}${v.name}${local.nsfx.contracts}"
        contract_class = length(regexall(
          "consumed", lookup(v, "contract_type", local.epg.contracts.contract_type))) > 0 ? "fvRsCons" : length(
          regexall("contract_interface", lookup(v, "contract_type", local.epg.contracts.contract_type))
          ) > 0 ? "fvRsConsIf" : length(regexall(
          "intra_epg", lookup(v, "contract_type", local.epg.contracts.contract_type))
          ) > 0 ? "fvRsIntraEpg" : length(regexall("provided", lookup(
          v, "contract_type", local.epg.contracts.contract_type))
          ) > 0 && length(regexall("oob", value.epg_type)) > 0 ? "mgmtRsOoBProv" : length(regexall(
          "provided", lookup(v, "contract_type", local.epg.contracts.contract_type))) > 0 ? "fvRsProv" : length(
          regexall("taboo", lookup(v, "contract_type", local.epg.contracts.contract_type)
        )) > 0 ? "fvRsProtBy" : ""
        contract_dn = length(regexall(
          "consumed", lookup(v, "contract_type", local.epg.contracts.contract_type))) > 0 ? "rscons" : length(
          regexall("contract_interface", lookup(v, "contract_type", local.epg.contracts.contract_type))
          ) > 0 ? "rsconsIf" : length(regexall("intra_epg", lookup(
            v, "contract_type", local.epg.contracts.contract_type))) > 0 ? "rsintraEpg" : length(regexall(
            "provided", lookup(v, "contract_type", local.epg.contracts.contract_type))) > 0 && length(regexall(
            "oob", value.epg_type)) > 0 ? "rsooBProv" : length(regexall(
          "provided", lookup(v, "contract_type", local.epg.contracts.contract_type))) > 0 ? "rsprov" : length(
          regexall("taboo", lookup(v, "contract_type", local.epg.contracts.contract_type))
        ) > 0 ? "rsprotBy" : ""
        contract_tdn = length(regexall("taboo", lookup(v, "contract_type", local.epg.contracts.contract_type))
        ) > 0 ? "taboo" : "brc"
        contract_tenant = lookup(v, "tenant", var.tenant)
        contract_type   = lookup(v, "contract_type", local.epg.contracts.contract_type)
        ndo = {
          contract_schema   = lookup(lookup(v, "ndo", {}), "schema", lookup(value.ndo, "schema", ""))
          contract_template = lookup(lookup(v, "ndo", {}), "template", lookup(value.ndo, "template", ""))
          schema            = lookup(value.ndo, "schema", "")
          template          = lookup(value.ndo, "template", "")
        }
        qos_class = lookup(v, "qos_class", local.epg.contracts.qos_class)
        epg_type  = value.epg_type
        tenant    = value.tenant
      }
    ]
  ]) : "${i.application_profile}/${i.application_epg}/${i.contract_type}/${i.contract}" => i }


  #__________________________________________________________
  #
  # Contract Variables
  #__________________________________________________________
  contracts = {
    for v in lookup(local.tenant_contracts, "contracts", []
      ) : "${local.npfx.contracts}${v.name}${local.nsfx.contracts}" => merge(
      local.contract, v,
      {
        annotations = length(lookup(v, "annotations", local.contract.annotations)
        ) > 0 ? lookup(v, "annotations", local.contract.annotations) : local.annotations
        filters = flatten([for s in lookup(v, "subjects", []) : [
          for e in s.filters : merge(local.contract.subjects, s, { name = "${local.npfx.filters}${e}${local.nsfx.filters}" })]
        ])
        name     = "${local.npfx.contracts}${v.name}${local.nsfx.contracts}"
        subjects = lookup(v, "subjects", [])
        schema   = local.schema
        sites    = local.sites
        template = lookup(v, "template", "")
        tenant   = var.tenant
      }
    )
  }

  contract_subjects = { for i in flatten([
    for key, value in local.contracts : [
      for v in value.subjects : merge(
        local.contract.subjects, v, {
          contract      = key
          contract_type = value.contract_type
          filters       = lookup(v, "filters", [])
          tenant        = value.tenant
        }
      )
    ] if local.controller.type == "apic"
  ]) : "${i.contract}/${i.name}" => i }

  subject_filters = { for i in flatten([
    for k, v in local.contract_subjects : [
      for s in v.filters : merge(local.contract.subjects,
        v, {
          filter  = "${local.npfx.filters}${s}${local.nsfx.filters}"
          subject = v.name
        }
      )
    ]
  ]) : "${i.contract}/${i.subject}/${i.filter}" => i }


  #__________________________________________________________
  #
  # Filter Variables
  #__________________________________________________________
  filters = {
    for v in lookup(local.tenant_contracts, "filters", []) : "${local.npfx.filters}${v.name}${local.nsfx.filters}" => {
      alias = lookup(v, "alias", local.filter.alias)
      annotations = length(lookup(v, "annotations", local.filter.annotations)
      ) > 0 ? lookup(v, "annotations", local.filter.annotations) : local.annotations
      description    = lookup(v, "description", local.filter.description)
      filter_entries = lookup(v, "filter_entries", [])
      name           = "${local.npfx.filters}${v.name}${local.nsfx.filters}"
      schema         = local.schema
      template       = lookup(v, "template", "")
      tenant         = var.tenant
    }
  }

  filter_entries = { for i in flatten([
    for key, value in local.filters : [
      for v in value.filter_entries : merge(
        local.filter.filter_entries, v,
        {
          filter_name = key
          name        = v.name
          schema      = value.schema
          tcp_session_rules = merge(
            local.filter.filter_entries.tcp_session_rules, lookup(v, "tcp_session_rules", {})
          )
          template = value.template
          tenant   = var.tenant
        }
      )
    ]
  ]) : "${i.filter_name}:${i.name}" => i }


  #__________________________________________________________
  #
  # L3Out Variables
  #__________________________________________________________

  #==================================
  # L3Outs
  #==================================

  l3outs = {
    for v in lookup(local.networking, "l3outs", []) : "${local.npfx.l3outs}${v.name}${local.nsfx.l3outs}" => merge(
      local.l3out, v, {
        annotations = length(lookup(v, "annotations", local.l3out.annotations)
        ) > 0 ? lookup(v, "annotations", local.l3out.annotations) : local.annotations
        external_epgs         = lookup(v, "external_epgs", [])
        logical_node_profiles = lookup(v, "logical_node_profiles", [])
        ndo = {
          schema   = lookup(lookup(v, "ndo", {}), "schema", local.schema)
          sites    = lookup(lookup(v, "ndo", {}), "sites", local.sites)
          template = lookup(lookup(v, "ndo", {}), "template", local.l3out.ndo.template)
        }
        ospf_external_profile = lookup(v, "ospf_external_profile", [])
        route_control_enforcement = { import = lookup(lookup(v, "route_control_enforcement", {}
        ), "import", local.l3out.route_control_enforcement.import) }
        route_control_for_dampening = [for s in lookup(v, "route_control_for_dampening", []) : {
          address_family = lookup(s, "address_family", "ipv4"), route_map = s.route_map
        }]
        route_profiles_for_redistribution = lookup(v, "route_profiles_for_redistribution", [])
        tenant                            = var.tenant
        vrf                               = "${local.npfx.vrfs}${v.vrf}${local.nsfx.vrfs}"
        vrf_template                      = lookup(v, "vrf_template", lookup(lookup(v, "ndo", {}), "template", local.l3out.ndo.template))
      }
    )
  }

  l3out_route_profiles_for_redistribution = { for i in flatten([
    for key, value in local.l3outs : [
      for v in value.route_profiles_for_redistribution : {
        l3out     = key
        tenant    = value.tenant
        rm_l3out  = lookup(v, "l3out", local.l3out.route_profiles_for_redistribution.l3out)
        source    = lookup(v, "source", local.l3out.route_profiles_for_redistribution.source)
        route_map = v.route_map
      }
    ]
  ]) : "${i.l3out}/${i.route_map}/${i.source}" => i }

  #==================================
  # L3Outs - External EPGs
  #==================================

  l3out_external_epgs = { for i in flatten([
    for key, value in local.l3outs : [
      for v in value.external_epgs : merge(
        local.l3out.external_epgs, v, {
          contracts = lookup(v, "contracts", [])
          l3out     = key
          l3out_contract_masters = [
            for s in lookup(v, "l3out_contract_masters", []) : { external_epg = s.external_epg, l3out = s.l3out }
          ]
          name = "${local.npfx.external_epgs}${v.name}${local.nsfx.external_epgs}"
          ndo = {
            schema   = lookup(lookup(v, "ndo", {}), "schema", value.ndo.schema)
            sites    = lookup(lookup(v, "ndo", {}), "sites", value.ndo.sites)
            template = lookup(lookup(v, "ndo", {}), "template", value.ndo.template)
          }
          subnets = lookup(v, "subnets", [])
          route_control_profiles = [
            for s in lookup(v, "route_control_profiles", []) : { direction = s.direction, route_map = s.route_map }
          ]
          tenant = value.tenant
        }
      )
    ]
  ]) : "${i.l3out}/${i.name}" => i }

  l3out_ext_epg_contracts = { for i in flatten([
    for key, value in local.l3out_external_epgs : [
      for v in value.contracts : merge(
        local.l3out.external_epgs.contracts, v, {
          contract     = "${local.npfx.contracts}${v.name}${local.nsfx.contracts}",
          external_epg = key,
          ndo = {
            schema   = lookup(lookup(v, "ndo", {}), "schema", value.ndo.schema)
            sites    = lookup(lookup(v, "ndo", {}), "sites", value.ndo.sites)
            template = lookup(lookup(v, "ndo", {}), "template", value.ndo.template)
          }
          tenant = value.tenant
        }
      )
    ]
  ]) : "${i.external_epg}/${i.contract_type}/${i.contract}" => i }

  l3out_external_epg_subnets = { for i in flatten([
    for key, value in local.l3out_external_epgs : [for v in lookup(value, "subnets", []) : [
      for s in v.subnets : merge(
        local.subnets, v, {
          aggregate    = merge(local.subnets.aggregate, lookup(v, "aggregate", {}))
          external_epg = key, l3out = value.l3out
          route_control_profiles = [
            for s in lookup(v, "route_control_profiles", []) : { direction = s.direction, route_map = s.route_map }
          ]
          external_epg_classification = merge(
            local.subnets.external_epg_classification, lookup(v, "external_epg_classification", {})
          )
          ndo           = value.ndo
          route_control = merge(local.subnets.route_control, lookup(v, "route_control", {}))
          subnet        = s
        }
      )
    ]] if length(lookup(value, "subnets", [])) > 0
  ]) : "${i.external_epg}/${i.subnet}" => i }

  #=======================================================================================
  # L3Outs - OSPF External Policies
  #=======================================================================================

  l3out_ospf_external_profile = { for i in flatten([
    for key, value in local.l3outs : [for v in [value.ospf_external_profile] : merge(
      local.l3ospf, v, {
        l3out             = key, tenant = var.tenant
        ospf_area_control = merge(local.l3ospf.ospf_area_control, lookup(v, "ospf_area_control", {}))
      }
    )] if length(value.ospf_external_profile) > 0
  ]) : "${i.l3out}:ospf-external-profile" => i }

  #=======================================================================================
  # L3Outs - Logical Node Profiles
  #=======================================================================================

  l3out_node_profiles = { for i in flatten([
    for key, value in local.l3outs : [
      for v in value.logical_node_profiles : merge(
        local.lnp, v, {
          l3out              = key, tenant = value.tenant
          interface_profiles = lookup(v, "logical_interface_profiles", [])
          name               = "${local.npfx.logical_node_profiles}${v.name}${local.nsfx.logical_node_profiles}"
          ndo                = value.ndo
          nodes = [
            for s in lookup(v, "nodes", []) : {
              l3out         = key, node_id = s.node_id, router_id = s.router_id, tenant = value.tenant
              node_profile  = "${key}/${local.npfx.logical_node_profiles}${v.name}${local.nsfx.logical_node_profiles}"
              pod_id        = lookup(v, "pod_id", local.lnp.pod_id)
              static_routes = lookup(v, "static_routes", [])
              use_router_id_as_loopback = lookup(
                s, "use_router_id_as_loopback", local.lnp.nodes.use_router_id_as_loopback
              )
            }
          ]
          vrf = value.vrf
        }
      )
    ]
  ]) : "${i.l3out}/${i.name}" => i }

  l3out_node_profiles_nodes = { for i in flatten([
    for key, value in local.l3out_node_profiles : [
      for v in value.nodes : merge(v, {
        l3out  = v.l3out
        ndo    = value.ndo
        pod_id = value.pod_id
        tenant = value.tenant
        vrf    = value.vrf
      })
    ]
  ]) : "${i.node_profile}/${i.node_id}" => i }

  #=======================================================================================
  # L3Outs - Logical Node Profiles - Static Routes
  #=======================================================================================

  l3out_node_profile_static_routes = { for i in flatten([
    for key, value in local.l3out_node_profiles_nodes : [
      for v in value.static_routes : [
        for e in lookup(v, "prefixes", {}) : merge(local.lnpstrt, value, v, {
          key                = key
          next_hop_addresses = lookup(v, "next_hop_addresses", {})
          prefix             = e
          route_control = {
            bfd = lookup(lookup(v, "route_control", {}), "bfd", local.lnpstrt.route_control.bfd)
          }
          track_list_policy = lookup(v, "track_list_policy", local.lnpstrt.track_list_policy)
          vrf               = value.vrf
        })
      ]
    ]
  ]) : "${i.key}/${i.prefix}" => i }

  l3out_static_routes_next_hop = { for i in flatten([
    for key, value in local.l3out_node_profile_static_routes : [
      for v in [value.next_hop_addresses] : [
        for e in v.next_hop_ips : merge(local.lnpsrnh, value, v, {
          key         = key
          next_hop_ip = e.next_hop_ip
          preference  = lookup(e, "preference", local.lnpsrnh.next_hop_ips.preference)
          prefix_dn   = key
          track_list  = lookup(v, "track_list", false) == true ? "${value.vrf}_${e.next_hop_ip}" : ""
          track_member = lookup(v, "track_list", false) == true && lookup(v, "track_member", false
          ) == true ? "${value.vrf}_${e.next_hop_ip}" : ""
          vrf = value.vrf
        })
      ]
    ]
  ]) : "${i.key}/${i.next_hop_ip}" => i }

  #=======================================================================================
  # L3Outs - Logical Node Profiles - Logical Interface Profiles
  #=======================================================================================

  l3out_interface_profiles = { for i in flatten([
    for key, value in local.l3out_node_profiles : [
      for v in value.interface_profiles : merge(
        local.lip, v, {
          color_tag              = value.color_tag
          bgp_peers              = lookup(v, "bgp_peers", [])
          l3out                  = value.l3out
          hsrp_interface_profile = lookup(v, "hsrp_interface_profile", {})
          netflow_monitor_policies = [
            for s in lookup(v, "netflow_monitor_policies", []) : {
              filter_type    = s.filter_type != null ? s.filter_type : "ipv4"
              netflow_policy = s.netflow_policy
            }
          ]
          name                   = "${local.npfx.logical_interface_profiles}${v.name}${local.nsfx.logical_interface_profiles}"
          ndo                    = value.ndo
          node_profile           = key
          nodes                  = [for keys, values in value.nodes : value.nodes[keys]["node_id"]]
          ospf_interface_profile = lookup(v, "ospf_interface_profile", {})
          pod_id                 = value.pod_id
          svi_addresses          = lookup(v, "svi_addresses", {})
          target_dscp            = value.target_dscp
          tenant                 = value.tenant
        }
      )
    ]
  ]) : "${i.node_profile}/${i.name}" => i }

  l3out_paths_svi_addressing = { for i in flatten([
    for key, value in local.l3out_interface_profiles : [
      for v in [value.svi_addresses] : [
        for s in range(length(v.primary_preferred_addresses)) : {
          ipv6_dad = value.ipv6_dad
          link_local_address = length(lookup(v, "link_local_addresses", [])
          ) == 2 ? element(v.link_local_addresses, s) : "::"
          l3out_interface_profile   = key
          ndo                       = value.ndo
          primary_preferred_address = element(v.primary_preferred_addresses, s)
          secondary_addresses = length(lookup(v, "secondary_addresses", [])) % 2 == 0 && length(
            lookup(v, "secondary_addresses", [])) > 0 ? element(chunklist(
            v.secondary_addresses, length(v.secondary_addresses) / 2), s
          ) : []
          side           = length(regexall("false", tostring(s % 2 != 0))) > 0 ? "A" : "B"
          interface_type = value.interface_type
        }
      ]] if length(regexall("^eth[0-9]{1,2}/\\d{1,3}(/\\d{1,3})?$", value.interface_or_policy_group)
    ) == 0 && value.interface_type == "ext-svi"
  ]) : "${i.l3out_interface_profile}/${i.side}" => i }

  interface_secondaries_ips = { for i in flatten([
    for k, v in local.l3out_interface_profiles : [
      for s in range(length(v.secondary_addresses)) : {
        ipv6_dad                = v.ipv6_dad
        l3out_interface_profile = k
        path_type               = "other"
        secondary_ip_address    = element(v.secondary_addresses, s)
      }
    ]
  ]) : "${i.l3out_interface_profile}/${i.secondary_ip_address}" => i }

  svi_secondaries_ips = { for i in flatten([
    for k, v in local.l3out_paths_svi_addressing : [
      for s in range(length(v.secondary_addresses)) : {
        ipv6_dad                = v.ipv6_dad
        l3out_interface_profile = k
        path_type               = "svi"
        secondary_ip_address    = element(v.secondary_addresses, s)
      }
    ]
  ]) : "${i.l3out_interface_profile}/${i.secondary_ip_address}" => i }
  l3out_paths_secondary_ips = merge(local.interface_secondaries_ips, local.svi_secondaries_ips)

  #=======================================================================================
  # L3Outs - Logical Node Profiles - Logical Interface Profiles - BGP Peers
  #=======================================================================================

  bgp_peer_connectivity_profiles = { for i in flatten([
    for key, value in local.l3out_interface_profiles : [
      for v in value.bgp_peers : [
        for s in range(length(v.peer_addresses)) : merge(
          local.bgppeer, v, {
            address_type_controls   = merge(local.bgppeer.address_type_controls, lookup(v, "address_type_controls", {}))
            bgp_controls            = merge(local.bgppeer.bgp_controls, lookup(v, "bgp_controls", {}))
            l3out_interface_profile = key
            ndo                     = value.ndo
            node_profile            = value.node_profile
            peer_address            = element(v.peer_addresses, s)
            peer_asn                = v.peer_asn
            peer_controls           = merge(local.bgppeer.peer_controls, lookup(v, "peer_controls", {}))
            private_as_control      = merge(local.bgppeer.private_as_control, lookup(v, "private_as_control", {}))
            route_control_profiles = [
              for s in lookup(v, "route_control_profiles", []) : { direction = s.direction, route_map = s.route_map }
            ]
          }
        )
      ]
    ]
  ]) : "${i.l3out_interface_profile}-bgp/${i.peer_address}" => i }


  #=======================================================================================
  # L3Outs - Logical Node Profiles - Logical Interface Profiles - HSRP Interface Profiles
  #=======================================================================================

  hsrp_interface_profile = { for i in flatten([
    for key, value in local.l3out_interface_profiles : [
      for v in [value.hsrp_interface_profile] : merge(local.hip, v, { groups = lookup(v, "groups", []) },
      { l3out_interface_profile = key })
    ] if length(value.hsrp_interface_profile) > 0
  ]) : "${i.l3out_interface_profile}-hsrp" => i }

  hsrp_interface_profile_groups = { for i in flatten([
    for key, value in local.hsrp_interface_profile : [
      for v in value.groups : merge(local.hip.groups, v, { hsrp_interface_profile = key })
    ]
  ]) : "${i.hsrp_interface_profile}/${i.name}" => i }

  hsrp_interface_profile_group_secondaries = { for i in flatten([
    for key, value in local.hsrp_interface_profile_groups : [for s in value.secondary_virtual_ips : {
      hsrp_interface_profile_group = key
      secondary_ip                 = s
    }]
  ]) : "${i.hsrp_interface_profile_group}/${i.secondary_ip}" => i }

  #=======================================================================================
  # L3Outs - Logical Node Profiles - Logical Interface Profiles - OSPF Interface Policies
  #=======================================================================================

  l3out_ospf_interface_profiles = { for i in flatten([
    for key, value in local.l3out_interface_profiles : [for v in [value.ospf_interface_profile] : merge(local.ospfip, v, {
      l3out_interface_profile = key
      l3out                   = value.l3out
      ndo                     = value.ndo
      tenant                  = value.tenant
    })] if length(value.ospf_interface_profile) > 0
  ]) : "${i.l3out_interface_profile}:ospf" => i }


  #__________________________________________________________
  #
  # Policies - BFD Interface
  #__________________________________________________________

  bfd_interface = {
    for v in lookup(local.protocol, "bfd_interface", []
    ) : v.name => merge(local.bfd, v, { tenant = var.tenant })
  }


  #__________________________________________________________
  #
  # Policies - BGP
  #__________________________________________________________
  bgp = lookup(local.protocol, "bgp", {})
  bgp_address_family_context = {
    for v in lookup(local.bgp, "bgp_address_family_context", []) : v.name => merge(local.bgpa, v, { tenant = var.tenant })
  }
  bgp_best_path = {
    for v in lookup(local.bgp, "bgp_best_path", []) : v.name => merge(local.bgpb, v, { tenant = var.tenant })
  }
  bgp_peer_prefix = {
    for v in lookup(local.bgp, "bgp_peer_prefix", []) : v.name => merge(local.bgpp, v, { tenant = var.tenant })
  }
  bgp_route_summarization = {
    for v in lookup(local.bgp, "bgp_route_summarization", []) : v.name => merge(local.bgps, v, {
      address_type_controls = merge(local.bgps.address_type_controls, lookup(v, "address_type_controls", {}))
      control_state         = merge(local.bgps.control_state, lookup(v, "control_state", {}))
      tenant                = var.tenant
    })
  }
  bgp_timers = {
    for v in lookup(local.bgp, "bgp_timers", []) : v.name => merge(local.bgpt, v, { tenant = var.tenant })
  }


  #__________________________________________________________
  #
  # Policies - DHCP Variables
  #__________________________________________________________
  dhcp = lookup(local.protocol, "dhcp", {})
  dhcp_option = { for v in lookup(local.dhcp, "option_policies", []) : v.name => {
    description = lookup(v, "description", local.dhcpo.description)
    options = { for value in lookup(v, "options", []) : value.option_id => {
      data = value.data, name = lookup(value, "name", value.option_id), option_id = value.option_id }
    }
    tenant = var.tenant
  } }
  dhcp_relay = flatten([for v in lookup(local.dhcp, "relay_policies", []) : [
    for e in v.dhcp_servers : merge(local.dhcpr, v, { dhcp_server = e }, { tenant = var.tenant })
  ]])


  #__________________________________________________________
  #
  # Policies - Endpoint Retention Variables
  #__________________________________________________________

  endpoint_retention = {
    for v in lookup(local.protocol, "endpoint_retention", []) : v.name => merge(local.ep, v, { tenant = var.tenant })
  }


  #__________________________________________________________
  #
  # Policies - HSRP
  #__________________________________________________________
  hsrp       = lookup(local.protocol, "hsrp", {})
  hsrp_group = { for v in lookup(local.hsrp, "group_policies", []) : v.name => merge(local.hsrpg, v, { tenant = var.tenant }) }
  hsrp_interface = {
    for v in lookup(local.hsrp, "interface_policies", []) : v.name => merge(local.hsrpi, v, { tenant = var.tenant })
  }

  #__________________________________________________________
  #
  # Policies - IP SLA
  #__________________________________________________________
  ip_sla = lookup(local.protocol, "ip_sla", {})
  ip_sla_monitoring = {
    for v in lookup(local.ip_sla, "ip_sla_monitoring_policies", []) : v.name => merge(local.sla, v, { tenant = var.tenant })
  }

  track_lists = merge({
    for k, v in local.l3out_static_routes_next_hop : "${v.vrf}_${v.next_hop_ip}" => {
      name            = "${v.vrf}_${v.next_hop_ip}"
      percentage_down = 50
      percentage_up   = 100
      tenant          = v.tenant
      type            = "percentage"
      weight_down     = 0
      weight_up       = 1
    } if v.track_list == true }
  )
  track_members = []

  #__________________________________________________________
  #
  # Policies - L4-L7 Policy-Based Redirect
  #__________________________________________________________
  l4_l7_policy_based_redirect = {
    for v in lookup(local.protocol, "l4-l7_policy-based_redirect", []
    ) : v.name => merge(local.l4l7pbr, v, { destinations = lookup(v, "destinations", []) }, { tenant = var.tenant })
  }

  l4_l7_pbr_destinations = { for i in flatten([
    for key, value in local.l4_l7_policy_based_redirect : [
      for k, v in value.destinations : {
        additional_ipv4_ipv6 = length(regexall("L3", value.destination_type)
        ) > 0 ? lookup(v, "additional_ipv4_ipv6", local.l4l7pbr.destinations.additional_ipv4_ipv6) : "0.0.0.0"
        ip       = length(regexall("L3", value.destination_type)) > 0 ? lookup(v, "ip", "0.0.0.0") : "0.0.0.0"
        dest_key = k
        mac = length(regexall("^(L1|L2)$", value.destination_type)
        ) > 0 ? lookup(v, "mac", local.l4l7pbr.destinations.mac) : ""
        pod_id = lookup(v, "pod_id", local.l4l7pbr.destinations.pod_id)
        redirect_health_group = length(regexall("L3", value.destination_type)
        ) > 0 ? lookup(v, "redirect_health_group", local.l4l7pbr.destinations.redirect_health_group) : ""
      }
    ]
  ]) : "${i.l4_l7_pbr_policy}/${i.dest_key}" => i }

  #__________________________________________________________
  #
  # Policies - L4-L7 Redirect Health Groups
  #__________________________________________________________
  l4_l7_redirect_health_groups = {
    for v in lookup(local.protocol, "l4-l7_redirect_health_groups", []) : v.name => {
      description = lookup(v, "description", local.l4l7rhg.description)
    }
  }


  #__________________________________________________________
  #
  # Policies - OSPF Variables
  #__________________________________________________________
  ospf = lookup(local.protocol, "ospf", {})
  ospf_interface = {
    for v in lookup(local.ospf, "ospf_interface", []) : v.name => merge(local.ospfi, v, {
      interface_controls = merge(local.ospfi.interface_controls, lookup(v, "interface_controls")), tenant = var.tenant
    })
  }
  ospf_route_summarization = {
    for v in lookup(local.ospf, "ospf_route_summarization", []) : v.name => merge(local.ospfs, v, { tenant = var.tenant })
  }
  ospf_timers = {
    for v in lookup(local.ospf, "ospf_timers", []) : v.name => merge(local.ospft, v, {
      control_knobs = merge(local.ospft.control_knobs, lookup(v, "control_knobs", {})), tenant = var.tenant
    })
  }


  #__________________________________________________________
  #
  # Route Map Match Rule Variables
  #__________________________________________________________

  route_map_match_rules = {
    for v in lookup(local.protocol, "route_map_match_rules", []) : v.name => {
      description                  = lookup(v, "description", local.rmsr.description)
      match_community_terms        = lookup(v, "match_community_terms", [])
      match_regex_community_terms  = lookup(v, "match_regex_community_terms", [])
      match_route_destination_rule = lookup(v, "match_route_destination_rule", [])
      tenant                       = var.tenant
    }
  }
  match_rules_match_community_terms = { for i in flatten([
    for key, value in local.route_map_match_rules : [
      for v in value.match_community_terms : {
        description = lookup(v, "description", local.rmmr.match_community_terms.description)
        match_community_factors = [
          for i in lookup(v, "match_community_factors", []) : {
            community   = v.community
            description = lookup(v, "description", local.rmmr.match_community_terms.match_community_factors.description)
            scope       = lookup(v, "scope", local.rmmr.match_community_terms.match_community_factors.scope)
          }
        ]
        match_rule = key
        name       = v.name
        tenant     = value.tenant
      }
    ]
  ]) : "${i.match_rule}/${i.name}" => i }

  match_rules_match_regex_community_terms = { for i in flatten([
    for key, value in local.route_map_match_rules : [
      for v in value.match_regex_community_terms : {
        community_type     = lookup(v, "community_type", local.rmmr.match_regex_community_terms.community_type)
        description        = lookup(v, "description", local.rmmr.match_regex_community_terms.description)
        match_rule         = key
        name               = v.name
        regular_expression = v.regular_expression
        tenant             = value.tenant
      }
    ]
  ]) : "${i.match_rule}/${i.community_type}" => i }

  match_rules_match_route_destination_rule = { for i in flatten([
    for key, value in local.route_map_match_rules : [
      for v in value.rules : {
        description       = lookup(v, "description", local.rmmr.match_route_destination_rule.description)
        greater_than_mask = lookup(v, "greater_than", local.rmmr.match_route_destination_rule.greater_than_mask)
        ip                = v.ip
        less_than_mask    = lookup(v, "less_than", local.rmmr.match_route_destination_rule.less_than_mask)
        match_rule        = key
        tenant            = value.tenant
      }
    ]
  ]) : "${i.match_rule}/${i.ip}" => i }


  #__________________________________________________________
  #
  # Route Map Set Rule Variables
  #__________________________________________________________

  route_map_set_rules = {
    for v in lookup(local.protocol, "route_map_set_rules", []) : v.name => merge(local.rmsr, v, {
      additional_communities = lookup(v, "additional_communities", [])
      set_as_path            = lookup(v, "set_as_path", [])
      set_communities        = lookup(v, "set_communities", [])
      set_dampening          = lookup(v, "set_dampening", [])
      set_external_epg       = lookup(v, "set_external_epg", [])
      tenant                 = var.tenant
    })
  }

  set_rules_additional_communities = { for i in flatten([
    for key, value in local.route_map_set_rules : [for v in value.additional_communities : {
      community   = v.community
      description = lookup(v, "description", local.rmsr.rules.communites.description)
      set_rule    = value.set_rule
      tenant      = value.tenant
    }]
  ]) : "${i.set_rule}/${i.community}" => i }

  set_rules_set_as_path = { for i in flatten([
    for key, value in local.route_map_set_rules : [for v in value.set_as_path : {
      autonomous_systems = length(lookup(v, "autonomous_systems", [])) > 0 ? [
        for s in range(length(v.autonomous_systems)) : { asn = element(v.autonomous_systems, s), order = s }
      ] : []
      criteria      = lookup(v, "criteria", local.rmsr.set_as_path.criteria)
      last_as_count = lookup(v, "last_as_count", local.rmsr.set_as_path.last_as_count)
      set_rule      = value.set_rule
      tenant        = value.tenant
    }]
  ]) : "${i.set_rule}/${i.criteria}" => i }

  set_rules_set_communities = { for i in flatten([
    for key, value in local.route_map_set_rules : [for v in value.set_communities : {
      community = lookup(v, "community", local.rmsr.set_communities.community)
      criteria  = lookup(v, "criteria", local.rmsr.set_communities.criteria)
      set_rule  = key
      tenant    = var.tenant
    }]
  ]) : "${i.set_rule}/${i.criteria}" => i }

  set_rules_set_dampening = { for i in flatten([
    for key, value in local.route_map_set_rules : [for v in value.set_dampening : {
      half_life         = lookup(v, "half_life", local.rmsr.rules.half_life)
      max_suprress_time = lookup(v, "max_suprress_time", local.rmsr.rules.max_suprress_time)
      reuse_limit       = lookup(v, "reuse_limit", local.rmsr.rules.reuse_limit)
      set_rule          = key
      suppress_limit    = lookup(v, "suppress_limit", local.rmsr.rules.suppress_limit)
      tenant            = var.tenant
    }]
  ]) : "${i.set_rule}-dampening" => i }

  set_rules_set_external_epg = { for i in flatten([
    for key, value in local.route_map_set_rules : [for v in value.rules : {
      epg_tenant     = v.tenant
      external_epg   = v.external_epg
      l3out          = v.l3out
      set_rule       = key
      suppress_limit = lookup(v, "suppress_limit", local.rmsr.rules.suppress_limit)
    }]
  ]) : "${i.set_rule}-external-epg" => i }


  #__________________________________________________________
  #
  # Route Maps Rule Variables
  #__________________________________________________________

  route_maps_for_route_control = {
    for v in lookup(local.protocol, "route_maps_for_route_control", []) : v.name => {
      contexts           = lookup(v, "contexts", [])
      description        = lookup(v, "description", local.rm.description)
      route_map_continue = lookup(v, "route_map_continue", local.rm.route_map_continue)
      tenant             = var.tenant
      type               = lookup(v, "type", local.rm.type)
    }
  }

  route_map_contexts = { for i in flatten([
    for key, value in local.route_maps_for_route_control : [for k, v in value.contexts : {
      action                 = v.action
      description            = lookup(v, "description", local.rm.contexts.description)
      associated_match_rules = [for i in lookup(v, "associated_match_rules", []) : { rule_name = i }]
      name                   = v.name
      order                  = k
      route_map              = key
      set_rule               = lookup(v, "set_rule", local.rm.contexts.set_rule)
      tenant                 = value.tenant
    }]
  ]) : "${i.route_map}/${i.name}" => i }


  #__________________________________________________________
  #
  # L4-L7 Variables
  #__________________________________________________________

  #==================================
  # L4-L7 Devices
  #==================================
  l4_l7_devices       = {}
  concrete_devices    = {}
  concrete_interfaces = {}
  logical_interfaces  = {}

  #==================================
  # L4-L7 Service Graph Templates
  #==================================
  l4_l7_service_graph_templates   = {}
  l4_l7_service_graph_connections = {}
  function_nodes                  = {}
}
