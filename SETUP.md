# Hermes Specialists setup guide

You already have [Hermes Agent](https://hermes-agent.nousresearch.com/) installed and the default profile can chat. This guide installs the specialists on top of that: one Chief of Staff you talk to, plus critic, strategist, coder, and reviewer.

You talk to **chief**. Chief runs the specialists. You do not open the kanban board.

This pack ships no API keys, tokens, memories, or session history.

Stop at the first failed step. Do not skip the alive check.

## What you will have when this works

```text
you → chief (chat or Telegram)
        creates the work
        dispatcher inside chief's gateway (~60s) starts the specialist
        specialist finishes
        chief answers you
```

| Profile | Job |
|---|---|
| `chief` | Decompose, assign, report. Never implement. |
| `critic` | Kill bad plans. |
| `strategist` | Decide what is worth doing. |
| `coder` | Implement. Small verified deliverables. |
| `reviewer` | Kill bad code. |

Critic kills plans. Reviewer kills diffs. Do not merge them.

## Before you start

Confirm all three. If any fail, fix Hermes first. Do not install this pack yet.

1. `hermes` is on PATH.
2. `hermes --version` prints **0.19 or newer**.
3. Default can finish one chat:

```text
hermes -p default chat -q "Reply with the word alive."
```

You should see the word `alive`. If that command fails, the workers will boot on OpenRouter with no key and die.

On Windows, Hermes home is often `%LOCALAPPDATA%\hermes`, not `~\.hermes`. Clone this repo **outside** that folder.

## Step 1. Clone and install

**Windows: use PowerShell.** Do not run `./install.sh` in PowerShell (it no-ops). Do not run `./install.sh` in Git Bash on Windows either. That script only looks at `~/.hermes`, so a `%LOCALAPPDATA%\hermes` install will miss the home.

```powershell
git clone https://github.com/klawcode193/hermes-specialists.git
cd hermes-specialists
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**macOS / Linux:**

```bash
git clone https://github.com/klawcode193/hermes-specialists.git
cd hermes-specialists
./install.sh
```

What install does:

- Drops five profiles: chief, critic, strategist, coder, reviewer.
- Points kanban at chief (this writes `kanban.orchestrator_profile=chief` onto your **default** Hermes config; required).
- Copies default's working model and provider onto those profiles.
- Copies `auth.json` only when a profile does not already have one.

Reruns update existing profiles and keep your `config.yaml` (Telegram chat ids survive).

`-Force` / `--force` is not part of this path. It can replace a live chief config. See "If something breaks."

## Step 2. One gateway

Two running gateways means two dispatchers and a dead install. Stop default, then start chief.

```text
hermes -p default gateway stop
hermes profile use chief
hermes -p chief gateway start
```

`hermes profile use chief` changes your current profile. A bare `hermes` command now talks to chief. Use `hermes -p default` when you still need the old one.

A new profile is a new OS service. If it asks to install the gateway, Y.

On Windows, UAC opens in another window. Approve it, then run start again if this is down:

```text
hermes -p chief gateway status
```

## Step 3. Prove workers are alive

Required. Skip this and the first real card dies in about a minute with no log.

```text
hermes -p strategist chat -q "Reply with the word alive. Do not load skills."
```

You should see `alive`.

If it fails, do **not** add a new provider. Inherit the model default already uses:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-models.ps1
```

```bash
./setup-models.sh
```

Then run the strategist line again.

## Step 4. Talk to chief

```text
hermes -p chief chat
```

Talk only to chief. Do not run `hermes kanban`. Do not open the dashboard.

Telegram is optional and comes after the tests.

## Step 5. Three tests (stop at the first fail)

Coder has full coding tools. The only folder in test 3 is one you create in this step.

**Test 1. Identity.** Ask: `Who are you and what do you not do?`

Pass: it says it is Chief of Staff and it does not implement. Fail: it loads skills or starts writing code. You are still on default.

**Test 2. Hands.** Ask: `Read a file in my home folder and summarize it.`

Pass: chief refuses and offers to assign a specialist. Fail: it opens disk.

**Test 3. One card.** Create this folder, then paste the line below.

```powershell
mkdir $env:USERPROFILE\specialists-test
```

```bash
mkdir -p "$HOME/specialists-test"
```

Ask chief:

`Kill or keep $HOME/specialists-test (or %USERPROFILE%\specialists-test). Done when you give one recommendation. Do not touch any other path.`

Pass: chief creates the work, does not ask you to say "dispatch," and in about a minute a specialist-shaped answer comes back.

If a folder named `specialists-test` already exists from an earlier run, delete it first or the card is reviewing leftover files.

## Telegram (optional)

Do this only after the three tests pass.

One bot token can belong to one profile. The bot you already have is almost certainly **default**.

1. Do not rewire Telegram from inside the Telegram chat. Stopping that gateway kills the chat.
2. From a local terminal (not from Telegram):

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-telegram.ps1
```

```bash
./setup-telegram.sh
```

The script moves `TELEGRAM_BOT_TOKEN` from default `.env` to chief `.env` without printing it. It stops default only if default still holds the token. Then it starts chief.

3. Message the same bot. Send `/new`. That should be chief.

If a live chief (already has chat ids) says it has no kanban tools, merge this into the **existing** `profiles/chief/config.yaml`. Do not replace the file.

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

Skip this on the first install.

Chief has no file tools. On purpose. After the tests pass, you can give chief a short `memories/USER.md` and `memories/MEMORY.md` (Hermes caps: 1375 / 2200 characters). Paths yes. File contents no.

After you edit those files: `/new` in Telegram, or start a new chief chat. Restart the gateway only if it still sounds old.

## If something breaks

- Windows Hermes home is often `%LOCALAPPDATA%\hermes`, not `~\.hermes`.
- `./install.sh` in PowerShell does nothing. Use `install.ps1`.
- Git Bash on Windows should also use `install.ps1`, not `install.sh`.
- "Profile already exists" is a rerun. Update in place. Do not force-wipe chat ids.
- `-Force` / `--force` replaces shipped files and can replace `config.yaml`. Never use it on a live chief.
- "Gateway service is not installed" on `chief gateway start` means *chief's* service, not that Hermes is missing. Y to install. UAC is another process.
- Default gateway still running + chief gateway = two dispatchers. Stop default, or leave `dispatch_in_gateway` true on exactly one gateway.
- Default Telegram + chief Telegram = token lock. One bot. One chief.
- A session with no terminal cannot move `.env` files. Use the telegram setup script locally.
- Nested Grok Build or Cursor inside this pack is two chiefs. Pin a model on the coder profile instead.
- New profiles often default to OpenRouter with no key. Worker dies in about a minute, no kanban log. Run `setup-models.ps1` or `./setup-models.sh`. Do not add a new provider.

## Security

Public pack. Never commit `.env`, tokens, memories, chat ids, vault paths, or emails.

## License

MIT. Repo: https://github.com/klawcode193/hermes-specialists
