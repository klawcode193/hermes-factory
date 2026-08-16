#!/usr/bin/env bash
# Copy the working default model/provider onto specialist profiles.
# Does not print keys. Does not overwrite an existing per-profile auth.json.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

if [[ -n "${HERMES_HOME:-}" && -d "$HERMES_HOME" ]]; then
  :
elif [[ -d "${HOME}/.hermes" ]]; then
  HERMES_HOME="${HOME}/.hermes"
else
  die "no Hermes home found"
fi

PROFILES=(chief critic strategist coder reviewer)

provider="$(hermes -p default config get model.provider 2>/dev/null || true)"
model="$(hermes -p default config get model.default 2>/dev/null || true)"
if [[ -z "$provider" ]]; then provider="$(hermes config get model.provider 2>/dev/null || true)"; fi
if [[ -z "$model" ]]; then model="$(hermes config get model.default 2>/dev/null || true)"; fi
if [[ -z "$provider" && -z "$model" ]]; then
  die "could not read default model. Run hermes -p default model first."
fi

echo "source: provider=$provider model=$model"
for name in "${PROFILES[@]}"; do
  [[ -n "$provider" ]] && hermes -p "$name" config set model.provider "$provider"
  [[ -n "$model" ]] && hermes -p "$name" config set model.default "$model"
  src_auth="$HERMES_HOME/auth.json"
  dst_auth="$HERMES_HOME/profiles/$name/auth.json"
  if [[ -f "$src_auth" && ! -f "$dst_auth" ]]; then
    cp "$src_auth" "$dst_auth"
    echo "copied auth.json to $name (not printed)"
  else
    echo "set $name (existing auth.json left alone)"
  fi
done

echo
echo "Prove it:"
echo '  hermes -p strategist chat -q "Reply with the word alive. Do not load skills."'
