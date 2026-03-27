#!/usr/bin/env bash
# setup_fonts.sh — Install Microsoft core fonts.
# Run as root. Requires interactive input to accept the Microsoft EULA.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

echo "[+] Installing Microsoft core fonts (Times New Roman, Arial, Courier New, etc.)..."
echo "    You will be prompted to accept the Microsoft EULA to proceed."
echo ""

apt update -q
apt install -y ttf-mscorefonts-installer

echo ""
echo "[+] Refreshing font cache..."
fc-cache -fv

echo ""
echo "[+] Verifying installation..."
fc-list | grep -i "times new roman" && echo "[ok] Times New Roman found" || echo "[!] Times New Roman not found"

echo ""
echo "[+] Font setup complete."
