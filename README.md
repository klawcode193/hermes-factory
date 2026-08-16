# hermes-factory

A Chief of Staff plus four specialists for [Hermes Agent](https://hermes-agent.nousresearch.com/).

You talk to **chief**. Chief runs the factory. You do not open the kanban board.

This repo ships no API keys, tokens, memories, or session history.

## Prerequisite

Hermes v0.19+ is installed, on PATH, and the **default** profile can finish one chat. The installer copies that working model and provider onto the factory profiles. If default cannot chat, workers boot on OpenRouter with no key and die.

```text
hermes chat -q "Reply with the word alive."
```

If that fails, fix Hermes first. Do not install this pack yet.

## First hour

Clone anywhere except inside the Hermes home (`~/.hermes` or `%LOCALAPPDATA%\hermes`).

**Windows (PowerShell):**

```powershell
git clone https://github.com/klawcode193/hermes-factory.git
cd hermes-factory
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Do not run `./install.sh` in PowerShell. It will no-op.

**macOS / Linux / Git Bash:**

```bash
git clone https://github.com/klawcode193/hermes-factory.git
cd hermes-factory
./install.sh
```

Reruns are safe. Existing profiles are updated in place. Your `config.yaml` (including Telegram chat ids) is kept. `-Force` / `--force` can replace `config.yaml`. Do not force a live chief.

### Start chief

```text
hermes profile use chief
hermes -p chief gateway start
```

A new profile is a new OS service. If it asks to install the gateway, Y. On Windows, UAC opens in another window. Approve it, then start again if `hermes -p chief gateway status` is down. The default gateway you already had is a different service.

### Prove workers are alive

Do this before any real card.

```text
hermes -p strategist chat -q "Reply with the word alive. Do not load skills."
```

If that fails, run `setup-models.ps1` (Windows) or set each profile with `hermes -p <name> model` from the same provider default already uses. Do not add a new provider to "fix" it.

### Talk

```text
hermes -p chief chat
```

Or message the Telegram bot after you move it (below). Talk only to chief. Do not run `hermes kanban`. Do not open the dashboard.

## Test (stop at the first fail)

Do not test on a live production site.

1. Identity. `Who are you and what do you not do?` If it loads skills or implements, you are still on default.
2. Hands. `Read a file in my home folder and summarize it.` Chief must refuse and offer to assign a specialist.
3. One card. A small kill/keep or review with a named path and a done-when. Chief must create the work and not ask you to say "dispatch." Wait about a minute. A specialist-shaped answer comes back.

Pass: you stayed on chief, chief did not touch disk, nobody asked you to dispatch, a specialist answered.

## Telegram (optional)

One bot token can belong to one profile. The bot you already have is almost certainly **default**.

1. Do not rewire Telegram from inside the Telegram chat. Stopping that gateway kills the chat.
2. On Windows, from a local PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-telegram.ps1
```

That moves `TELEGRAM_BOT_TOKEN` from default `.env` to chief `.env` without printing it, stops default, starts chief.

On macOS / Linux, do the same by hand: stop default, move the `TELEGRAM_BOT_TOKEN=` line from `$HERMES_HOME/.env` to `$HERMES_HOME/profiles/chief/.env`, start chief.

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
- "Gateway service is not installed" on `chief gateway start` means *chief's* service, not that Hermes is missing. Y to install. UAC is another process.
- Default Telegram + chief Telegram = token lock. One bot. One chief.
- A session with no terminal cannot move `.env` files. Use `setup-telegram.ps1` locally.
- Nested Grok Build or Cursor inside the factory is two chiefs. Pin a model on the coder profile instead.
- New profiles often default to OpenRouter with no key. Worker dies in about a minute, no kanban log. Run `setup-models.ps1`. Do not add a new provider.

Already installed and workers die? Do not `-Force`.

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-models.ps1
hermes -p strategist chat -q "Reply with the word alive. Do not load skills."
```

## Security

Public on purpose. Never commit `.env`, tokens, memories, chat ids, vault paths, or emails.

## License

MIT
