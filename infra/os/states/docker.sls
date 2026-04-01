# =============================================================================
# SaltStack Docker State — SI Boilerplate (Tier 1)
# =============================================================================
# Installs Docker CE from the official repository with production configuration.
# Pillar: os/pillar/docker.sls
# =============================================================================

{% set docker_version = pillar.get('docker:version', '') %}
{% set admin_user = pillar.get('base:admin_user', 'siadmin') %}
{% set os_family = grains['os_family'] %}

# -----------------------------------------------------------------------------
# Prerequisites
# -----------------------------------------------------------------------------
docker_prereqs:
  pkg.installed:
    - pkgs:
      - ca-certificates
      - curl
      - gnupg
      - lsb-release

# -----------------------------------------------------------------------------
# Docker APT Repository (Debian/Ubuntu)
# -----------------------------------------------------------------------------
{% if os_family == 'Debian' %}

docker_gpg_key:
  cmd.run:
    - name: |
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/{{ grains['os'] | lower }}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
    - creates: /etc/apt/keyrings/docker.gpg
    - require:
      - pkg: docker_prereqs

docker_repo:
  pkgrepo.managed:
    - humanname: Docker Official Repository
    - name: >-
        deb [arch={{ grains['osarch'] }}
        signed-by=/etc/apt/keyrings/docker.gpg]
        https://download.docker.com/linux/{{ grains['os'] | lower }}
        {{ grains['oscodename'] }} stable
    - file: /etc/apt/sources.list.d/docker.list
    - require:
      - cmd: docker_gpg_key

{% elif os_family == 'RedHat' %}

# -----------------------------------------------------------------------------
# Docker YUM Repository (RHEL/CentOS)
# -----------------------------------------------------------------------------
docker_repo:
  pkgrepo.managed:
    - humanname: Docker Official Repository
    - baseurl: https://download.docker.com/linux/centos/$releasever/$basearch/stable
    - gpgcheck: 1
    - gpgkey: https://download.docker.com/linux/centos/gpg
    - require:
      - pkg: docker_prereqs

{% endif %}

# -----------------------------------------------------------------------------
# Docker Packages
# -----------------------------------------------------------------------------
docker_packages:
  pkg.installed:
    - pkgs:
      {% if docker_version %}
      - docker-ce: '{{ docker_version }}'
      - docker-ce-cli: '{{ docker_version }}'
      {% else %}
      - docker-ce
      - docker-ce-cli
      {% endif %}
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    - refresh: true
    - require:
      - pkgrepo: docker_repo

# -----------------------------------------------------------------------------
# Docker Daemon Configuration
# -----------------------------------------------------------------------------
{% set daemon_config = pillar.get('docker:daemon', {}) %}
{% set default_daemon = {
  'log-driver': 'json-file',
  'log-opts': {
    'max-size': '10m',
    'max-file': '3'
  },
  'default-address-pools': [
    {'base': '172.17.0.0/12', 'size': 24}
  ],
  'storage-driver': 'overlay2',
  'live-restore': True,
  'max-concurrent-downloads': 10,
  'max-concurrent-uploads': 5,
  'default-ulimits': {
    'nofile': {
      'Name': 'nofile',
      'Hard': 65536,
      'Soft': 65536
    }
  }
} %}

docker_daemon_config:
  file.serialize:
    - name: /etc/docker/daemon.json
    - dataset: {{ daemon_config | default(default_daemon, true) | json }}
    - formatter: json
    - user: root
    - group: root
    - mode: '0644'
    - makedirs: true
    - require:
      - pkg: docker_packages

# -----------------------------------------------------------------------------
# Docker Service
# -----------------------------------------------------------------------------
docker_service:
  service.running:
    - name: docker
    - enable: true
    - watch:
      - file: docker_daemon_config
    - require:
      - pkg: docker_packages

containerd_service:
  service.running:
    - name: containerd
    - enable: true
    - require:
      - pkg: docker_packages

# -----------------------------------------------------------------------------
# Admin User Docker Access
# -----------------------------------------------------------------------------
docker_group:
  group.present:
    - name: docker
    - system: true
    - require:
      - pkg: docker_packages

docker_user_{{ admin_user }}:
  user.present:
    - name: {{ admin_user }}
    - groups:
      - docker
    - remove_groups: false
    - require:
      - group: docker_group

# -----------------------------------------------------------------------------
# Docker Log Rotation (additional logrotate config)
# -----------------------------------------------------------------------------
docker_logrotate:
  file.managed:
    - name: /etc/logrotate.d/docker-containers
    - contents: |
        /var/lib/docker/containers/*/*.log {
          rotate 7
          daily
          compress
          delaycompress
          missingok
          notifempty
          copytruncate
          maxsize 100M
        }
    - user: root
    - group: root
    - mode: '0644'

# -----------------------------------------------------------------------------
# Docker System Prune Cron
# -----------------------------------------------------------------------------
docker_prune_cron:
  cron.present:
    - name: /usr/bin/docker system prune -af --filter "until=168h" > /dev/null 2>&1
    - user: root
    - hour: 3
    - minute: 0
    - dayweek: 0
    - comment: "Weekly Docker cleanup — remove dangling images/containers older than 7 days"
    - require:
      - service: docker_service

# -----------------------------------------------------------------------------
# Registry Mirror Authentication (optional, if pillar has credentials)
# -----------------------------------------------------------------------------
{% if pillar.get('docker:registry_auth') %}
{% for registry in pillar.get('docker:registry_auth', []) %}
docker_login_{{ registry.name }}:
  cmd.run:
    - name: >-
        echo '{{ registry.password }}' |
        docker login {{ registry.url }}
        --username '{{ registry.username }}'
        --password-stdin
    - unless: test -f /root/.docker/config.json && grep -q "{{ registry.url }}" /root/.docker/config.json
    - require:
      - service: docker_service
{% endfor %}
{% endif %}
