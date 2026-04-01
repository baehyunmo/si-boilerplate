# =============================================================================
# SaltStack Pillar — Docker Configuration — SI Boilerplate (Tier 1)
# =============================================================================
# Consumed by: os/states/docker.sls
# Override per environment by placing in pillar/env/<env>/docker.sls
# =============================================================================

docker:
  # ---------------------------------------------------------------------------
  # Docker Version (leave empty for latest stable)
  # ---------------------------------------------------------------------------
  # version: "5:24.0.7-1~ubuntu.22.04~jammy"
  version: ""

  # ---------------------------------------------------------------------------
  # Daemon Configuration (/etc/docker/daemon.json)
  # ---------------------------------------------------------------------------
  daemon:
    log-driver: json-file
    log-opts:
      max-size: "10m"
      max-file: "3"
    default-address-pools:
      - base: "172.17.0.0/12"
        size: 24
    storage-driver: overlay2
    live-restore: true
    max-concurrent-downloads: 10
    max-concurrent-uploads: 5
    default-ulimits:
      nofile:
        Name: nofile
        Hard: 65536
        Soft: 65536
    # Metrics endpoint for Prometheus scraping
    metrics-addr: "127.0.0.1:9323"
    experimental: false

  # ---------------------------------------------------------------------------
  # Registry Mirrors
  # ---------------------------------------------------------------------------
  # Uncomment and configure for air-gapped or accelerated environments.
  # registry_mirrors:
  #   - "https://registry-mirror.internal.example.com"
  #   - "https://mirror.gcr.io"

  # ---------------------------------------------------------------------------
  # Insecure Registries (use only for internal dev registries)
  # ---------------------------------------------------------------------------
  # insecure_registries:
  #   - "registry.dev.internal:5000"

  # ---------------------------------------------------------------------------
  # Registry Authentication (optional)
  # ---------------------------------------------------------------------------
  # In production, credentials should come from Vault or encrypted pillar.
  # registry_auth:
  #   - name: harbor
  #     url: harbor.example.com
  #     username: robot$si-project
  #     password: VAULT_MANAGED_SECRET
  #   - name: ghcr
  #     url: ghcr.io
  #     username: si-bot
  #     password: VAULT_MANAGED_SECRET
