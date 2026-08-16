#!/usr/bin/env bash
# Install the hermes-factory roster onto an existing Hermes install.
# No secrets. Does not start the gateway.
# Idempotent: existing profiles are updated in place (config.yaml kept).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

die() { echo "error: $*" >&2; exit 1; }

command -v hermes >/dev/null 2>&1 || die "hermes is not on PATH. Install Hermes first, then rerun."

if [[ -n "${HERMES_HOME:-}" && -d "$HERMES_HOME" ]]; then
  :
elif [[ -d "${HOME}/.hermes" ]]; then
  HERMES_HOME="${HOME}/.hermes"
else
  die "no Hermes home at ~/.hermes. This pack assumes Hermes is already set up."
fi

PROFILES=(chief critic strategist coder reviewer)

describe_chief='Decomposes work onto the board. Assigns critic, strategist, coder, reviewer. Never implements. Reports results to the human.'
describe_critic='Kills bad plans. Finds hidden assumptions, failure modes, missing information, contradictions, and cheaper paths. Does not implement.'
describe_strategist='Decides what is worth doing and why. Recommendation first. Hands execution to a follow-up card. Does not implement.'
describe_coder='Implements the card. Small verified deliverables, tests, tight diffs. Requests review when the card says so.'
describe_reviewer='Kills bad code. Reviews diffs and tests. request_changes or approve. Does not rewrite the feature.'

echo "hermes-factory: installing roster into $HERMES_HOME"
echo

for name in "${PROFILES[@]}"; do
  src="$ROOT/profiles/$name"
  [[ -f "$src/distribution.yaml" ]] || die "missing $src/distribution.yaml"
  args=(profile install "$src" --name "$name" --alias -y)
  if [[ "$FORCE" == 1 ]]; then
    args+=(--force)
  fi
  echo "→ hermes ${args[*]}"
  if ! hermes "${args[@]}"; then
    if [[ "$FORCE" == 1 ]]; then
      die "install failed for $name even with --force"
    fi
    echo "   profile $name exists. Updating in place (keeps your config.yaml)."
    hermes profile update "$name" || die "update failed for $name"
  fi
done

echo
echo "→ writing kanban routing descriptions"
hermes profile describe chief --text "$describe_chief" || true
hermes profile describe critic --text "$describe_critic" || true
hermes profile describe strategist --text "$describe_strategist" || true
hermes profile describe coder --text "$describe_coder" || true
hermes profile describe reviewer --text "$describe_reviewer" || true

echo
echo "→ pointing the default config at chief as orchestrator"
hermes config set kanban.orchestrator_profile chief
hermes config set kanban.dispatch_in_gateway true
hermes config set kanban.auto_decompose true
hermes config set kanban.auto_subscribe_on_create true

echo
echo "→ hermes kanban init"
hermes kanban init || true


echo
echo "→ pinning workers to the model that already works on default"
provider="$(hermes -p default config get model.provider 2>/dev/null || true)"
model="$(hermes -p default config get model.default 2>/dev/null || true)"
if [[ -z "$provider" ]]; then provider="$(hermes config get model.provider 2>/dev/null || true)"; fi
if [[ -z "$model" ]]; then model="$(hermes config get model.default 2>/dev/null || true)"; fi
if [[ -n "$provider" || -n "$model" ]]; then
  echo "   source: provider=$provider model=$model"
  for name in "${PROFILES[@]}"; do
    [[ -n "$provider" ]] && hermes -p "$name" config set model.provider "$provider" || true
    [[ -n "$model" ]] && hermes -p "$name" config set model.default "$model" || true
    src_auth="$HERMES_HOME/auth.json"
    dst_auth="$HERMES_HOME/profiles/$name/auth.json"
    if [[ -f "$src_auth" && ! -f "$dst_auth" ]]; then
      cp "$src_auth" "$dst_auth"
      echo "   copied auth.json to $name (not printed)"
    fi
  done
else
  echo "   could not read default model. Set each profile with hermes -p <name> model"
fi

echo
echo "done."
echo
echo "Next:"
echo "  hermes profile use chief"
echo "  hermes -p chief gateway start"
echo "  Talk only to chief. Do not open the board."
echo "  Telegram: move TELEGRAM_BOT_TOKEN onto chief .env, stop default gateway."
