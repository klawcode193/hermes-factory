# hermes-factory

A Chief of Staff plus four specialists for [Hermes Agent](https://hermes-agent.nousresearch.com/).

You talk to **chief**. Chief runs the factory. You do not open the kanban board.

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

## Install

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

Reruns are safe. If a profile already exists, the script updates it and **keeps your `config.yaml`** (Telegram chat ids survive). `-Force` / `--force` overwrites shipped files and can replace `config.yaml`. Don't use force on a live chief that already has chat ids.

Then:

```powershell
hermes profile use chief
hermes -p chief gateway start
```

New profile = new OS service. If it asks to install the gateway service, Y. On Windows, UAC opens in another window. Approve it, then start again if `hermes -p chief gateway status` is down. The default gateway you already had is a different service.

Talk to chief. Do not run `hermes kanban` yourself. Do not open the dashboard.

## Telegram

The bot you already have is almost certainly the **default** profile. Two profiles cannot share one token.

1. Do not rewire Telegram from inside the Telegram chat. Stopping that gateway kills the chat.
2. Run locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-telegram.ps1
```

That moves `TELEGRAM_BOT_TOKEN` from default `.env` to chief `.env` without printing it, stops default, starts chief.

3. Message the same bot. `/new`. That should be chief.

If chief says it has no kanban tools, merge this into *existing* `profiles/chief/config.yaml`. Do not replace the file.

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

## Binder, not the vault

Chief has no file tools. On purpose. Give chief a one-page `memories/USER.md` and `memories/MEMORY.md` (Hermes caps: 1375 / 2200 chars). Paths yes. File contents no. Let the old default profile distill your context into those two files, then stop using default.

In flight should be a short pay list, not every prototype on disk. Reviewer kills diffs. Chief unblocks humans. Do not merge those jobs.

After editing memory files: `/new` in Telegram. Restart the gateway only if it still sounds old.

## Test (stop at the first fail)

Do not test on a live production site.

1. Identity. `Who are you and what do you not do?` If it loads skills or implements, you are still on default.
2. Hands. `Open the vault and summarize my dashboard.` Chief must refuse and offer to card a specialist.
3. One card. A small kill/keep or review with a named path and a done-when. Chief must `kanban_create` and not ask you to say "dispatch." Wait about a minute for the dispatcher tick. A specialist-shaped answer comes back.

Pass: Telegram stays chief, no disk, no "say dispatch," an answer from the specialist.

## Footguns we already hit

- Windows Hermes home is often `%LOCALAPPDATA%\hermes`, not `~\.hermes`.
- `./install.sh` in PowerShell does nothing. Use `install.ps1`.
- "Profile already exists" is a rerun. Update in place. Don't force-wipe chat ids.
- "Gateway service is not installed" on `chief gateway start` means *chief's* service, not that Hermes is missing. Y to install. UAC is another process.
- Default Telegram + chief Telegram = token lock. One bot. One chief.
- A session with no terminal cannot move `.env` files. Use `setup-telegram.ps1`.
- Nested Grok Build or Cursor inside the factory is two chiefs. Pin a model on the coder profile instead.

## How a job runs

```
you → chief (Telegram or chief chat)
        kanban_create
        dispatcher (inside chief's gateway, ~60s) spawns the assignee
        worker completes / request_review / block
        chief notify+wake
        chief answers you
```

## Security

Public on purpose. Never commit `.env`, tokens, memories, chat ids, vault paths, or emails.

## License

MIT
