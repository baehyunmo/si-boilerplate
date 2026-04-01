# =============================================================================
# SaltStack Security Hardening State — SI Boilerplate (Tier 1)
# =============================================================================
# SSH hardening, password policy, audit logging, service minimization.
# =============================================================================

{% set allowed_ssh_users = pillar.get('security:ssh_allowed_users', ['siadmin']) %}
{% set ssh_port = pillar.get('security:ssh_port', 22) %}

# -----------------------------------------------------------------------------
# SSH Hardening
# -----------------------------------------------------------------------------
sshd_config:
  file.managed:
    - name: /etc/ssh/sshd_config.d/99-si-hardening.conf
    - contents: |
        # SI Boilerplate — SSH Hardening (managed by SaltStack)

        # Authentication
        PermitRootLogin no
        PasswordAuthentication no
        PubkeyAuthentication yes
        AuthenticationMethods publickey
        PermitEmptyPasswords no
        MaxAuthTries 3
        MaxSessions 5
        LoginGraceTime 30

        # Access control
        AllowUsers {{ allowed_ssh_users | join(' ') }}

        # Network
        Port {{ ssh_port }}
        AddressFamily inet
        X11Forwarding no
        AllowTcpForwarding no
        AllowAgentForwarding no
        GatewayPorts no
        PermitTunnel no

        # Session
        ClientAliveInterval 300
        ClientAliveCountMax 2

        # Logging
        LogLevel VERBOSE
        SyslogFacility AUTH

        # Cryptography (modern ciphers only)
        KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
        MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

        # Miscellaneous
        UsePAM yes
        PrintMotd no
        AcceptEnv LANG LC_*
        Subsystem sftp /usr/lib/openssh/sftp-server
    - user: root
    - group: root
    - mode: '0600'
    - makedirs: true

sshd_restart:
  service.running:
    - name: sshd
    - enable: true
    - watch:
      - file: sshd_config

# Remove SSH host keys with weak algorithms
remove_weak_host_keys:
  cmd.run:
    - name: |
        rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_dsa_key.pub
        rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ecdsa_key.pub
    - onlyif: test -f /etc/ssh/ssh_host_dsa_key -o -f /etc/ssh/ssh_host_ecdsa_key

# -----------------------------------------------------------------------------
# Password Policy (PAM)
# -----------------------------------------------------------------------------
password_quality_package:
  pkg.installed:
    - name: libpam-pwquality

password_quality_config:
  file.managed:
    - name: /etc/security/pwquality.conf
    - contents: |
        # SI Boilerplate — Password Quality (managed by SaltStack)
        minlen = 12
        dcredit = -1
        ucredit = -1
        lcredit = -1
        ocredit = -1
        maxrepeat = 3
        maxsequence = 3
        dictcheck = 1
        enforcing = 1
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - pkg: password_quality_package

# Password aging
login_defs:
  file.replace:
    - name: /etc/login.defs
    - pattern: '^PASS_MAX_DAYS.*'
    - repl: 'PASS_MAX_DAYS   90'

login_defs_min:
  file.replace:
    - name: /etc/login.defs
    - pattern: '^PASS_MIN_DAYS.*'
    - repl: 'PASS_MIN_DAYS   7'

login_defs_warn:
  file.replace:
    - name: /etc/login.defs
    - pattern: '^PASS_WARN_AGE.*'
    - repl: 'PASS_WARN_AGE   14'

# -----------------------------------------------------------------------------
# Audit Logging (auditd)
# -----------------------------------------------------------------------------
auditd_packages:
  pkg.installed:
    - pkgs:
      - auditd
      - audispd-plugins

auditd_rules:
  file.managed:
    - name: /etc/audit/rules.d/99-si-audit.rules
    - contents: |
        # SI Boilerplate — Audit Rules (managed by SaltStack)
        # Remove any existing rules
        -D

        # Buffer size
        -b 8192

        # Failure mode (1=printk, 2=panic)
        -f 1

        # Monitor authentication
        -w /etc/pam.d/ -p wa -k pam_changes
        -w /etc/shadow -p wa -k shadow_changes
        -w /etc/passwd -p wa -k passwd_changes
        -w /etc/group -p wa -k group_changes
        -w /etc/gshadow -p wa -k gshadow_changes

        # Monitor SSH configuration
        -w /etc/ssh/sshd_config -p wa -k sshd_config
        -w /etc/ssh/sshd_config.d/ -p wa -k sshd_config

        # Monitor sudo usage
        -w /etc/sudoers -p wa -k sudoers_changes
        -w /etc/sudoers.d/ -p wa -k sudoers_changes
        -w /var/log/auth.log -p ra -k auth_log

        # Monitor system calls for privilege escalation
        -a always,exit -F arch=b64 -S execve -k exec_commands
        -a always,exit -F arch=b64 -S setuid -S setgid -k priv_escalation

        # Monitor network configuration changes
        -w /etc/hosts -p wa -k hosts_changes
        -w /etc/network/ -p wa -k network_changes
        -w /etc/sysctl.conf -p wa -k sysctl_changes
        -w /etc/sysctl.d/ -p wa -k sysctl_changes

        # Monitor Docker
        -w /usr/bin/docker -p x -k docker_commands
        -w /etc/docker/ -p wa -k docker_config
        -w /var/lib/docker/ -p wa -k docker_data

        # Monitor cron
        -w /etc/crontab -p wa -k cron_changes
        -w /etc/cron.d/ -p wa -k cron_changes
        -w /etc/cron.daily/ -p wa -k cron_changes
        -w /etc/cron.hourly/ -p wa -k cron_changes

        # Make config immutable (must be last)
        -e 2
    - user: root
    - group: root
    - mode: '0640'
    - require:
      - pkg: auditd_packages

auditd_config:
  file.managed:
    - name: /etc/audit/auditd.conf
    - contents: |
        # SI Boilerplate — Auditd Configuration (managed by SaltStack)
        log_file = /var/log/audit/audit.log
        log_group = adm
        log_format = ENRICHED
        flush = INCREMENTAL_ASYNC
        freq = 50
        max_log_file = 50
        num_logs = 10
        max_log_file_action = ROTATE
        space_left = 75
        space_left_action = SYSLOG
        admin_space_left = 50
        admin_space_left_action = SUSPEND
        disk_full_action = SUSPEND
        disk_error_action = SUSPEND
        name_format = HOSTNAME
    - user: root
    - group: root
    - mode: '0640'
    - require:
      - pkg: auditd_packages

auditd_service:
  service.running:
    - name: auditd
    - enable: true
    - watch:
      - file: auditd_rules
      - file: auditd_config

# -----------------------------------------------------------------------------
# Disable Unnecessary Services
# -----------------------------------------------------------------------------
{% set disable_services = pillar.get('security:disable_services', [
  'avahi-daemon',
  'cups',
  'rpcbind',
  'bluetooth',
  'telnet',
]) %}

{% for svc in disable_services %}
disable_{{ svc }}:
  service.dead:
    - name: {{ svc }}
    - enable: false
    - onlyif: systemctl list-unit-files | grep -q "{{ svc }}"
{% endfor %}

# Remove unnecessary packages
remove_unnecessary_packages:
  pkg.purged:
    - pkgs:
      - telnetd
      - rsh-server
      - xinetd

# -----------------------------------------------------------------------------
# File Permissions Hardening
# -----------------------------------------------------------------------------
{% for path in ['/etc/passwd', '/etc/group'] %}
permissions_{{ path | replace('/', '_') }}:
  file.managed:
    - name: {{ path }}
    - mode: '0644'
    - replace: false
{% endfor %}

{% for path in ['/etc/shadow', '/etc/gshadow'] %}
permissions_{{ path | replace('/', '_') }}:
  file.managed:
    - name: {{ path }}
    - mode: '0640'
    - replace: false
{% endfor %}

permissions_cron_dirs:
  cmd.run:
    - name: |
        chmod 700 /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly 2>/dev/null || true
        chmod 600 /etc/crontab 2>/dev/null || true
    - onlyif: test -d /etc/cron.d

# -----------------------------------------------------------------------------
# Kernel Hardening via Sysctl
# -----------------------------------------------------------------------------
security_sysctl:
  file.managed:
    - name: /etc/sysctl.d/99-si-security.conf
    - contents: |
        # SI Boilerplate — Security Sysctl (managed by SaltStack)
        # Disable IP forwarding (unless routing is needed)
        net.ipv4.ip_forward = 0
        net.ipv6.conf.all.forwarding = 0

        # Disable ICMP redirects
        net.ipv4.conf.all.accept_redirects = 0
        net.ipv4.conf.default.accept_redirects = 0
        net.ipv6.conf.all.accept_redirects = 0

        # Disable source routing
        net.ipv4.conf.all.accept_source_route = 0
        net.ipv4.conf.default.accept_source_route = 0

        # Enable SYN flood protection
        net.ipv4.tcp_syncookies = 1

        # Log suspicious packets
        net.ipv4.conf.all.log_martians = 1
        net.ipv4.conf.default.log_martians = 1

        # Disable SUID core dumps
        fs.suid_dumpable = 0

        # Restrict kernel pointers
        kernel.kptr_restrict = 2

        # Restrict dmesg access
        kernel.dmesg_restrict = 1

        # Restrict perf_event
        kernel.perf_event_paranoid = 3

        # ASLR full randomization
        kernel.randomize_va_space = 2
    - user: root
    - group: root
    - mode: '0644'

apply_security_sysctl:
  cmd.run:
    - name: sysctl --system
    - onchanges:
      - file: security_sysctl

# -----------------------------------------------------------------------------
# Fail2Ban
# -----------------------------------------------------------------------------
fail2ban_package:
  pkg.installed:
    - name: fail2ban

fail2ban_config:
  file.managed:
    - name: /etc/fail2ban/jail.local
    - contents: |
        # SI Boilerplate — Fail2Ban (managed by SaltStack)
        [DEFAULT]
        bantime = 3600
        findtime = 600
        maxretry = 3
        backend = systemd
        banaction = ufw

        [sshd]
        enabled = true
        port = {{ ssh_port }}
        filter = sshd
        maxretry = 3
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - pkg: fail2ban_package

fail2ban_service:
  service.running:
    - name: fail2ban
    - enable: true
    - watch:
      - file: fail2ban_config
