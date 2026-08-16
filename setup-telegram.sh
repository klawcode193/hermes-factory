#!/usr/bin/env bash
# Move TELEGRAM_BOT_TOKEN from default Hermes onto chief.
# Does not print the token. Run in a local terminal, not in the Telegram chat.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

if [[ -n "${HERMES_HOME:-}" && -d "$HERMES_HOME" ]]; then
  :
elif [[ -d "${HOME}/.hermes" ]]; then
  HERMES_HOME="${HOME}/.hermes"
else
  die "no Hermes home found"
fi

default_env="$HERMES_HOME/.env"
chief_dir="$HERMES_HOME/profiles/chief"
chief_env="$chief_dir/.env"

[[ -d "$chief_dir" ]] || die "chief profile missing at $chief_dir. Run ./install.sh first."

echo "hermes home: $HERMES_HOME"
hermes profile list

default_line=""
if [[ -f "$default_env" ]]; then
  default_line="$(grep -E '^[[:space:]]*TELEGRAM_BOT_TOKEN=' "$default_env" || true)"
fi
chief_has=0
if [[ -f "$chief_env" ]] && grep -Eq '^[[:space:]]*TELEGRAM_BOT_TOKEN=' "$chief_env"; then
  chief_has=1
fi

if [[ -z "$default_line" && "$chief_has" == 1 ]]; then
  echo "token already on chief only. Leaving default gateway alone."
elif [[ -z "$default_line" && "$chief_has" == 0 ]]; then
  die "no TELEGRAM_BOT_TOKEN in default .env or chief .env"
else
  echo "stopping default gateway (it still holds the token)"
  hermes -p default gateway stop
  touch "$chief_env"
  grep -Ev '^[[:space:]]*TELEGRAM_BOT_TOKEN=' "$chief_env" > "$chief_env.tmp" || true
  printf '%s\n' "$default_line" >> "$chief_env.tmp"
  mv "$chief_env.tmp" "$chief_env"
  grep -Ev '^[[:space:]]*TELEGRAM_BOT_TOKEN=' "$default_env" > "$default_env.tmp" || true
  mv "$default_env.tmp" "$default_env"
  echo "token moved (value not printed)"
fi

hermes -p chief gateway start
hermes profile use chief
hermes -p chief gateway status
echo "Message the same Telegram bot. That should be chief."
