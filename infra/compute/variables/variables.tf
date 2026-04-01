# =============================================================================
# Terraform Variable Declarations — SI Boilerplate (Tier 1)
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

variable "user_name" {
  description = "OpenStack username (prefer OS_USERNAME env var)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "password" {
  description = "OpenStack password (prefer OS_PASSWORD env var)"
  type        = string
  default     = ""
  sensitive   = true
}

# --- Instance Configuration --------------------------------------------------

variable "instance_name" {
  description = "Base name for the compute instance(s)"
  type        = string
  default     = "si-server"
}

variable "instance_count" {
  description = "Number of instances to provision"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 20
    error_message = "instance_count must be between 1 and 20."
  }
}

variable "flavor_name" {
  description = "OpenStack flavor name (e.g., m1.medium)"
  type        = string
  default     = "m1.medium"
}

variable "image_name" {
  description = "OS image name (e.g., Ubuntu-22.04)"
  type        = string
  default     = "Ubuntu-22.04"
}

variable "network_name" {
  description = "Name of the network to attach instances to"
  type        = string
}

variable "key_pair" {
  description = "Name of the SSH key pair registered in OpenStack"
  type        = string
}

variable "security_groups" {
  description = "List of security group names to apply"
  type        = list(string)
  default     = ["default"]
}

# --- Floating IP -------------------------------------------------------------

variable "assign_floating_ip" {
  description = "Whether to assign a floating (public) IP"
  type        = bool
  default     = false
}

variable "floating_ip_pool" {
  description = "Name of the floating IP pool (external network)"
  type        = string
  default     = "external-net"
}

# --- Block Storage -----------------------------------------------------------

variable "data_volume_size" {
  description = "Size of the data volume in GB (0 to skip)"
  type        = number
  default     = 0

  validation {
    condition     = var.data_volume_size >= 0 && var.data_volume_size <= 2000
    error_message = "data_volume_size must be between 0 and 2000 GB."
  }
}

variable "data_volume_type" {
  description = "Volume type (e.g., SSD, HDD)"
  type        = string
  default     = "SSD"
}

# --- Cloud-init Parameters ---------------------------------------------------

variable "timezone" {
  description = "System timezone"
  type        = string
  default     = "Asia/Seoul"
}

variable "admin_user" {
  description = "Admin username to create via cloud-init"
  type        = string
  default     = "siadmin"
}

variable "ssh_pub_key" {
  description = "SSH public key for the admin user"
  type        = string
  sensitive   = true
}

# --- Tagging -----------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "project_tag" {
  description = "Project identifier for resource tagging"
  type        = string
  default     = "si-boilerplate"
}

variable "extra_metadata" {
  description = "Additional metadata tags for instances"
  type        = map(string)
  default     = {}
}
