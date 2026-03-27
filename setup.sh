#!/usr/bin/env bash
# setup.sh — Fresh server setup script.
# Run as root.

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

USERS=("clara" "atlas")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log()  { echo "[+] $*"; }
warn() { echo "[!] $*"; }

# Append a block to a file only when a marker string is absent (idempotent).
append_once() {
    local marker="$1"
    local block="$2"
    local file="$3"

    if grep -qF "$marker" "$file" 2>/dev/null; then
        echo "    [skip] already present: $marker"
    else
        printf '\n%s\n' "$block" >> "$file"
        echo "    [ok]   appended: $marker"
    fi
}

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

install_packages() {
    log "Installing system packages..."
    apt update -q
    apt install -y git unzip file ripgrep
    apt install -y libreoffice
    apt install -y python3-pip python3-openpyxl python3-docx

    log "Installing snaps..."
    snap list nvim &>/dev/null && snap refresh nvim || snap install nvim --classic
    snap list yazi &>/dev/null && snap refresh yazi || snap install yazi --classic

    log "Installing Node.js 24 via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt install -y nodejs
}

setup_users() {
    log "Setting up users..."
    for user in "${USERS[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            log "Created user: $user"
        else
            warn "User already exists: $user"
        fi

        loginctl enable-linger "$user"

        local home
        home="$(getent passwd "$user" | cut -d: -f6)"
        mkdir -p "$home/.config/systemd/user"
        chown -R "$user:$user" "$home/.config"

        log "Configured: $user"
    done
}

setup_nvim() {
    log "Installing Neovim config for each user..."
    for user in "${USERS[@]}"; do
        local home
        home="$(getent passwd "$user" | cut -d: -f6)"
        local nvim_config="$home/.config/nvim"

        if [[ -d "$nvim_config" ]]; then
            warn "Neovim config already exists for $user — skipping"
            continue
        fi

        git clone --depth 1 https://github.com/phhphc/neovim-config "$nvim_config"
        rm -rf "$nvim_config/.git"
        chown -R "$user:$user" "$nvim_config"
        log "Neovim config installed for: $user"
    done
}

setup_bashrc() {
    log "Configuring .bashrc for each user..."

    # Yazi shell wrapper — lets `y` act as a cd-on-exit wrapper around yazi.
    # See: https://yazi-rs.github.io/docs/quick-start#shell-wrapper
    local yazi_block
    read -r -d '' yazi_block << 'EOF' || true

# Yazi shell wrapper
# Changes the working directory to wherever yazi exits in.
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
EOF

    # OpenClaw startup optimisations.
    # NODE_COMPILE_CACHE speeds up repeated CLI invocations (Node.js >= v22.1).
    # OPENCLAW_NO_RESPAWN=1 skips self-respawn to cut startup overhead.
    # See: https://docs.openclaw.ai/vps
    local openclaw_block
    read -r -d '' openclaw_block << 'EOF' || true

# OpenClaw startup optimisations (Node compile cache + skip self-respawn)
export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
mkdir -p /var/tmp/openclaw-compile-cache
export OPENCLAW_NO_RESPAWN=1
EOF

    for user in "${USERS[@]}"; do
        local home
        home="$(getent passwd "$user" 2>/dev/null | cut -d: -f6)" || true

        if [[ -z "$home" ]]; then
            warn "User '$user' not found — skipping .bashrc setup"
            continue
        fi

        local bashrc="$home/.bashrc"
        [[ -f "$bashrc" ]] || touch "$bashrc"

        echo "  >>> $user ($bashrc)"
        append_once "# Yazi shell wrapper" "$yazi_block" "$bashrc"
        append_once "# OpenClaw startup optimisations" "$openclaw_block" "$bashrc"
    done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    if [[ $EUID -ne 0 ]]; then
        echo "Please run as root: sudo $0"
        exit 1
    fi

    install_packages
    setup_users
    setup_nvim
    setup_bashrc

    echo ""
    log "Setup complete. Reboot if needed."
}

main "$@"
