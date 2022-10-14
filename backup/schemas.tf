data "mso_schema" "schemas" {
  provider = ndo
  depends_on = [
    mso_schema.schemas
  ]
  for_each = local.schemas
  name     = each.key

}

resource "mso_schema" "schemas" {
  provider = ndo
  depends_on = [
    mso_tenant.tenants
  ]
  for_each = { for k, v in local.schemas : k => v if v.templates != [] }
  name     = each.key
  dynamic "template" {
    for_each = each.value.templates
    content {
      display_name = template.value.name
      name         = template.value.name
      tenant_id    = mso_tenant.tenants[template.value.tenant].id
    }
  }
}

resource "mso_schema_site" "sites" {
  provider = ndo
  depends_on = [
    mso_schema.schemas
  ]
  for_each      = local.template_sites
  schema_id     = mso_schema.schemas[each.value.schema].id
  site_id       = data.mso_site.ndo_sites[each.value.site].id
  template_name = each.value.name
}

output "schemas" {
  value = {
    schemas = var.schemas != {} ? { for v in sort(
      keys(data.mso_schema.schemas)
    ) : v => data.mso_schema.schemas[v].id } : {}
    # schema_template_sites = var.schemas != {} ? { for v in sort(
    #   keys(mso_schema_site.sites)
    # ) : v => mso_schema_site.sites[v].id } : {}
  }
}
