#!/usr/bin/env bash
# Install the hermes-factory roster onto an existing Hermes install.
# No secrets. Does not start the gateway. Does not open the board.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

die() { echo "error: $*" >&2; exit 1; }

command -v hermes >/dev/null 2>&1 || die "hermes is not on PATH. Install Hermes first, then rerun."

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
[[ -d "$HERMES_HOME" ]] || die "no Hermes home at $HERMES_HOME. This pack assumes Hermes is already set up."

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
    die "install failed for $name (rerun with --force to replace an existing profile)"
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
echo "done."
echo
echo "Next (you, once):"
echo "  hermes profile use chief"
echo "  hermes gateway start"
echo "  chief chat"
echo
echo "Talk to chief. Do not open the board."
echo "Pin a cheap model on workers if chief is on a frontier model:"
echo "  coder config set model.default <cheap-model>"
echo "  critic config set model.default <cheap-model>"
echo "  reviewer config set model.default <cheap-model>"
echo "  strategist config set model.default <cheap-model>"
