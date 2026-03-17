#!/usr/bin/env bash

set -euo pipefail

. /env.sh
declare -i PROXY_STARTUP_TIMEOUT_SECONDS=30

die() {
  echo "$1" >&2
  exit 1
}

. /secrets.sh

require_public_host() {
  if [[ -z "$MTPROXY_PUBLIC_HOST" ]]; then
    die "MTPROXY_PUBLIC_HOST is required"
  fi
}

telegram_files_present() {
  [[ -s "$PROXY_SECRET_FILE" && -s "$PROXY_CONFIG_FILE" ]]
}

check_data_dir() {
  mkdir -p "$DATA_DIR"
}

check_telegram_files() {
  check_data_dir

  if [[ "$MTPROXY_AUTO_UPDATE_TELEGRAM_FILES" != "1" ]]; then
    return 0
  fi

  if /tg-config-updater.sh || telegram_files_present; then
    return 0
  fi

  die "Failed to download Telegram proxy files and no local copies exist."
}

require_local_telegram_files() {
  if [[ ! -s "$PROXY_SECRET_FILE" || ! -s "$PROXY_CONFIG_FILE" ]]; then
    die "Missing required ${PROXY_SECRET_FILE} or ${PROXY_CONFIG_FILE}."
  fi
}

start_proxy() {
  local args=(
    -p "$MTPROXY_STATS_PORT"
    -H "$MTPROXY_PORT"
    --aes-pwd "$PROXY_SECRET_FILE" "$PROXY_CONFIG_FILE"
    -M "$MTPROXY_WORKERS"
    -u nobody
  )
  local secret

  for secret in "${CLIENT_SECRETS[@]}"; do
    args+=( -S "$secret" )
  done

  if [[ -n "${MTPROXY_TAG:-}" ]]; then
    args+=( -P "$MTPROXY_TAG" )
  fi

  /mtproto-proxy "${args[@]}" &
  proxy_pid="$!"
}

# Probe a listening TCP socket by opening /dev/tcp/host/port
# and then closing it.
proxy_port_open() {
  if { exec 3<>"/dev/tcp/127.0.0.1/${MTPROXY_PORT}"; } 2>/dev/null; then
    exec 3<&-
    exec 3>&-
    return 0
  fi

  return 1
}

wait_for_proxy() {
  local started=0

  for ((attempt = 1; attempt <= PROXY_STARTUP_TIMEOUT_SECONDS; attempt++)); do
    if ! kill -0 "$proxy_pid" 2>/dev/null; then
      wait "$proxy_pid"
      exit $?
    fi
    if proxy_port_open; then
      started=1
      break
    fi
    sleep 1
  done

  if [[ "$started" == "1" ]]; then
    echo "MTProxy is reachable on ${MTPROXY_PORT}."
    print_proxy_links
    return 0
  fi

  echo "MTProxy did not open port ${MTPROXY_PORT}" \
       " within ${PROXY_STARTUP_TIMEOUT_SECONDS}s." >&2
  return 1
}

require_public_host
check_data_dir

if [[ "$MTPROXY_AUTO_UPDATE_TELEGRAM_FILES" == "1" ]]; then
  check_telegram_files
else
  require_local_telegram_files
fi

load_client_secrets
require_client_secrets
start_proxy
wait_for_proxy

wait "$proxy_pid"
