variable "tags" {
  default = {
    terraform = "yes",
    resource  = "VM"
  }
}
variable "location" {
  default = "East US"
}

locals {
  common_name = "Azure_VM"
}

variable "prefix" {
  default = "tfvmex"
}

variable "vm_size" {
  default = "Standard_DS2_v2"
}