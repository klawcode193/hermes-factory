# hermes-specialists

A Chief of Staff plus four specialists for [Hermes Agent](https://hermes-agent.nousresearch.com/).

You talk to **chief**. Chief runs the specialists. You do not open the kanban board.

This repo ships no API keys, tokens, memories, or session history.

Walkthrough: [SETUP.md](SETUP.md) · [SETUP.pdf](SETUP.pdf)

## Prerequisite

1. `hermes` is on PATH.
2. `hermes --version` is **0.19 or newer**.
3. The **default** profile can finish one chat:

```text
hermes -p default chat -q "Reply with the word alive."
```

The installer copies that working model and provider onto the specialist profiles. If default cannot chat, workers boot on OpenRouter with no key and die. Fix Hermes first. Do not install this pack yet.

## First hour

Clone anywhere except inside the Hermes home (`~/.hermes` or `%LOCALAPPDATA%\hermes`).

**Windows (PowerShell):**

```powershell
git clone https://github.com/klawcode193/hermes-specialists.git
cd hermes-specialists
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Do not run `./install.sh` in PowerShell. It will no-op.

**macOS / Linux / Git Bash:**

```bash
git clone https://github.com/klawcode193/hermes-specialists.git
cd hermes-specialists
./install.sh
```

Reruns update existing profiles and keep your `config.yaml`.

Install also writes `kanban.orchestrator_profile=chief` onto your **default** Hermes config. That is required for the dispatcher. A bare `hermes` command still uses whichever profile `hermes profile use` last set.

### 1. One gateway

Stop the default gateway, or leave `dispatch_in_gateway` true on exactly one gateway. Two running gateways means two dispatchers and a dead install.

```text
hermes -p default gateway stop
hermes profile use chief
hermes -p chief gateway start
```

`hermes profile use chief` changes your current profile. Use `hermes -p default` when you still need the old one.

A new profile is a new OS service. If it asks to install the gateway, Y. On Windows, UAC opens in another window. Approve it, then start again if `hermes -p chief gateway status` is down.

### 2. Prove workers are alive

Required. Skip this and the first real card dies in about a minute with no log.

```text
hermes -p strategist chat -q "Reply with the word alive. Do not load skills."
```

If that fails, run `setup-models.ps1` (Windows) or `./setup-models.sh` (Unix). Do not add a new provider to "fix" it.

### 3. Talk

```text
hermes -p chief chat
```

Or message the Telegram bot after you move it. Talk only to chief. Do not run `hermes kanban`. Do not open the dashboard.

## Test (stop at the first fail)

Coder has full coding tools. The only folder in this test is one you just created.

1. Identity. `Who are you and what do you not do?` If it loads skills or implements, you are still on default.
2. Hands. `Read a file in my home folder and summarize it.` Chief must refuse and offer to assign a specialist.
3. One card. Make the folder, then ask chief for a kill/keep on that folder only, done-when: one recommendation.

```powershell
mkdir $env:USERPROFILE\specialists-test
```

```bash
mkdir -p "$HOME/specialists-test"
```

Then: `Kill or keep $HOME/specialists-test (or %USERPROFILE%\specialists-test). Done when you give one recommendation. Do not touch any other path.` Chief must create the work and not ask you to say "dispatch." Wait about a minute. A specialist-shaped answer comes back.

Pass: you stayed on chief, chief did not touch disk, nobody asked you to dispatch, a specialist answered.

## Telegram (optional)

One bot token can belong to one profile. The bot you already have is almost certainly **default**.

1. Do not rewire Telegram from inside the Telegram chat. Stopping that gateway kills the chat.
2. From a local terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-telegram.ps1
```

```bash
./setup-telegram.sh
```

The script moves `TELEGRAM_BOT_TOKEN` from default `.env` to chief `.env` without printing it. It stops default only if default still holds the token. Then it starts chief.

3. Message the same bot. `/new`. That should be chief.

If a **live** chief (already has chat ids) says it has no kanban tools, merge this into the existing `profiles/chief/config.yaml`. Do not replace the file.

```yaml
toolsets:
  - kanban
  - memory
  - clarify

platform_toolsets:
  cli:
    - kanban
    - memory
    - clarify
  telegram:
    - kanban
    - memory
    - clarify
```

`custom_toolsets.orchestrator` does nothing on Telegram. Name `kanban` on `platform_toolsets.telegram`.

## Binder (optional, later)

Chief has no file tools. On purpose. After the tests pass, give chief a short `memories/USER.md` and `memories/MEMORY.md` (Hermes caps: 1375 / 2200 chars). Paths yes. File contents no.

A first install works without a binder. Skip this until you want chief to remember your projects.

After editing memory files: `/new` in Telegram, or start a new chief chat. Restart the gateway only if it still sounds old.

## Roster

| Profile | Job |
|---|---|
| `chief` | Decompose, assign, report. Never implement. |
| `critic` | Kill bad plans. Assumptions, failure modes, cheaper paths. |
| `strategist` | Decide what is worth doing. Hand off execution. |
| `coder` | Implement. Small verified deliverables. |
| `reviewer` | Kill bad code. `request_changes` or approve. |

Critic kills plans. Reviewer kills diffs. Do not merge them.

## How a job runs

```text
you → chief (chief chat or Telegram)
        create work
        dispatcher (inside chief's gateway, ~60s) starts the assignee
        worker finishes / asks for review / blocks
        chief is notified
        chief answers you
```

## If something breaks

- Windows Hermes home is often `%LOCALAPPDATA%\hermes`, not `~\.hermes`.
- `./install.sh` in PowerShell does nothing. Use `install.ps1`.
- "Profile already exists" is a rerun. Update in place. Do not force-wipe chat ids.
- `-Force` / `--force` replaces shipped files and can replace `config.yaml`. Never use it on a live chief.
- "Gateway service is not installed" on `chief gateway start` means *chief's* service, not that Hermes is missing. Y to install. UAC is another process.
- Default gateway still running + chief gateway = two dispatchers. Stop default.
- Default Telegram + chief Telegram = token lock. One bot. One chief.
- A session with no terminal cannot move `.env` files. Use the telegram setup script locally.
- Nested Grok Build or Cursor inside this pack is two chiefs. Pin a model on the coder profile instead.
- New profiles often default to OpenRouter with no key. Worker dies in about a minute, no kanban log. Run the models setup script. Do not add a new provider.

Already installed and workers die? Do not `-Force`.

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-models.ps1
hermes -p strategist chat -q "Reply with the word alive. Do not load skills."
```

```bash
./setup-models.sh
hermes -p strategist chat -q "Reply with the word alive. Do not load skills."
```

## Security

Public on purpose. Never commit `.env`, tokens, memories, chat ids, vault paths, or emails.

## License

MIT
