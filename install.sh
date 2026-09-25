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
cp "${SCRIPT_DIR}/manifest.json" "${SCRIPT_DIR}/BarWidget.qml" "${SCRIPT_DIR}/Panel.qml" "${TARGET_PLUGIN_DIR}/"
rm -f "${TARGET_PLUGIN_DIR}/Widget.qml"
if [[ -d "${SCRIPT_DIR}/assets" ]]; then
  cp -r "${SCRIPT_DIR}/assets" "${TARGET_PLUGIN_DIR}/"
fi
if [[ -d "${SCRIPT_DIR}/scripts" ]]; then
  cp -r "${SCRIPT_DIR}/scripts" "${TARGET_PLUGIN_DIR}/"
fi
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
if [[ -x "/usr/share/omarchy/bin/omarchy-restart-shell" ]]; then
  /usr/share/omarchy/bin/omarchy-restart-shell || true
elif command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins || true
fi

echo "=== Antigravity 1.1 installed successfully! ==="
