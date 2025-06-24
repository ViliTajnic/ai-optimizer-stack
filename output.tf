# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

output "client_url" {
  description = "URL for Client Access"
  value       = format("http://%s", oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address)
}

output "server_url" {
  description = "URL for Server API Access"
  value       = format("http://%s:8000/v1/docs", oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address)
}

output "load_balancer_ip" {
  description = "Load Balancer Public IP Address"
  value       = oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address
}

output "client_repository" {
  description = "Path to push Client Image"
  value       = var.infrastructure == "Kubernetes" ? module.kubernetes[0].client_repository : "N/A"
}

output "server_repository" {
  description = "Path to push Server Image"
  value       = var.infrastructure == "Kubernetes" ? module.kubernetes[0].server_repository : "N/A"
}

output "kubeconfig_cmd" {
  description = "Command to generate kubeconfig file"
  value       = var.infrastructure == "Kubernetes" ? module.kubernetes[0].kubeconfig_cmd : "N/A"
}

output "k8s_manifest" {
  description = "Kubernetes Manifest"
  value       = var.infrastructure == "Kubernetes" ? module.kubernetes[0].k8s_manifest : "N/A"
}

output "helm_values" {
  description = "Helm Values"
  value       = var.infrastructure == "Kubernetes" ? module.kubernetes[0].helm_values : "N/A"
}

output "gpu_instance_details" {
  description = "GPU instance details (if enabled)"
  value       = var.infrastructure == "VM" && var.vm_gpu_enabled && length(module.vm) > 0 ? module.vm[0].instance_details : null
}

output "instance_details" {
  description = "Compute instance details"
  value       = var.infrastructure == "VM" && length(module.vm) > 0 ? module.vm[0].instance_details : null
}

output "database_connection_info" {
  description = "Database connection information"
  value = {
    db_name     = local.adb_name
    db_service  = format("%s_TP", local.adb_name)
    db_username = "ADMIN"
    connection_string = format("(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=%s))(connect_data=(service_name=%s))(security=(ssl_server_cert_dn=\"%s\")))",
      oci_database_autonomous_database.default_adb.connection_strings[0].profiles[0].host_format,
      oci_database_autonomous_database.default_adb.connection_strings[0].profiles[0].service_name,
      "CN=adwc.eucom-central-1.oraclecloud.com,OU=Oracle BMCS FRANKFURT,O=Oracle Corporation,L=Redwood City,ST=California,C=US"
    )
  }
  sensitive = false
}

output "deployment_info" {
  description = "Deployment configuration summary"
  value = {
    infrastructure_type = var.infrastructure
    gpu_enabled        = var.vm_gpu_enabled
    gpu_shape          = var.vm_gpu_enabled ? var.compute_gpu_shape : "N/A"
    cpu_shape          = !var.vm_gpu_enabled ? var.compute_cpu_shape : "N/A"
    region             = var.region
    compartment_id     = local.compartment_ocid
    label_prefix       = local.label_prefix
    cuda_version       = var.cuda_version
    pytorch_version    = var.pytorch_cuda_version
    boot_volume_size   = var.vm_gpu_enabled ? var.gpu_boot_volume_size : 50
  }
}

output "monitoring_urls" {
  description = "URLs for monitoring and validation"
  value = var.infrastructure == "VM" ? {
    streamlit_health   = format("http://%s/_stcore/health", oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address)
    fastapi_health     = format("http://%s:8000/v1/liveness", oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address)
    ollama_api         = format("http://%s:11434/api/version", oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address)
  } : {}
}

output "ssh_connection_info" {
  description = "SSH connection information (for troubleshooting)"
  value = var.infrastructure == "VM" && length(module.vm) > 0 ? {
    instance_private_ip = module.vm[0].instance_details.private_ip
    ssh_command        = format("ssh -i ~/.ssh/id_rsa opc@%s", module.vm[0].instance_details.private_ip)
    note              = "Instance is in private subnet - requires bastion host or VPN connection"
  } : null
}

output "validation_commands" {
  description = "Commands to validate the deployment"
  value = var.infrastructure == "VM" ? [
    "curl -s http://${oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address}/_stcore/health",
    "curl -s http://${oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address}:8000/v1/liveness", 
    "curl -s http://${oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address}:11434/api/version"
  ] : []
}