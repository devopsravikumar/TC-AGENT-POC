variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "GCP zone"
}

variable "instance_name" {
  type        = string
  description = "Name of the compute instance"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the VM"
}

variable "image" {
  type        = string
  description = "Custom or public Windows image"
}

variable "network" {
  type        = string
  description = "VPC network name"
}

variable "subnet" {
  type        = string
  description = "Subnetwork name"
}

variable "service_account" {
  type        = string
  description = "Service account email to attach to the VM"
}

variable "tags" {
  type        = list(string)
  description = "Network tags"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for RDP access"
}
