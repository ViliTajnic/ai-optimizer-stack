# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

# ---------------------------------------------
# Load Balancer Backend Sets
# ---------------------------------------------
resource "oci_load_balancer_backend_set" "cli_lb_bset" {
  load_balancer_id = var.lb_id
  name             = format("%s-cli-lb-set", var.label_prefix)
  policy           = "LEAST_CONNECTIONS"
  health_checker {
    port     = var.streamlit_client_port
    protocol = "HTTP"
    url_path = "/_stcore/health"
  }
}

resource "oci_load_balancer_backend_set" "srv_lb_bset" {
  load_balancer_id = var.lb_id
  name             = format("%s-srv-lb-set", var.label_prefix)
  policy           = "LEAST_CONNECTIONS"
  health_checker {
    port     = var.fastapi_server_port
    protocol = "HTTP"
    url_path = "/v1/liveness"
  }
}

# ---------------------------------------------
# Load Balancer Backends (Only for CPU Instances)
# ---------------------------------------------
resource "oci_load_balancer_backend" "cli_lb_backend" {
  count             = var.vm_gpu_enabled ? 0 : 1
  load_balancer_id  = var.lb_id
  backendset_name   = oci_load_balancer_backend_set.cli_lb_bset.name
  ip_address        = oci_core_instance.instance[count.index].private_ip
  port              = var.streamlit_client_port
}

resource "oci_load_balancer_backend" "srv_lb_backend" {
  count             = var.vm_gpu_enabled ? 0 : 1
  load_balancer_id  = var.lb_id
  backendset_name   = oci_load_balancer_backend_set.srv_lb_bset.name
  ip_address        = oci_core_instance.instance[count.index].private_ip
  port              = var.fastapi_server_port
}

# ---------------------------------------------
# Compute Instance (CPU)
# ---------------------------------------------
resource "oci_core_instance" "instance" {
  count               = var.vm_gpu_enabled ? 0 : 1
  compartment_id      = var.compartment_id
  display_name        = format("%s-compute", var.label_prefix)
  availability_domain = var.availability_domains[0]
  shape               = var.compute_cpu_shape
  shape_config {
    memory_in_gbs = var.compute_cpu_ocpu * 16
    ocpus         = var.compute_cpu_ocpu
  }
  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.images.images[0].id
    boot_volume_size_in_gbs = 50
  }
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false
    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }
  create_vnic_details {
    subnet_id        = var.private_subnet_id
    assign_public_ip = false
    nsg_ids          = [oci_core_network_security_group.compute.id]
  }
  metadata = {
    user_data = base64encode(local.cloud_init)
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source_details.0.source_id, defined_tags]
  }
}

# ---------------------------------------------
# Compute Instance (GPU)
# ---------------------------------------------
resource "oci_core_instance" "gpuinst" {
  count               = var.vm_gpu_enabled ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  shape               = var.compute_gpu_shape

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
  }

  metadata = {
    user_data = base64encode(<<-EOT
      #!/bin/bash
      yum -y install kernel-devel-$(uname -r) gcc make
      cd /tmp
      curl -O https://us.download.nvidia.com/tesla/525.60.11/NVIDIA-Linux-x86_64-525.60.11.run
      chmod +x NVIDIA-Linux-x86_64-525.60.11.run
      ./NVIDIA-Linux-x86_64-525.60.11.run -s
    EOT
    )
  }

  source_details {
    source_type = "image"
  }

  display_name = "gpu-instance-ai-optimizer"
}