#!/usr/bin/env bash

set -euo pipefail

. /env.sh

log_error() {
  echo "$1" >&2
}

tmp_secret="$(mktemp)"
tmp_config="$(mktemp)"

cleanup() {
  rm -f "$tmp_secret" "$tmp_config"
}
trap cleanup EXIT

if curl -fsSL https://core.telegram.org/getProxySecret -o "$tmp_secret" \
  && curl -fsSL https://core.telegram.org/getProxyConfig -o "$tmp_config"; then
  mv "$tmp_secret" "$PROXY_SECRET_FILE"
  mv "$tmp_config" "$PROXY_CONFIG_FILE"
  chmod 0644 "$PROXY_SECRET_FILE" "$PROXY_CONFIG_FILE"
  echo "Updated Telegram proxy files."
else
  log_error "Failed to download Telegram proxy files."
  exit 1
fi
