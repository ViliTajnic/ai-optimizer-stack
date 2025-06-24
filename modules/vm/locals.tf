# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

locals {
  # CPU cloud-init template
  cloud_init = templatefile("${path.module}/templates/cloudinit-compute.tpl", {
    tenancy_id     = var.tenancy_ocid
    compartment_id = var.compartment_ocid
    oci_region     = var.region
    db_name        = var.adb_name
    db_password    = var.adb_password
  })
  
  # GPU cloud-init template with enhanced configuration
  gpu_cloud_init = templatefile("${path.module}/templates/cloudinit-gpu.tpl", {
    tenancy_id             = var.tenancy_ocid
    compartment_id         = var.compartment_ocid
    oci_region             = var.region
    db_name                = var.adb_name
    db_password            = var.adb_password
    cuda_version           = var.cuda_version
    pytorch_cuda_version   = var.pytorch_cuda_version
    gpu_driver_version     = var.gpu_driver_version
    ollama_gpu_layers      = var.ollama_gpu_layers
    enable_gpu_monitoring  = var.enable_gpu_monitoring
    default_embedding_model = var.default_embedding_model
    default_chat_model     = var.default_chat_model
    enable_cuda_cache      = var.enable_cuda_cache
  })
}