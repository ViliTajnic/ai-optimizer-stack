# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

output "instance_details" {
  description = "Details of the created compute instance"
  value = var.vm_gpu_enabled ? (
    length(oci_core_instance.gpu_instance) > 0 ? {
      id                = oci_core_instance.gpu_instance[0].id
      private_ip        = oci_core_instance.gpu_instance[0].private_ip
      public_ip         = oci_core_instance.gpu_instance[0].public_ip
      shape             = oci_core_instance.gpu_instance[0].shape
      state             = oci_core_instance.gpu_instance[0].state
      type              = "GPU"
      availability_domain = oci_core_instance.gpu_instance[0].availability_domain
      boot_volume_size  = var.gpu_boot_volume_size
      image_id          = local.selected_image_id
      cuda_version      = var.cuda_version
      pytorch_version   = var.pytorch_cuda_version
    } : {}
  ) : (
    length(oci_core_instance.cpu_instance) > 0 ? {
      id                = oci_core_instance.cpu_instance[0].id
      private_ip        = oci_core_instance.cpu_instance[0].private_ip
      public_ip         = oci_core_instance.cpu_instance[0].public_ip
      shape             = oci_core_instance.cpu_instance[0].shape
      state             = oci_core_instance.cpu_instance[0].state
      type              = "CPU"
      availability_domain = oci_core_instance.cpu_instance[0].availability_domain
      boot_volume_size  = 50
      image_id          = local.selected_image_id
      cuda_version      = "N/A"
      pytorch_version   = "CPU"
    } : {}
  )
}

output "gpu_instance_public_ip" {
  description = "Public IP of GPU instance (if enabled and has public IP)"
  value       = var.vm_gpu_enabled && length(oci_core_instance.gpu_instance) > 0 ? oci_core_instance.gpu_instance[0].public_ip : null
}

output "load_balancer_backends" {
  description = "Load balancer backend configuration"
  value = {
    client_backend = var.vm_gpu_enabled ? (
      length(oci_load_balancer_backend.client_lb_backend_gpu) > 0 ? {
        ip_address = oci_load_balancer_backend.client_lb_backend_gpu[0].ip_address
        port       = oci_load_balancer_backend.client_lb_backend_gpu[0].port
      } : {}
    ) : (
      length(oci_load_balancer_backend.client_lb_backend_cpu) > 0 ? {
        ip_address = oci_load_balancer_backend.client_lb_backend_cpu[0].ip_address
        port       = oci_load_balancer_backend.client_lb_backend_cpu[0].port
      } : {}
    )
    server_backend = var.vm_gpu_enabled ? (
      length(oci_load_balancer_backend.server_lb_backend_gpu) > 0 ? {
        ip_address = oci_load_balancer_backend.server_lb_backend_gpu[0].ip_address
        port       = oci_load_balancer_backend.server_lb_backend_gpu[0].port
      } : {}
    ) : (
      length(oci_load_balancer_backend.server_lb_backend_cpu) > 0 ? {
        ip_address = oci_load_balancer_backend.server_lb_backend_cpu[0].ip_address
        port       = oci_load_balancer_backend.server_lb_backend_cpu[0].port
      } : {}
    )
  }
}

output "service_endpoints" {
  description = "Internal service endpoints"
  value = var.vm_gpu_enabled ? (
    length(oci_core_instance.gpu_instance) > 0 ? {
      streamlit_internal = format("http://%s:%d", oci_core_instance.gpu_instance[0].private_ip, var.streamlit_client_port)
      fastapi_internal   = format("http://%s:%d", oci_core_instance.gpu_instance[0].private_ip, var.fastapi_server_port)
      ollama_internal    = format("http://%s:11434", oci_core_instance.gpu_instance[0].private_ip)
    } : {}
  ) : (
    length(oci_core_instance.cpu_instance) > 0 ? {
      streamlit_internal = format("http://%s:%d", oci_core_instance.cpu_instance[0].private_ip, var.streamlit_client_port)
      fastapi_internal   = format("http://%s:%d", oci_core_instance.cpu_instance[0].private_ip, var.fastapi_server_port)
      ollama_internal    = format("http://%s:11434", oci_core_instance.cpu_instance[0].private_ip)
    } : {}
  )
}

output "gpu_configuration" {
  description = "GPU-specific configuration details"
  value = var.vm_gpu_enabled ? {
    gpu_shape           = var.compute_shape
    cuda_version        = var.cuda_version
    pytorch_cuda_version = var.pytorch_cuda_version
    driver_version      = var.gpu_driver_version
    ollama_gpu_layers   = var.ollama_gpu_layers
    gpu_monitoring      = var.enable_gpu_monitoring
    cuda_cache_enabled  = var.enable_cuda_cache
    boot_volume_size    = var.gpu_boot_volume_size
    embedding_model     = var.default_embedding_model
    chat_model          = var.default_chat_model
  } : {}
}

output "troubleshooting_info" {
  description = "Information for troubleshooting deployment issues"
  value = {
    log_files = [
      "/var/log/cloud-init-custom.log",
      "/var/log/nvidia-install.log", 
      "/var/log/environment-setup.log",
      "/var/log/ollama-install.log",
      "/var/log/python-setup.log",
      "/var/log/database-setup.log",
      "/var/log/models-install.log"
    ]
    service_commands = [
      "sudo systemctl status ai-optimizer",
      "sudo systemctl status ollama",
      "sudo systemctl status nvidia-persistenced",
      "sudo journalctl -u ai-optimizer -f",
      "sudo journalctl -u ollama -f"
    ]
    validation_commands = var.vm_gpu_enabled ? [
      "nvidia-smi",
      "nvcc --version", 
      "source /app/.venv/bin/activate && python -c 'import torch; print(torch.cuda.is_available())'",
      "curl -s http://127.0.0.1:11434/api/version",
      "curl -s http://127.0.0.1:8501/_stcore/health"
    ] : [
      "source /app/.venv/bin/activate && python -c 'import torch; print(torch.__version__)'",
      "curl -s http://127.0.0.1:11434/api/version",
      "curl -s http://127.0.0.1:8501/_stcore/health"
    ]
    ssh_note = "Instance is in private subnet. Use bastion host or VPN for SSH access."
  }
}