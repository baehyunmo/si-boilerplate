# =============================================================================
# OpenStack Compute Provisioning — SI Boilerplate (Tier 1)
# =============================================================================
# Usage:
#   terraform init
#   terraform plan -var-file="../variables/common.tfvars"
#   terraform apply -var-file="../variables/common.tfvars"
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }

  backend "s3" {
    # Configure remote state backend per environment
    # bucket = "terraform-state"
    # key    = "infra/compute/terraform.tfstate"
    # region = "us-east-1"
  }
}

# -----------------------------------------------------------------------------
# Provider
# -----------------------------------------------------------------------------
provider "openstack" {
  auth_url    = var.auth_url
  region      = var.region
  tenant_name = var.project_name
  user_name   = var.user_name
  password    = var.password
  # Alternatively use application credentials:
  # application_credential_id     = var.app_credential_id
  # application_credential_secret = var.app_credential_secret
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "openstack_images_image_v2" "os_image" {
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "instance_flavor" {
  name = var.flavor_name
}

data "openstack_networking_network_v2" "network" {
  name = var.network_name
}

data "openstack_networking_secgroup_v2" "secgroups" {
  for_each = toset(var.security_groups)
  name     = each.value
}

# -----------------------------------------------------------------------------
# Cloud-init Template
# -----------------------------------------------------------------------------
data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.yaml")

  vars = {
    hostname     = var.instance_name
    timezone     = var.timezone
    admin_user   = var.admin_user
    ssh_pub_key  = var.ssh_pub_key
  }
}

# -----------------------------------------------------------------------------
# Compute Instance
# -----------------------------------------------------------------------------
resource "openstack_compute_instance_v2" "instance" {
  count = var.instance_count

  name            = var.instance_count > 1 ? "${var.instance_name}-${count.index + 1}" : var.instance_name
  image_id        = data.openstack_images_image_v2.os_image.id
  flavor_id       = data.openstack_compute_flavor_v2.instance_flavor.id
  key_pair        = var.key_pair
  user_data       = data.template_file.cloud_init.rendered
  config_drive    = true

  network {
    uuid = data.openstack_networking_network_v2.network.id
  }

  dynamic "security_groups" {
    for_each = var.security_groups
    content {
      name = security_groups.value
    }
  }

  metadata = merge(
    {
      managed_by  = "terraform"
      project     = var.project_tag
      environment = var.environment
    },
    var.extra_metadata
  )

  lifecycle {
    ignore_changes = [user_data]
  }
}

# -----------------------------------------------------------------------------
# Floating IP Association (optional)
# -----------------------------------------------------------------------------
resource "openstack_networking_floatingip_v2" "fip" {
  count = var.assign_floating_ip ? var.instance_count : 0
  pool  = var.floating_ip_pool
}

resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  count       = var.assign_floating_ip ? var.instance_count : 0
  floating_ip = openstack_networking_floatingip_v2.fip[count.index].address
  instance_id = openstack_compute_instance_v2.instance[count.index].id
}

# -----------------------------------------------------------------------------
# Block Storage Volume (optional)
# -----------------------------------------------------------------------------
resource "openstack_blockstorage_volume_v3" "data_volume" {
  count       = var.data_volume_size > 0 ? var.instance_count : 0
  name        = "${var.instance_name}-data-${count.index + 1}"
  size        = var.data_volume_size
  volume_type = var.data_volume_type

  metadata = {
    managed_by = "terraform"
    attached_to = openstack_compute_instance_v2.instance[count.index].name
  }
}

resource "openstack_compute_volume_attach_v2" "data_attach" {
  count       = var.data_volume_size > 0 ? var.instance_count : 0
  instance_id = openstack_compute_instance_v2.instance[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.data_volume[count.index].id
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "instance_ids" {
  description = "IDs of the created compute instances"
  value       = openstack_compute_instance_v2.instance[*].id
}

output "instance_names" {
  description = "Names of the created compute instances"
  value       = openstack_compute_instance_v2.instance[*].name
}

output "instance_private_ips" {
  description = "Private IP addresses of the instances"
  value       = openstack_compute_instance_v2.instance[*].access_ip_v4
}

output "instance_floating_ips" {
  description = "Floating (public) IP addresses, if assigned"
  value       = var.assign_floating_ip ? openstack_networking_floatingip_v2.fip[*].address : []
}

output "volume_ids" {
  description = "IDs of attached data volumes"
  value       = openstack_blockstorage_volume_v3.data_volume[*].id
}
