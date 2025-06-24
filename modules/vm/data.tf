# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

# CPU images data source - for non-GPU workloads
data "oci_core_images" "images" {
  compartment_id   = var.compartment_ocid
  operating_system = "Oracle Linux"
  shape            = var.compute_shape

  filter {
    name   = "display_name"
    values = ["Oracle-Linux-${var.compute_os_ver}-.*"]
    regex  = true
  }

  filter {
    name   = "state"
    values = ["AVAILABLE"]
  }

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

# GPU images data source - specifically for GPU shapes
data "oci_core_images" "gpu_images" {
  count = var.vm_gpu_enabled ? 1 : 0
  
  compartment_id   = var.compartment_ocid
  operating_system = "Oracle Linux"
  shape            = var.compute_shape

  filter {
    name   = "display_name"
    values = ["Oracle-Linux-${var.compute_os_ver}-.*"]
    regex  = true
  }

  filter {
    name   = "state"
    values = ["AVAILABLE"]
  }

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

# VCN data source
data "oci_core_vcn" "vcn" {
  vcn_id = var.vcn_id
}

# OCI Services data source
data "oci_core_services" "core_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# Get available GPU shapes in the region
data "oci_core_shapes" "available_shapes" {
  compartment_id = var.compartment_ocid

  filter {
    name   = "name"
    values = var.vm_gpu_enabled ? ["VM.GPU.*"] : ["VM.Standard.*"]
    regex  = true
  }
}

# Check GPU availability in availability domains (only when GPU is enabled)
data "oci_limits_limit_values" "gpu_limits" {
  count = var.vm_gpu_enabled ? 1 : 0
  
  compartment_id = var.compartment_ocid
  service_name   = "compute"
  scope_type     = "AD"
  
  filter {
    name   = "name"
    values = ["gpu-.*-count"]
    regex  = true
  }
}

# Get availability domain information
data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.compartment_ocid
}

# Local values for image selection logic
locals {
  # Select appropriate image based on instance type
  selected_image_id = var.vm_gpu_enabled ? (
    length(data.oci_core_images.gpu_images) > 0 && length(data.oci_core_images.gpu_images[0].images) > 0 ? 
    data.oci_core_images.gpu_images[0].images[0].id : 
    data.oci_core_images.images.images[0].id
  ) : data.oci_core_images.images.images[0].id

  # Available ADs for GPU instances
  gpu_available_ads = var.vm_gpu_enabled && length(data.oci_limits_limit_values.gpu_limits) > 0 ? [
    for limit in data.oci_limits_limit_values.gpu_limits[0].limit_values : 
    limit.availability_domain if tonumber(limit.value) > 0
  ] : []

  # Select appropriate availability domain
  selected_availability_domain = var.vm_gpu_enabled ? (
    var.gpu_availability_domain != "" ? var.gpu_availability_domain : (
      length(local.gpu_available_ads) > 0 ? local.gpu_available_ads[0] : var.availability_domains[0]
    )
  ) : var.availability_domains[0]
}