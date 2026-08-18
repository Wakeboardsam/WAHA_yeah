#!/bin/sh
set -eu

CONFIG_PATH="/data/options.json"

if [ ! -f "${CONFIG_PATH}" ]; then
  echo "[ERROR] Home Assistant options file is missing; WAHA cannot start securely." >&2
  exit 1
fi

WAHA_API_KEY="$(node -e '
  const fs = require("fs");
  const options = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  process.stdout.write(String(options.waha_api_key || ""));
' "${CONFIG_PATH}")"

if [ -z "${WAHA_API_KEY}" ]; then
  echo "[ERROR] Set waha_api_key in the add-on Configuration tab before starting WAHA." >&2
  exit 1
fi

export WAHA_API_KEY
exec /entrypoint.sh
