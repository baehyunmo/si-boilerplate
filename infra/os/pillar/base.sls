# =============================================================================
# SaltStack Pillar — Base Configuration — SI Boilerplate (Tier 1)
# =============================================================================
# Consumed by: os/states/base.sls
# Override per environment by placing in pillar/env/<env>/base.sls
# =============================================================================

base:
  # ---------------------------------------------------------------------------
  # System
  # ---------------------------------------------------------------------------
  timezone: Asia/Seoul
  locale: en_US.UTF-8
  admin_user: siadmin

  # ---------------------------------------------------------------------------
  # Packages
  # ---------------------------------------------------------------------------
  packages:
    - curl
    - wget
    - git
    - vim
    - htop
    - jq
    - unzip
    - python3
    - python3-pip
    - ca-certificates
    - gnupg
    - lsb-release
    - apt-transport-https
    - software-properties-common
    - net-tools
    - dnsutils
    - traceroute
    - strace
    - rsync
    - tmux

  # ---------------------------------------------------------------------------
  # Sysctl Parameters
  # ---------------------------------------------------------------------------
  sysctl:
    # VM tuning
    vm.swappiness: 10
    vm.dirty_ratio: 15
    vm.dirty_background_ratio: 5
    vm.overcommit_memory: 1

    # Network performance
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 65535
    net.core.rmem_max: 16777216
    net.core.wmem_max: 16777216
    net.ipv4.tcp_max_syn_backlog: 65535
    net.ipv4.ip_local_port_range: "1024 65535"
    net.ipv4.tcp_tw_reuse: 1
    net.ipv4.tcp_fin_timeout: 15
    net.ipv4.tcp_keepalive_time: 600
    net.ipv4.tcp_keepalive_intvl: 60
    net.ipv4.tcp_keepalive_probes: 5
    net.ipv4.conf.all.rp_filter: 1
    net.ipv4.conf.default.rp_filter: 1

    # File descriptors
    fs.file-max: 2097152
    fs.inotify.max_user_watches: 524288
    fs.inotify.max_user_instances: 8192

  # ---------------------------------------------------------------------------
  # NTP Servers
  # ---------------------------------------------------------------------------
  ntp_servers:
    - time.google.com
    - time.cloudflare.com
    - ntp.ubuntu.com
    - time.kriss.re.kr    # Korea Standard Time (for KR-based SI)

  # ---------------------------------------------------------------------------
  # Admin Users
  # ---------------------------------------------------------------------------
  # Add SSH keys for each admin user who needs access.
  # In production, reference these from Vault or a secure pillar.
  admin_users:
    - name: siadmin
      groups:
        - sudo
        - docker
      shell: /bin/bash
      ssh_keys:
        - "ssh-ed25519 AAAA_REPLACE_WITH_REAL_KEY siadmin@si-project"
    # - name: deploy
    #   groups:
    #     - docker
    #   shell: /bin/bash
    #   ssh_keys:
    #     - "ssh-ed25519 AAAA_REPLACE_WITH_REAL_KEY deploy@ci-cd"

  # ---------------------------------------------------------------------------
  # Firewall Rules (additional ports beyond SSH)
  # ---------------------------------------------------------------------------
  firewall_rules: []
    # - port: 80
    #   proto: tcp
    # - port: 443
    #   proto: tcp
    # - port: 6443
    #   proto: tcp
    #   from: 10.0.0.0/8    # K8s API from internal only
