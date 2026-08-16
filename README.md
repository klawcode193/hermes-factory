# hermes-factory

A Chief of Staff plus four specialists for [Hermes Agent](https://hermes-agent.nousresearch.com/).

You talk to **chief**. Chief runs the factory. You do not open the kanban board.

This is a fleet pack, not a costume in one prompt. Each role is a real Hermes profile with its own `SOUL.md`. Coordination is the shared board. Specialists do not DM each other.

Requires a working Hermes install (v0.19+). This repo ships no API keys, tokens, memories, or session history.

## Roster

| Profile | Job |
|---|---|
| `chief` | Decompose, assign, report. Never implement. |
| `critic` | Kill bad plans. Assumptions, failure modes, cheaper paths. |
| `strategist` | Decide what is worth doing. Hand off execution. |
| `coder` | Implement. Small verified deliverables. |
| `reviewer` | Kill bad code. `request_changes` or approve. |

Critic kills plans. Reviewer kills diffs. Do not merge them.

## What this is not

- Not a group chat. Workers cannot see sibling cards.
- Not `delegate_task(profile="coder")`. Maintainers rejected that. Kanban is the supported path.
- Not A2A ping-pong on one machine. Official same-machine advice is the board. A2A exists in 0.20 for cross-process/machine work and caps ping-pong at 5 turns.

## Install

On a machine that already has Hermes working. Clone the repo anywhere except inside `~/.hermes`.

**Windows (PowerShell):**

```powershell
git clone https://github.com/klawcode193/hermes-factory.git
cd hermes-factory
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**macOS / Linux / Git Bash:**

```bash
git clone https://github.com/klawcode193/hermes-factory.git
cd hermes-factory
./install.sh
```

The script:

1. Installs the five profiles from `profiles/*` via `hermes profile install`
2. Writes routing descriptions so the decomposer can assign work
3. Sets `kanban.orchestrator_profile=chief` on the default config
4. Runs `hermes kanban init`
5. Prints the one command you run next

Then:

```bash
hermes profile use chief
hermes gateway start
chief chat
```

Talk to chief like a normal assistant. Do not run `hermes kanban` yourself. Do not open the dashboard. If you are looking at columns, chief failed.

`./install.sh --force` or `install.ps1 -Force` overwrites existing profiles of the same names. Memories and `.env` stay put (Hermes installer rule).

## After install, you still do these yourself

Hermes already works on the machine, so models and keys already exist. Still:

1. **Start exactly one gateway** and leave it up. The dispatcher lives inside it. Without it, cards sit in `ready` forever. `hermes gateway install` if you want it to survive reboot.
2. **Talk only to `chief`.** `hermes profile use chief` so plain `hermes chat` hits chief. Or `chief chat`.
3. **Do not give chief file/terminal tools.** The shipped `config.yaml` already locks chief to `kanban`, `memory`, and `clarify`. If you later run `hermes tools` on chief and turn coding back on, you have one guy in a meeting with himself.
4. **Worker models.** Cheap models on critic/coder/reviewer/strategist. Frontier on chief. Edit each profile with `coder config set model.default <your-cheap-model>` etc. Do not put keys in this repo.
5. **Human decisions.** When a worker blocks on money, a repo, or a real fork, chief should ask you in chat, then unblock the card itself. That is being CEO, not running kanban.
6. **One dispatcher.** If you start a gateway per profile, only one may have `kanban.dispatch_in_gateway: true`. The install sets it on the default config. Leave the others false.

## How a job actually runs

```
you → chief chat
        chief kanban_create / auto-decompose
        dispatcher (gateway, ~60s tick) spawns the assignee profile
        worker: kanban_show → work → complete | request_review | block
        chief gets notify+wake
        chief answers you
```

Shared decisions go in every child card body. Workers cannot see siblings. If two cards must agree on a file format, chief picks it once and stamps both cards.

`delegate_task` is fine *inside* a card for a 2-minute helper. Do not raise `max_spawn_depth` and call it a company. Depth 3 × 3-wide is 27 agents.

## Updating

```bash
cd hermes-factory && git pull
./install.sh --force
# or, per profile:
hermes profile update chief
hermes profile update critic
hermes profile update coder
hermes profile update reviewer
hermes profile update strategist
```

Updates replace SOUL and shipped config. Your `.env`, memories, and sessions stay.

## Repo layout

```
profiles/chief|critic|coder|reviewer|strategist/
  distribution.yaml    # hermes profile install manifest
  SOUL.md              # identity
  config.yaml          # tool defaults, no secrets
install.sh             # fleet installer
```

Each profile is a valid Hermes distribution. You can install one:

```bash
hermes profile install ./profiles/coder --alias
```

## Security

Public on purpose. Nothing secret belongs here.

Never commit: `.env`, `auth.json`, API keys, bot tokens, `memories/`, `sessions/`, `state.db`, logs, private repo URLs, machine paths, personal emails.

The Hermes installer also strips those paths even if someone screws up. That protects installers, not the git history. `.gitignore` is the author-side lock.

If you fork this and add keys, make that fork private before the first commit.

## License

MIT
