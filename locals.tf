locals {
  #__________________________________________________________
  #
  # Model Inputs
  #__________________________________________________________

  defaults          = lookup(var.model, "defaults", {})
  networking        = lookup(local.tenant[var.tenant], "networking", {})
  policies          = lookup(local.tenant[var.tenant], "policies", {})
  static_mgmt_add   = lookup(lookup(local.tenant[var.tenant], "node_management_addresses", {}), "static_node_management_addresses", {})
  templates_bds     = lookup(lookup(var.model, "templates", {}), "bridge_domains", {})
  templates_epgs    = lookup(lookup(var.model, "templates", {}), "application_epgs", {})
  templates_subnets = lookup(lookup(var.model, "templates", {}), "subnets", {})
  tenant            = lookup(var.model, "tenants", {})
  tenant_contracts  = lookup(local.tenant[var.tenant], "contracts", {})

  # Defaults
  apic_inb = local.defaults.tenants.node_management_addresses.static_node_management_addresses.apics_inband
  app      = local.defaults.tenants.application_profiles
  adv      = local.bd.advanced_troubleshooting
  bd       = local.defaults.tenants.networking.bridge_domains
  bfd      = local.defaults.tenants.policies.protocol.bfd_interface
  bgpa     = local.defaults.tenants.policies.protocol.bgp.bgp_address_family_context
  bgpb     = local.defaults.tenants.policies.protocol.bgp.bgp_best_path
  bgpp     = local.defaults.tenants.policies.protocol.bgp.bgp_peer_prefix
  bgppeer  = local.lip.bgp_peers
  bgps     = local.defaults.tenants.policies.protocol.bgp.bgp_route_summarization
  bgpt     = local.defaults.tenants.policies.protocol.bgp.bgp_timers
  contract = local.defaults.tenants.contracts.contracts
  dhcpo    = local.defaults.tenants.policies.protocol.dhcp.option_policies
  dhcpr    = local.defaults.tenants.policies.protocol.dhcp.relay_policies
  ep       = local.defaults.tenants.policies.protocol.endpoint_retention
  epg      = local.app.application_epgs
  filter   = local.defaults.tenants.contracts.filters
  general  = local.bd.general
  hip      = local.lip.hsrp_interface_profiles
  hsrpg    = local.defaults.tenants.policies.protocol.hsrp.group_policies
  hsrpi    = local.defaults.tenants.policies.protocol.hsrp.interface_policies
  l3       = local.bd.l3_configurations
  l3ospf   = local.l3out.ospf_external_profile
  l3out    = local.defaults.tenants.networking.l3outs
  l4l7pbr  = local.defaults.tenants.policies.protocol.l4-l7_policy-based_redirect
  l4l7rhg  = local.defaults.tenants.policies.protocol.l4-l7_redirect_health_groups
  lnp      = local.l3out.logical_node_profiles
  lnpstrt  = local.l3out.logical_node_profiles.static_routes
  lnpsrnh  = local.l3out.logical_node_profiles.static_routes.next_hop_addresses
  lip      = local.lnp.logical_interface_profiles
  ospfi    = local.defaults.tenants.policies.protocol.ospf.ospf_interface
  ospfs    = local.defaults.tenants.policies.protocol.ospf.ospf_route_summarization
  ospft    = local.defaults.tenants.policies.protocol.ospf.ospf_timers
  ospfip   = local.lnp.logical_interface_profiles.ospf_interface_profile
  sla      = local.defaults.tenants.policies.protocol.ip_sla.ip_sla_monitoring_policies
  subnet   = local.l3.subnets
  subnets  = local.l3out.external_epgs.subnets
  rm       = local.defaults.tenants.policies.protocol.route_maps_for_route_control
  rmmr     = local.defaults.tenants.policies.protocol.route_map_match_rules
  rmsr     = local.defaults.tenants.policies.protocol.route_map_set_rules
  tnt      = local.defaults.tenants
  vrf      = local.defaults.tenants.networking.vrfs

  # Local Values
  controller_type = var.controller_type
  policy_tenant   = local.tenants[var.tenant].policy_tenant

  #__________________________________________________________
  #
  # Tenant Variables
  #__________________________________________________________

  tenants = {
    for v in lookup(var.model, "tenants", []) : v.name => {
      alias      = lookup(v, "alias", local.tnt.alias)
      annotation = lookup(v, "annotation", local.tnt.annotation)
      annotations = length(lookup(v, "annotations", local.tnt.annotations)
      ) > 0 ? lookup(v, "annotations", local.tnt.annotations) : var.annotations
      controller_type   = local.controller_type
      create            = lookup(v, "create", local.tnt.create)
      description       = lookup(v, "description", local.tnt.description)
      global_alias      = lookup(v, "global_alias", local.tnt.global_alias)
      monitoring_policy = lookup(v, "monitoring_policy", local.tnt.monitoring_policy)
      name              = v.name
      policy_tenant     = lookup(v, "policy_tenant", local.tnt.policy_tenant)
      sites = [for i in lookup(lookup(v, "ndo", {}), "sites", []) : {
        aws_access_key_id = lookup(i, "aws_access_key_id", local.tnt.ndo.sites.aws_access_key_id)
        aws_account_id    = lookup(i, "aws_account_id", local.tnt.ndo.sites.aws_account_id)
        azure_access_type = lookup(i, "azure_access_type", local.tnt.ndo.sites.azure_access_type)
        azure_active_directory_id = lookup(
          i, "azure_active_directory_id", local.tnt.ndo.sites.azure_active_directory_id
        )
        azure_application_id    = lookup(i, "azure_application_id", local.tnt.ndo.sites.azure_application_id)
        azure_shared_account_id = lookup(i, "azure_shared_account_id", local.tnt.ndo.sites.azure_shared_account_id)
        azure_subscription_id   = lookup(i, "azure_subscription_id", local.tnt.ndo.sites.azure_subscription_id)
        is_aws_account_trusted  = lookup(i, "is_aws_account_trusted", local.tnt.ndo.sites.is_aws_account_trusted)
        name                    = i.name
        vendor                  = lookup(i, "vendor", local.tnt.ndo.sites.vendor)
        }
      ]
      schemas = lookup(lookup(v, "ndo", {}), "schemas", [])
      users   = lookup(lookup(v, "ndo", {}), "users", [])
    } if v.name == var.tenant
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
          }
        ]
      }
    ]
  ]) : i.name => i }
  schema = length(local.schemas) > 0 ? flatten([for k, v in local.schemas : k])[0] : ""
  sites  = [for i in local.tenants[var.tenant].sites : i.name]
  users  = local.tenants[var.tenant].users

  template_sites = { for i in flatten([
    for key, value in local.schemas : [
      for v in value.templates : [
        for s in v.sites : {
          schema   = key
          template = v.name
          site     = s
        }
      ]
    ]
  ]) : "${i.schema}:${i.template}:${i.site}" => i }

  apics_inband_mgmt_addresses = {
    for v in lookup(local.static_mgmt_add, "apics_inband", []) : v.apic_node_id => {
      apic_node_id   = v.apic_node_id
      ipv4_address   = lookup(v, "ipv4_address", local.apic_inb.ipv4_address)
      ipv4_gateway   = lookup(v, "ipv4_gateway", local.apic_inb.ipv4_gateway)
      ipv6_address   = lookup(v, "ipv6_address", local.apic_inb.ipv6_address)
      ipv6_gateway   = lookup(v, "ipv6_gateway", local.apic_inb.ipv6_gateway)
      management_epg = lookup(v, "management_epg", local.apic_inb.management_epg)
      pod_id         = lookup(v, "pod_id", local.apic_inb.pod_id)
    }
  }
  #__________________________________________________________
  #
  # VRF Variables
  #__________________________________________________________

  vrfs = {
    for v in lookup(local.networking, "vrfs", []) : v.name => {
      alias      = lookup(v, "alias", local.vrf.alias)
      annotation = lookup(v, "annotation", local.vrf.annotation)
      annotations = length(lookup(v, "annotations", local.vrf.annotations)
      ) > 0 ? lookup(v, "annotations", local.vrf.annotations) : var.annotations
      bd_enforcement_status = lookup(v, "bd_enforcement_status", local.vrf.bd_enforcement_status)
      bgp_timers_per_address_family = lookup(
      v, "bgp_timers_per_address_family", local.vrf.bgp_timers_per_address_family)
      bgp_timers  = lookup(v, "bgp_timers", local.vrf.bgp_timers)
      communities = lookup(v, "communities", local.vrf.communities)
      create      = lookup(v, "create", local.vrf.create)
      description = lookup(v, "description", local.vrf.description)
      eigrp_timers_per_address_family = lookup(
        v, "eigrp_timers_per_address_family", local.vrf.eigrp_timers_per_address_family
      )
      endpoint_retention_policy = lookup(
        v, "endpoint_retention_policy", local.vrf.endpoint_retention_policy
      )
      epg_esg_collection_for_vrfs = {
        contracts = lookup(
        lookup(v, "epg_esg_collection_for_vrfs", {}), "contracts", [])
        label_match_criteria = lookup(
          lookup(v, "epg_esg_collection_for_vrfs", {}
          ), "label_match_criteria", local.vrf.epg_esg_collection_for_vrfs.label_match_criteria
        )
      }
      global_alias           = lookup(v, "global_alias", local.vrf.global_alias)
      ip_data_plane_learning = lookup(v, "ip_data_plane_learning", local.vrf.ip_data_plane_learning)
      layer3_multicast       = lookup(v, "layer3_multicast", local.vrf.layer3_multicast)
      monitoring_policy      = lookup(v, "monitoring_policy", local.vrf.monitoring_policy)
      name                   = v.name
      ospf_timers_per_address_family = lookup(
        v, "ospf_timers_per_address_family", local.vrf.ospf_timers_per_address_family
      )
      ospf_timers = lookup(v, "ospf_timers", local.vrf.ospf_timers)
      policy_control_enforcement_direction = lookup(
      v, "policy_control_enforcement_direction", local.vrf.policy_control_enforcement_direction)

      policy_control_enforcement_preference = lookup(
        v, "policy_control_enforcement_preference", local.vrf.policy_control_enforcement_preference
      )
      policy_tenant            = local.policy_tenant
      preferred_group          = lookup(v, "preferred_group", local.vrf.preferred_group)
      sites                    = lookup(lookup(v, "ndo", {}), "sites", local.sites)
      schema                   = lookup(lookup(v, "ndo", {}), "schema", "")
      template                 = lookup(lookup(v, "ndo", {}), "template", "")
      tenant                   = var.tenant
      transit_route_tag_policy = lookup(v, "transit_route_tag_policy", local.vrf.transit_route_tag_policy)
    }
  }
  vzany_contracts = { for i in flatten([
    for key, value in local.vrfs : [
      for v in value.epg_esg_collection_for_vrfs.contracts : {
        annotation = value.annotation
        contract   = v.name
        contract_type = lookup(
          v, "contract_type", local.vrf.epg_esg_collection_for_vrfs.contracts.contract_type
        )
        contract_schema      = lookup(lookup(v, "ndo", {}), "schema", value.schema)
        contract_template    = lookup(lookup(v, "ndo", {}), "template", value.template)
        contract_tenant      = lookup(v, "tenant", value.tenant)
        label_match_criteria = value.epg_esg_collection_for_vrfs.label_match_criteria
        qos_class            = lookup(v, "template", local.vrf.epg_esg_collection_for_vrfs.contracts.qos_class)
        schema               = value.schema
        template             = value.template
        tenant               = var.tenant
        vrf                  = key
      }
    ]
  ]) : "${i.vrf}:${i.contract}:${i.contract_type}" => i }

  vrf_sites = { for i in flatten([
    for k, v in local.vrfs : [
      for s in v.sites : {
        create   = v.create
        schema   = v.schema
        site     = s
        template = v.template
        vrf      = k
      }
    ] if local.controller_type == "ndo"
  ]) : "${i.vrf}:${i.site}" => i }

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
      ], local.templates_bds[index(local.templates_bds[*].template_name, v.template)])
    ]
  ]) : i.name => i }

  bds = { for v in lookup(local.networking, "bridge_domains", []) : v.name => v }

  merged_bds = merge(local.bds, local.merge_bds_template)

  bridge_domains = {
    for k, v in local.merged_bds : v.name => {
      advanced_troubleshooting = {
        endpoint_clear = lookup(lookup(v, "advanced/troubleshooting", {}
        ), "endpoint_clear", local.adv.endpoint_clear)
        intersite_bum_traffic_allow = lookup(lookup(v, "advanced/troubleshooting", {}
        ), "intersite_bum_traffic_allow", local.adv.intersite_bum_traffic_allow)
        intersite_l2_stretch = lookup(lookup(v, "advanced/troubleshooting", {}
        ), "intersite_l2_stretch", local.adv.intersite_l2_stretch)
        optimize_wan_bandwidth = lookup(lookup(v, "advanced/troubleshooting", {}
        ), "optimize_wan_bandwidth", local.adv.optimize_wan_bandwidth)
        disable_ip_data_plane_learning_for_pbr = lookup(lookup(v, "advanced/troubleshooting", {}
        ), "disable_ip_data_plane_learning_for_pbr", local.adv.disable_ip_data_plane_learning_for_pbr)
        first_hop_security_policy = lookup(lookup(v, "advanced/troubleshooting", {}
        ), "first_hop_security_policy", local.adv.first_hop_security_policy)
        monitoring_policy = lookup(lookup(v, "advanced/troubleshooting", {}
        ), "monitoring_policy", local.adv.monitoring_policy)
        netflow_monitor_policies = [
          for s in lookup(lookup(v, "advanced/troubleshooting", {}), "netflow_monitor_policies", []) : {
            filter_type    = lookup(s, "filter_type", local.adv.netflow_monitor_policies.filter_type)
            netflow_policy = s.netflow_policy
          }
        ]
        rogue_coop_exception_list = lookup(lookup(
          v, "advanced/troubleshooting", {}), "rogue_coop_exception_list", []
        )
      }
      application_epg     = lookup(v, "application_epg", [])
      combine_description = lookup(v, "combine_description", local.bd.combine_description)
      dhcp_relay_labels = flatten([
        for s in lookup(v, "dhcp_relay_labels", {}) : [
          for i in lookup(s, "names", []) : {
            dhcp_option_policy         = lookup(s, "dhcp_option_policy", local.bd.dhcp_relay_labels.dhcp_option_policy)
            dhcp_option_policy_version = lookup(s, "dhcp_option_policy_version", local.bd.dhcp_relay_labels.dhcp_option_policy_version)
            scope                      = lookup(s, "scope", local.bd.dhcp_relay_labels.scope)
            name                       = i
            version                    = lookup(s, "version", local.bd.dhcp_relay_labels.version)
          }
        ]
      ])
      general = {
        advertise_host_routes = lookup(lookup(v, "general", {}
        ), "advertise_host_routes", local.general.advertise_host_routes)
        alias      = lookup(lookup(v, "general", {}), "alias", local.general.alias)
        annotation = lookup(lookup(v, "general", {}), "annotation", local.general.annotation)
        annotations = length(lookup(lookup(v, "general", {}), "annotations", local.general.annotations)
          ) > 0 ? lookup(lookup(v, "general", {}), "annotations", local.general.annotations
        ) : var.annotations
        arp_flooding = lookup(lookup(v, "general", {}), "arp_flooding", local.general.arp_flooding)
        description = coalesce(lookup(lookup(v, "general", {}), "description", local.general.description
        ), lookup(v, "description", local.general.description))
        endpoint_retention_policy = lookup(lookup(v, "general", {}
        ), "endpoint_retention_policy", local.general.endpoint_retention_policy)
        global_alias = lookup(lookup(v, "general", {}), "global_alias", local.general.global_alias)
        igmp_snooping_policy = lookup(lookup(v, "general", {}
        ), "igmp_snooping_policy", local.general.igmp_snooping_policy)
        ipv6_l3_unknown_multicast = lookup(lookup(v, "general", {}
        ), "ipv6_l3_unknown_multicast", local.general.ipv6_l3_unknown_multicast)
        l2_unknown_unicast = lookup(lookup(v, "general", {}
        ), "l2_unknown_unicast", local.general.l2_unknown_unicast)
        l3_unknown_multicast_flooding = lookup(lookup(v, "general", {}
        ), "l3_unknown_multicast_flooding", local.general.l3_unknown_multicast_flooding)
        limit_ip_learn_to_subnets = lookup(lookup(v, "general", {}
        ), "limit_ip_learn_to_subnets", local.general.limit_ip_learn_to_subnets)
        mld_snoop_policy = lookup(lookup(v, "general", {}
        ), "mld_snoop_policy", local.general.mld_snoop_policy)
        multi_destination_flooding = lookup(lookup(v, "general", {}
        ), "multi_destination_flooding", local.general.multi_destination_flooding)
        pim    = lookup(lookup(v, "general", {}), "pim", local.general.pim)
        pimv6  = lookup(lookup(v, "general", {}), "pimv6", local.general.pimv6)
        tenant = var.tenant
        type   = lookup(lookup(v, "general", {}), "type", local.general.type)
        vrf = {
          name   = lookup(lookup(lookup(v, "general", {}), "vrf", {}), "name", "")
          schema = lookup(lookup(lookup(v, "general", {}), "vrf", {}), "schema", "")
          template = lookup(lookup(lookup(v, "general", {}
          ), "vrf", {}), "template", lookup(lookup(v, "ndo", {}), "template", ""))
          tenant = lookup(lookup(lookup(v, "general", {}), "vrf", {}), "tenant", local.tenant)
        }
      }
      l3_configurations = {
        associated_l3outs = [
          for s in lookup(lookup(v, "l3_configurations", {}), "associated_l3outs", []) : {
            l3outs        = s.l3outs
            route_profile = lookup(s, "route_profile", "")
            tenant        = lookup(s, "tenant", var.tenant)
          }
        ]
        ep_move_detection_mode = lookup(lookup(v, "l3_configurations", {}
        ), "ep_move_detection_mode", local.l3.ep_move_detection_mode)
        unicast_routing = lookup(lookup(v, "l3_configurations", {}
        ), "unicast_routing", local.l3.unicast_routing)
        custom_mac_address = lookup(lookup(v, "l3_configurations", {}
        ), "custom_mac_address", local.l3.custom_mac_address)
        link_local_ipv6_address = lookup(lookup(v, "l3_configurations", {}
        ), "link_local_ipv6_address", local.l3.link_local_ipv6_address)
        subnets = concat(lookup(lookup(v, "l3_configurations", {}), "subnets", []), flatten(
          [length(lookup(v, "subnets", [])) > 0 ? [for i in v.subnets : merge(
        i, local.templates_subnets[index(local.templates_subnets[*].template_name, i.template)])] : []]))
        virtual_mac_address = lookup(lookup(v, "l3_configurations", {}
        ), "virtual_mac_address", local.l3.virtual_mac_address)
      }
      name = "${local.bd.name_prefix}${v.name}${local.bd.name_suffix}"
      ndo = {
        schema   = lookup(lookup(v, "ndo", {}), "schema", "")
        sites    = lookup(lookup(v, "ndo", {}), "sites", local.sites)
        template = lookup(lookup(v, "ndo", {}), "template", "")
      }
      tenant = var.tenant
    }
  }
  #ndo_bd_sites = {}
  ndo_bd_sites = { for i in flatten([
    for k, v in local.bridge_domains : [
      for s in range(length(v.ndo.sites)) : {
        advertise_host_routes = s % 2 != 0 ? false : v.general.advertise_host_routes
        bridge_domain         = v.name
        l3out                 = element(v.l3_configurations.associated_l3outs[0].l3outs, s + 1)
        l3out_schema          = v.general.vrf.schema
        l3out_template        = v.general.vrf.template
        schema                = v.ndo.schema
        site                  = element(v.ndo.sites, s + 1)
        template              = v.ndo.template
      }
    ]
  ]) : "${i.bridge_domain}:${i.site}" => i if local.controller_type == "ndo" }

  bridge_domain_dhcp_labels = { for i in flatten([
    for key, value in local.bridge_domains : [
      for v in value.dhcp_relay_labels : {
        annotation         = value.general.annotation
        bridge_domain      = key
        dhcp_option_policy = v.dhcp_option_policy
        name               = v.name
        scope              = v.scope
        tenant             = value.tenant
      }
    ]
  ]) : "${i.bridge_domain}:${i.name}" => i }

  bridge_domain_subnets = { for i in flatten([
    for key, value in local.bridge_domains : [
      for v in value.l3_configurations.subnets : {
        bridge_domain          = value.name
        description            = lookup(v, "description", local.subnet.description)
        gateway_ip             = v.gateway_ip
        ip_data_plane_learning = lookup(v, "ip_data_plane_learning", local.subnet.ip_data_plane_learning)
        make_this_ip_address_primary = lookup(
          v, "make_this_ip_address_primary", local.subnet.make_this_ip_address_primary
        )
        ndo = {
          schema   = value.ndo.schema
          sites    = value.ndo.sites
          template = value.ndo.template
        }
        scope = {
          advertise_externally = lookup(
            lookup(v, "scope", {}), "advertise_externally", local.subnet.scope.advertise_externally
          )
          shared_between_vrfs = lookup(
            lookup(v, "scope", {}), "shared_between_vrfs", local.subnet.scope.shared_between_vrfs
          )
        }
        subnet_control = {
          neighbor_discovery = lookup(
            lookup(v, "subnet_control", {}
            ), "neighbor_discovery", local.subnet.subnet_control.neighbor_discovery
          )
          no_default_svi_gateway = lookup(
            lookup(v, "subnet_control", {}
            ), "no_default_svi_gateway", local.subnet.subnet_control.no_default_svi_gateway
          )
          querier_ip = lookup(lookup(v, "subnet_control", {}
          ), "querier_ip", local.subnet.subnet_control.querier_ip)
        }
        treat_as_virtual_ip_address = lookup(
        v, "treat_as_virtual_ip_address", local.subnet.treat_as_virtual_ip_address)
      }
    ]
  ]) : "${i.bridge_domain}:${i.gateway_ip}" => i }

  rogue_coop_exception_list = { for i in flatten([
    for k, v in local.bridge_domains : [
      for s in v.advanced_troubleshooting.rogue_coop_exception_list : {
        bridge_domain = k
        mac_address   = s
        tenant        = v.tenant
      }
    ] if local.controller_type == "apic"
  ]) : "${i.bridge_domain}:${i.mac_address}" => i }


  #__________________________________________________________
  #
  # Application Profile(s) and Endpoint Group(s) - Variables
  #__________________________________________________________

  application_profiles = {
    for v in lookup(local.tenant[var.tenant], "application_profiles", {}) : v.name => {
      alias      = lookup(v, "alias", local.app.alias)
      annotation = lookup(v, "annotation", local.app.annotation)
      annotations = length(lookup(v, "annotations", local.app.annotations)
      ) > 0 ? lookup(v, "annotations", local.app.annotations) : var.annotations
      application_epgs  = lookup(v, "application_epgs", [])
      description       = lookup(v, "description", local.app.description)
      create            = lookup(v, "create", local.app.create)
      global_alias      = lookup(v, "global_alias", local.app.global_alias)
      monitoring_policy = lookup(v, "monitoring_policy", local.app.monitoring_policy)
      name              = v.name
      qos_class         = lookup(v, "qos_class", local.app.qos_class)
      ndo = {
        schema   = lookup(lookup(v, "ndo", {}), "schema", "")
        sites    = lookup(lookup(v, "ndo", {}), "sites", local.sites)
        template = lookup(lookup(v, "ndo", {}), "template", "")
      }
      tenant = var.tenant
    }
  }

  application_sites = { for i in flatten([
    for k, v in local.application_profiles : [
      for s in v.ndo.sites : {
        application_profile = k
        create              = v.create
        schema              = v.ndo.schema
        site                = s
        template            = v.ndo.template
      }
    ] if local.controller_type == "ndo"
  ]) : "${i.application_profile}:${i.site}" => i }

  bd_with_epgs = [
    for k, v in local.bridge_domains : {
      name     = k
      template = lookup(lookup(v, "application_epg", ), "template", "")
    } if length(v.application_epg) > 0
  ]
  bd_to_epg = { for i in flatten([
    for v in local.bd_with_epgs : [
      merge(local.networking.bridge_domains[index(local.networking.bridge_domains[*].name, v.name)
        ], local.templates_epgs[index(local.templates_epgs[*].template_name, v.template)],
        { name = v.name },
      { bridge_domain = v.name })
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
      merge(local.epgs[v.name], local.templates_epgs[index(local.templates_epgs[*].template_name, v.template)])
    ]
  ]) : i.name => i }

  merged_epgs = merge(local.bd_to_epg, local.epgs, local.merge_templates)

  application_epgs = {
    for k, v in local.merged_epgs : k => {
      alias      = lookup(v, "alias", local.epg.alias)
      annotation = lookup(v, "annotation", local.epg.annotation)
      annotations = length(lookup(v, "annotations", local.epg.annotations)
      ) > 0 ? lookup(v, "annotations", local.epg.annotations) : var.annotations
      application_profile = v.application_profile
      bd = {
        name = length(compact([lookup(v, "bridge_domain", "")])
        ) > 0 ? local.bridge_domains["${v.bridge_domain}"].name : ""
        schema = length(compact([lookup(v, "bridge_domain", "")])
        ) > 0 ? local.bridge_domains["${v.bridge_domain}"].ndo.schema : ""
        template = length(compact([lookup(v, "bridge_domain", "")])
        ) > 0 ? local.bridge_domains["${v.bridge_domain}"].ndo.template : ""
      }
      bridge_domain          = lookup(v, "bridge_domain", "")
      combine_description    = lookup(v, "combine_description", local.epg.combine_description)
      contract_exception_tag = lookup(v, "contract_exception_tag", local.epg.contract_exception_tag)
      contracts              = lookup(v, "contracts", [])
      controller_type        = local.controller_type
      custom_qos_policy      = lookup(v, "custom_qos_policy", local.epg.custom_qos_policy)
      data_plane_policer     = lookup(v, "data_plane_policer", local.epg.data_plane_policer)
      description            = lookup(v, "description", local.epg.description)
      domains                = lookup(v, "domains", [])
      epg_admin_state        = lookup(v, "epg_admin_state", local.epg.epg_admin_state)
      epg_contract_masters = [
        for s in lookup(v, "epg_contract_masters", []) : {
          application_profile = lookup(s, "application_profile", v.application_profile)
          application_epg     = s.application_epg
        }
      ]
      epg_to_aaeps = length(lookup(v, "epg_to_aaep_vlans", [])) > 0 ? [
        for s in lookup(v, "epg_to_aaeps", []) : {
          aaep = s.aaep
          instrumentation_immediacy = lookup(
            s, "instrumentation_immediacy", local.epg.epg_to_aaeps.instrumentation_immediacy
          )
          mode = lookup(s, "mode", local.epg.epg_to_aaeps.mode)
          vlans = length(lookup(v, "epg_to_aaep_vlans", [])
          ) > 0 ? v.epg_to_aaep_vlans : lookup(s, "vlans", [])
        }
      ] : []
      epg_type                 = lookup(v, "epg_type", local.epg.epg_type)
      fhs_trust_control_policy = lookup(v, "fhs_trust_control_policy", local.epg.fhs_trust_control_policy)
      flood_in_encapsulation   = lookup(v, "flood_in_encapsulation", local.epg.flood_in_encapsulation)
      global_alias             = lookup(v, "global_alias", local.epg.global_alias)
      has_multicast_source     = lookup(v, "has_multicast_source", local.epg.has_multicast_source)
      intra_epg_isolation      = lookup(v, "intra_epg_isolation", local.epg.intra_epg_isolation)
      label_match_criteria     = lookup(v, "label_match_criteria", local.epg.label_match_criteria)
      monitoring_policy        = lookup(v, "monitoring_policy", local.epg.monitoring_policy)
      name                     = "${local.epg.name_prefix}${v.name}${local.epg.name_suffix}"
      ndo = {
        schema   = lookup(lookup(v, "ndo", {}), "schema", "")
        sites    = local.sites
        template = lookup(lookup(v, "ndo", {}), "template", "")
      }
      preferred_group_member = lookup(v, "preferred_group_member", local.epg.preferred_group_member)
      qos_class              = lookup(v, "qos_class", local.epg.qos_class)
      static_paths           = lookup(v, "static_paths", [])
      tenant                 = var.tenant
      useg_epg               = lookup(v, "useg_epg", local.epg.useg_epg)
      vlans                  = lookup(v, "vlans", local.epg.vlans)
      vrf = {
        name = length(compact([lookup(v, "bridge_domain", "")])
        ) > 0 ? local.bridge_domains["${v.bridge_domain}"].general.vrf.name : ""
        schema = length(compact([lookup(v, "bridge_domain", "")])
        ) > 0 ? local.bridge_domains["${v.bridge_domain}"].general.vrf.schema : ""
        template = length(compact([lookup(v, "bridge_domain", "")])
        ) > 0 ? local.bridge_domains["${v.bridge_domain}"].general.vrf.template : ""
        tenant = length(compact([lookup(v, "bridge_domain", "")])
        ) > 0 ? local.bridge_domains["${v.bridge_domain}"].general.vrf.tenant : ""
      }
      vzGraphCont = lookup(v, "vzGraphCont", local.epg.vzGraphCont)
    }
  }

  epg_to_domains = { for i in flatten([
    for key, value in local.application_epgs : [
      for v in value.domains : {
        annotation = lookup(v, "annotation", local.epg.domains.annotation)
        allow_micro_segmentation = lookup(
          v, "allow_micro_segmentation", local.epg.domains.allow_micro_segmentation
        )
        application_profile  = value.application_profile
        application_epg      = value.name
        controller_type      = value.controller_type
        delimiter            = lookup(v, "delimiter", local.epg.domains.delimiter)
        deploy_immediacy     = lookup(v, "deploy_immediacy", local.epg.domains.deploy_immediacy)
        domain               = v.name
        domain_type          = lookup(v, "domain_type", local.epg.domains.domain_type)
        enhanced_lag_policy  = lookup(v, "enhanced_lag_policy", local.epg.domains.enhanced_lag_policy)
        epg_type             = value.epg_type
        ndo                  = value.ndo
        number_of_ports      = lookup(v, "number_of_ports", local.epg.domains.number_of_ports)
        port_allocation      = lookup(v, "port_allocation", local.epg.domains.port_allocation)
        port_binding         = lookup(v, "port_binding", local.epg.domains.port_binding)
        resolution_immediacy = lookup(v, "resolution_immediacy", local.epg.domains.resolution_immediacy)
        security = {
          allow_promiscuous = lookup(lookup(v, "security", {}
          ), "allow_promiscuous", local.epg.domains.security.allow_promiscuous)
          forged_transmits = lookup(lookup(v, "security", {}
          ), "forged_transmits", local.epg.domains.security.forged_transmits)
          mac_changes = lookup(lookup(v, "security", {}), "mac_changes", local.epg.domains.security.mac_changes)
        }
        sites           = lookup(v, "sites", local.epg.domains.sites)
        switch_provider = lookup(v, "switch_provider", local.epg.domains.switch_provider)
        vlan_mode       = lookup(v, "vlan_mode", local.epg.domains.vlan_mode)
        vlans           = lookup(v, "vlans", local.epg.domains.vlans)
      }
    ]
  ]) : "${i.application_profile}:${i.application_epg}:${i.domain}" => i }
  ndo_epg_to_domains = { for i in flatten([
    for k, v in local.epg_to_domains : [
      for s in range(length(v.sites)) : {
        annotation               = v.annotation
        allow_micro_segmentation = v.allow_micro_segmentation
        application_profile      = v.application_profile
        application_epg          = v.application_epg
        controller_type          = v.controller_type
        delimiter                = v.delimiter
        deploy_immediacy         = v.deploy_immediacy
        domain                   = v.domain
        domain_type              = v.domain_type
        enhanced_lag_policy      = v.enhanced_lag_policy
        epg_type                 = v.epg_type
        number_of_ports          = v.number_of_ports
        port_allocation          = v.port_allocation
        port_binding             = v.port_binding
        resolution_immediacy     = v.resolution_immediacy
        schema                   = v.ndo.schema
        security                 = v.security
        site                     = element(v.sites, s)
        switch_provider          = v.switch_provider
        template                 = v.ndo.template
        vlan_mode                = v.vlan_mode
        vlans                    = v.vlans
      }
    ]
  ]) : "${i.application_profile}:${i.application_epg}:${i.domain}:${i.site}" => i if i.controller_type == "ndo" }

  epg_to_static_paths = { for i in flatten([
    for key, value in local.application_epgs : [
      for v in value.static_paths : [
        for s in v.names : {
          annotation          = value.annotation
          application_epg     = key
          application_profile = value.application_profile
          encapsulation_type  = lookup(v, "encapsulation_type", local.epg.static_paths.encapsulation_type)
          mode                = lookup(v, "mode", local.epg.static_paths.mode)
          name                = s
          nodes               = v.nodes
          path_type           = lookup(v, "path_type", local.epg.static_paths.path_type)
          pod                 = lookup(v, "pod", local.epg.static_paths.pod)
          vlans               = lookup(v, "vlans", local.epg.static_paths.vlans)
        }
      ]
    ]
  ]) : "${i.application_profile}:${i.application_epg}:${i.name}" => i }

  epg_to_aaeps = { for i in flatten([
    for key, value in local.application_epgs : [
      for v in value.epg_to_aaeps : {
        application_epg     = key
        application_profile = value.application_profile
        aaep                = v.aaep
        instrumentation_immediacy = lookup(
          v, "instrumentation_immediacy", local.epg.epg_to_aaeps.instrumentation_immediacy
        )
        mode  = lookup(v, "mode", local.epg.epg_to_aaeps.mode)
        vlans = v.vlans
      }
    ]
  ]) : "${i.application_profile}:${i.application_epg}:${i.aaep}" => i }

  contract_to_epgs = { for i in flatten([
    for key, value in local.application_epgs : [
      for v in value.contracts : {
        annotation          = value.annotation
        application_epg     = key
        application_profile = value.application_profile
        contract            = v.name
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
        qos_class       = lookup(v, "qos_class", local.epg.contracts.qos_class)
        epg_type        = value.epg_type
        tenant          = value.tenant
      }
    ]
  ]) : "${i.application_profile}:${i.application_epg}:${i.contract_type}:${i.contract}" => i }


  #__________________________________________________________
  #
  # Contract Variables
  #__________________________________________________________
  contracts = {
    for v in lookup(local.tenant_contracts, "contracts", []) : v.name => {
      alias      = lookup(v, "alias", local.contract.alias)
      annotation = lookup(v, "annotation", local.contract.annotation)
      annotations = length(lookup(v, "annotations", local.contract.annotations)
      ) > 0 ? lookup(v, "annotations", local.contract.annotations) : var.annotations
      apply_both_directions = length(lookup(v, "subjects", [])) > 0 ? lookup(
        v.subjects[0], "apply_both_directions", local.contract.subjects.apply_both_directions
      ) : false
      contract_type = lookup(v, "contract_type", local.contract.contract_type)
      description   = lookup(v, "description", local.contract.description)
      filters = flatten([
        for s in lookup(v, "subjects", []) : [
          s.filters
        ]
      ])
      global_alias = lookup(v, "global_alias", local.contract.global_alias)
      log          = lookup(v, "log", local.contract.log)
      qos_class    = lookup(v, "qos_class", local.contract.qos_class)
      subjects     = lookup(v, "subjects", [])
      schema       = local.schema
      scope        = lookup(v, "scope", local.contract.scope)
      sites        = local.sites
      target_dscp  = lookup(v, "target_dscp", local.contract.target_dscp)
      template     = lookup(v, "template", "")
      tenant       = var.tenant
    }
  }

  contract_subjects = { for i in flatten([
    for key, value in local.contracts : [
      for v in value.subjects : {
        action                = lookup(v, "action", local.contract.subjects.action)
        apply_both_directions = lookup(v, "apply_both_directions", local.contract.subjects.apply_both_directions)
        annotation            = value.annotation
        contract              = key
        contract_type         = value.contract_type
        description           = lookup(v, "description", local.contract.subjects.description)
        directives            = lookup(v, "directives", local.contract.subjects.directives)
        filters               = lookup(v, "filters", [])
        label_match_criteria  = lookup(v, "label_match_criteria", local.contract.subjects.label_match_criteria)
        name                  = v.name
        qos_class             = lookup(v, "qos_class", value.qos_class)
        target_dscp           = lookup(v, "target_dscp", value.target_dscp)
        tenant                = value.tenant
      }
    ] if local.controller_type == "apic"
  ]) : "${i.contract}:${i.name}" => i }

  subject_filters = { for i in flatten([
    for k, v in local.contract_subjects : [
      for s in v.filters : {
        action        = v.action
        contract      = v.contract
        contract_type = v.contract_type
        directives = {
          enable_policy_compression = lookup(lookup(v, "directives"
          ), "enable_policy_compression", local.contract.subjects.directives.enable_policy_compression)
          log = lookup(lookup(v, "directives"), "log", local.contract.subjects.directives.log)
        }
        filter  = s
        subject = v.name
        tenant  = v.tenant
      }
    ]
  ]) : "${i.contract}:${i.subject}:${i.filter}" => i }


  #__________________________________________________________
  #
  # Filter Variables
  #__________________________________________________________
  filters = {
    for v in lookup(local.tenant_contracts, "filters", []) : v.name => {
      alias      = lookup(v, "alias", local.filter.alias)
      annotation = lookup(v, "annotation", local.filter.annotation)
      annotations = length(lookup(v, "annotations", local.filter.annotations)
      ) > 0 ? lookup(v, "annotations", local.filter.annotations) : var.annotations
      description    = lookup(v, "description", local.filter.description)
      filter_entries = lookup(v, "filter_entries", [])
      schema         = local.schema
      template       = lookup(v, "template", "")
      tenant         = var.tenant
    }
  }

  filter_entries = { for i in flatten([
    for key, value in local.filters : [
      for k, v in value.filter_entries : {
        alias                 = lookup(v, "alias", local.filter.filter_entries.alias)
        annotation            = lookup(v, "annotation", local.filter.filter_entries.annotation)
        arp_flag              = lookup(v, "arp_flag", local.filter.filter_entries.arp_flag)
        description           = lookup(v, "description", local.filter.filter_entries.description)
        destination_port_from = lookup(v, "destination_port_from", local.filter.filter_entries.destination_port_from)
        destination_port_to   = lookup(v, "destination_port_to", local.filter.filter_entries.destination_port_to)
        ethertype             = lookup(v, "ethertype", local.filter.filter_entries.ethertype)
        filter_name           = key
        icmpv4_type           = lookup(v, "icmpv4_type", local.filter.filter_entries.icmpv4_type)
        icmpv6_type           = lookup(v, "icmpv6_type", local.filter.filter_entries.icmpv6_type)
        ip_protocol           = lookup(v, "ip_protocol", local.filter.filter_entries.ip_protocol)
        match_dscp            = lookup(v, "match_dscp", local.filter.filter_entries.match_dscp)
        match_only_fragments  = lookup(v, "match_only_fragments", local.filter.filter_entries.match_only_fragments)
        name                  = v.name
        schema                = value.schema
        source_port_from      = lookup(v, "source_port_from", local.filter.filter_entries.source_port_from)
        source_port_to        = lookup(v, "source_port_to", local.filter.filter_entries.source_port_to)
        stateful              = lookup(v, "stateful", local.filter.filter_entries.stateful)
        tcp_session_rules = {
          acknowledgement = lookup(lookup(
            v, "tcp_session_rules", {}), "acknowledgement", local.filter.filter_entries.tcp_session_rules.acknowledgement
          )
          established = lookup(lookup(
            v, "tcp_session_rules", {}), "established", local.filter.filter_entries.tcp_session_rules.established
          )
          finish = lookup(lookup(v, "tcp_session_rules", {}), "finish", local.filter.filter_entries.tcp_session_rules.finish)
          reset  = lookup(lookup(v, "tcp_session_rules", {}), "reset", local.filter.filter_entries.tcp_session_rules.reset)
          synchronize = lookup(lookup(
            v, "tcp_session_rules", {}), "synchronize", local.filter.filter_entries.tcp_session_rules.synchronize
          )
        }
        template = value.template
        tenant   = var.tenant
      }
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
    for v in lookup(local.networking, "l3outs", []) : v.name => {
      alias      = lookup(v, "alias", local.l3out.alias)
      annotation = lookup(v, "annotation", local.l3out.annotation)
      annotations = length(lookup(v, "annotations", local.l3out.annotations)
      ) > 0 ? lookup(v, "annotations", local.l3out.annotations) : var.annotations
      consumer_label        = lookup(v, "consumer_label", local.l3out.consumer_label)
      description           = lookup(v, "description", local.l3out.description)
      enable_bgp            = lookup(v, "enable_bgp", local.l3out.enable_bgp)
      external_epgs         = lookup(v, "external_epgs", [])
      global_alias          = lookup(v, "global_alias", local.l3out.global_alias)
      l3_domain             = lookup(v, "l3_domain", local.l3out.l3_domain)
      logical_node_profiles = lookup(v, "logical_node_profiles", [])
      ndo = {
        schema   = lookup(lookup(v, "ndo", {}), "schema", "")
        sites    = lookup(lookup(v, "ndo", {}), "sites", local.l3out.ndo.sites)
        template = lookup(lookup(v, "ndo", {}), "template", local.l3out.ndo.template)
      }
      ospf_external_profile = lookup(v, "ospf_external_profile", [])
      pim                   = lookup(v, "pim", local.l3out.pim)
      pimv6                 = lookup(v, "pimv6", local.l3out.pimv6)
      provider_label        = lookup(v, "provider_label", local.l3out.provider_label)
      route_control_enforcement = {
        import = lookup(lookup(v, "route_control_enforcement", {}), "import", local.l3out.route_control_enforcement.import)
      }
      route_control_for_dampening = [
        for s in lookup(v, "route_control_for_dampening", []) : {
          address_family = s.address_family != null ? s.address_family : "ipv4"
          route_map      = s.route_map
        }
      ]
      route_profile_for_interleak       = lookup(v, "route_profile_for_interleak", local.l3out.route_profile_for_interleak)
      route_profiles_for_redistribution = lookup(v, "route_profiles_for_redistribution", [])
      target_dscp                       = lookup(v, "target_dscp", local.l3out.target_dscp)
      tenant                            = var.tenant
      vrf                               = lookup(v, "vrf", local.l3out.vrf)
      vrf_template                      = lookup(v, "vrf_template", lookup(lookup(v, "ndo", {}), "template", local.l3out.ndo.template))
    }
  }

  l3out_route_profiles_for_redistribution = { for i in flatten([
    for key, value in local.l3outs : [
      for v in value.route_profiles_for_redistribution : {
        annotation = value.annotation
        l3out      = key
        tenant     = value.tenant
        rm_l3out   = lookup(v, "l3out", local.l3out.route_profiles_for_redistribution.l3out)
        source     = lookup(v, "source", local.l3out.route_profiles_for_redistribution.source)
        route_map  = v.route_map
      }
    ]
  ]) : "${i.l3out}:${i.route_map}:${i.source}" => i }

  #==================================
  # L3Outs - External EPGs
  #==================================

  l3out_external_epgs = { for i in flatten([
    for key, value in local.l3outs : [
      for v in value.external_epgs : {
        annotation             = value.annotation
        alias                  = lookup(v, "alias", local.l3out.external_epgs.alias)
        contract_exception_tag = lookup(v, "contract_exception_tag", local.l3out.external_epgs.contract_exception_tag)
        contracts              = lookup(v, "contracts", [])
        description            = lookup(v, "description", local.l3out.external_epgs.description)
        flood_on_encapsulation = lookup(v, "flood_on_encapsulation", local.l3out.external_epgs.flood_on_encapsulation)
        annotation             = value.annotation
        l3out                  = key
        l3out_contract_masters = [
          for s in lookup(v, "l3out_contract_masters", []) : {
            external_epg = s.external_epg
            l3out        = s.l3out
          }
        ]
        label_match_criteria   = lookup(v, "label_match_criteria", local.l3out.external_epgs.label_match_criteria)
        name                   = lookup(v, "name", local.l3out.external_epgs.name)
        preferred_group_member = lookup(v, "preferred_group_member", local.l3out.external_epgs.preferred_group_member)
        qos_class              = lookup(v, "qos_class", local.l3out.external_epgs.qos_class)
        subnets                = lookup(v, "subnets", [])
        target_dscp            = lookup(v, "target_dscp", local.l3out.external_epgs.target_dscp)
        route_control_profiles = [
          for s in lookup(v, "route_control_profiles", []) : {
            direction = s.direction
            route_map = s.route_map
          }
        ]
        tenant = value.tenant
      }
    ]
  ]) : "${i.l3out}:${i.name}" => i }

  l3out_ext_epg_contracts = { for i in flatten([
    for key, value in local.l3out_external_epgs : [
      for v in value.contracts : {
        annotation    = value.annotation
        contract      = v.name
        tenant        = lookup(v, "tenant", local.l3out.external_epgs.contracts.tenant)
        contract_type = lookup(v, "contract_type", local.l3out.external_epgs.contracts.contract_type)
        qos_class     = lookup(v, "qos_class", local.l3out.external_epgs.contracts.qos_class)
        external_epg  = value.name
        l3out         = value.l3out
        tenant        = value.tenant
      }
    ]
  ]) : "${i.l3out}:${i.external_epg}:${i.contract_type}:${i.contract}" => i }

  l3out_external_epg_subnets = { for i in flatten([
    for key, value in local.l3out_external_epgs : [
      for v in lookup(value, "subnets", []) : [
        for s in v.subnets : {
          aggregate = {
            aggregate_export = lookup(lookup(v, "aggregate", {}), "aggregate_export", local.subnets.aggregate.aggregate_export)
            aggregate_import = lookup(lookup(v, "aggregate", {}), "aggregate_import", local.subnets.aggregate.aggregate_import)
            aggregate_shared_routes = lookup(lookup(v, "aggregate", {}
            ), "aggregate_shared_routes", local.subnets.aggregate.aggregate_shared_routes)
          }
          annotation   = value.annotation
          description  = lookup(v, "description", local.subnets.description)
          external_epg = key
          l3out        = value.l3out
          route_control_profiles = [
            for s in lookup(v, "route_control_profiles", []) : {
              direction = s.direction
              route_map = s.route_map
            }
          ]
          route_summarization_policy = lookup(v, "route_summarization_policy", local.subnets.route_summarization_policy)
          external_epg_classification = {
            external_subnets_for_external_epg = lookup(lookup(v, "external_epg_classification", {}
            ), "external_subnets_for_external_epg", local.subnets.external_epg_classification.external_subnets_for_external_epg)
            shared_security_import_subnet = lookup(lookup(v, "external_epg_classification", {}
            ), "shared_security_import_subnet", local.subnets.external_epg_classification.shared_security_import_subnet)
          }
          route_control = {
            export_route_control_subnet = lookup(lookup(v, "route_control", {}
            ), "export_route_control_subnet", local.subnets.route_control.export_route_control_subnet)
            import_route_control_subnet = lookup(lookup(v, "route_control", {}
            ), "import_route_control_subnet", local.subnets.route_control.import_route_control_subnet)
            shared_route_control_subnet = lookup(lookup(v, "route_control", {}
            ), "shared_route_control_subnet", local.subnets.route_control.shared_route_control_subnet)
          }
          subnet = s
        }
      ]
    ] if length(lookup(value, "subnets", [])) > 0
  ]) : "${i.external_epg}:${i.subnet}" => i }

  #=======================================================================================
  # L3Outs - OSPF External Policies
  #=======================================================================================

  l3out_ospf_external_profile = { for i in flatten([
    for key, value in local.l3outs : [
      for v in value.ospf_external_profile : {
        annotation     = value.annotation
        l3out          = key
        ospf_area_cost = lookup(v, "ospf_area_cost", local.l3ospf.ospf_area_cost)
        ospf_area_id   = lookup(v, "ospf_area_id", local.l3ospf.ospf_area_id)
        ospf_area_type = lookup(v, "ospf_area_type", local.l3ospf.ospf_area_type)
        ospf_area_control = {
          originate_summary_lsa = lookup(lookup(v, "ospf_area_control", {}
          ), "originate_summary_lsa", local.l3ospf.ospf_area_control.originate_summary_lsa)
          send_redistribution_lsas_into_nssa_area = lookup(lookup(v, "ospf_area_control", {}
          ), "send_redistribution_lsas_into_nssa_area", local.l3ospf.ospf_area_control.send_redistribution_lsas_into_nssa_area)
          suppress_forwarding_address = lookup(lookup(v, "ospf_area_control", {}
          ), "suppress_forwarding_address", local.l3ospf.ospf_area_control.suppress_forwarding_address)
        }
        tenant = var.tenant
      }
    ]
  ]) : "${i.l3out}:ospf-external-profile" => i }

  #=======================================================================================
  # L3Outs - Logical Node Profiles
  #=======================================================================================

  l3out_node_profiles = { for i in flatten([
    for key, value in local.l3outs : [
      for v in value.logical_node_profiles : {
        alias              = lookup(v, "alias", local.lnp.alias)
        annotation         = lookup(v, "annotation", local.lnp.annotation)
        color_tag          = lookup(v, "color_tag", local.lnp.color_tag)
        description        = lookup(v, "description", local.lnp.description)
        interface_profiles = lookup(v, "interface_profiles", [])
        l3out              = key
        name               = v.name
        nodes = [
          for s in lookup(v, "nodes", []) : {
            annotation    = lookup(v, "annotation", local.lnp.annotation)
            l3out         = key
            node_id       = s.node_id
            node_profile  = "${key}:${v.name}"
            pod_id        = lookup(v, "pod_id", local.lnp.pod_id)
            router_id     = s.router_id
            static_routes = lookup(v, "static_routes", [])
            use_router_id_as_loopback = lookup(
              s, "use_router_id_as_loopback", local.lnp.nodes.use_router_id_as_loopback
            )
          }
        ]
        pod_id      = lookup(v, "pod_id", local.lnp.pod_id)
        target_dscp = lookup(v, "target_dscp", local.lnp.target_dscp)
        tenant      = var.tenant
      }
    ]
  ]) : "${i.l3out}:${i.name}" => i }

  l3out_node_profiles_nodes = { for i in flatten([
    for key, value in local.l3out_node_profiles : [for v in value.nodes : v]
  ]) : "${i.node_profile}:${i.node_id}" => i }

  #=======================================================================================
  # L3Outs - Logical Node Profiles - Static Routes
  #=======================================================================================

  l3out_node_profile_static_routes = { for i in flatten([
    for key, value in local.l3out_node_profiles_nodes : [
      for v in value.static_routes : [
        for e in lookup(v, "prefixes", {}) : {
          aggregate           = lookup(v, "aggregate", local.lnpstrt.aggregate)
          alias               = lookup(v, "alias", local.lnpstrt.alias)
          annotation          = lookup(v, "annotation", local.lnpstrt.annotation)
          description         = lookup(v, "description", local.lnpstrt.description)
          fallback_preference = lookup(v, "fallback_preference", local.lnpstrt.fallback_preference)
          key                 = key
          next_hop_addresses = [
            for x in range(0, length(lookup(lookup(v, "next_hop_addresses", {}), "next_hop_ips", []))) : {
              alias         = lookup(lookup(v, "next_hop_addresses", {}), "alias", local.lnpsrnh.alias)
              annotation    = lookup(lookup(v, "next_hop_addresses", {}), "annotation", local.lnpsrnh.annotation)
              description   = lookup(lookup(v, "next_hop_addresses", {}), "description", local.lnpsrnh.description)
              next_hop_ip   = v.next_hop_addresses.next_hop_ips[x]
              next_hop_type = lookup(lookup(v, "next_hop_addresses", {}), "next_hop_type", local.lnpsrnh.next_hop_type)
              preference    = lookup(lookup(v, "next_hop_addresses", {}), "preference", local.lnpsrnh.preference)
              static_route  = "${key}:${e}"
              track_list    = lookup(lookup(v, "next_hop_addresses", {}), "track_list", local.lnpsrnh.track_list)
              track_member = length(
                lookup(lookup(v, "next_hop_addresses", {}), "track_members", [])
              ) > 0 ? lookup(lookup(v, "next_hop_addresses", {}), "track_members", [])[x] : ""
            }
          ]
          node_id = value.node_id
          prefix  = e
          route_control = {
            bfd = lookup(lookup(v, "route_control", {}), "bfd", local.lnpstrt.route_control.bfd)
          }
          description = lookup(v, "description", local.lnpstrt.description)
          tenant      = var.tenant
          track_list  = lookup(v, "track_list", local.lnpstrt.track_list)
        }
      ]
    ]
  ]) : "${i.key}:${i.prefix}" => i }

  l3out_static_routes_next_hop = { for i in flatten([
    for key, value in local.l3out_node_profile_static_routes : [for v in value.next_hop_addresses : v]
  ]) : "${i.static_route}:${i.next_hop_ip}" => i }

  #=======================================================================================
  # L3Outs - Logical Node Profiles - Logical Interface Profiles
  #=======================================================================================

  l3out_interface_profiles = { for i in flatten([
    for key, value in local.l3out_node_profiles : [
      for v in value.interface_profiles : {
        annotation                  = value.annotation
        color_tag                   = value.color_tag
        l3out                       = value.l3out
        arp_policy                  = lookup(v, "arp_policy", local.lip.arp_policy)
        auto_state                  = lookup(v, "auto_state", local.lip.auto_state)
        bgp_peers                   = lookup(v, "bgp_peers", [])
        custom_qos_policy           = lookup(v, "custom_qos_policy", local.lip.custom_qos_policy)
        description                 = lookup(v, "description", local.lip.description)
        data_plane_policing_egress  = lookup(v, "data_plane_policing_egress", local.lip.data_plane_policing_egress)
        data_plane_policing_ingress = lookup(v, "data_plane_policing_ingress", local.lip.data_plane_policing_ingress)
        encap_scope                 = lookup(v, "encap_scope", local.lip.encap_scope)
        encap_vlan                  = lookup(v, "encap_vlan", local.lip.encap_vlan)
        hsrp_interface_profile      = lookup(v, "hsrp_interface_profile", [])
        interface_or_policy_group   = lookup(v, "interface_or_policy_group", local.lip.interface_or_policy_group)
        interface_type              = lookup(v, "interface_type", local.lip.interface_type)
        ipv6_dad                    = lookup(v, "ipv6_dad", local.lip.ipv6_dad)
        link_local_address          = lookup(v, "link_local_address", local.lip.link_local_address)
        mac_address                 = lookup(v, "mac_address", local.lip.mac_address)
        mode                        = lookup(v, "mode", local.lip.mode)
        mtu                         = lookup(v, "mtu", local.lip.mtu)
        name                        = v.name
        nd_policy                   = lookup(v, "nd_policy", local.lip.nd_policy)
        netflow_monitor_policies = [
          for s in lookup(v, "netflow_monitor_policies", []) : {
            filter_type    = s.filter_type != null ? s.filter_type : "ipv4"
            netflow_policy = s.netflow_policy
          }
        ]
        node_profile              = key
        nodes                     = [for keys, values in value.nodes : value.nodes[keys]["node_id"]]
        ospf_interface_profile    = lookup(v, "ospf_interface_profile", [])
        pod_id                    = value.pod_id
        primary_preferred_address = lookup(v, "primary_preferred_address", local.lip.primary_preferred_address)
        qos_class                 = lookup(v, "qos_class", local.lip.qos_class)
        secondary_addresses       = lookup(v, "secondary_addresses", [])
        svi_addresses             = lookup(v, "svi_addresses", [])
        target_dscp               = value.target_dscp
        tenant                    = value.tenant
      }
    ]
  ]) : "${i.node_profile}:${i.name}" => i }

  l3out_paths_svi_addressing = { for i in flatten([
    for key, value in local.l3out_interface_profiles : [
      for v in value.svi_addresses : [
        for s in range(length(v.primary_preferred_addresses)) : {
          annotation = value.annotation
          ipv6_dad   = value.ipv6_dad
          link_local_address = length(lookup(v, "link_local_addresses", [])
          ) == 2 ? element(v.link_local_addresses, s) : "::"
          l3out_interface_profile   = key
          primary_preferred_address = element(v.primary_preferred_addresses, s)
          secondary_addresses       = lookup(v, "secondary_addresses", [])
          side                      = length(regexall("false", tostring(s % 2 == 0))) > 0 ? "A" : "B"
          interface_type            = value.interface_type
        }
      ]
    ] if value.interface_type == "ext-svi"
  ]) : "${i.l3out_interface_profile}:${i.side}" => i }

  interface_secondaries_ips = { for i in flatten([
    for k, v in local.l3out_interface_profiles : [
      for s in range(length(v.secondary_addresses)) : {
        annotation              = v.annotation
        ipv6_dad                = v.ipv6_dad
        secondary_ip            = "${k}:${s}"
        l3out_interface_profile = k
        secondary_ip_address    = element(v.secondary_addresses, s)
      }
    ]
  ]) : "${i.l3out_interface_profile}:${i.secondary_ip_address}" => i }

  svi_secondaries_ips = { for i in flatten([
    for k, v in local.l3out_paths_svi_addressing : [
      for s in range(length(v.secondary_addresses)) : {
        annotation              = v.annotation
        ipv6_dad                = v.ipv6_dad
        l3out_interface_profile = k
        secondary_ip_address    = element(v.secondary_addresses, s)
      }
    ]
  ]) : "${i.l3out_interface_profile}:${i.secondary_ip_address}" => i }
  l3out_paths_secondary_ips = merge(local.interface_secondaries_ips, local.svi_secondaries_ips)

  #=======================================================================================
  # L3Outs - Logical Node Profiles - Logical Interface Profiles - BGP Peers
  #=======================================================================================

  bgp_peer_connectivity_profiles = { for i in flatten([
    for key, value in local.l3out_interface_profiles : [
      for v in value.bgp_peers : [
        for s in range(length(v.peer_addresses)) : {
          address_type_controls = {
            af_mcast = lookup(lookup(
              v, "address_type_controls", {}), "af_mcast", local.bgppeer.address_type_controls.af_mcast
            )
            af_ucast = lookup(lookup(
              v, "address_type_controls", {}), "af_ucast", local.bgppeer.address_type_controls.af_ucast
            )
          }
          admin_state           = lookup(v, "admin_state", local.bgppeer.admin_state)
          allowed_self_as_count = lookup(v, "allowed_self_as_count", local.bgppeer.allowed_self_as_count)
          annotation            = value.annotation
          bgp_controls = {
            allow_self_as = lookup(lookup(v, "bgp_controls", {}), "allow_self_as", local.bgppeer.bgp_controls.allow_self_as)
            as_override   = lookup(lookup(v, "bgp_controls", {}), "as_override", local.bgppeer.bgp_controls.as_override)
            disable_peer_as_check = lookup(lookup(v, "bgp_controls", {}
            ), "disable_peer_as_check", local.bgppeer.bgp_controls.disable_peer_as_check)
            next_hop_self  = lookup(lookup(v, "bgp_controls", {}), "next_hop_self", local.bgppeer.bgp_controls.next_hop_self)
            send_community = lookup(lookup(v, "bgp_controls", {}), "send_community", local.bgppeer.bgp_controls.send_community)
            send_domain_path = lookup(lookup(v, "bgp_controls", {}
            ), "send_domain_path", local.bgppeer.bgp_controls.send_domain_path)
            send_extended_community = lookup(lookup(v, "bgp_controls", {}
            ), "send_extended_community", local.bgppeer.bgp_controls.send_extended_community)
          }
          bgp_peer_prefix_policy  = lookup(v, "bgp_peer_prefix_policy", local.bgppeer.bgp_peer_prefix_policy)
          description             = lookup(v, "description", local.bgppeer.description)
          ebgp_multihop_ttl       = lookup(v, "ebgp_multihop_ttl", local.bgppeer.ebgp_multihop_ttl)
          local_as_number         = lookup(v, "local_as_number", local.bgppeer.local_as_number)
          local_as_number_config  = lookup(v, "local_as_number_config", local.bgppeer.local_as_number_config)
          password                = lookup(v, "password", local.bgppeer.password)
          l3out_interface_profile = key
          node_profile            = value.node_profile
          peer_address            = element(v.peer_addresses, s)
          peer_asn                = v.peer_asn
          peer_controls = {
            bidirectional_forwarding_detection = lookup(lookup(v, "peer_controls", {}
            ), "bidirectional_forwarding_detection", local.bgppeer.peer_controls.bidirectional_forwarding_detection)
            disable_connected_check = lookup(lookup(v, "peer_controls", {}
            ), "disable_connected_check", local.bgppeer.peer_controls.disable_connected_check)
          }
          peer_level = lookup(v, "peer_level", local.bgppeer.peer_level)
          private_as_control = {
            remove_all_private_as = lookup(lookup(v, "private_as_control", {}
            ), "remove_all_private_as", local.bgppeer.private_as_control.remove_all_private_as)
            remove_private_as = lookup(lookup(v, "private_as_control", {}
            ), "remove_private_as", local.bgppeer.private_as_control.remove_private_as)
            replace_private_as_with_local_as = lookup(lookup(v, "private_as_control", {}
            ), "replace_private_as_with_local_as", local.bgppeer.private_as_control.replace_private_as_with_local_as)
          }
          route_control_profiles = [
            for s in lookup(v, "route_control_profiles", []) : {
              direction = s.direction
              route_map = s.route_map
            }
          ]
          weight_for_routes_from_neighbor = lookup(
            v, "weight_for_routes_from_neighbor", local.bgppeer.weight_for_routes_from_neighbor
          )
        }
      ]
    ]
  ]) : "${i.l3out_interface_profile}-bgp:${i.peer_address}" => i }


  #=======================================================================================
  # L3Outs - Logical Node Profiles - Logical Interface Profiles - HSRP Interface Profiles
  #=======================================================================================

  hsrp_interface_profile = { for i in flatten([
    for key, value in local.l3out_interface_profiles : [
      for v in value.hsrp_interface_profile : {
        alias                   = lookup(v, "alias", local.hip.alias)
        annotation              = lookup(v, "annotation", local.hip.annotation)
        description             = lookup(v, "description", local.hip.description)
        groups                  = lookup(v, "groups", local.hip.groups)
        hsrp_interface_policy   = lookup(v, "hsrp_interface_policy", local.hip.hsrp_interface_policy)
        l3out_interface_profile = key
        version                 = lookup(v, "version", local.hip.version)
      }
    ]
  ]) : "${i.l3out_interface_profile}-hsrp" => i }

  hsrp_interface_profile_groups = { for i in flatten([
    for key, value in local.hsrp_interface_profile : [
      for v in value.groups : {
        alias                  = lookup(v, "alias", local.hip.groups.alias)
        annotation             = lookup(v, "annotation", local.hip.groups.annotation)
        description            = lookup(v, "description", local.hip.groups.description)
        group_id               = lookup(v, "group_id", local.hip.groups.group_id)
        group_name             = lookup(v, "group_name", local.hip.groups.group_name)
        group_type             = lookup(v, "group_type", local.hip.groups.group_type)
        hsrp_group_policy      = lookup(v, "hsrp_group_policy", local.hip.groups.hsrp_group_policy)
        hsrp_interface_profile = key
        ip_address             = lookup(v, "ip_address", local.hip.groups.ip_address)
        ip_obtain_mode         = lookup(v, "ip_obtain_mode", local.hip.groups.ip_obtain_mode)
        mac_address            = lookup(v, "mac_address", local.hip.groups.mac_address)
        name                   = v.name
        secondary_virtual_ips  = lookup(v, "secondary_virtual_ips", local.hip.groups.secondary_virtual_ips)
      }
    ]
  ]) : "${i.hsrp_interface_profile}:${i.name}" => i }

  hsrp_interface_profile_group_secondaries = { for i in flatten([
    for key, value in local.hsrp_interface_profile_groups : [
      for s in value.secondary_virtual_ips : {
        hsrp_interface_profile_group = key
        secondary_ip                 = s
      }
    ]
  ]) : "${i.hsrp_interface_profile_group}:${i.secondary_ip}" => i }

  #=======================================================================================
  # L3Outs - Logical Node Profiles - Logical Interface Profiles - OSPF Interface Policies
  #=======================================================================================

  l3out_ospf_interface_profiles = { for i in flatten([
    for key, value in local.l3out_interface_profiles : [
      for v in value.ospf_interface_profile : {
        annotation              = value.annotation
        authentication_type     = lookup(v, "authentication_type", local.ospfip.authentication_type)
        description             = lookup(v, "description", local.ospfip.description)
        l3out_interface_profile = key
        l3out                   = value.l3out
        name                    = v.name
        ospf_key                = lookup(v, "ospf_key", local.ospfip.ospf_key)
        ospf_interface_policy   = lookup(v, "ospf_interface_policy", local.ospfip.ospf_interface_policy)
        tenant                  = value.tenant
      }
    ]
  ]) : "${i.l3out_interface_profile}:ospf:${i.name}" => i }


  #__________________________________________________________
  #
  # Policies - BFD Interface
  #__________________________________________________________

  policies_bfd_interface = {
    for v in lookup(local.policies, "bfd_interface", []) : v.name => {
      admin_state           = lookup(v, "admin_state", local.bfd.admin_state)
      annotation            = lookup(v, "annotation", local.bfd.annotation)
      description           = lookup(v, "description", local.bfd.description)
      detection_multiplier  = lookup(v, "detection_multiplier", local.bfd.detection_multiplier)
      echo_admin_state      = lookup(v, "echo_admin_state", local.bfd.echo_admin_state)
      echo_recieve_interval = lookup(v, "echo_recieve_interval", local.bfd.echo_recieve_interval)
      enable_sub_interface_optimization = lookup(
        v, "enable_sub_interface_optimization", local.bfd.enable_sub_interface_optimization
      )
      minimum_recieve_interval  = lookup(v, "minimum_recieve_interval", local.bfd.minimum_recieve_interval)
      minimum_transmit_interval = lookup(v, "minimum_transmit_interval", local.bfd.minimum_transmit_interval)
      tenant                    = var.tenant
    }
  }


  #__________________________________________________________
  #
  # Policies - BGP
  #__________________________________________________________

  policies_bgp_address_family_context = {
    for v in lookup(lookup(local.policies, "bgp", {}), "bgp_address_family_context", []) : v.name => {
      annotation             = lookup(v, "annotation", local.bgpa.annotation)
      description            = lookup(v, "description", local.bgpa.description)
      ebgp_distance          = lookup(v, "ebgp_distance", local.bgpa.ebgp_distance)
      ebgp_max_ecmp          = lookup(v, "ebgp_max_ecmp", local.bgpa.ebgp_max_ecmp)
      enable_host_route_leak = lookup(v, "enable_host_route_leak", local.bgpa.enable_host_route_leak)
      ibgp_distance          = lookup(v, "ibgp_distance", local.bgpa.ibgp_distance)
      ibgp_max_ecmp          = lookup(v, "ibgp_max_ecmp", local.bgpa.ibgp_max_ecmp)
      local_distance         = lookup(v, "local_distance", local.bgpa.local_distance)
      tenant                 = var.tenant
    }
  }

  policies_bgp_best_path = {
    for v in lookup(lookup(local.policies, "bgp", {}), "bgp_best_path", []) : v.name => {
      annotation  = lookup(v, "annotation", local.bgpb.annotation)
      description = lookup(v, "description", local.bgpb.description)
      relax_as_path_restriction = lookup(
        v, "relax_as_path_restriction", local.bgpb.relax_as_path_restriction
      )
      tenant = var.tenant
    }
  }

  policies_bgp_peer_prefix = {
    for v in lookup(lookup(local.policies, "bgp", {}), "bgp_peer_prefix", []) : v.name => {
      action      = lookup(v, "action", local.bgpp.action)
      annotation  = lookup(v, "annotation", local.bgpp.annotation)
      description = lookup(v, "description", local.bgpp.description)
      maximum_number_of_prefixes = lookup(
        v, "maximum_number_of_prefixes", local.bgpp.maximum_number_of_prefixes
      )
      restart_time = lookup(v, "restart_time", local.bgpp.restart_time)
      tenant       = var.tenant
      threshold    = lookup(v, "threshold", local.bgpp.threshold)
    }
  }

  policies_bgp_route_summarization = {
    for v in lookup(lookup(local.policies, "bgp", {}), "bgp_route_summarization", []) : v.name => {
      address_type_controls = {
        do_not_advertise_more_specifics = lookup(lookup(
          v, "address_type_controls", local.bgps.address_type_controls), "af_mcast", false
        )
        generate_as_set_information = lookup(lookup(
          v, "address_type_controls", local.bgps.address_type_controls), "af_ucast", true
        )
      }
      annotation  = lookup(v, "annotation", local.bgps.annotation)
      description = lookup(v, "description", local.bgps.description)
      control_state = {
        do_not_advertise_more_specifics = lookup(lookup(
          v, "control_state", local.bgps.control_state), "do_not_advertise_more_specifics", false
        )
        generate_as_set_information = lookup(lookup(
          v, "control_state", local.bgps.control_state), "generate_as_set_information", false
        )
      }
      tenant = var.tenant
    }
  }

  policies_bgp_timers = {
    for v in lookup(lookup(local.policies, "bgp", {}), "bgp_timers", []) : v.name => {
      annotation              = lookup(v, "annotation", local.bgpt.annotation)
      description             = lookup(v, "description", local.bgpt.description)
      graceful_restart_helper = lookup(v, "graceful_restart_helper", local.bgpt.graceful_restart_helper)
      hold_interval           = lookup(v, "hold_interval", local.bgpt.hold_interval)
      keepalive_interval      = lookup(v, "keepalive_interval", local.bgpt.keepalive_interval)
      maximum_as_limit        = lookup(v, "maximum_as_limit", local.bgpt.maximum_as_limit)
      stale_interval          = lookup(v, "stale_interval", local.bgpt.stale_interval)
      tenant                  = var.tenant
    }
  }


  #__________________________________________________________
  #
  # Policies - DHCP Variables
  #__________________________________________________________

  policies_dhcp_option = {
    for v in lookup(lookup(local.policies, "dhcp", {}), "option_policies", []) : v.name => {
      annotation  = lookup(v, "annotation", local.dhcpo.annotation)
      description = lookup(v, "description", local.dhcpo.description)
      options = { for value in lookup(v, "options", []) : v.name =>
        {
          data           = value.data
          dhcp_option_id = value.dhcp_option_id
          name           = value.name
        }
      }
      tenant = var.tenant
    }
  }

  policies_dhcp_relay = {
    for v in lookup(lookup(local.policies, "dhcp", {}), "relay_policies", []) : v.name => {
      annotation  = lookup(v, "annotation", local.dhcpr.annotation)
      description = lookup(v, "description", local.dhcpr.description)
      dhcp_relay_providers = { for value in v.dhcp_relay_providers : value.address =>
        {
          address = value.address
          application_profile = lookup(
            value, "application_profile", local.dhcpr.dhcp_relay_providers.application_profile
          )
          epg      = lookup(value, "epg", local.dhcpr.dhcp_relay_providers.epg)
          epg_type = lookup(value, "epg_type", local.dhcpr.dhcp_relay_providers.epg_type)
          l3out    = lookup(value, "l3out", local.dhcpr.dhcp_relay_providers.l3out)
          tenant   = var.tenant
        }
      }
      mode   = lookup(v, "mode", local.dhcpr.mode)
      tenant = var.tenant
    }
  }


  #__________________________________________________________
  #
  # Policies - Endpoint Retention Variables
  #__________________________________________________________

  policies_endpoint_retention = {
    for v in lookup(local.policies, "endpoint_retention", []) : v.name => {
      annotation = lookup(v, "annotation", local.ep.annotation)
      bounce_entry_aging_interval = lookup(
        v, "bounce_entry_aging_interval", local.ep.bounce_entry_aging_interval
      )
      bounce_trigger = lookup(v, "bounce_trigger", local.ep.bounce_trigger)
      description    = lookup(v, "description", local.ep.description)
      hold_interval  = lookup(v, "hold_interval", local.ep.hold_interval)
      local_endpoint_aging_interval = lookup(
        v, "local_endpoint_aging_interval", local.ep.local_endpoint_aging_interval
      )
      move_frequency = lookup(v, "move_frequency", local.ep.move_frequency)
      remote_endpoint_aging_interval = lookup(
        v, "remote_endpoint_aging_interval", local.ep.remote_endpoint_aging_interval
      )
      tenant = var.tenant
    }
  }


  #__________________________________________________________
  #
  # Policies - HSRP
  #__________________________________________________________

  policies_hsrp_group = {
    for v in lookup(lookup(local.policies, "hsrp", {}), "group_policies", []) : v.name => {
      annotation  = lookup(v, "annotation", local.hsrpg.annotation)
      description = lookup(v, "description", local.hsrpg.description)
      enable_preemption_for_the_group = lookup(
        v, "enable_preemption_for_the_group", local.hsrpg.enable_preemption_for_the_group
      )
      hello_interval = lookup(v, "hello_interval", local.hsrpg.hello_interval)
      hold_interval  = lookup(v, "hold_interval", local.hsrpg.hold_interval)
      key            = lookup(v, "key", local.hsrpg.key)
      max_seconds_to_prevent_preemption = lookup(
        v, "max_seconds_to_prevent_preemption", local.hsrpg.max_seconds_to_prevent_preemption
      )
      min_preemption_delay = lookup(v, "min_preemption_delay", local.hsrpg.min_preemption_delay)
      preemption_delay_after_reboot = lookup(
        v, "preemption_delay_after_reboot", local.hsrpg.preemption_delay_after_reboot
      )
      priority = lookup(v, "priority", local.hsrpg.priority)
      timeout  = lookup(v, "timeout", local.hsrpg.timeout)
      type     = lookup(v, "type", local.hsrpg.type)
      tenant   = var.tenant
    }
  }

  policies_hsrp_interface = {
    for v in lookup(lookup(local.policies, "hsrp", {}), "interface_policies", []) : v.name => {
      annotation   = lookup(v, "annotation", local.hsrpi.annotation)
      delay        = lookup(v, "delay", local.hsrpi.delay)
      description  = lookup(v, "description", local.hsrpi.description)
      reload_delay = lookup(v, "reload_delay", local.hsrpi.reload_delay)
      enable_bidirectional_forwarding_detection = lookup(
        v, "enable_bidirectional_forwarding_detection", local.hsrpi.enable_bidirectional_forwarding_detection
      )
      use_burnt_in_mac_address_of_the_interface = lookup(
        v, "use_burnt_in_mac_address_of_the_interface", local.hsrpi.use_burnt_in_mac_address_of_the_interface
      )
      tenant = var.tenant
    }
  }

  #__________________________________________________________
  #
  # Policies - IP SLA
  #__________________________________________________________
  policies_ip_sla_monitoring = {
    for v in lookup(lookup(local.policies, "ip_sla", {}), "ip_sla_monitoring_policies", []) : v.name => {
      annotation          = lookup(v, "annotation", local.sla.annotation)
      detect_multiplier   = lookup(v, "detect_multiplier", local.sla.detect_multiplier)
      http_uri            = lookup(v, "http_uri", local.sla.http_uri)
      http_version        = lookup(v, "http_version", local.sla.http_version)
      operation_timeout   = lookup(v, "operation_timeout", local.sla.operation_timeout)
      request_data_size   = lookup(v, "request_data_size", local.sla.request_data_size)
      sla_frequency       = lookup(v, "sla_frequency", local.sla.sla_frequency)
      sla_port            = lookup(v, "sla_port", local.sla.sla_port)
      sla_type            = lookup(v, "sla_type", local.sla.sla_type)
      threshold           = lookup(v, "threshold", local.sla.threshold)
      http_uri            = lookup(v, "http_uri", local.sla.http_uri)
      traffic_class_value = lookup(v, "traffic_class_value", local.sla.traffic_class_value)
      type_of_service     = lookup(v, "type_of_service", local.sla.type_of_service)
    }
  }

  #__________________________________________________________
  #
  # Policies - L4-L7 Policy-Based Redirect
  #__________________________________________________________
  policies_l4_l7_pbr = {
    for v in lookup(local.policies, "l4-l7_policy-based_redirect", []) : v.name => {
      annotation       = lookup(v, "annotation", local.l4l7pbr.annotation)
      anycast_enabled  = lookup(v, "anycast_enabled", local.l4l7pbr.anycast_enabled)
      description      = lookup(v, "description", local.l4l7pbr.description)
      destinations     = lookup(v, "destinations", [])
      destination_type = lookup(v, "destination_type", local.l4l7pbr.destination_type)
      enable_pod_id_aware_redirection = lookup(
        v, "enable_pod_id_aware_redirection", local.l4l7pbr.enable_pod_id_aware_redirection
      )
      hashing_algorithm         = lookup(v, "hashing_algorithm", local.l4l7pbr.hashing_algorithm)
      ip_sla_monitoring_policy  = lookup(v, "ipsla_monitoring_policy", local.l4l7pbr.ip_sla_monitoring_policy)
      max_threshold_percentage  = lookup(v, "max_threshold_percentage", local.l4l7pbr.max_threshold_percentage)
      min_threshold_percentage  = lookup(v, "min_threshold_percentage", local.l4l7pbr.min_threshold_percentage)
      resilient_hashing_enabled = lookup(v, "resilient_hashing_enabled", local.l4l7pbr.resilient_hashing_enabled)
      threshold_enable          = lookup(v, "threshold_enable", local.l4l7pbr.threshold_enable)
      threshold_down_action     = lookup(v, "threshold_down_action", local.l4l7pbr.threshold_down_action)
    }
  }

  policies_l4_l7_pbr_destinations = { for i in flatten([
    for key, value in local.policies_l4_l7_pbr : [
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
  ]) : "${i.l4_l7_pbr_policy}:${i.dest_key}" => i }

  #__________________________________________________________
  #
  # Policies - L4-L7 Redirect Health Groups
  #__________________________________________________________
  policies_l4_l7_redirect_health_groups = {
    for v in lookup(local.policies, "l4-l7_redirect_health_groups", []) : v.name => {
      annotation  = lookup(v, "annotation", local.l4l7rhg.annotation)
      description = lookup(v, "description", local.l4l7rhg.description)
    }
  }


  #__________________________________________________________
  #
  # Policies - OSPF Variables
  #__________________________________________________________

  policies_ospf_interface = {
    for v in lookup(lookup(local.policies, "ospf", {}), "ospf_interface", []) : v.name => {
      annotation        = lookup(v, "annotation", local.ospfi.annotation)
      cost_of_interface = lookup(v, "cost_of_interface", local.ospfi.cost_of_interface)
      dead_interval     = lookup(v, "dead_interval", local.ospfi.dead_interval)
      description       = lookup(v, "description", local.ospfi.description)
      hello_interval    = lookup(v, "hello_interval", local.ospfi.hello_interval)
      interface_controls = {
        advertise_subnet = lookup(v, "advertise_subnet", local.ospfi.interface_controls.advertise_subnet)
        bfd              = lookup(v, "bfd", local.ospfi.interface_controls.bfd)
        mtu_ignore       = lookup(v, "mtu_ignore", local.ospfi.interface_controls.mtu_ignore)
        passive_participation = lookup(
          v, "passive_participation", local.ospfi.interface_controls.passive_participation
        )
      }
      network_type        = lookup(v, "network_type", local.ospfi.network_type)
      priority            = lookup(v, "priority", local.ospfi.priority)
      retransmit_interval = lookup(v, "retransmit_interval", local.ospfi.retransmit_interval)
      tenant              = var.tenant
      transmit_delay      = lookup(v, "transmit_delay", local.ospfi.transmit_delay)
    }
  }

  policies_ospf_route_summarization = {
    for v in lookup(lookup(local.policies, "ospf", {}), "ospf_route_summarization", []) : v.name => {
      annotation         = lookup(v, "annotation", local.ospfs.annotation)
      cost               = lookup(v, "cost", local.ospfs.cost)
      description        = lookup(v, "description", local.ospfs.description)
      inter_area_enabled = lookup(v, "inter_area_enabled", local.ospfs.inter_area_enabled)
      tenant             = var.tenant
    }
  }

  policies_ospf_timers = {
    for v in lookup(lookup(local.policies, "ospf", {}), "ospf_timers", []) : v.name => {
      annotation                = lookup(v, "annotation", local.ospft.annotation)
      bandwidth_reference       = lookup(v, "bandwidth_reference", local.ospft.bandwidth_reference)
      description               = lookup(v, "description", local.ospft.description)
      admin_distance_preference = lookup(v, "admin_distance_preference", local.ospft.admin_distance_preference)
      graceful_restart_helper   = lookup(v, "graceful_restart_helper", local.ospft.graceful_restart_helper)
      initial_spf_scheduled_delay_interval = lookup(
        v, "initial_spf_scheduled_delay_interval", local.ospft.initial_spf_scheduled_delay_interval
      )
      lsa_group_pacing_interval = lookup(v, "lsa_group_pacing_interval", local.ospft.lsa_group_pacing_interval)
      lsa_generation_throttle_hold_interval = lookup(
        v, "lsa_generation_throttle_hold_interval", local.ospft.lsa_generation_throttle_hold_interval
      )
      lsa_generation_throttle_maximum_interval = lookup(
        v, "lsa_generation_throttle_maximum_interval", local.ospft.lsa_generation_throttle_maximum_interval
      )
      lsa_generation_throttle_start_wait_interval = lookup(
        v, "lsa_generation_throttle_start_wait_interval", local.ospft.lsa_generation_throttle_start_wait_interval
      )
      lsa_maximum_action         = lookup(v, "lsa_maximum_action", local.ospft.lsa_maximum_action)
      lsa_threshold              = lookup(v, "lsa_threshold", local.ospft.lsa_threshold)
      maximum_ecmp               = lookup(v, "maximum_ecmp", local.ospft.maximum_ecmp)
      maximum_lsa_reset_interval = lookup(v, "maximum_lsa_reset_interval", local.ospft.maximum_lsa_reset_interval)
      maximum_lsa_sleep_count    = lookup(v, "maximum_lsa_sleep_count", local.ospft.maximum_lsa_sleep_count)
      maximum_lsa_sleep_interval = lookup(v, "maximum_lsa_sleep_interval", local.ospft.maximum_lsa_sleep_interval)
      maximum_number_of_not_self_generated_lsas = lookup(
        v, "maximum_number_of_not_self_generated_lsas", local.ospft.maximum_number_of_not_self_generated_lsas
      )
      minimum_hold_time_between_spf_calculations = lookup(
        v, "minimum_hold_time_between_spf_calculations", local.ospft.minimum_hold_time_between_spf_calculations
      )
      minimum_interval_between_arrival_of_a_lsa = lookup(
        v, "minimum_interval_between_arrival_of_a_lsa", local.ospft.minimum_interval_between_arrival_of_a_lsa
      )
      maximum_wait_time_between_spf_calculations = lookup(
        v, "maximum_wait_time_between_spf_calculations", local.ospft.maximum_wait_time_between_spf_calculations
      )
      control_knobs = {
        enable_name_lookup_for_router_ids = lookup(
          lookup(v, "control_knobs"
        ), "enable_name_lookup_for_router_ids", local.ospft.control_knobs.enable_name_lookup_for_router_ids)
        prefix_suppress = lookup(lookup(v, "control_knobs"
        ), "prefix_suppress", local.ospft.control_knobs.prefix_suppress)
      }
      tenant = var.tenant
    }
  }


  #__________________________________________________________
  #
  # Route Map Match Rule Variables
  #__________________________________________________________

  route_map_match_rules = {
    for v in lookup(lookup(local.policies, "protocol", {}), "route_map_match_rules", []) : v.name => {
      annotation                   = lookup(v, "annotation", local.rmsr.annotation)
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
  ]) : "${i.match_rule}:${i.name}" => i }

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
  ]) : "${i.match_rule}:${i.community_type}" => i }

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
  ]) : "${i.match_rule}:${i.ip}" => i }


  #__________________________________________________________
  #
  # Route Map Set Rule Variables
  #__________________________________________________________

  route_map_set_rules = {
    for v in lookup(lookup(local.policies, "protocol", {}), "route_map_set_rules", []) : v.name => {
      additional_communities = lookup(v, "additional_communities", [])
      annotation             = lookup(v, "annotation", local.rmsr.annotation)
      description            = lookup(v, "description", local.rmsr.description)
      multipath              = lookup(v, "multipath", local.rmsr.multipath)
      next_hop_propegation   = lookup(v, "next_hop_propegation", local.rmsr.next_hop_propegation)
      set_as_path            = lookup(v, "set_as_path", [])
      set_communities        = lookup(v, "set_communities", [])
      set_dampening          = lookup(v, "set_dampening", [])
      set_external_epg       = lookup(v, "set_external_epg", [])
      set_metric             = lookup(v, "set_metric", local.rmsr.set_metric)
      set_metric_type        = lookup(v, "set_metric_type", local.rmsr.set_metric_type)
      set_next_hop_address   = lookup(v, "set_next_hop_address", local.rmsr.set_next_hop_address)
      set_preference         = lookup(v, "set_preference", local.rmsr.set_preference)
      set_route_tag          = lookup(v, "set_route_tag", local.rmsr.set_route_tag)
      set_weight             = lookup(v, "set_weight", local.rmsr.set_weight)
      tenant                 = var.tenant
    }
  }

  set_rules_additional_communities = { for i in flatten([
    for key, value in local.route_map_set_rules : [
      for v in value.additional_communities : {
        community   = v.community
        description = lookup(v, "description", local.rmsr.rules.communites.description)
        set_rule    = value.set_rule
        tenant      = value.tenant
      }
    ]
  ]) : "${i.set_rule}:${i.community}" => i }

  set_rules_set_as_path = { for i in flatten([
    for key, value in local.route_map_set_rules : [
      for v in value.set_as_path : {
        autonomous_systems = length(lookup(v, "autonomous_systems", [])) > 0 ? [
          for s in range(length(v.autonomous_systems)) : {
            asn   = element(v.autonomous_systems, s)
            order = s
          }
        ] : []
        criteria      = lookup(v, "criteria", local.rmsr.set_as_path.criteria)
        last_as_count = lookup(v, "last_as_count", local.rmsr.set_as_path.last_as_count)
        set_rule      = value.set_rule
        tenant        = value.tenant
      }
    ]
  ]) : "${i.set_rule}:${i.criteria}" => i }

  set_rules_set_communities = { for i in flatten([
    for key, value in local.route_map_set_rules : [
      for v in value.set_communities : {
        community = lookup(v, "community", local.rmsr.set_communities.community)
        criteria  = lookup(v, "criteria", local.rmsr.set_communities.criteria)
        set_rule  = key
        tenant    = var.tenant
      }
    ]
  ]) : "${i.set_rule}:${i.criteria}" => i }

  set_rules_set_dampening = { for i in flatten([
    for key, value in local.route_map_set_rules : [
      for v in value.set_dampening : {
        half_life         = lookup(v, "half_life", local.rmsr.rules.half_life)
        max_suprress_time = lookup(v, "max_suprress_time", local.rmsr.rules.max_suprress_time)
        reuse_limit       = lookup(v, "reuse_limit", local.rmsr.rules.reuse_limit)
        set_rule          = key
        suppress_limit    = lookup(v, "suppress_limit", local.rmsr.rules.suppress_limit)
        tenant            = var.tenant
      }
    ]
  ]) : "${i.set_rule}-dampening" => i }

  set_rules_set_external_epg = { for i in flatten([
    for key, value in local.route_map_set_rules : [
      for v in value.rules : {
        epg_tenant     = v.tenant
        external_epg   = v.external_epg
        l3out          = v.l3out
        set_rule       = key
        suppress_limit = lookup(v, "suppress_limit", local.rmsr.rules.suppress_limit)
      }
    ]
  ]) : "${i.set_rule}-external-epg" => i }


  #__________________________________________________________
  #
  # Route Maps Rule Variables
  #__________________________________________________________

  route_maps_for_route_control = {
    for v in lookup(lookup(local.policies, "protocol", {}), "route_maps_for_route_control", []) : v.name => {
      annotation         = lookup(v, "annotation", local.rm.annotation)
      contexts           = lookup(v, "contexts", [])
      description        = lookup(v, "description", local.rm.description)
      route_map_continue = lookup(v, "route_map_continue", local.rm.route_map_continue)
      tenant             = var.tenant
      type               = lookup(v, "type", local.rm.type)
    }
  }

  route_map_contexts = { for i in flatten([
    for key, value in local.route_maps_for_route_control : [
      for k, v in value.contexts : {
        action      = v.action
        annotation  = value.annotation
        description = lookup(v, "description", local.rm.contexts.description)
        match_rules = [
          for i in lookup(v, "match_rules", []) : {
            rule_name = i
          }
        ]
        name      = v.name
        order     = k
        route_map = key
        set_rule  = lookup(v, "set_rule", local.rm.contexts.set_rule)
        tenant    = value.tenant
      }
    ]
  ]) : "${i.route_map}:${i.name}" => i }


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
