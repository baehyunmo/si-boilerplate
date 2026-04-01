# =============================================================================
# Terraform Variable Declarations — Network — SI Boilerplate (Tier 1)
# =============================================================================

# --- OpenStack Authentication ------------------------------------------------

variable "auth_url" {
  description = "OpenStack Keystone authentication URL"
  type        = string
}

variable "region" {
  description = "OpenStack region"
  type        = string
  default     = "RegionOne"
}

variable "project_name" {
  description = "OpenStack project (tenant) name"
  type        = string
}

# --- Project Naming ----------------------------------------------------------

variable "project_prefix" {
  description = "Prefix for all resource names (e.g., si-myproject)"
  type        = string
  default     = "si-project"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.project_prefix))
    error_message = "project_prefix must be lowercase alphanumeric with hyphens, 3-25 chars."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

# --- Network Configuration --------------------------------------------------

variable "external_network_name" {
  description = "Name of the external (public) network for floating IPs and router gateway"
  type        = string
  default     = "external-net"
}

variable "subnet_cidr" {
  description = "CIDR block for the internal subnet"
  type        = string
  default     = "10.10.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR block."
  }
}

variable "gateway_ip" {
  description = "Gateway IP for the subnet (typically .1 of the CIDR)"
  type        = string
  default     = "10.10.0.1"
}

variable "allocation_pool_start" {
  description = "Start of DHCP allocation pool"
  type        = string
  default     = "10.10.0.10"
}

variable "allocation_pool_end" {
  description = "End of DHCP allocation pool"
  type        = string
  default     = "10.10.0.250"
}

variable "dns_nameservers" {
  description = "DNS nameservers for the subnet"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

# --- Security Group Access Controls -----------------------------------------

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH (restrict to bastion/VPN in production)"
  type        = list(string)
  default     = ["10.0.0.0/8"]

  validation {
    condition     = !contains(var.ssh_allowed_cidrs, "0.0.0.0/0") || length(var.ssh_allowed_cidrs) == 1
    error_message = "Allowing SSH from 0.0.0.0/0 is discouraged. Use a bastion host or VPN CIDR."
  }
}

variable "k8s_api_allowed_cidrs" {
  description = "CIDR blocks allowed to access the Kubernetes API (port 6443)"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

# --- Floating IPs ------------------------------------------------------------

variable "lb_floating_ip_count" {
  description = "Number of floating IPs to pre-allocate for load balancers"
  type        = number
  default     = 1

  validation {
    condition     = var.lb_floating_ip_count >= 0 && var.lb_floating_ip_count <= 5
    error_message = "lb_floating_ip_count must be between 0 and 5."
  }
}

variable "create_bastion_fip" {
  description = "Whether to allocate a floating IP for a bastion host"
  type        = bool
  default     = true
}
