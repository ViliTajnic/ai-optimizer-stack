# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

variable "tenancy_id" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "region" {
  type = string
}

variable "label_prefix" {
  type = string
}

variable "lb_id" {
  type = string
}

variable "availability_domains" {
  type = list(any)
}
variable "vcn_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}
variable "compute_os_ver" {
  type = string
}

variable "compute_cpu_shape" {
  type = string
}

variable "compute_cpu_ocpu" {
  type = number
}

variable "adb_name" {
  type = string
}

variable "adb_password" {
  type = string
}

variable "streamlit_client_port" {
  type = number
}

variable "fastapi_server_port" {
  type = number
}

variable "lb_client_port" {
  type = number
}

variable "lb_server_port" {
  type = number
}

variable "use_gpu" {
  description = "Enable additional GPU instance for AI workloads"
  type        = bool
  default     = false
}

variable "vm_gpu_enabled" {
  description = "This will enable VM with GPU"
  type        = bool
  default     = false
}
// additiona variable for VM GPU instance
variable "availability_domain" {
  description = "Availability Domain for the VM"
  type        = string
}

variable "subnet_id" {
  description = "Subnet OCID for the VM"
  type        = string
}

variable "compute_gpu_shape" {
  description = "The shape of the GPU instance"
  type        = string
}

variable "tenancy_ocid" {
  description = "The OCID of the tenancy."
  type        = string
}

/*
variable "ssh_public_key" {
  description = "SSH Public Key for accessing the VM"
  type        = string
}
*/