variable "resource_group_name" {
  description = "Resource group name"
  default     = "rg-loadbalancer-demo"
}

variable "location" {
  description = "Azure region"
  default     = "East US"
}

variable "admin_username" {
  description = "Admin username for VMs"
  default     = "vikas"
}

variable "admin_password" {
  description = "Admin password for VMs"
  default     = "P@ssword1234!"
  sensitive   = true
}
