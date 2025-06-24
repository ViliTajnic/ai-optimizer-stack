# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

variable "tenancy_ocid" {
  type = string
}

variable "compartment_ocid" {
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

variable "lb_client_port" {
  type = number
}

variable "lb_server_port" {
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

variable "compute_os_ver" {
  type = string
}

variable "compute_cpu_ocpu" {
  type = number
}

variable "compute_shape" {
  description = "The compute shape to use (CPU or GPU based on selection)"
  type        = string
}

variable "vm_gpu_enabled" {
  description = "Enable GPU instance instead of CPU instance"
  type        = bool
  default     = false
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

variable "availability_domain" {
  description = "Availability Domain for the VM"
  type        = string
}

variable "subnet_id" {
  description = "Subnet OCID for the VM"
  type        = string
}

variable "gpu_availability_domain" {
  description = "Specific availability domain for GPU instances"
  type        = string
  default     = ""
}

variable "gpu_subnet_id" {
  description = "Specific subnet for GPU instances"
  type        = string
  default     = ""
}