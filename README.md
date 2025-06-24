# Oracle AI Optimizer OCI Stack with GPU Support

## Overview

This repository contains enhanced Terraform Infrastructure as Code (IaC) for deploying the Oracle AI Optimizer with GPU acceleration on Oracle Cloud Infrastructure (OCI). The deployment supports both CPU-only and GPU-accelerated configurations for optimal AI/ML performance.

## 🚀 Features

### GPU Support
- **NVIDIA A10 GPU Support**: VM.GPU.A10.1 and VM.GPU.A10.2 shapes
- **Modern NVIDIA Drivers**: Latest driver installation via DNF repositories
- **CUDA 12.4 Toolkit**: Full CUDA development environment
- **PyTorch GPU**: CUDA 12.1 compatible PyTorch installation
- **Ollama GPU Acceleration**: Configured for maximum GPU utilization

### AI Capabilities
- **Oracle Database 23ai**: Vector search and AI capabilities
- **RAG (Retrieval-Augmented Generation)**: Document-based AI responses
- **Multiple LLM Support**: Llama 3.1, CodeLlama, Mistral, and more
- **Embedding Models**: mxbai-embed-large, all-minilm, nomic-embed-text
- **Streamlit Interface**: User-friendly web interface
- **FastAPI Backend**: RESTful API for programmatic access

### Infrastructure Options
- **Virtual Machine**: Lightweight single-instance deployment
- **Kubernetes**: Scalable container-based deployment
- **Auto-scaling**: Database and compute auto-scaling capabilities
- **Load Balancing**: High-availability load balancer configuration

## 📋 Prerequisites

### Required
- **OCI Account** with appropriate permissions
- **Terraform** >= 1.5
- **OCI CLI** configured with API keys
- **GPU Quota** in target region (for GPU deployments)

### Optional
- **SSH Key Pair** for instance access
- **VPN or Bastion Host** for private subnet access

## 🔧 Installation

### 1. Clone and Prepare

```bash
git clone <your-repository>
cd ai-optimizer-terraform
```

### 2. Configure Terraform Variables

Create `terraform.tfvars`:

```hcl
# OCI Configuration
tenancy_ocid     = "ocid1.tenancy.oc1..your-tenancy-ocid"
compartment_ocid = "ocid1.compartment.oc1..your-compartment-ocid"
region           = "us-ashburn-1"
user_ocid        = "ocid1.user.oc1..your-user-ocid"
fingerprint      = "your-key-fingerprint"
private_key_path = "~/.oci/oci_api_key.pem"

# GPU Configuration
infrastructure    = "VM"
vm_gpu_enabled   = true
compute_gpu_shape = "VM.GPU.A10.1"
gpu_boot_volume_size = 200

# Database Configuration
adb_ecpu_core_count = 4
adb_data_storage_size_in_gb = 100

# Network Security (restrict in production)
client_allowed_cidrs = "0.0.0.0/0"
server_allowed_cidrs = "0.0.0.0/0"
```

### 3. Deploy Infrastructure

#### Option A: Using the Deployment Script (Recommended)

```bash
chmod +x deploy.sh
./deploy.sh
```

#### Option B: Manual Deployment

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### 4. Access Your Deployment

After deployment (20-30 minutes), access your AI Optimizer:

- **Web Interface**: `http://<load-balancer-ip>`
- **API Documentation**: `http://<load-balancer-ip>:8000/v1/docs`

## 📁 Repository Structure

```
├── main.tf                          # Main Terraform configuration
├── variables.tf                     # Variable definitions
├── output.tf                        # Output definitions
├── provider.tf                      # Provider configuration
├── locals.tf                        # Local values
├── nsgs.tf                         # Network security groups
├── schema.yaml                     # OCI Resource Manager schema
├── deploy.sh                       # Deployment script
├── terraform.tfvars.example        # Example variables file
├── modules/
│   ├── network/                    # Network module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── output.tf
│   │   └── data.tf
│   └── vm/                         # Virtual machine module
│       ├── main.tf
│       ├── variables.tf
│       ├── output.tf
│       ├── data.tf
│       ├── locals.tf
│       ├── iam.tf
│       ├── nsgs.tf
│       └── templates/
│           ├── cloudinit-compute.tpl  # CPU instance template
│           └── cloudinit-gpu.tpl      # GPU instance template
└── validation/
    └── gpu_validation_script.sh    # Post-deployment validation
```

## 🔧 Configuration Options

### GPU Configuration

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `vm_gpu_enabled` | Enable GPU instance | `true` | `true`, `false` |
| `compute_gpu_shape` | GPU instance shape | `VM.GPU.A10.1` | `VM.GPU.A10.1`, `VM.GPU.A10.2`, `VM.GPU3.1`, `VM.GPU3.2`, `VM.GPU3.4` |
| `gpu_boot_volume_size` | Boot volume size (GB) | `200` | `150-1000` |
| `cuda_version` | CUDA toolkit version | `12.4` | `12.4` |
| `pytorch_cuda_version` | PyTorch CUDA compatibility | `cu121` | `cu121`, `cu118` |
| `ollama_gpu_layers` | GPU layers for Ollama | `999` | `0-999` |

### AI Model Configuration

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `default_embedding_model` | Pre-installed embedding model | `mxbai-embed-large` | `mxbai-embed-large`, `all-minilm:l6-v2`, `nomic-embed-text` |
| `default_chat_model` | Pre-installed chat model | `llama3.1` | `llama3.1`, `llama3.1:8b`, `codellama:7b`, `mistral:7b` |

### Database Configuration

| Variable | Description | Default | Range |
|----------|-------------|---------|-------|
| `adb_ecpu_core_count` | Database CPU cores | `4` | `2-128` |
| `adb_data_storage_size_in_gb` | Database storage | `100` | `20-393216` |
| `adb_is_cpu_auto_scaling_enabled` | CPU auto-scaling | `true` | `true`, `false` |
| `adb_is_storage_auto_scaling_enabled` | Storage auto-scaling | `true` | `true`, `false` |

## 🔍 Monitoring and Validation

### Deployment Progress

Monitor deployment progress:

```bash
# Check cloud-init status
sudo cloud-init status

# Monitor installation logs
sudo tail -f /var/log/cloud-init-custom.log
sudo tail -f /var/log/nvidia-install.log
sudo tail -f /var/log/python-setup.log

# Check service status
sudo systemctl status ai-optimizer
sudo systemctl status ollama
```

### Validation Script

Use the provided validation script:

```bash
# Copy validation script to instance
scp validation/gpu_validation_script.sh opc@<instance-ip>:/tmp/

# Run validation
ssh opc@<instance-ip>
chmod +x /tmp/gpu_validation_script.sh
sudo /tmp/gpu_validation_script.sh
```

### Health Checks

Validate deployment health:

```bash
# Client interface health
curl -s http://<load-balancer-ip>/_stcore/health

# API server health  
curl -s http://<load-balancer-ip>:8000/v1/liveness

# Ollama API health
curl -s http://<load-balancer-ip>:11434/api/version
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Services Not Starting
```bash
# Check service logs
sudo journalctl -u ai-optimizer -f
sudo journalctl -u ollama -f

# Restart services
sudo systemctl restart ollama
sudo systemctl restart ai-optimizer
```

#### 2. GPU Not Detected
```bash
# Check NVIDIA driver
nvidia-smi

# Verify CUDA
nvcc --version

# Test PyTorch GPU
source /app/.venv/bin/activate
python -c "import torch; print('CUDA available:', torch.cuda.is_available())"
```

#### 3. Database Connection Issues
```bash
# Check wallet download
ls -la /app/tns_admin/

# Test database connection
sqlplus admin/<password>@<service_name