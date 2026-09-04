#!/usr/bin/env bash
# Antigravity 1.1 — One-click Installation and Setup for Omarchy Linux
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PLUGIN_DIR="${HOME}/.config/omarchy/plugins/simonez.antigem"
TARGET_BIN_DIR="${HOME}/.local/bin"

echo "=== Installing Antigravity 1.1 ==="

# 1. Create Directories
mkdir -p "${TARGET_PLUGIN_DIR}" "${TARGET_BIN_DIR}"

# 2. Copy Plugin Files
echo "-> Deploying plugin files to ${TARGET_PLUGIN_DIR}..."
cp "${SCRIPT_DIR}/manifest.json" "${SCRIPT_DIR}/Widget.qml" "${TARGET_PLUGIN_DIR}/"
cp -r "${SCRIPT_DIR}/assets" "${SCRIPT_DIR}/scripts" "${TARGET_PLUGIN_DIR}/"
find "${TARGET_PLUGIN_DIR}" -type f -exec chmod 0644 {} +
chmod 0755 "${TARGET_PLUGIN_DIR}/scripts/antigravity_scanner.py"

# 3. Copy Companion Launcher
echo "-> Deploying launcher to ${TARGET_BIN_DIR}/omarchy-launch-antigravity..."
cp "${SCRIPT_DIR}/bin/omarchy-launch-antigravity" "${TARGET_BIN_DIR}/"
chmod 0755 "${TARGET_BIN_DIR}/omarchy-launch-antigravity"

# 4. Validate Plugin
echo "-> Validating plugin schema with Omarchy CLI..."
omarchy plugin validate "${TARGET_PLUGIN_DIR}"

# 5. Reload / Restart Shell
echo "-> Restarting Omarchy Shell..."
omarchy restart shell || true

echo "=== Antigravity 1.1 installed successfully! ==="
