# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

// Load Balancer Backend Sets
resource "oci_load_balancer_backend_set" "client_lb_backend_set" {
  load_balancer_id = var.lb_id
  name             = format("%s-client-be", var.label_prefix)
  policy           = "LEAST_CONNECTIONS"
  health_checker {
    port     = var.streamlit_client_port
    protocol = "HTTP"
    url_path = "/_stcore/health"
  }
}

resource "oci_load_balancer_backend_set" "server_lb_backend_set" {
  load_balancer_id = var.lb_id
  name             = format("%s-server-be", var.label_prefix)
  policy           = "LEAST_CONNECTIONS"
  health_checker {
    port     = var.fastapi_server_port
    protocol = "HTTP"
    url_path = "/v1/liveness"
  }
}

// Load Balancer Listeners
resource "oci_load_balancer_listener" "client_lb_listener" {
  load_balancer_id         = var.lb_id
  name                     = format("%s-client-list", var.label_prefix)
  default_backend_set_name = oci_load_balancer_backend_set.client_lb_backend_set.name
  port                     = var.lb_client_port
  protocol                 = "HTTP"
}

resource "oci_load_balancer_listener" "server_lb_listener" {
  load_balancer_id         = var.lb_id
  name                     = format("%s-server-list", var.label_prefix)
  default_backend_set_name = oci_load_balancer_backend_set.server_lb_backend_set.name
  port                     = var.lb_server_port
  protocol                 = "HTTP"
}

// CPU Instance (when GPU is disabled)
resource "oci_core_instance" "cpu_instance" {
  count               = var.vm_gpu_enabled ? 0 : 1
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domains[0]
  display_name        = format("%s-cpu-instance", var.label_prefix)
  shape               = var.compute_shape

  dynamic "shape_config" {
    for_each = can(regex("Flex$", var.compute_shape)) ? [1] : []
    content {
      ocpus         = var.compute_cpu_ocpu
      memory_in_gbs = var.compute_cpu_ocpu * 16
    }
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.images.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id                 = var.private_subnet_id
    assign_public_ip          = false
    assign_private_dns_record = true
    nsg_ids                   = [oci_core_network_security_group.compute.id]
  }

  metadata = {
    user_data = base64encode(local.cloud_init)
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source_details.0.source_id, defined_tags]
  }
}

// GPU Instance (when GPU is enabled)
resource "oci_core_instance" "gpu_instance" {
  count               = var.vm_gpu_enabled ? 1 : 0
  compartment_id      = var.compartment_ocid
  availability_domain = local.selected_availability_domain
  display_name        = format("%s-gpu-instance", var.label_prefix)
  shape               = var.compute_shape

  # GPU shapes have fixed configurations - no shape_config block needed

  source_details {
    source_type             = "image"
    source_id               = local.selected_image_id
    boot_volume_size_in_gbs = var.gpu_boot_volume_size
  }

  create_vnic_details {
    subnet_id                 = var.gpu_subnet_id != "" ? var.gpu_subnet_id : var.private_subnet_id
    assign_public_ip          = false
    assign_private_dns_record = true
    nsg_ids                   = [oci_core_network_security_group.compute.id]
  }

  metadata = {
    user_data = base64encode(local.gpu_cloud_init)
  }

  # Add dedicated volume for models and data if needed
  provisioner "remote-exec" {
    inline = [
      "echo 'GPU instance provisioned successfully'",
      "# Wait for cloud-init to complete",
      "cloud-init status --wait || echo 'Cloud-init completed with warnings'",
      "# Verify GPU setup",
      "nvidia-smi || echo 'NVIDIA driver not yet available'",
    ]
    
    connection {
      type        = "ssh"
      user        = "opc"
      host        = self.private_ip
      private_key = file("~/.ssh/id_rsa")  # Adjust path as needed
      timeout     = "10m"
      
      # Connection through bastion or VPN would be needed since this is private
      # This is just an example - adjust for your networking setup
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source_details.0.source_id, defined_tags]
  }
}

// Load Balancer Backends - CPU Instance
resource "oci_load_balancer_backend" "client_lb_backend_cpu" {
  count            = var.vm_gpu_enabled ? 0 : 1
  load_balancer_id = var.lb_id
  backendset_name  = oci_load_balancer_backend_set.client_lb_backend_set.name
  ip_address       = oci_core_instance.cpu_instance[0].private_ip
  port             = var.streamlit_client_port
}

resource "oci_load_balancer_backend" "server_lb_backend_cpu" {
  count            = var.vm_gpu_enabled ? 0 : 1
  load_balancer_id = var.lb_id
  backendset_name  = oci_load_balancer_backend_set.server_lb_backend_set.name
  ip_address       = oci_core_instance.cpu_instance[0].private_ip
  port             = var.fastapi_server_port
}

// Load Balancer Backends - GPU Instance
resource "oci_load_balancer_backend" "client_lb_backend_gpu" {
  count            = var.vm_gpu_enabled ? 1 : 0
  load_balancer_id = var.lb_id
  backendset_name  = oci_load_balancer_backend_set.client_lb_backend_set.name
  ip_address       = oci_core_instance.gpu_instance[0].private_ip
  port             = var.streamlit_client_port
}

resource "oci_load_balancer_backend" "server_lb_backend_gpu" {
  count            = var.vm_gpu_enabled ? 1 : 0
  load_balancer_id = var.lb_id
  backendset_name  = oci_load_balancer_backend_set.server_lb_backend_set.name
  ip_address       = oci_core_instance.gpu_instance[0].private_ip
  port             = var.fastapi_server_port
}