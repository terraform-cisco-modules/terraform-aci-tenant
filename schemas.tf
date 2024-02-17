data "mso_schema" "map" {
  provider   = mso
  depends_on = [mso_schema.map]
  for_each   = local.schemas
  name       = each.key
}

resource "mso_schema" "map" {
  provider   = mso
  depends_on = [mso_tenant.map]
  for_each   = { for k, v in local.schemas : k => v if v.create == true }
  name       = each.key
  dynamic "template" {
    for_each = each.value.templates
    content {
      display_name = template.value.name
      name         = template.value.name
      tenant_id    = data.mso_tenant.map[template.value.tenant].id
    }
  }
}

resource "mso_schema_site" "map" {
  provider = mso
  depends_on = [
    data.mso_site.map,
    mso_schema.map
  ]
  for_each      = { for k, v in local.template_sites : k => v if v.create == true }
  schema_id     = data.mso_schema.map[each.value.schema].id
  site_id       = data.mso_site.map[each.value.site].id
  template_name = each.value.template
  lifecycle { ignore_changes = [schema_id, site_id] }
}


#resource "mso_schema_template_deploy_ndo" "name" {
#  depends_on = [
#    mso_schema.map,
#    mso_schema_site.map,
#    mso_schema_site_anp_epg_bulk_staticport.static_port,
#    mso_schema_site_anp_epg_domain.map,
#    mso_schema_site_bd.map,
#    mso_schema_site_bd_l3out.map,
#    mso_schema_site_vrf.map,
#    mso_schema_template_anp.map,
#    mso_schema_template_anp_epg.map,
#    mso_schema_template_bd.map,
#    mso_schema_template_bd_subnet.map,
#    mso_schema_template_contract.map,
#    mso_schema_template_filter_entry.map,
#    mso_schema_template_l3out.map,
#    mso_tenant.map
#  ]
#  for_each      = { for k, v in local.template_sites : k => v }
#  schema_id     = data.mso_schema.map[each.value.schema].id
#  template_name = each.value.template
#  lifecycle {
#    ignore_changes = [schema_id]
#  }
#}