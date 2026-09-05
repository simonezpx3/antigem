#!/usr/bin/env bash
# Anti/Gem (Antigravity 1.1) — One-click Uninstaller for Omarchy Linux
set -euo pipefail

TARGET_PLUGIN_DIR="${HOME}/.config/omarchy/plugins/simonez.antigem"
TARGET_BIN_DIR="${HOME}/.local/bin"
CACHE_DIR="${HOME}/.cache/omarchy/antigem"
SHELL_CONFIG="${HOME}/.config/omarchy/shell.json"

echo "=== Uninstalling Anti/Gem (Antigravity 1.1) ==="

# 1. Remove plugin via Omarchy CLI if available, or delete directory directly
if command -v omarchy >/dev/null 2>&1; then
  echo "-> Removing plugin via Omarchy CLI..."
  omarchy plugin remove simonez.antigem 2>/dev/null || true
fi

if [[ -d "${TARGET_PLUGIN_DIR}" ]]; then
  echo "-> Deleting plugin directory: ${TARGET_PLUGIN_DIR}..."
  rm -rf "${TARGET_PLUGIN_DIR}"
fi

# 2. Remove companion launcher
if [[ -f "${TARGET_BIN_DIR}/omarchy-launch-antigravity" ]]; then
  echo "-> Removing launcher: ${TARGET_BIN_DIR}/omarchy-launch-antigravity..."
  rm -f "${TARGET_BIN_DIR}/omarchy-launch-antigravity"
fi

# 3. Remove cache directory
if [[ -d "${CACHE_DIR}" ]]; then
  echo "-> Removing cache data: ${CACHE_DIR}..."
  rm -rf "${CACHE_DIR}"
fi

# 4. Remove from shell.json if present
if [[ -f "${SHELL_CONFIG}" ]] && command -v jq >/dev/null 2>&1; then
  if jq -e '.bar.layout.right[] | select((.id? == "simonez.antigem") or (. == "simonez.antigem"))' "${SHELL_CONFIG}" >/dev/null 2>&1; then
    echo "-> Removing simonez.antigem from shell.json..."
    tmp_json=$(mktemp)
    jq '.bar.layout.right = [.bar.layout.right[] | select((.id? != "simonez.antigem") and (. != "simonez.antigem"))]' "${SHELL_CONFIG}" > "${tmp_json}" && mv "${tmp_json}" "${SHELL_CONFIG}"
  fi
fi

# 5. Restart Omarchy Shell
if command -v omarchy >/dev/null 2>&1; then
  echo "-> Restarting Omarchy Shell..."
  omarchy restart shell || true
fi

echo "=== Anti/Gem uninstalled successfully! ==="
