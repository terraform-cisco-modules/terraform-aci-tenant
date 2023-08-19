/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvIPSLAMonitoringPo"
 - Distinguished Name: "uni/tn-{tenant}/ipslaMonitoringPol-{name}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > IP SLA >  IP SLA Monitoring Policies > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_ip_sla_monitoring_policy" "map" {
  depends_on = [aci_tenant.map]
  for_each   = local.ip_sla_monitoring
  #description = each.value.description
  name         = each.key
  http_uri     = each.value.http_uri
  http_version = "HTTP/${each.value.http_version}" # 1.0, 1.1, default 1.0
  #req_data_size         = each.value.request_data_size      # 0-17512, default 28 
  sla_detect_multiplier = each.value.detect_multiplier # 1-100, default 3
  sla_frequency         = each.value.sla_frequency     # 1-300, default is 60
  sla_port              = length(regexall("tcp", each.value.sla_type)) > 0 ? each.value.sla_port : null
  sla_type              = each.value.sla_type # http, icmp, l2ping, tcp, default is icmp
  tenant_dn             = "uni/tn-${each.value.tenant}"
  threshold             = each.value.threshold           # 0-604800000, default is 900
  timeout               = each.value.operation_timeout   # 0-604800000, default is 900
  traffic_class_value   = each.value.traffic_class_value # 0-255, IPv6 (QoS) default is 0
  type_of_service       = each.value.type_of_service     # 0-255 IPv4 (QoS) default 0
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvTrackList"
 - Distinguished Name: "uni/tn-{tenant}/tracklist-{vrf}_{next_hop_ip}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > IP SLA >  Track Lists > {name}
_______________________________________________________________________________________________________________________
*/

resource "aci_rest_managed" "track_lists" {
  for_each   = { for k, v in local.track_lists : k => v }
  dn         = "uni/tn-${each.value.tenant}/tracklist-${each.value.name}"
  class_name = "fvTrackList"
  content = {
    percentageDown = each.value.percentage_down
    percentageUp   = each.value.percentage_up
    type           = each.value.type
    weightDown     = each.value.weight_down
    weightUp       = each.value.weight_up
  }
  child {
    class_name = "fvRsOtmListMember"
    rn         = "rsotmListMember-[uni/tn-${each.value.tenant}/trackmember-${each.value.name}]"
    content = {
      tDn = "uni/tn-${each.value.tenant}/trackmember-${each.value.name}"
    }
  }
}


/*_____________________________________________________________________________________________________________________

API Information:
 - Class: "fvTrackMember"
 - Distinguished Name: "uni/tn-{tenant}/trackmember-{vrf}_{next_hop_ip}"
GUI Location:
 - Tenants > {tenant} > Networking > Policies > Protocol > IP SLA >  Track Member > {name}
_______________________________________________________________________________________________________________________
*/
resource "aci_rest_managed" "track_member" {
  depends_on = [aci_l3_outside.map]
  for_each   = { for k, v in local.track_members : k => v }
  dn         = "uni/tn-${each.value.tenant}/trackmember-${each.value.vrf}_${each.value.next_hop_ip}"
  class_name = "fvTrackMember"
  content = {
    dstIpAddr = each.value.next_hop_ip
    scopeDn   = "uni/tn-${each.value.tenant}/out-${each.value.l3out}"
  }
  child {
    class_name = "fvRsIpslaMonPol"
    rn         = "rsIpslaMonPol"
    content = {
      tDn = "uni/tn-${each.value.tenant}/ipslaMonitoringPol-${each.value.ip_sla_monitoring_policy}"
    }
  }
  child {
    class_name = "fvRtOtmListMember"
    rn         = "rtotmListMember-[uni/tn-${each.value.tenant}/tracklist-${each.value.vrf}_${each.value.next_hop_ip}"
    content = {
      tDn = "uni/tn-${each.value.tenant}/tracklist-${each.value.vrf}_${each.value.next_hop_ip}"
    }
  }
  dynamic "child" {
    for_each = each.value.track_members
    content {
      class_name = "fvRtNHTrackMember"
      rn         = "rtipNHTrackMember-[${each.value.node_profile}/rsnodeL3OutAtt-[topology/pod-${each.value.pod_id}/node-${child.value.node_id}]/rt-[${each.value.prefix}]/nh-[${each.value.next_hop_ip}]] "
      content = {
        tDn = "${each.value.node_profile}/rsnodeL3OutAtt-[topology/pod-${each.value.pod_id}/node-${child.value.node_id}]/rt-[${each.value.prefix}]/nh-[${each.value.next_hop_ip}]"
      }
    }
  }
}
