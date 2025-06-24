# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

output "instance_details" {
  description = "Details of the created compute instance"
  value = var.vm_gpu_enabled ? (
    length(oci_core_instance.gpu_instance) > 0 ? {
      id         = oci_core_instance.gpu_instance[0].id
      private_ip = oci_core_instance.gpu_instance[0].private_ip
      shape      = oci_core_instance.gpu_instance[0].shape
      state      = oci_core_instance.gpu_instance[0].state
      type       = "GPU"
    } : {}
  ) : (
    length(oci_core_instance.cpu_instance) > 0 ? {
      id         = oci_core_instance.cpu_instance[0].id
      private_ip = oci_core_instance.cpu_instance[0].private_ip
      shape      = oci_core_instance.cpu_instance[0].shape
      state      = oci_core_instance.cpu_instance[0].state
      type       = "CPU"
    } : {}
  )
}

output "gpu_instance_public_ip" {
  description = "Public IP of GPU instance (if enabled and has public IP)"
  value       = var.vm_gpu_enabled && length(oci_core_instance.gpu_instance) > 0 ? oci_core_instance.gpu_instance[0].public_ip : null
}