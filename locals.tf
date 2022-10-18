locals {
  #__________________________________________________________
  #
  # Model Inputs
  #__________________________________________________________

  defaults          = lookup(var.model, "defaults", {})
  networking        = lookup(local.tenant[index(local.tenant[*].name, var.tenant)], "networking", {})
  policies          = lookup(local.tenant[index(local.tenant[*].name, var.tenant)], "policies", {})
  templates_bds     = lookup(lookup(var.model, "templates", {}), "bridge_domains", {})
  templates_epgs    = lookup(lookup(var.model, "templates", {}), "application_epgs", {})
  templates_subnets = lookup(lookup(var.model, "templates", {}), "subnets", {})
  tenant            = lookup(var.model, "tenants", {})
  tenant_contracts  = lookup(local.tenant[index(local.tenant[*].name, var.tenant)], "contracts", {})

  # Defaults
  app      = local.defaults.tenants.application_profiles
  adv      = local.bd.advanced_troubleshooting
  bd       = local.defaults.tenants.networking.bridge_domains
  bfd      = local.defaults.tenants.policies.protocol.bfd_interface
  bgpa     = local.defaults.tenants.policies.protocol.bgp.bgp_address_family_context
  bgpb     = local.defaults.tenants.policies.protocol.bgp.bgp_best_path
  bgpp     = local.defaults.tenants.policies.protocol.bgp.bgp_peer_prefix
  bgps     = local.defaults.tenants.policies.protocol.bgp.bgp_route_summarization
  bgpt     = local.defaults.tenants.policies.protocol.bgp.bgp_timers
  contract = local.defaults.tenants.contracts.contract
  dhcpo    = local.defaults.tenants.policies.protocol.dhcp.option_policies
  dhcpr    = local.defaults.tenants.policies.protocol.dhcp.relay_policies
  ep       = local.defaults.tenants.policies.protocol.endpoint_retention
  epg      = local.app.application_epgs
  filter   = local.defaults.tenants.contracts.filters
  general  = local.bd.general
  hsrpg    = local.defaults.tenants.policies.protocol.hsrp.group_policies
  hsrpi    = local.defaults.tenants.policies.protocol.hsrp.interface_policies
  l3       = local.bd.l3_configurations
  l3out    = local.defaults.tenants.networking.l3outs
  ospfi    = local.defaults.tenants.policies.protocol.ospf.ospf_interface
  ospfs    = local.defaults.tenants.policies.protocol.ospf.ospf_route_summarization
  ospft    = local.defaults.tenants.policies.protocol.ospf.ospf_timers
  subnet   = local.l3.subnets
  rm       = local.defaults.policies.protocol.route_maps_for_route_control
  rmmr     = local.defaults.policies.protocol.route_map_match_rules
  rmsr     = local.defaults.policies.protocol.route_map_set_rules
  tnt      = local.defaults.tenants
  vrf      = local.defaults.tenants.networking.vrfs

  # Local Values
  controller_type = local.tenants[var.tenant].controller_type
  policy_tenant   = local.tenants[var.tenant].policy_tenant
  schema = length([for i in local.schemas : i.name]
  ) > 0 ? [for i in local.schemas : i.name][0] : ""
  sites = [for i in local.tenants[var.tenant].sites : i.name]
  users = local.tenants[var.tenant].users

  #__________________________________________________________
  #
  # Tenant Variables
  #__________________________________________________________

  tenants = {
    for v in lookup(var.model, "tenants", []) : v.name => {
      alias      = lookup(v, "alias", local.tnt.alias)
      annotation = lookup(v, "annotation", local.tnt.annotation)
      annotations = length(lookup(v, "annotations", local.tnt.annotations)
      ) > 0 ? lookup(v, "annotations", local.tnt.annotations) : local.defaults.annotations
      controller_type   = length(lookup(v, "schema", [])) > 0 ? "ndo" : "apic"
      description       = lookup(v, "description", local.tnt.description)
      global_alias      = lookup(v, "global_alias", local.tnt.global_alias)
      monitoring_policy = lookup(v, "monitoring_policy", local.tnt.monitoring_policy)
      name              = v.name
      policy_tenant     = lookup(v, "policy_tenant", local.tnt.policy_tenant)
      schema            = lookup(v, "schema", [])
      sites = [
        for i in lookup(lookup(v, "ndo", {}), "sites", []) : {
          aws_access_key_id = lookup(i, "aws_access_key_id", local.tnt.site.aws_access_key_id)
          aws_account_id    = lookup(i, "aws_account_id", local.tnt.site.aws_account_id)
          azure_access_type = lookup(i, "azure_access_type", local.tnt.site.azure_access_type)
          azure_active_directory_id = lookup(
            i, "azure_active_directory_id", local.tnt.site.azure_active_directory_id
          )
          azure_application_id    = lookup(i, "azure_application_id", local.tnt.site.azure_application_id)
          azure_shared_account_id = lookup(i, "azure_shared_account_id", local.tnt.site.azure_shared_account_id)
          azure_subscription_id   = lookup(i, "azure_subscription_id", local.tnt.site.azure_subscription_id)
          is_aws_account_trusted  = lookup(i, "is_aws_account_trusted", local.tnt.site.is_aws_account_trusted)
          name                    = i.name
          vendor                  = lookup(i, "vendor", local.tnt.site.vendor)
        }
      ]
      users = lookup(lookup(v, "ndo", {}), "users", [])
    } if v.name == var.tenant
  }

  schemas = { for i in flatten([
    for k, v in local.tenants : [
      for s in v.schema : {
        name = s.name
        templates = [
          for t in lookup(s, "templates", []) : {
            name  = t.name
            sites = lookup(t, "sites", [])
          }
        ]
        tenant = k

      }
    ]
  ]) : i.name => i }

  template_sites = { for i in flatten([
    for value in local.schemas : [
      for v in value.templates : [
        for s in v.sites : {
          schema   = value.name
          template = v.name
          site     = s
        }
      ]
    ]
  ]) : "${i.schema}_${i.template}_${i.site}" => i }

  apics_inband_mgmt_addresses = {}
  #__________________________________________________________
  #
  # VRF Variables
  #__________________________________________________________

  vrfs = {
    for v in lookup(local.networking, "vrfs", []) : v.name => {
      alias      = lookup(v, "alias", local.vrf.alias)
      annotation = lookup(v, "annotation", local.vrf.annotation)
      annotations = length(lookup(v, "annotations", local.vrf.annotations)
      ) > 0 ? lookup(v, "annotations", local.vrf.annotations) : local.defaults.annotations
      bd_enforcement_status = lookup(v, "bd_enforcement_status", local.vrf.bd_enforcement_status)
      bgp_timers_per_address_family = lookup(
      v, "bgp_timers_per_address_family", local.vrf.bgp_timers_per_address_family)
      bgp_timers  = lookup(v, "bgp_timers", local.vrf.bgp_timers)
      communities = lookup(v, "communities", local.vrf.communities)
      description = lookup(v, "description", local.vrf.description)
      eigrp_timers_per_address_family = lookup(
        v, "eigrp_timers_per_address_family", local.vrf.eigrp_timers_per_address_family
      )
      endpoint_retention_policy = lookup(
        v, "endpoint_retention_policy", local.vrf.endpoint_retention_policy
      )
      epg_esg_collection_for_vrfs = {
        contracts = lookup(
        lookup(v, "epg_esg_collections_for_vrfs", {}), "contracts", [])
        label_match_criteria = lookup(
          lookup(v, "epg_esg_collections_for_vrfs", {}
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
      sites                    = lookup(lookup(v, "ndo", {}), "sites", [])
      schema                   = local.schema
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
        template             = value.template
        tenant               = value.tenant
        vrf                  = key
      }
    ]
  ]) : "${i.vrf}_${i.contract}_${i.contract_type}" => i }

  vrf_sites = { for i in flatten([
    for k, v in local.vrfs : [
      for s in v.sites : {
        schema   = v.schema
        site     = s
        template = v.template
        vrf      = k
      }
    ] if local.controller_type == "ndo"
  ]) : "${i.vrf}_${i.site}" => i }

  #__________________________________________________________
  #
  # Bridge Domain Variables
  #__________________________________________________________

  bds_to_merge = [
    for v in lookup(local.networking, "bridge_domains", []) : {
      bd       = v.name
      template = lookup(v, "template", "")
    } if lookup(v, "template", "") != ""
  ]
  merge_bds = length(local.bds_to_merge) > 0 ? { for i in flatten([
    for v in local.bds_to_merge : [
      merge(local.networking.bridge_domains[index(local.networking.bridge_domains[*].name, v.bd)
      ], local.templates_bds[index(local.templates_bds[*].template_name, v.template)])
    ]
  ]) : i.name => i } : {}

  bds = { for v in lookup(local.networking, "bridge_domains", []) : v.name => v }

  merged_bds = merge(local.bds, local.merge_bds)

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
      dhcp_relay_labels = flatten([
        for s in lookup(v, "dhcp_relay_labels") : [
          for i in s.names : {
            dhcp_option_policy = lookup(s, "dhcp_option_policy", local.bd.dhcp_relay_labels.dhcp_option_policy)
            scope              = lookup(s, "scope", local.bd.dhcp_relay_labels.scope)
            name               = i
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
        ) : local.defaults.annotations
        arp_flooding = lookup(lookup(v, "general", {}), "arp_flooding", local.general.arp_flooding)
        description  = lookup(lookup(v, "general", {}), "description", local.general.description)
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
          schema = lookup(lookup(lookup(v, "general", {}), "vrf", {}), "schema", local.schema)
          template = lookup(lookup(lookup(v, "general", {}
          ), "vrf", {}), "name", lookup(lookup(v, "ndo", {}), "template", ""))
          tenant = lookup(lookup(lookup(v, "general", {}), "vrf", {}), "name", local.tenant)
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
      ndo = {
        schema   = local.schema
        sites    = lookup(lookup(v, "ndo", {}), "sites", [])
        template = lookup(lookup(v, "ndo", {}), "template", "")
      }
      tenant = var.tenant
    }
  }
  ndo_bd_sites = { for i in flatten([
    for k, v in local.bridge_domains : [
      for s in range(length(v.ndo.sites)) : {
        advertise_host_routes = s == s + 1 ? false : v.general.advertise_host_routes
        bridge_domain         = k
        l3out                 = element(v.l3_configurations.associated_l3outs.l3out, s + 1)
        schema                = v.ndo.schema
        site                  = element(v.sites, s + 1)
        template              = v.ndo.template
      }
    ]
  ]) : "${i.bridge_domain}-${i.site}" => i if local.controller_type == "ndo" }

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
  ]) : "${i.bridge_domain}-${i.name}" => i }

  bridge_domain_subnets = { for i in flatten([
    for key, value in local.bridge_domains : [
      for v in value.l3_configurations.subnets : {
        bridge_domain          = key
        description            = lookup(v, "description", local.subnet.description)
        gateway_ip             = v.address
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
  ]) : "${i.bridge_domain}-${i.gateway_ip}" => i }

  rogue_coop_exception_list = { for i in flatten([
    for k, v in local.bridge_domains : [
      for s in v.advanced_troubleshooting.rogue_coop_exception_list : {
        bridge_domain = k
        mac_address   = s
        tenant        = v.tenant
      }
    ] if local.controller_type == "apic"
  ]) : "${i.bridge_domain}_${i.mac_address}" => i }


  #__________________________________________________________
  #
  # Application Profile(s) and Endpoint Group(s) - Variables
  #__________________________________________________________

  application_profiles = {
    for v in lookup(local.tenant[index(local.tenant[*].name, var.tenant)], "application_profiles", {}
      ) : v.name => {
      alias      = lookup(v, "alias", local.app.alias)
      annotation = lookup(v, "annotation", local.app.annotation)
      annotations = length(lookup(v, "annotations", local.app.annotations)
      ) > 0 ? lookup(v, "annotations", local.app.annotations) : local.defaults.annotations
      application_epgs  = lookup(v, "application_epgs", [])
      description       = lookup(v, "description", local.app.description)
      global_alias      = lookup(v, "global_alias", local.app.global_alias)
      monitoring_policy = lookup(v, "monitoring_policy", local.app.monitoring_policy)
      name              = v.name
      qos_class         = lookup(v, "qos_class", local.app.qos_class)
      ndo = {
        schema   = local.schema
        sites    = local.sites
        template = lookup(v, "template", "")
      }
      tenant = var.tenant
    }
  }

  application_sites = { for i in flatten([
    for k, v in local.application_profiles : [
      for s in v.ndo.sites : {
        application_profile = k
        schema              = v.ndo.schema
        site                = s
        template            = v.ndo.template
      }
    ] if local.controller_type == "ndo"
  ]) : "${i.application_profile}-${i.site}" => i }

  # merged_epgs = { for i in flatten([
  #   for value in local.application_profiles : [
  #     [for v in value.applications_epgs : concat(lookup)]
  #   ]
  # ])
  application_epgs = { for i in flatten([
    for value in local.application_profiles : [
      for v in value.application_epgs : {
        alias      = lookup(v, "alias", local.epg.alias)
        annotation = lookup(v, "annotation", local.epg.annotation)
        annotations = length(lookup(v, "annotations", local.epg.annotations)
        ) > 0 ? lookup(v, "annotations", local.epg.annotations) : local.defaults.annotations
        application_profile    = value.name
        bridge_domain          = lookup(v, "bridge_domain", local.epg.bridge_domain)
        contract_exception_tag = lookup(v, "contract_exception_tag", local.epg.contract_exception_tag)
        contracts              = lookup(v, "contracts", [])
        controller_type        = value.controller_type
        custom_qos_policy      = lookup(v, "custom_qos_policy", local.epg.custom_qos_policy)
        data_plane_policer     = lookup(v, "data_plane_policer", local.epg.data_plane_policer)
        description            = lookup(v, "description", local.epg.description)
        domains                = lookup(v, "domains", [])
        epg_admin_state        = lookup(v, "epg_admin_state", local.epg.epg_admin_state)
        epg_contract_masters = [
          for s in lookup(v, "epg_contract_masters", []) : {
            application_profile = lookup(s, "application_profile", value.name)
            application_epg     = s.application_epg
          }
        ]
        epg_to_aaeps = [
          for s in lookup(v, "epg_to_aaeps", []) : {
            aaep = s.aaep
            instrumentation_immediacy = lookup(
              s, "instrumentation_immediacy", local.epg.epg_to_aaeps.instrumentation_immediacy
            )
            mode  = lookup(s, "mode", local.epg.epg_to_aaeps.mode)
            vlans = lookup(s, "vlans", [])
          }
        ]
        epg_type                 = lookup(v, "epg_type", local.epg.epg_type)
        fhs_trust_control_policy = lookup(v, "fhs_trust_control_policy", local.epg.fhs_trust_control_policy)
        flood_in_encapsulation   = lookup(v, "flood_in_encapsulation", local.epg.flood_in_encapsulation)
        global_alias             = lookup(v, "global_alias", local.epg.global_alias)
        has_multicast_source     = lookup(v, "has_multicast_source", local.epg.has_multicast_source)
        intra_epg_isolation      = lookup(v, "intra_epg_isolation", local.epg.intra_epg_isolation)
        label_match_criteria     = lookup(v, "label_match_criteria", local.epg.label_match_criteria)
        monitoring_policy        = lookup(v, "monitoring_policy", local.epg.monitoring_policy)
        name                     = v.name
        ndo = {
          schema   = local.schema
          sites    = local.sites
          template = lookup(v, "template", "")
        }
        preferred_group_member = lookup(v, "preferred_group_member", local.epg.preferred_group_member)
        qos_class              = lookup(v, "qos_class", local.epg.qos_class)
        static_paths           = lookup(v, "static_paths", [])
        tenant                 = var.tenant
        useg_epg               = lookup(v, "useg_epg", local.epg.useg_epg)
        vlan                   = lookup(v, "vlan", local.epg.vlan)
        vrf = {
          name     = local.bridge_domains[v.bridge_domain].vrf.name
          schema   = local.bridge_domains[v.bridge_domain].vrf.schema
          template = local.bridge_domains[v.bridge_domain].vrf.template
          tenant   = local.bridge_domains[v.bridge_domain].vrf.tenant
        }
        vzGraphCont = lookup(v, "vzGraphCont", local.epg.vzGraphCont)
      }
    ]
  ]) : "${i.application_profile}-${i.name}" => i }

  epg_to_domains = { for i in flatten([
    for key, value in local.application_epgs : [
      for v in value.domains : {
        annotation = lookup(v, "annotation", local.epg.domains.annotation)
        allow_micro_segmentation = lookup(
          v, "allow_micro_segmentation", local.epg.domains.allow_micro_segmentation
        )
        application_profile  = lookup(v, "application_profile", local.epg.domains.application_profile)
        application_epg      = lookup(v, "application_epg", local.epg.domains.application_epg)
        delimiter            = lookup(v, "delimiter", local.epg.domains.delimiter)
        deploy_immediacy     = lookup(v, "deploy_immediacy", local.epg.domains.deploy_immediacy)
        domain               = v.name
        domain_type          = lookup(v, "domain_type", local.epg.domain_type)
        enhanced_lag_policy  = lookup(v, "enhanced_lag_policy", local.epg.enhanced_lag_policy)
        epg_type             = value.epg_type
        number_of_ports      = lookup(v, "number_of_ports", local.epg.number_of_ports)
        port_allocation      = lookup(v, "port_allocation", local.epg.port_allocation)
        port_binding         = lookup(v, "port_binding", local.epg.port_binding)
        resolution_immediacy = lookup(v, "resolution_immediacy", local.epg.resolution_immediacy)
        security = {
          allow_promiscuous = lookup(lookup(v, "security", {}
          ), "allow_promiscuous", local.epg.security.allow_promiscuous)
          forged_transmits = lookup(lookup(v, "security", {}
          ), "forged_transmits", local.epg.security.forged_transmits)
          mac_changes = lookup(lookup(v, "security", {}), "mac_changes", local.epg.security.mac_changes)
        }
        switch_provider = lookup(v, "switch_provider", local.epg.switch_provider)
        vlan_mode       = lookup(v, "vlan_mode", local.epg.vlan_mode)
        vlans           = lookup(v, "vlans", local.epg.vlans)
      }
    ]
  ]) : "${i.application_profile}-${i.application_epg}-${i.domain}" => i }

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
  ]) : "${i.application_profile}-${i.application_epg}-${i.name}" => i }

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
  ]) : "${i.application_profile}-${i.application_epg}-${i.aaep}" => i }

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
  ]) : "${i.application_profile}-${i.application_epg}-${i.contract_type}-${i.contract}" => i }


  #__________________________________________________________
  #
  # Contract Variables
  #__________________________________________________________

  contracts = {
    for v in lookup(local.tenant_contracts, "contracts", []) : v.name => {
      alias      = lookup(v, "alias", local.contract.alias)
      annotation = lookup(v, "annotation", local.contract.annotation)
      annotations = length(lookup(v, "annotations", local.contract.annotations)
      ) > 0 ? lookup(v, "annotations", local.contract.annotations) : local.defaults.annotations
      apply_both_directions = lookup(lookup(
        v, "subjects", {})[0], "apply_both_directions", local.contract.subjects.apply_both_directions
      )
      contract_type = lookup(v, "contract_type", local.contract.contract_type)
      description   = lookup(v, "description", local.contract.description)
      filters = flatten([
        for s in lookup(v, "subjects", []) : [
          s.filters
        ]
      ])
      global_alias = v.global_alias != null ? v.global_alias : ""
      log          = v.log != null ? v.log : false
      ndo = {
        schema   = local.schema
        sites    = local.sites
        template = lookup(v, "template", "")
      }
      qos_class   = lookup(v, "qos_class", local.contract.qos_class)
      subjects    = lookup(v, "subjects", [])
      scope       = lookup(v, "scope", local.contract.scope)
      target_dscp = lookup(v, "target_dscp", local.contract.target_dscp)
      tenant      = var.tenant
    }
  }


  contract_subjects = { for i in flatten([
    for key, value in local.contracts : [
      for v in value.subjects : {
        action                = lookup(v, "action", local.contract.subjects.action)
        apply_both_directions = lookup(v, "apply_both_directions", local.contract.subjects.apply_both_directions)
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
    ] if value.controller_type == "apic"
  ]) : "${i.contract}_${i.name}" => i }

  subject_filters = { for i in flatten([
    for k, v in local.contract_subjects : [
      for s in v.filters : {
        action        = v.action
        contract      = v.contract
        contract_type = v.contract_type
        directives = {
          enable_policy_compression = lookup(lookup(v, "directives"
          ), "enable_policy_compression", local.contract.subject.directives.enable_policy_compression)
          log = lookup(lookup(v, "directives"), "log", local.contract.subject.directives.log)
        }
        filter  = s
        subject = v.name
        tenant  = v.tenant
      }
    ]
  ]) : "${i.contract}_${i.subject}_${i.filter}" => i }


  #__________________________________________________________
  #
  # Filter Variables
  #__________________________________________________________

  filters = {
    for v in lookup(local.tenant_contracts, "filters", []) : v.name => {
      alias      = lookup(v, "alias", local.filter.alias)
      annotation = lookup(v, "annotation", local.filter.annotation)
      annotations = length(lookup(v, "annotations", local.filter.annotations)
      ) > 0 ? lookup(v, "annotations", local.filter.annotations) : local.defaults.annotations
      description    = lookup(v, "description", local.filter.description)
      filter_entries = lookup(v, "filter_entries", [])
      ndo = {
        schema   = local.schema
        template = lookup(v, "template", "")
      }
      tenant = var.tenant
    }
  }

  filter_entries = { for i in flatten([
    for key, value in local.filters : [
      for k, v in value.filter_entries : {
        alias                 = lookup(v, "alias", local.filter.alias)
        annotation            = lookup(v, "annotation", local.filter.annotation)
        arp_flag              = lookup(v, "arp_flag", local.filter.arp_flag)
        description           = lookup(v, "description", local.filter.description)
        destination_port_from = lookup(v, "destination_port_from", local.filter.destination_port_from)
        destination_port_to   = lookup(v, "destination_port_to", local.filter.destination_port_to)
        ethertype             = lookup(v, "ethertype", local.filter.ethertype)
        filter_name           = key
        icmpv4_type           = lookup(v, "icmpv4_type", local.filter.icmpv4_type)
        icmpv6_type           = lookup(v, "icmpv6_type", local.filter.icmpv6_type)
        ip_protocol           = lookup(v, "ip_protocol", local.filter.ip_protocol)
        match_dscp            = lookup(v, "match_dscp", local.filter.match_dscp)
        match_only_fragments  = lookup(v, "match_only_fragments", local.filter.match_only_fragments)
        name                  = v.name
        ndo                   = value.ndo
        source_port_from      = lookup(v, "source_port_from", local.filter.source_port_from)
        source_port_to        = lookup(v, "source_port_to", local.filter.source_port_to)
        stateful              = lookup(v, "stateful", local.filter.stateful)
        tcp_session_rules = {
          acknowledgement = lookup(lookup(
            v, "tcp_session_rules", {}), "acknowledgement", local.filter.tcp_session_rules.acknowledgement
          )
          established = lookup(lookup(
            v, "tcp_session_rules", {}), "established", local.filter.tcp_session_rules.established
          )
          finish = lookup(lookup(v, "tcp_session_rules", {}), "finish", local.filter.tcp_session_rules.finish)
          reset  = lookup(lookup(v, "tcp_session_rules", {}), "reset", local.filter.tcp_session_rules.reset)
          synchronize = lookup(lookup(
            v, "tcp_session_rules", {}), "synchronize", local.filter.tcp_session_rules.synchronize
          )
        }
        tenant = value.tenant
      }
    ]
  ]) : "${i.filter_name}_${i.name}" => i }


  #__________________________________________________________
  #
  # L3Out Variables
  #__________________________________________________________

  #==================================
  # L3Outs
  #==================================

  #  l3outs = {
  #    for k, v in var.l3outs : k => {
  #      alias                 = v.alias != null ? v.alias : ""
  #      annotation            = v.annotation != null ? v.annotation : ""
  #      annotations           = v.annotations != null ? v.annotations : []
  #      consumer_label        = v.consumer_label != null ? v.consumer_label : ""
  #      controller_type       = v.controller_type != null ? v.controller_type : "apic"
  #      description           = v.description != null ? v.description : ""
  #      enable_bgp            = v.enable_bgp != null ? v.enable_bgp : false
  #      external_epgs         = v.external_epgs != null ? v.external_epgs : []
  #      import                = coalesce(v.route_control_enforcement[0].import, false)
  #      global_alias          = v.global_alias != null ? v.global_alias : ""
  #      l3_domain             = v.l3_domain != null ? v.l3_domain : ""
  #      pim                   = v.pim != null ? v.pim : false
  #      pimv6                 = v.pimv6 != null ? v.pimv6 : false
  #      ospf_external_profile = v.ospf_external_profile != null ? v.ospf_external_profile : []
  #      policy_source_tenant  = v.policy_source_tenant != null ? v.policy_source_tenant : local.first_tenant
  #      provider_label        = v.provider_label != null ? v.provider_label : ""
  #      route_control_for_dampening = v.route_control_for_dampening != null ? [
  #        for s in v.route_control_for_dampening : {
  #          address_family = s.address_family != null ? s.address_family : "ipv4"
  #          route_map      = s.route_map
  #        }
  #      ] : []
  #      route_profile_for_interleak       = v.route_profile_for_interleak != null ? v.route_profile_for_interleak : ""
  #      route_profiles_for_redistribution = v.route_profiles_for_redistribution != null ? v.route_profiles_for_redistribution : []
  #      target_dscp                       = v.target_dscp != null ? v.target_dscp : "unspecified"
  #      schema                            = v.schema != null ? v.schema : local.first_tenant
  #      sites                             = v.sites != null ? v.sites : []
  #      template                          = v.template != null ? v.template : local.first_tenant
  #      tenant                            = v.tenant != null ? v.tenant : local.first_tenant
  #      vrf                               = v.vrf != null ? v.vrf : "default"
  #    }
  #  }
  #
  #  l3out_route_profiles = flatten([
  #    for key, value in local.l3outs : [
  #      for k, v in value.route_profiles_for_redistribution : {
  #        annotation = value.annotation
  #        l3out      = key
  #        tenant     = value.tenant
  #        rm_l3out   = v.l3out != null ? v.l3out : ""
  #        route_map  = v.route_map
  #        source     = v.source != null ? v.source : "static"
  #      }
  #    ]
  #  ])
  #  l3out_route_profiles_for_redistribution = {
  #    for k, v in local.l3out_route_profiles_loop : "${v.l3out}_${v.route_map}_${v.source}" => v
  #  }
  #
  #  #==================================
  #  # L3Outs - External EPGs
  #  #==================================
  #
  #  external_epgs = flatten([
  #    for key, value in local.l3outs : [
  #      for k, v in value.external_epgs : {
  #        alias                  = v.alias != null ? v.alias : ""
  #        annotation             = value.annotation
  #        contract_exception_tag = v.contract_exception_tag != null ? v.contract_exception_tag : 0
  #        contracts              = v.contracts != null ? v.contracts : []
  #        controller_type        = value.controller_type
  #        description            = v.description != null ? v.description : ""
  #        epg_type               = v.epg_type != null ? v.epg_type : "standard"
  #        flood_on_encapsulation = v.flood_on_encapsulation != null ? v.flood_on_encapsulation : "disabled"
  #        l3out                  = key
  #        l3out_contract_masters = v.l3out_contract_masters != null ? [
  #          for s in v.l3out_contract_masters : {
  #            external_epg = s.external_epg
  #            l3out        = s.l3out
  #          }
  #        ] : []
  #        label_match_criteria   = v.label_match_criteria != null ? v.label_match_criteria : "AtleastOne"
  #        name                   = v.name != null ? v.name : "default"
  #        preferred_group_member = v.preferred_group_member != null ? v.preferred_group_member : false
  #        qos_class              = v.qos_class != null ? v.qos_class : "unspecified"
  #        subnets                = v.subnets != null ? v.subnets : []
  #        target_dscp            = v.target_dscp != null ? v.target_dscp : "unspecified"
  #        tenant                 = value.tenant
  #        route_control_profiles = v.route_control_profiles != null ? [
  #          for s in v.route_control_profiles : {
  #            direction = s.direction
  #            route_map = s.route_map
  #          }
  #        ] : []
  #        tenant = value.tenant
  #      }
  #    ]
  #  ])
  #  l3out_external_epgs = { for k, v in local.external_epgs_loop : "${v.l3out}_${v.epg_type}_${v.name}" => v }
  #
  #  ext_epg_contracts = flatten([
  #    for key, value in local.l3out_external_epgs : [
  #      for k, v in value.contracts : {
  #        annotation      = value.annotation
  #        contract        = v.name
  #        contract_tenant = v.tenant != null ? v.tenant : value.tenant
  #        contract_type   = v.contract_type != null ? v.contract_type : "consumer"
  #        controller_type = value.controller_type
  #        epg             = value.name
  #        l3out           = value.l3out
  #        qos_class       = v.qos_class
  #        tenant          = v.tenant != null ? v.tenant : value.tenant
  #      }
  #    ]
  #  ])
  #  l3out_ext_epg_contracts = { for k, v in local.ext_epg_contracts_loop : "${v.l3out}_${v.epg}_${v.contract_type}_${v.contract}" => v }
  #
  #  l3out_external_epg_subnets = flatten([
  #    for key, value in local.l3out_external_epgs : [
  #      for k, v in value.subnets : {
  #        aggregate_export        = coalesce(v.aggregate[0].aggregate_export, false)
  #        aggregate_import        = coalesce(v.aggregate[0].aggregate_import, false)
  #        aggregate_shared_routes = coalesce(v.aggregate[0].aggregate_shared_routes, false)
  #        annotation              = value.annotation
  #        controller_type         = value.controller_type
  #        description             = v.description != null ? v.description : ""
  #        epg_type                = value.epg_type
  #        ext_epg                 = key
  #        key2                    = k
  #        route_control_profiles = v.route_control_profiles != null ? [
  #          for s in v.route_control_profiles : {
  #            direction = s.direction
  #            route_map = s.route_map
  #          }
  #        ] : []
  #        route_summarization_policy        = v.route_summarization_policy != null ? v.route_summarization_policy : ""
  #        external_subnets_for_external_epg = coalesce(v.external_epg_classification[0].external_subnets_for_external_epg, true)
  #        shared_security_import_subnet     = coalesce(v.external_epg_classification[0].shared_security_import_subnet, false)
  #        export_route_control_subnet       = coalesce(v.route_control[0].export_route_control_subnet, false)
  #        import_route_control_subnet       = coalesce(v.route_control[0].import_route_control_subnet, false)
  #        shared_route_control_subnet       = coalesce(v.route_control[0].shared_route_control_subnet, false)
  #        subnets                           = v.subnets != null ? v.subnets : ["0.0.0.0/1", "128.0.0.0/1"]
  #      }
  #    ]
  #  ])
  #  external_epg_subnets_loop_2 = { for k, v in local.external_epg_subnets_loop_1 : "${v.ext_epg}_${v.key2}" => v }
  #  external_epg_subnets_loop_3 = flatten([
  #    for k, v in local.external_epg_subnets_loop_2 : [
  #      for s in v.subnets : {
  #        aggregate_export                  = v.aggregate_export
  #        aggregate_import                  = v.aggregate_import
  #        aggregate_shared_routes           = v.aggregate_shared_routes
  #        annotation                        = v.annotation
  #        controller_type                   = v.controller_type
  #        description                       = v.description
  #        epg_type                          = v.epg_type
  #        ext_epg                           = v.ext_epg
  #        route_control_profiles            = v.route_control_profiles
  #        route_summarization_policy        = v.route_summarization_policy
  #        export_route_control_subnet       = v.export_route_control_subnet
  #        external_subnets_for_external_epg = v.external_subnets_for_external_epg
  #        import_route_control_subnet       = v.import_route_control_subnet
  #        shared_security_import_subnet     = v.shared_security_import_subnet
  #        shared_route_control_subnet       = v.shared_route_control_subnet
  #        subnet                            = s
  #      }
  #    ]
  #  ])
  #  l3out_external_epg_subnets = { for k, v in local.external_epg_subnets_loop_3 : "${v.ext_epg}_${v.subnet}" => v }
  #
  #  #=======================================================================================
  #  # L3Outs - OSPF External Policies
  #  #=======================================================================================
  #
  #  l3out_ospf_external_policies = flatten([
  #    for key, value in local.l3outs : [
  #      for k, v in value.ospf_external_profile : {
  #        annotation                              = value.annotation
  #        l3out                                   = key
  #        ospf_area_cost                          = v.ospf_area_cost != null ? v.ospf_area_cost : 1
  #        ospf_area_id                            = v.ospf_area_id != null ? v.ospf_area_id : "0.0.0.0"
  #        ospf_area_type                          = v.ospf_area_type != null ? v.ospf_area_type : "regular"
  #        originate_summary_lsa                   = coalesce(v.ospf_area_control[0].originate_summary_lsa, true)
  #        send_redistribution_lsas_into_nssa_area = coalesce(v.ospf_area_control[0].send_redistribution_lsas_into_nssa_area, true)
  #        suppress_forwarding_address             = coalesce(v.ospf_area_control[0].suppress_forwarding_address, true)
  #        type                                    = value.type
  #      }
  #    ]
  #  ])
  #  l3out_ospf_external_policies = { for k, v in local.ospf_process_loop : v.l3out => v }
  #
  #  #=======================================================================================
  #  # L3Outs - Logical Node Profiles
  #  #=======================================================================================
  #
  #  l3out_node_profiles = {
  #    for k, v in var.l3out_logical_node_profiles : k => {
  #      alias              = v.alias != null ? v.alias : ""
  #      annotation         = v.annotation != null ? v.annotation : ""
  #      color_tag          = v.color_tag != null ? v.color_tag : "yellow-green"
  #      description        = v.description != null ? v.description : ""
  #      interface_profiles = v.interface_profiles != null ? v.interface_profiles : []
  #      l3out              = v.l3out
  #      name               = v.name
  #      nodes              = v.nodes != null ? v.nodes : []
  #      pod_id             = v.pod_id != null ? v.pod_id : 1
  #      target_dscp        = v.target_dscp != null ? v.target_dscp : "unspecified"
  #      tenant             = v.tenant != null ? v.tenant : local.first_tenant
  #    }
  #  }
  #
  #  l3out_node_profiles_nodes = flatten([
  #    for key, value in local.l3out_node_profiles : [
  #      for k, v in value.nodes : {
  #        annotation                = value.annotation
  #        node_id                   = v.node_id != null ? v.node_id : 201
  #        node_profile              = key
  #        pod_id                    = value.pod_id
  #        router_id                 = v.router_id != null ? v.router_id : "198.18.0.1"
  #        use_router_id_as_loopback = v.use_router_id_as_loopback != null ? v.use_router_id_as_loopback : true
  #      }
  #    ]
  #  ])
  #  l3out_node_profiles_nodes = { for k, v in local.nodes_loop : "${v.node_profile}_${v.node_id}" => v }
  #
  #  l3out_node_profile_static_routes = {}
  #
  #  #=======================================================================================
  #  # L3Outs - Logical Node Profiles - Logical Interface Profiles
  #  #=======================================================================================
  #
  #  l3out_interface_profiles = flatten([
  #    for key, value in local.l3out_node_profiles : [
  #      for k, v in value.interface_profiles : {
  #        annotation                  = value.annotation
  #        arp_policy                  = v.arp_policy != null ? v.arp_policy : ""
  #        auto_state                  = v.auto_state != null ? v.auto_state : "disabled"
  #        bgp_peers                   = v.bgp_peers != null ? v.bgp_peers : []
  #        color_tag                   = value.color_tag
  #        custom_qos_policy           = v.custom_qos_policy != null ? v.custom_qos_policy : ""
  #        description                 = v.description != null ? v.description : ""
  #        data_plane_policing_egress  = v.data_plane_policing_egress != null ? v.data_plane_policing_egress : ""
  #        data_plane_policing_ingress = v.data_plane_policing_ingress != null ? v.data_plane_policing_ingress : ""
  #        encap_scope                 = v.encap_scope != null ? v.encap_scope : "local"
  #        encap_vlan                  = v.encap_vlan != null ? v.encap_vlan : 1
  #        hsrp_interface_profile = v.hsrp_interface_profile != null ? [
  #          for s in v.hsrp_interface_profile : {
  #            alias       = s.alias != null ? s.alias : ""
  #            annotation  = s.annotation != null ? s.annotation : ""
  #            description = s.description != null ? s.description : ""
  #            groups = s.groups != null ? [
  #              for a in s.groups : {
  #                alias                 = a.alias != null ? a.alias : ""
  #                annotation            = a.annotation != null ? a.annotation : ""
  #                description           = a.description != null ? a.description : ""
  #                group_id              = a.group_id != null ? a.group_id : 0
  #                group_name            = a.group_name != null ? a.group_name : ""
  #                group_type            = a.group_type != null ? a.group_type : "ipv4"
  #                hsrp_group_policy     = a.hsrp_group_policy != null ? a.hsrp_group_policy : ""
  #                ip_address            = a.ip_address != null ? a.ip_address : ""
  #                ip_obtain_mode        = a.ip_obtain_mode != null ? a.ip_obtain_mode : "admin"
  #                mac_address           = a.mac_address != null ? a.mac_address : ""
  #                name                  = a.name != null ? a.name : "default"
  #                secondary_virtual_ips = a.secondary_virtual_ips != null ? a.secondary_virtual_ips : []
  #              }
  #            ] : []
  #            hsrp_interface_policy = s.hsrp_interface_policy != null ? s.hsrp_interface_policy : "default"
  #            policy_source_tenant  = s.policy_source_tenant != null ? s.policy_source_tenant : local.first_tenant
  #            version               = s.version != null ? s.version : "v1"
  #          }
  #        ] : []
  #        interface_or_policy_group = v.interface_or_policy_group != null ? v.interface_or_policy_group : "eth1/1"
  #        interface_type            = v.interface_type != null ? v.interface_type : "l3-port"
  #        ipv6_dad                  = v.ipv6_dad != null ? v.ipv6_dad : "enabled"
  #        l3out                     = value.l3out
  #        link_local_address        = v.link_local_address != null ? v.link_local_address : "::"
  #        mac_address               = v.mac_address != null ? v.mac_address : "00:22:BD:F8:19:FF"
  #        mode                      = v.mode != null ? v.mode : "regular"
  #        mtu                       = v.mtu != null ? v.mtu : "inherit" # 576 to 9216
  #        name                      = v.name != null ? v.name : "default"
  #        nd_policy                 = v.nd_policy != null ? v.nd_policy : ""
  #        netflow_monitor_policies = v.netflow_monitor_policies != null ? [
  #          for s in v.netflow_monitor_policies : {
  #            filter_type    = s.filter_type != null ? s.filter_type : "ipv4"
  #            netflow_policy = s.netflow_policy
  #          }
  #        ] : []
  #        node_profile = key
  #        nodes        = [for keys, values in value.nodes : value.nodes[keys]["node_id"]]
  #        ospf_interface_profile = v.ospf_interface_profile != null ? [
  #          for s in v.ospf_interface_profile : {
  #            description           = s.description != null ? s.description : ""
  #            authentication_type   = s.authentication_type != null ? s.authentication_type : "none"
  #            name                  = s.name != null ? s.name : "default"
  #            ospf_key              = s.ospf_key != null ? s.ospf_key : 0
  #            ospf_interface_policy = s.ospf_interface_policy != null ? s.ospf_interface_policy : "default"
  #            policy_source_tenant  = s.policy_source_tenant != null ? s.policy_source_tenant : value.tenant
  #          }
  #        ] : []
  #        pod_id                    = value.pod_id
  #        primary_preferred_address = v.primary_preferred_address != null ? v.primary_preferred_address : "198.18.1.1/24"
  #        qos_class                 = v.qos_class != null ? v.qos_class : "unspecified"
  #        secondary_addresses       = v.secondary_addresses != null ? v.secondary_addresses : []
  #        secondaries_keys          = v.secondary_addresses != null ? range(length(v.secondary_addresses)) : []
  #        svi_addresses = v.svi_addresses != null ? [
  #          for s in v.svi_addresses : {
  #            link_local_address        = s.link_local_address != null ? s.link_local_address : "::"
  #            primary_preferred_address = s.primary_preferred_address
  #            secondary_addresses       = s.secondary_addresses != null ? s.secondary_addresses : []
  #            side                      = s.side
  #          }
  #        ] : []
  #        target_dscp = value.target_dscp
  #        tenant      = value.tenant
  #      }
  #    ]
  #  ])
  #  l3out_interface_profiles = { for k, v in local.interface_profiles_loop : "${v.node_profile}_${v.name}" => v }
  #
  #  l3out_paths_svi_addressing = flatten([
  #    for key, value in local.l3out_interface_profiles : [
  #      for s in value.svi_addresses : {
  #        annotation                = value.annotation
  #        ipv6_dad                  = value.ipv6_dad
  #        link_local_address        = s.link_local_address
  #        path                      = key
  #        primary_preferred_address = s.primary_preferred_address
  #        secondary_addresses       = s.secondary_addresses
  #        secondaries_keys          = s.secondary_addresses != null ? range(length(s.secondary_addresses)) : []
  #        side                      = s.side
  #        interface_type            = value.interface_type
  #      }
  #    ] if value.interface_type == "ext-svi"
  #  ])
  #  l3out_paths_svi_addressing = { for k, v in local.svi_addressing_loop : "${v.path}_${v.side}" => v }
  #
  #  l3out_paths_secondary_ips = flatten([
  #    for k, v in local.l3out_interface_profiles : [
  #      for s in v.secondaries_keys : {
  #        annotation           = v.annotation
  #        controller_type      = v.controller_type
  #        ipv6_dad             = v.ipv6_dad != null ? v.ipv6_dad : "enabled"
  #        key1                 = "${k}-${s}"
  #        l3out_path           = k
  #        secondary_ip_address = element(v.secondary_addresses, s)
  #      }
  #    ]
  #  ])
  #  interface_secondaries = { for k, v in local.secondaries_loop_1 : "${v.key1}" => v }
  #  secondaries_loop_2 = flatten([
  #    for k, v in local.l3out_paths_svi_addressing : [
  #      for s in v.secondaries_keys : {
  #        annotation           = v.annotation
  #        ipv6_dad             = v.ipv6_dad != null ? v.ipv6_dad : "enabled"
  #        key1                 = "${k}-${s}"
  #        l3out_path           = k
  #        secondary_ip_address = element(v.secondary_addresses, s)
  #      }
  #    ]
  #  ])
  #  svi_secondaries           = { for k, v in local.secondaries_loop_2 : "${v.key1}" => v }
  #  l3out_paths_secondary_ips = merge(local.interface_secondaries, local.svi_secondaries)
  #
  #  #=======================================================================================
  #  # L3Outs - Logical Node Profiles - Logical Interface Profiles - BGP Peers
  #  #=======================================================================================
  #
  #  bgp_peer_connectivity_profiles = {
  #    for i in flatten([
  #    for key, value in local.l3out_interface_profiles : [
  #      for k, v in value.bgp_peers : {
  #        address_type_controls = {
  #            af_mcast = s.af_mcast != null ? s.af_mcast : false
  #            af_ucast = s.af_ucast != null ? s.af_ucast : true
  #          }
  #        admin_state           = v.admin_state != null ? v.admin_state : "enabled"
  #        allowed_self_as_count = v.allowed_self_as_count != null ? v.allowed_self_as_count : 3
  #        annotation            = value.annotation
  #        bgp_controls = {
  #            allow_self_as           = s.allow_self_as != null ? s.allow_self_as : false
  #            as_override             = s.as_override != null ? s.as_override : false
  #            disable_peer_as_check   = s.disable_peer_as_check != null ? s.disable_peer_as_check : false
  #            next_hop_self           = s.next_hop_self != null ? s.next_hop_self : false
  #            send_community          = s.send_community != null ? s.send_community : false
  #            send_domain_path        = s.send_domain_path != null ? s.send_domain_path : false
  #            send_extended_community = s.send_extended_community != null ? s.send_extended_community : false
  #          }
  #        bgp_peer_prefix_policy = v.bgp_peer_prefix_policy != null ? v.bgp_peer_prefix_policy : ""
  #        description            = v.description != null ? v.description : ""
  #        ebgp_multihop_ttl      = v.ebgp_multihop_ttl != null ? v.ebgp_multihop_ttl : 1
  #        local_as_number        = v.local_as_number != null ? v.local_as_number : null
  #        local_as_number_config = v.local_as_number_config != null ? v.local_as_number_config : "none"
  #        password               = v.password != null ? v.password : 0
  #        path_profile           = "${key}"
  #        peer_address           = v.peer_address != null ? v.peer_address : "**REQUIRED**"
  #        peer_asn               = v.peer_asn
  #        peer_controls = {
  #            bidirectional_forwarding_detection = s.bidirectional_forwarding_detection != null ? s.bidirectional_forwarding_detection : false
  #            disable_connected_check            = s.disable_connected_check != null ? s.disable_connected_check : false
  #          }
  #        peer_level           = v.peer_level != null ? v.peer_level : "interface"
  #        policy_source_tenant = v.policy_source_tenant != null ? v.policy_source_tenant : "common"
  #        private_as_control = {
  #            remove_all_private_as            = s.remove_all_private_as != null ? s.remove_all_private_as : false
  #            remove_private_as                = s.remove_private_as != null ? s.remove_private_as : false
  #            replace_private_as_with_local_as = s.replace_private_as_with_local_as != null ? s.replace_private_as_with_local_as : false
  #          }
  #        route_control_profiles = v.route_control_profiles != null ? [
  #          for s in v.route_control_profiles : {
  #            direction = s.direction
  #            route_map = s.route_map
  #          }
  #        ] : []
  #        weight_for_routes_from_neighbor = v.weight_for_routes_from_neighbor != null ? v.weight_for_routes_from_neighbor : 0
  #      }
  #    ]
  #  ]) : "${i.path_profile}_${i.peer_address}" => i
  #  }
  #
  #
  #  #=======================================================================================
  #  # L3Outs - Logical Node Profiles - Logical Interface Profiles - HSRP Interface Profiles
  #  #=======================================================================================
  #
  #  hsrp_interface_profile_loop = flatten([
  #    for key, value in local.l3out_interface_profiles : [
  #      for k, v in value.hsrp_interface_profile : {
  #        alias                 = v.alias
  #        annotation            = v.annotation
  #        description           = v.description
  #        groups                = v.groups
  #        hsrp_interface_policy = v.hsrp_interface_policy
  #        interface_profile     = key
  #        policy_source_tenant  = v.policy_source_tenant
  #        version               = v.version
  #      }
  #    ]
  #  ])
  #  hsrp_interface_profile = {
  #    for k, v in local.hsrp_interface_profile_loop : "${v.interface_profile}" => v
  #  }
  #
  #  hsrp_interface_profile_groups_loop = flatten([
  #    for key, value in local.hsrp_interface_profile : [
  #      for k, v in value.groups : {
  #        alias                 = v.alias != null ? v.alias : ""
  #        annotation            = v.annotation != null ? v.annotation : ""
  #        description           = v.description != null ? v.description : ""
  #        group_id              = v.group_id != null ? v.group_id : 0
  #        group_name            = v.group_name != null ? v.group_name : ""
  #        group_type            = v.group_type != null ? v.group_type : "ipv4"
  #        hsrp_group_policy     = v.hsrp_group_policy != null ? v.hsrp_group_policy : ""
  #        ip_address            = v.ip_address != null ? v.ip_address : ""
  #        ip_obtain_mode        = v.ip_obtain_mode != null ? v.ip_obtain_mode : "admin"
  #        key1                  = key
  #        mac_address           = v.mac_address != null ? v.mac_address : ""
  #        name                  = v.name != null ? v.name : "default"
  #        policy_source_tenant  = value.policy_source_tenant
  #        secondary_virtual_ips = v.secondary_virtual_ips != null ? v.secondary_virtual_ips : []
  #      }
  #    ]
  #  ])
  #  hsrp_interface_profile_groups = {
  #    for k, v in local.hsrp_interface_profile_groups_loop : "${v.key1}_${v.name}" => v
  #  }
  #
  #  hsrp_interface_profile_group_secondaries_loop = flatten([
  #    for key, value in local.hsrp_interface_profile_groups : [
  #      for s in value.secondary_virtual_ips : {
  #        key1         = "${value.key1}_${value.name}"
  #        secondary_ip = s
  #      }
  #    ]
  #  ])
  #  hsrp_interface_profile_group_secondaries = {
  #    for k, v in local.hsrp_interface_profile_group_secondaries_loop : "${v.key1}_${v.name}" => v
  #  }
  #
  #  #=======================================================================================
  #  # L3Outs - Logical Node Profiles - Logical Interface Profiles - OSPF Interface Policies
  #  #=======================================================================================
  #
  #  ospf_profiles_loop = flatten([
  #    for key, value in local.l3out_interface_profiles : [
  #      for k, v in value.ospf_interface_profile : {
  #        annotation            = value.annotation
  #        authentication_type   = v.authentication_type != null ? v.authentication_type : "none"
  #        description           = v.description != null ? v.description : ""
  #        interface_profile     = key
  #        l3out                 = value.l3out
  #        name                  = v.name != null ? v.name : "default"
  #        ospf_key              = v.ospf_key != null ? v.ospf_key : 0
  #        ospf_interface_policy = v.ospf_interface_policy != null ? v.ospf_interface_policy : "default"
  #        policy_source_tenant  = v.policy_source_tenant != null ? v.policy_source_tenant : local.first_tenant
  #        tenant                = value.tenant
  #      }
  #    ]
  #  ])
  #  l3out_ospf_interface_profiles = { for k, v in local.ospf_profiles_loop : "${v.interface_profile}_${v.name}" => v }


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
      annotation  = lookup(v, "annotation", local.bgps.annotation)
      description = lookup(v, "description", local.bgps.description)
      generate_as_set_information = lookup(
        v, "generate_as_set_information", local.bgps.generate_as_set_information
      )
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
    for v in lookup(local.policies, "route_map_match_rules", []) : v.name => {
      annotation                   = lookup(v, "annotation", local.rmsr.annotation)
      description                  = lookup(v, "description", local.rmsr.description)
      match_community_terms        = lookup(v, "match_community_terms", [])
      match_regex_community_terms  = lookup(v, "match_regex_community_terms", [])
      match_route_destination_rule = lookup(v, "match_route_destination_rule", [])
      tenant                       = var.tenant
    }
  }

  match_community_terms = { for i in flatten([
    for key, value in local.route_map_match_rules : [
      for v in value.match_community_terms : {
        description             = lookup(v, "description", local.rmmr.match_community_terms.description)
        match_community_factors = lookup(v, "match_community_factors", [])
        match_rule              = key
        name                    = v.name
        tenant                  = value.tenant
      }
    ]
  ]) : "${i.match_rule}-${i.name}" => i }

  match_community_factors = { for i in flatten([
    for key, value in local.match_community_terms : [
      for v in value.match_community_factors : {
        community   = v.community
        description = lookup(v, "description", local.rmmr.match_community_terms.match_community_factors.description)
        match_rule  = key
        name        = v.name
        scope       = lookup(v, "description", local.rmmr.match_community_terms.match_community_factors.scope)
        tenant      = value.tenant
      }
    ]
  ]) : "${i.match_rule}-${i.name}-${i.community}" => i }

  match_regex_community_terms = { for i in flatten([
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
  ]) : "${i.match_rule}-${i.community_type}" => i }

  match_route_destination_rule = { for i in flatten([
    for key, value in local.match_route_destination_rule : [
      for v in value.rules : {
        description       = lookup(v, "description", local.rmmr.match_route_destination_rule.description)
        greater_than_mask = lookup(v, "greater_than", local.rmmr.match_route_destination_rule.greater_than_mask)
        ip                = v.ip
        less_than_mask    = lookup(v, "less_than", local.rmmr.match_route_destination_rule.less_than_mask)
        match_rule        = key
        tenant            = value.tenant
      }
    ]
  ]) : "${i.match_rule}-${i.ip}" => i }


  #__________________________________________________________
  #
  # Route Map Set Rule Variables
  #__________________________________________________________

  route_map_set_rules = {
    for v in lookup(local.policies, "route_map_set_rules", []) : v.name => {
      annotation  = lookup(v, "annotation", local.rmsr.annotation)
      description = lookup(v, "description", local.rmsr.description)
      rules       = lookup(v, "rules", [])
      tenant      = var.tenant
    }
  }

  set_rule_rules = { for i in flatten([
    for key, value in local.route_map_set_rules : [
      for v in value.rules : {
        address           = lookup(v, "address", local.rmsr.rules.address)
        asns              = lookup(v, "asns", [])
        communities       = lookup(v, "communities", {})
        criteria          = lookup(v, "criteria", local.rmsr.rules.criteria)
        half_life         = lookup(v, "half_life", local.rmsr.rules.half_life)
        last_as_count     = lookup(v, "last_as_count", local.rmsr.rules.last_as_count)
        max_suprress_time = lookup(v, "max_suprress_time", local.rmsr.rules.max_suprress_time)
        metric            = lookup(v, "metric", local.rmsr.rules.metric)
        metric_type       = lookup(v, "metric_type", local.rmsr.rules.metric_type)
        preference        = lookup(v, "preference", local.rmsr.rules.preference)
        reuse_limit       = lookup(v, "reuse_limit", local.rmsr.rules.reuse_limit)
        route_tag         = lookup(v, "route_tag", local.rmsr.rules.route_tag)
        set_rule          = key
        suppress_limit    = lookup(v, "suppress_limit", local.rmsr.rules.suppress_limit)
        tenant            = var.tenant
        type              = v.type
        weight            = lookup(v, "weight", local.rmsr.rules.weight)
      }
    ]
  ]) : "${i.set_rule}-${i.type}" => i }

  set_rule_asn_rules = {
    for k, v in local.set_rule_rules : k => {
      autonomous_systems = {
        for s in range(length(v.asns)) : s => {
          asn   = element(v.asns, s)
          order = s
        } if v.criteria == "prepend"
      }
      criteria      = v.criteria
      last_as_count = v.criteria == "prepend-last-as" ? v.last_as_count : 0
      set_rule      = v.set_rule
      tenant        = v.tenant
      type          = v.type
    } if v.type == "set_as_path"
  }

  set_rule_communities = { for i in flatten([
    for key, value in local.set_rule_rules : [
      for v in value.communities : {
        community    = v.community
        description  = lookup(v, "description", local.rmsr.rules.communites.description)
        index        = k
        set_criteria = lookup(v, "set_criteria", local.rmsr.rules.communites.set_criteria)
        set_rule     = value.set_rule
        type         = value.type
        tenant       = value.tenant
      }
    ]
  ]) : "${i.set_rule}-${i.type}-${i.index}" => v }


  #__________________________________________________________
  #
  # Route Maps Rule Variables
  #__________________________________________________________

  route_maps_for_route_control = {
    for v in var.route_maps_for_route_control : v.name => {
      annotation         = lookup(v, "annotation", local.rm.annotation)
      description        = lookup(v, "description", local.rm.description)
      match_rules        = lookup(v, "match_rules", local.rm.match_rules)
      route_map_continue = lookup(v, "route_map_continue", local.rm.route_map_continue)
      tenant             = var.tenant
    }
  }

  route_maps_context_rules = { for i in flatten([
    for key, value in local.route_maps_for_route_control : [
      for v in value.match_rules : {
        action       = v.action
        annotation   = value.annotation
        context_name = v.context_name
        description  = lookup(v, "description", local.rmcr.description)
        name         = v.name
        order        = v.order
        route_map    = key
        set_rule     = lookup(v, "set_rule", local.rmcr.set_rule)
        tenant       = value.tenant
      }
    ]
  ]) : "${i.route_map}-${i.context_name}" => v }
}
