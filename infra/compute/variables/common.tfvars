# =============================================================================
# Common Terraform Variables — SI Boilerplate (Tier 1)
# =============================================================================
# Copy this file and customize per environment:
#   cp common.tfvars dev.tfvars
#   terraform plan -var-file="dev.tfvars"
# =============================================================================

# --- OpenStack Authentication ------------------------------------------------
auth_url     = "https://openstack.example.com:5000/v3"
region       = "RegionOne"
project_name = "si-project"
user_name    = ""   # Set via OS_USERNAME env var or override here
password     = ""   # Set via OS_PASSWORD env var (never commit)

# --- Instance Configuration --------------------------------------------------
instance_name  = "si-app-server"
instance_count = 1
flavor_name    = "m1.medium"       # 2 vCPU, 4GB RAM, 40GB disk
image_name     = "Ubuntu-22.04"
network_name   = "si-internal-net"
key_pair       = "si-deploy-key"

security_groups = [
  "default",
  "si-ssh",
  "si-web",
]

# --- Floating IP (Public Access) ---------------------------------------------
assign_floating_ip = true
floating_ip_pool   = "external-net"

# --- Data Volume -------------------------------------------------------------
data_volume_size = 100    # GB, set to 0 to skip
data_volume_type = "SSD"

# --- Cloud-init Parameters ---------------------------------------------------
timezone    = "Asia/Seoul"
admin_user  = "siadmin"
ssh_pub_key = "ssh-ed25519 AAAA... your-key-here"

# --- Tagging -----------------------------------------------------------------
environment = "dev"
project_tag = "si-boilerplate"

extra_metadata = {
  team       = "infra"
  managed_by = "terraform"
}
