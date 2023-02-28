variable "env" {
  type    = string
  default = "dev"
}

variable "cluster_name" {
  type    = string
  default = "EKS-DEV"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "cluster_endpoint" {
  type    = string
  default = "<End Point URL of the Cluster>"
}

variable "cluster_ca_cert" {
  type    = string
  default = "<Cluster Certificate>"
}




