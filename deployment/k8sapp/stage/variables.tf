variable "env" {
  type    = string
  default = "stage"
}

variable "cluster_name" {
  type    = string
  default = "EKS-STAGE"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "cluster_endpoint" {
  type    = string
  default = "<End Point URL of the Cluster>"
}

variable "cluster_ca_cert" {
  type    = string
  default = "<Cluster Certificate>"
}




