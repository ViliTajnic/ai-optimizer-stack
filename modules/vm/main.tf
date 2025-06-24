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

// Compute