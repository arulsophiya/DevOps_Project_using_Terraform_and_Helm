terraform {
  required_providers {
    aws        = "3.63.0"
    kubernetes = ">=2.12"
    helm       = "2.9.0"
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_cert)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = ["eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--region", var.region]
      command = "aws"
    }
  }
}
