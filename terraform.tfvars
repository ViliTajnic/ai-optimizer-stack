# Example terraform.tfvars for GPU AI Optimizer deployment
# Copyright (c) 2024, 2025, Oracle and/or its affiliates.

# OCI Provider Configuration
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaa..."
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaa..."
region           = "us-ashburn-1"  # Choose region with GPU availability
user_ocid        = "ocid1.user.oc1..aaaaaaaa..."
fingerprint      = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path = "~/.oci/oci_api_key.pem"

# Deployment Configuration
infrastructure = "VM"              # Use VM for GPU deployment
label_prefix   = "aiopt"           # Max 8 characters

# GPU Configuration
vm_gpu_enabled    = true            # Enable GPU instance
compute_gpu_shape = "VM.GPU.A10.1"  # GPU shape

# GPU-specific settings
gpu_driver_version     = "latest"    # NVIDIA driver version
cuda_version          = "12.4"      # CUDA toolkit version
pytorch_cuda_version  = "cu121"     # PyTorch CUDA compatibility
gpu_boot_volume_size  = 200         # GB - increased for CUDA/models
ollama_gpu_layers     = 999         # Use all GPU layers
enable_gpu_monitoring = true        # Enable GPU monitoring
enable_cuda_cache     = true        # Enable CUDA compilation cache

# AI Model Configuration
default_embedding_model = "mxbai-embed-large"
default_chat_model     = "llama3.1"

# Autonomous Database Configuration
adb_ecpu_core_count                 = 4       # Increased for better performance
adb_data_storage_size_in_gb         = 100     # Increased storage
adb_is_cpu_auto_scaling_enabled     = true
adb_is_storage_auto_scaling_enabled = true
adb_license_model                   = "LICENSE_INCLUDED"
adb_whitelist_cidrs                 = "0.0.0.0/0"  # Restrict in production

# Load Balancer Configuration
lb_min_shape = 10   # Mbps
lb_max_shape = 100  # Mbps - increased for better performance

# Network Security Configuration
client_allowed_cidrs = "0.0.0.0/0"  # Restrict to your IP in production
server_allowed_cidrs = "0.0.0.0/0"  # Restrict to your IP in production

# Optional: Kubernetes configuration (not used when infrastructure = "VM")
k8s_api_is_public              = false
k8s_node_pool_gpu_deploy       = true
k8s_gpu_node_pool_size         = 1
k8s_cpu_node_pool_size         = 2
k8s_api_endpoint_allowed_cidrs = "0.0.0.0/0"

# Performance Tuning (Advanced)
compute_os_ver = "8.10"  # Oracle Linux version