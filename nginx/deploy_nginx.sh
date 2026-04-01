#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"
TARGET_DIR="/etc/nginx/conf.d"
BACKUP_ROOT="/etc/nginx/backup"
SERVICE_NAME="nginx"
INSTALL_FIREWALL_RULES="true"
DRY_RUN="false"
CONF_FILES=()
LISTEN_PORTS=()

log() {
    printf '[INFO] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

die() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

print_cmd() {
    local parts=()
    local arg=""
    for arg in "$@"; do
        parts+=("$(printf '%q' "$arg")")
    done
    printf '[DRY-RUN] %s\n' "${parts[*]}"
}

usage() {
    cat <<'EOF'
Usage:
  bash nginx/deploy_nginx.sh [options]

Options:
  --source-dir <dir>     Source directory that contains *.conf files.
  --target-dir <dir>     Target nginx include directory. Default: /etc/nginx/conf.d
  --backup-root <dir>    Backup directory root. Default: /etc/nginx/backup
  --service-name <name>  Service name managed by systemctl. Default: nginx
  --skip-firewall        Do not add firewall rules for listen ports.
  --dry-run              Print planned actions without changing the system.
  -h, --help             Show this help message.
EOF
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        need_cmd sudo
        sudo "$@"
    fi
}

run_as_root() {
    if [ "$DRY_RUN" = "true" ]; then
        if [ "$(id -u)" -eq 0 ]; then
            print_cmd "$@"
        else
            print_cmd sudo "$@"
        fi
        return 0
    fi
    as_root "$@"
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --source-dir)
                [ $# -ge 2 ] || die "Missing value for $1"
                SOURCE_DIR="$2"
                shift 2
                ;;
            --target-dir)
                [ $# -ge 2 ] || die "Missing value for $1"
                TARGET_DIR="$2"
                shift 2
                ;;
            --backup-root)
                [ $# -ge 2 ] || die "Missing value for $1"
                BACKUP_ROOT="$2"
                shift 2
                ;;
            --service-name)
                [ $# -ge 2 ] || die "Missing value for $1"
                SERVICE_NAME="$2"
                shift 2
                ;;
            --skip-firewall)
                INSTALL_FIREWALL_RULES="false"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown argument: $1"
                ;;
        esac
    done
}

collect_conf_files() {
    need_cmd find
    need_cmd sort
    mapfile -t CONF_FILES < <(find "$SOURCE_DIR" -maxdepth 1 -type f -name '*.conf' | sort)
    [ "${#CONF_FILES[@]}" -gt 0 ] || die "No .conf files found in $SOURCE_DIR"
}

install_nginx() {
    if command -v nginx >/dev/null 2>&1; then
        log "nginx is already installed"
        return
    fi

    log "nginx not found, installing it first"
    if command -v apt-get >/dev/null 2>&1; then
        run_as_root apt-get update
        run_as_root apt-get install -y nginx
    elif command -v dnf >/dev/null 2>&1; then
        run_as_root dnf install -y nginx
    elif command -v yum >/dev/null 2>&1; then
        if ! run_as_root yum install -y nginx; then
            warn "Direct yum install failed, trying epel-release first"
            run_as_root yum install -y epel-release
            run_as_root yum install -y nginx
        fi
    else
        die "Unsupported package manager, please install nginx manually"
    fi
}

prepare_target_dir() {
    run_as_root mkdir -p "$TARGET_DIR"
}

backup_existing_configs() {
    local backup_dir=""
    local backup_needed="false"

    for conf in "${CONF_FILES[@]}"; do
        local dest="$TARGET_DIR/$(basename "$conf")"
        if [ -f "$dest" ] || [ -L "$dest" ]; then
            if [ "$backup_needed" = "false" ]; then
                backup_dir="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
                run_as_root mkdir -p "$backup_dir"
                backup_needed="true"
            fi
            run_as_root cp -a "$dest" "$backup_dir/"
            log "Backed up $dest to $backup_dir/"
        fi
    done

    if [ "$backup_needed" = "false" ]; then
        log "No existing nginx config needed backup"
    fi
}

deploy_configs() {
    for conf in "${CONF_FILES[@]}"; do
        local dest="$TARGET_DIR/$(basename "$conf")"
        run_as_root install -m 644 "$conf" "$dest"
        log "Deployed $(basename "$conf") to $dest"
    done
}

collect_listen_ports() {
    need_cmd awk
    mapfile -t LISTEN_PORTS < <(
        awk '
            /^[[:space:]]*listen[[:space:]]+/ {
                for (i = 2; i <= NF; i++) {
                    token = $i
                    gsub(/;/, "", token)
                    if (token ~ /^[0-9]+$/) {
                        print token
                        break
                    }
                    if (token ~ /:[0-9]+$/) {
                        split(token, parts, ":")
                        print parts[length(parts)]
                        break
                    }
                }
            }
        ' "${CONF_FILES[@]}" | sort -n -u
    )
}

configure_firewall() {
    [ "$INSTALL_FIREWALL_RULES" = "true" ] || return
    if [ "${#LISTEN_PORTS[@]}" -eq 0 ]; then
        warn "No listen ports detected in config files, skipping firewall configuration"
        return
    fi

    if command -v ufw >/dev/null 2>&1; then
        if [ "$DRY_RUN" = "true" ]; then
            for port in "${LISTEN_PORTS[@]}"; do
                run_as_root ufw allow "${port}/tcp"
                log "Opened ufw port ${port}/tcp"
            done
            log "Dry-run note: ufw rules take effect only when ufw is active"
        elif as_root ufw status | grep -q 'Status: active'; then
            for port in "${LISTEN_PORTS[@]}"; do
                run_as_root ufw allow "${port}/tcp"
                log "Opened ufw port ${port}/tcp"
            done
        else
            warn "ufw is installed but not active, skipping ufw rules"
        fi
        return
    fi

    if command -v firewall-cmd >/dev/null 2>&1; then
        if [ "$DRY_RUN" = "true" ]; then
            for port in "${LISTEN_PORTS[@]}"; do
                run_as_root firewall-cmd --permanent --add-port="${port}/tcp"
                log "Opened firewalld port ${port}/tcp"
            done
            run_as_root firewall-cmd --reload
        elif as_root firewall-cmd --state >/dev/null 2>&1; then
            for port in "${LISTEN_PORTS[@]}"; do
                run_as_root firewall-cmd --permanent --add-port="${port}/tcp"
                log "Opened firewalld port ${port}/tcp"
            done
            run_as_root firewall-cmd --reload
        else
            warn "firewalld is installed but not running, skipping firewalld rules"
        fi
        return
    fi

    warn "No supported firewall manager detected, skipping firewall configuration"
}

reload_nginx() {
    if [ "$DRY_RUN" = "true" ]; then
        run_as_root nginx -t

        if command -v systemctl >/dev/null 2>&1; then
            run_as_root systemctl enable "$SERVICE_NAME"
            if systemctl is-active --quiet "$SERVICE_NAME" >/dev/null 2>&1; then
                run_as_root systemctl reload "$SERVICE_NAME"
                log "Dry-run: detected active service, would reload $SERVICE_NAME"
            else
                run_as_root systemctl restart "$SERVICE_NAME"
                log "Dry-run: service inactive or undetectable, would restart $SERVICE_NAME"
            fi
            return
        fi

        if pgrep -x nginx >/dev/null 2>&1; then
            run_as_root nginx -s reload
            log "Dry-run: would reload nginx via nginx -s reload"
        else
            run_as_root nginx
            log "Dry-run: would start nginx via nginx command"
        fi
        return
    fi

    as_root nginx -t

    if command -v systemctl >/dev/null 2>&1 && as_root systemctl cat "$SERVICE_NAME" >/dev/null 2>&1; then
        as_root systemctl enable "$SERVICE_NAME"
        if as_root systemctl is-active --quiet "$SERVICE_NAME"; then
            as_root systemctl reload "$SERVICE_NAME"
            log "Reloaded service: $SERVICE_NAME"
        else
            as_root systemctl restart "$SERVICE_NAME"
            log "Started service: $SERVICE_NAME"
        fi
        return
    fi

    if pgrep -x nginx >/dev/null 2>&1; then
        as_root nginx -s reload
        log "Reloaded nginx via nginx -s reload"
    else
        as_root nginx
        log "Started nginx via nginx command"
    fi
}

print_summary() {
    printf '\n'
    log "nginx deployment completed"
    if [ "$DRY_RUN" = "true" ]; then
        log "Mode: dry-run"
    fi
    log "Source dir: $SOURCE_DIR"
    log "Target dir: $TARGET_DIR"
    if [ "${#LISTEN_PORTS[@]}" -gt 0 ]; then
        log "Listen ports: ${LISTEN_PORTS[*]}"
    fi
}

main() {
    parse_args "$@"
    if [ "$DRY_RUN" = "true" ]; then
        log "Dry-run mode enabled, no system files or services will be changed"
    fi
    collect_conf_files
    collect_listen_ports
    install_nginx
    prepare_target_dir
    backup_existing_configs
    deploy_configs
    reload_nginx
    configure_firewall
    print_summary
}

main "$@"
