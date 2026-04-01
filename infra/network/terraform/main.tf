# =============================================================================
# OpenStack Network Provisioning — SI Boilerplate (Tier 1)
# =============================================================================
# Creates a complete network topology: network, subnet, router, security
# groups, and floating IPs for an SI project environment.
#
# Usage:
#   terraform init
#   terraform plan -var-file="variables.tfvars"
#   terraform apply -var-file="variables.tfvars"
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
    # key    = "infra/network/terraform.tfstate"
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
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
resource "openstack_networking_network_v2" "main" {
  name           = "${var.project_prefix}-network"
  admin_state_up = true
  description    = "Primary network for ${var.project_prefix}"

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
    "environment=${var.environment}",
  ]
}

# -----------------------------------------------------------------------------
# Subnet
# -----------------------------------------------------------------------------
resource "openstack_networking_subnet_v2" "main" {
  name            = "${var.project_prefix}-subnet"
  network_id      = openstack_networking_network_v2.main.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
  gateway_ip      = var.gateway_ip

  allocation_pool {
    start = var.allocation_pool_start
    end   = var.allocation_pool_end
  }

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
  ]
}

# -----------------------------------------------------------------------------
# Router (connects internal network to external/public network)
# -----------------------------------------------------------------------------
resource "openstack_networking_router_v2" "main" {
  name                = "${var.project_prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
  description         = "Gateway router for ${var.project_prefix}"

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
  ]
}

resource "openstack_networking_router_interface_v2" "main" {
  router_id = openstack_networking_router_v2.main.id
  subnet_id = openstack_networking_subnet_v2.main.id
}

# =============================================================================
# Security Groups
# =============================================================================

# -----------------------------------------------------------------------------
# Base Security Group (applied to all instances)
# -----------------------------------------------------------------------------
resource "openstack_networking_secgroup_v2" "base" {
  name        = "${var.project_prefix}-base"
  description = "Base security group: ICMP + outbound"

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
  ]
}

# Allow all outbound traffic
resource "openstack_networking_secgroup_rule_v2" "base_egress_v4" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.base.id
}

# Allow ICMP (ping) from internal subnet
resource "openstack_networking_secgroup_rule_v2" "base_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.base.id
}

# -----------------------------------------------------------------------------
# SSH Security Group
# -----------------------------------------------------------------------------
resource "openstack_networking_secgroup_v2" "ssh" {
  name        = "${var.project_prefix}-ssh"
  description = "SSH access"

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
  ]
}

resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  for_each = toset(var.ssh_allowed_cidrs)

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = each.value
  security_group_id = openstack_networking_secgroup_v2.ssh.id
}

# -----------------------------------------------------------------------------
# Web (HTTP/HTTPS) Security Group
# -----------------------------------------------------------------------------
resource "openstack_networking_secgroup_v2" "web" {
  name        = "${var.project_prefix}-web"
  description = "HTTP and HTTPS access"

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
  ]
}

resource "openstack_networking_secgroup_rule_v2" "http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web.id
}

resource "openstack_networking_secgroup_rule_v2" "https_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web.id
}

# -----------------------------------------------------------------------------
# Kubernetes API Security Group
# -----------------------------------------------------------------------------
resource "openstack_networking_secgroup_v2" "k8s_api" {
  name        = "${var.project_prefix}-k8s-api"
  description = "Kubernetes API server access"

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
  ]
}

resource "openstack_networking_secgroup_rule_v2" "k8s_api_ingress" {
  for_each = toset(var.k8s_api_allowed_cidrs)

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = each.value
  security_group_id = openstack_networking_secgroup_v2.k8s_api.id
}

# -----------------------------------------------------------------------------
# Kubernetes Internal Security Group (node-to-node)
# -----------------------------------------------------------------------------
resource "openstack_networking_secgroup_v2" "k8s_internal" {
  name        = "${var.project_prefix}-k8s-internal"
  description = "Kubernetes internal node communication"

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
  ]
}

# Kubelet API
resource "openstack_networking_secgroup_rule_v2" "kubelet" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_group_id   = openstack_networking_secgroup_v2.k8s_internal.id
  security_group_id = openstack_networking_secgroup_v2.k8s_internal.id
}

# NodePort range
resource "openstack_networking_secgroup_rule_v2" "nodeport" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_group_id   = openstack_networking_secgroup_v2.k8s_internal.id
  security_group_id = openstack_networking_secgroup_v2.k8s_internal.id
}

# etcd (control plane nodes)
resource "openstack_networking_secgroup_rule_v2" "etcd" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2380
  remote_group_id   = openstack_networking_secgroup_v2.k8s_internal.id
  security_group_id = openstack_networking_secgroup_v2.k8s_internal.id
}

# Flannel/Calico VXLAN overlay
resource "openstack_networking_secgroup_rule_v2" "vxlan" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 4789
  port_range_max    = 4789
  remote_group_id   = openstack_networking_secgroup_v2.k8s_internal.id
  security_group_id = openstack_networking_secgroup_v2.k8s_internal.id
}

# Calico BGP
resource "openstack_networking_secgroup_rule_v2" "calico_bgp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 179
  port_range_max    = 179
  remote_group_id   = openstack_networking_secgroup_v2.k8s_internal.id
  security_group_id = openstack_networking_secgroup_v2.k8s_internal.id
}

# =============================================================================
# Floating IPs (pre-allocated for load balancers / bastion)
# =============================================================================
resource "openstack_networking_floatingip_v2" "lb" {
  count       = var.lb_floating_ip_count
  pool        = var.external_network_name
  description = "${var.project_prefix} load balancer FIP ${count.index + 1}"

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
    "purpose=load-balancer",
  ]
}

resource "openstack_networking_floatingip_v2" "bastion" {
  count       = var.create_bastion_fip ? 1 : 0
  pool        = var.external_network_name
  description = "${var.project_prefix} bastion FIP"

  tags = [
    "managed_by=terraform",
    "project=${var.project_prefix}",
    "purpose=bastion",
  ]
}

# =============================================================================
# Outputs
# =============================================================================
output "network_id" {
  description = "ID of the created network"
  value       = openstack_networking_network_v2.main.id
}

output "network_name" {
  description = "Name of the created network"
  value       = openstack_networking_network_v2.main.name
}

output "subnet_id" {
  description = "ID of the created subnet"
  value       = openstack_networking_subnet_v2.main.id
}

output "subnet_cidr" {
  description = "CIDR of the created subnet"
  value       = openstack_networking_subnet_v2.main.cidr
}

output "router_id" {
  description = "ID of the created router"
  value       = openstack_networking_router_v2.main.id
}

output "secgroup_ids" {
  description = "Map of security group names to IDs"
  value = {
    base         = openstack_networking_secgroup_v2.base.id
    ssh          = openstack_networking_secgroup_v2.ssh.id
    web          = openstack_networking_secgroup_v2.web.id
    k8s_api      = openstack_networking_secgroup_v2.k8s_api.id
    k8s_internal = openstack_networking_secgroup_v2.k8s_internal.id
  }
}

output "secgroup_names" {
  description = "Map of security group purposes to names"
  value = {
    base         = openstack_networking_secgroup_v2.base.name
    ssh          = openstack_networking_secgroup_v2.ssh.name
    web          = openstack_networking_secgroup_v2.web.name
    k8s_api      = openstack_networking_secgroup_v2.k8s_api.name
    k8s_internal = openstack_networking_secgroup_v2.k8s_internal.name
  }
}

output "lb_floating_ips" {
  description = "Pre-allocated floating IPs for load balancers"
  value       = openstack_networking_floatingip_v2.lb[*].address
}

output "bastion_floating_ip" {
  description = "Floating IP for bastion host"
  value       = var.create_bastion_fip ? openstack_networking_floatingip_v2.bastion[0].address : null
}
