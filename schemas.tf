data "mso_schema" "schemas" {
  provider = mso
  depends_on = [
    mso_schema.schemas
  ]
  for_each = local.schemas
  name     = each.key

}

resource "mso_schema" "schemas" {
  provider = mso
  depends_on = [
    data.mso_tenant.tenants,
    mso_tenant.tenants
  ]
  for_each = { for k, v in local.schemas : k => v if v.create == true }
  name     = each.key
  dynamic "template" {
    for_each = each.value.templates
    content {
      display_name = template.value.name
      name         = template.value.name
      tenant_id    = data.mso_tenant.tenants[template.value.tenant].id
    }
  }
}

resource "mso_schema_site" "template_sites" {
  provider = mso
  depends_on = [
    mso_schema.schemas
  ]
  for_each      = local.template_sites
  schema_id     = data.mso_schema.schemas[each.value.schema].id
  site_id       = data.mso_site.sites[each.value.site].id
  template_name = each.value.template
}


