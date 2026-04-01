# =============================================================================
# SaltStack Base State — SI Boilerplate (Tier 1)
# =============================================================================
# Applies baseline OS configuration: packages, timezone, sysctl, NTP, firewall.
# Pillar: os/pillar/base.sls
# =============================================================================

# -----------------------------------------------------------------------------
# Common Packages
# -----------------------------------------------------------------------------
base_packages:
  pkg.installed:
    - pkgs: {{ pillar.get('base:packages', ['curl', 'wget', 'git', 'vim', 'htop', 'jq', 'unzip', 'python3', 'python3-pip', 'ca-certificates', 'gnupg']) | json }}
    - refresh: true

# -----------------------------------------------------------------------------
# Timezone
# -----------------------------------------------------------------------------
set_timezone:
  timezone.system:
    - name: {{ pillar.get('base:timezone', 'Asia/Seoul') }}

# -----------------------------------------------------------------------------
# Locale
# -----------------------------------------------------------------------------
{% set locale = pillar.get('base:locale', 'en_US.UTF-8') %}

generate_locale:
  cmd.run:
    - name: locale-gen {{ locale }}
    - unless: locale -a | grep -q "{{ locale | replace('.', '\\.') | replace('-', '') | lower }}"

set_default_locale:
  file.managed:
    - name: /etc/default/locale
    - contents: |
        LANG={{ locale }}
        LC_ALL={{ locale }}
    - require:
      - cmd: generate_locale

# -----------------------------------------------------------------------------
# Sysctl Tuning
# -----------------------------------------------------------------------------
{% set sysctl_params = pillar.get('base:sysctl', {
  'vm.swappiness': 10,
  'vm.dirty_ratio': 15,
  'vm.dirty_background_ratio': 5,
  'net.core.somaxconn': 65535,
  'net.core.netdev_max_backlog': 65535,
  'net.ipv4.tcp_max_syn_backlog': 65535,
  'net.ipv4.ip_local_port_range': '1024 65535',
  'net.ipv4.tcp_tw_reuse': 1,
  'net.ipv4.tcp_fin_timeout': 15,
  'net.ipv4.conf.all.rp_filter': 1,
  'net.ipv4.conf.default.rp_filter': 1,
  'fs.file-max': 2097152,
  'fs.inotify.max_user_watches': 524288,
}) %}

sysctl_tuning:
  file.managed:
    - name: /etc/sysctl.d/99-si-tuning.conf
    - contents: |
        # SI Boilerplate — Sysctl Tuning (managed by SaltStack)
        {% for key, value in sysctl_params.items() %}
        {{ key }} = {{ value }}
        {% endfor %}
    - user: root
    - group: root
    - mode: '0644'

apply_sysctl:
  cmd.run:
    - name: sysctl --system
    - onchanges:
      - file: sysctl_tuning

# -----------------------------------------------------------------------------
# NTP (chrony)
# -----------------------------------------------------------------------------
chrony_package:
  pkg.installed:
    - name: chrony

chrony_config:
  file.managed:
    - name: /etc/chrony/chrony.conf
    - source: salt://files/chrony.conf
    - template: jinja
    - defaults:
        ntp_servers: {{ pillar.get('base:ntp_servers', ['time.google.com', 'time.cloudflare.com', 'ntp.ubuntu.com']) | json }}
    - contents: |
        # SI Boilerplate — Chrony NTP Configuration (managed by SaltStack)
        {% for server in pillar.get('base:ntp_servers', ['time.google.com', 'time.cloudflare.com', 'ntp.ubuntu.com']) %}
        server {{ server }} iburst
        {% endfor %}

        driftfile /var/lib/chrony/drift
        makestep 1.0 3
        rtcsync
        keyfile /etc/chrony/chrony.keys
        leapsectz right/UTC
        logdir /var/log/chrony
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - pkg: chrony_package

chrony_service:
  service.running:
    - name: chrony
    - enable: true
    - watch:
      - file: chrony_config

# -----------------------------------------------------------------------------
# Firewall (UFW)
# -----------------------------------------------------------------------------
ufw_package:
  pkg.installed:
    - name: ufw

ufw_default_deny_incoming:
  cmd.run:
    - name: ufw default deny incoming
    - unless: ufw status verbose | grep -q "Default:.*deny (incoming)"
    - require:
      - pkg: ufw_package

ufw_default_allow_outgoing:
  cmd.run:
    - name: ufw default allow outgoing
    - unless: ufw status verbose | grep -q "Default:.*allow (outgoing)"
    - require:
      - pkg: ufw_package

ufw_allow_ssh:
  cmd.run:
    - name: ufw allow 22/tcp
    - unless: ufw status | grep -q "22/tcp.*ALLOW"
    - require:
      - cmd: ufw_default_deny_incoming

{% for rule in pillar.get('base:firewall_rules', []) %}
ufw_rule_{{ rule.port }}_{{ rule.proto | default('tcp') }}:
  cmd.run:
    - name: ufw allow {{ rule.port }}/{{ rule.proto | default('tcp') }}{% if rule.get('from') %} from {{ rule.from }}{% endif %}
    - unless: ufw status | grep -q "{{ rule.port }}/{{ rule.proto | default('tcp') }}.*ALLOW"
    - require:
      - cmd: ufw_default_deny_incoming
{% endfor %}

ufw_enable:
  cmd.run:
    - name: ufw --force enable
    - unless: ufw status | grep -q "Status: active"
    - require:
      - cmd: ufw_allow_ssh

# -----------------------------------------------------------------------------
# File Descriptor Limits
# -----------------------------------------------------------------------------
system_limits:
  file.managed:
    - name: /etc/security/limits.d/99-si-limits.conf
    - contents: |
        # SI Boilerplate — System Limits (managed by SaltStack)
        *    soft    nofile    65536
        *    hard    nofile    131072
        *    soft    nproc     65536
        *    hard    nproc     131072
        root soft    nofile    65536
        root hard    nofile    131072
    - user: root
    - group: root
    - mode: '0644'

# -----------------------------------------------------------------------------
# Standard Directories
# -----------------------------------------------------------------------------
{% for dir in ['/data', '/data/apps', '/data/logs', '/data/backups'] %}
{{ dir }}:
  file.directory:
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true
{% endfor %}
