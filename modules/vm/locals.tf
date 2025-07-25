# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

locals {
  cloud_init = templatefile("${path.module}/templates/cloudinit-compute.tpl", {
    tenancy_id     = var.tenancy_ocid
    compartment_id = var.compartment_ocid
    oci_region     = var.region
    db_name        = var.adb_name
    db_password    = var.adb_password
  })
  
  # GPU-specific cloud-init with CUDA driver installation
  gpu_cloud_init = templatefile("${path.module}/templates/cloudinit-gpu.tpl", {
    tenancy_id     = var.tenancy_ocid
    compartment_id = var.compartment_ocid
    oci_region     = var.region
    db_name        = var.adb_name
    db_password    = var.adb_password
  })
}