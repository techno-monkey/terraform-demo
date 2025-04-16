variable "tags" {
  default = {
    terraform = "yes",
    resource  = "AKS"
  }
}
variable "location" {
  default = "East US"
}

locals {
  common_name = "Azure_K8S"
}

variable "address_space" {
  default = ["10.1.0.0/16", "10.1.0.0/24", "10.1.0.0/32"]
}

variable "aks_cluster_name" {
  default = "Azure_K8S-k8s-cluster"
}

variable "agent_count" {
  default = 2
}

variable "agent_vm_size" {
  default = "Standard_DS2_v2"
}

variable "agent_poolname" {
  default = "standardds2"
}

variable "kubernetes_version" {
  default = "1.32.0"
}

variable "dns_prefix" {
  default = "azurek8sdemo"
}

variable "acr" {
  default = "myakscontainerregpuru"
}
