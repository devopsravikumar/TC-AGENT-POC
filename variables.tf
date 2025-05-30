variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-east4"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-east4-a"
}

variable "service_account_email" {
  description = "Service account email for the VM"
  type        = string
}
