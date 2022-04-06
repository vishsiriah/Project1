variable "azure_provider_id" {
	description = "Providers subscription id, client id, client secret & tenant id"
	default = {
		sub_id 	= "05ea1b17-c7ce-4c8c-8075-789ae0384a3d"
  		cli_id	= "d642eebe-4a15-4633-b6b2-6930f72e307b"
  		cli_sec = "Ml-KnyiW1RdP4dNHSJQOx66-1.AYF1Kc~Z"
  		ten_id  = "09a967ba-ab54-44a2-9cb2-e0305068fbf9"
	}
}

variable "infra_deployment_location" {
	description = "Azure infrastructure deployment location"
	default = "Australia East"
}

variable "az_rg" {
  description = "Azure deployment resource group"
  default     = "Udacity-rg-vspg-aus"
}

variable "az_packer_image" {
	description = "This is virtual machine image created in packer"
	default = "Udactiy_project1_VS_image"
}

variable "res_tag" {
	description = "This is default tag assigned to resources"
	default = "Production"
}

variable "counter" {
	description = "Setting the counter as 2 only. In only 2 VM can be created with the current sbscription"
	default = 2
}
