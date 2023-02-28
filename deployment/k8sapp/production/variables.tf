variable "env" {
  type    = string
  default = "prod"
}

variable "cluster_name" {
  type    = string
  default = "EKS-PROD"
}

variable "region" {
  type    = string
  default = "us-west-1"
}

variable "cluster_endpoint" {
  type    = string
  default = "<End Point URL of the Cluster>"
}

variable "cluster_ca_cert" {
  type    = string
  default = "<Cluster Certificate>"
}




