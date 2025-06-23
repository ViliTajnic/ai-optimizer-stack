# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

# ---------------------------------------------
# Dynamic Group for Compute Instances
# ---------------------------------------------
resource "oci_identity_dynamic_group" "compute_dyn_grp" {
  compartment_id = var.tenancy_id
  name           = format("%s-compute-dyn-grp", var.label_prefix)
  description    = "Dynamic group for compute instances in this stack"

  matching_rule = join(" OR ", compact(concat(
    var.vm_gpu_enabled ? [
      for i in range(length(oci_core_instance.gpuinst)) :
      format("instance.id='${oci_core_instance.gpuinst["%s"].id}'", i)
    ] : [],
    var.vm_gpu_enabled ? [] : [
      for i in range(length(oci_core_instance.instance)) :
      format("instance.id='${oci_core_instance.instance["%s"].id}'", i)
    ]
  )))
}

# ---------------------------------------------
# Policies for Dynamic Group
# ---------------------------------------------
resource "oci_identity_policy" "compute_dyn_grp_policy" {
  compartment_id = var.compartment_id
  name           = format("%s-dg-policy", var.label_prefix)
  description    = "Policy for dynamic group access"
  statements = [
    format(
      "Allow dynamic-group %s-compute-dyn-grp to manage all-resources in compartment id %s",
      var.label_prefix,
      var.compartment_id
    )
  ]
}