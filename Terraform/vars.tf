variable "location" {
  description = "Azure region"
  default     = "France central"
}

variable "environment" {
  description = "Environment name"
  default     = "demo"
}

variable "vm_size" {
  description = "Size of the VM"
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "VM admin username"
  default     = "ayoub"
}