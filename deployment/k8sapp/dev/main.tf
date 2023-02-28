locals {
  user_values = {
    name             = "user-app-${var.env}"
    namespace        = "user"
    deployment_name  = "user-deployment"
    deployment_label = "nginx-user"
    container_name   = "nginx-user"
    image            = "nginx:1.22.1"
    port             = "80"
    service_name     = "user-service"
    service_port     = "8080"
    hpa_name         = "user-hpa"
    hpa_ref          = "user-deployment"
  }
  shift_values = {
    name             = "shift-app-${var.env}"
    namespace        = "shift"
    deployment_name  = "shift-deployment"
    deployment_label = "http-shift"
    container_name   = "http-shift"
    image            = "httpd"
    port             = "80"
    service_name     = "shift-service"
    service_port     = "8080"
    hpa_name         = "shift-hpa"
    hpa_ref          = "shift-deployment"
  }
}

module "user-app" {
  source           = "../../../terraform/modules/myapp"
  cluster_endpoint = var.cluster_endpoint
  cluster_ca_cert  = var.cluster_ca_cert
  cluster_name     = var.cluster_name
  region           = var.region
  name             = local.user_values.name
  namespace        = local.user_values.namespace
  deployment_name  = local.user_values.deployment_name
  deployment_label = local.user_values.deployment_label
  container_name   = local.user_values.container_name
  image            = local.user_values.image
  port             = local.user_values.port
  service_name     = local.user_values.service_name
  service_port     = local.user_values.service_port
  hpa_name         = local.user_values.hpa_name
  hpa_ref          = local.user_values.hpa_ref
}

module "shift-app" {
  source           = "../../../terraform/modules/myapp"
  cluster_endpoint = var.cluster_endpoint
  cluster_ca_cert  = var.cluster_ca_cert
  cluster_name     = var.cluster_name
  region           = var.region
  name             = local.shift_values.name
  namespace        = local.shift_values.namespace
  deployment_name  = local.shift_values.deployment_name
  deployment_label = local.shift_values.deployment_label
  container_name   = local.shift_values.container_name
  image            = local.shift_values.image
  port             = local.shift_values.port
  service_name     = local.shift_values.service_name
  service_port     = local.shift_values.service_port
  hpa_name         = local.shift_values.hpa_name
  hpa_ref          = local.shift_values.hpa_ref
}