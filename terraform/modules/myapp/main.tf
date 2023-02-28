locals {
  app_values = {
    "deployment.name"            = var.deployment_name,
    "deployment.label"           = var.deployment_label,
    "deployment.container.name"  = var.container_name,
    "deployment.container.image" = var.image,
    "deployment.container.port"  = var.port,
    "hpa.name"                   = var.hpa_name,
    "hpa.ref"                    = var.hpa_ref,
    "service.name"               = var.service_name
    "service.port"               = var.service_port
  }
}

resource "helm_release" "app" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  chart            = "../../../helm/myapp"
  dynamic "set" {
    for_each = local.app_values
    content {
      name  = set.key
      value = set.value
      type  = "string"
    }
  }
}