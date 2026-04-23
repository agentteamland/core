# Version check (automatic, hook-driven)

## Who runs this

The **Claude Code harness** runs version checking automatically — not you. When `atl setup-hooks` has been configured (default on first install), two hooks fire in the background:

- `SessionStart` → `atl update --silent-if-clean` (every new session)
- `UserPromptSubmit` → `atl update --silent-if-clean --throttle=30m` (every message, throttled to once per 30m)

The hooks' output is captured by Claude Code and injected into your context. You see the result; you don't have to run the check yourself.

## What you see in your context

When something updated, you'll see one line per changed repo:

```
🔄 software-project-team 1.1.1 → 1.1.2 (auto-updated)
🔄 core 1.1.0 → 1.1.1 (auto-updated)
```

When a new `atl` binary release is available:

```
⬆  atl 0.1.4 → 0.1.5 available — run: brew upgrade atl
```

(The `atl` self-check runs at most once per 24h — it only talks to the GitHub releases API, not the cache.)

When nothing changed, you see nothing. That's the common case.

## How to use this information

- If you see a 🔄 line, the referenced repo's content on disk has been updated BEFORE your message was processed. Any agents / skills / rules you're about to use are already at the new version.
- If relevant to the user's request, mention the update briefly ("by the way, software-project-team just updated to 1.1.2 — notes are in the team's release"). Otherwise, proceed silently — the user doesn't need a status report for every minor bump.
- If you see a ⬆ atl-outdated line, surface it to the user at the end of your response: "Heads-up: a new atl is available; upgrade with `brew upgrade atl` when you get a minute." The binary upgrade isn't automatic (package-manager driven).

## What gets auto-updated

Every git repo under `~/.claude/repos/agentteamland/`:

- `core` — global rules + schemas
- `brainstorm` — global `/brainstorm` skill
- `rule` — global `/rule` + `/rule-wizard` skills
- `team-manager` — global `/team` skill
- Every installed team (`software-project-team`, `design-system-team`, user's own private teams, etc.)

All of these share the same pull mechanism: `git fetch origin main`, fast-forward `git pull` if behind, idempotent no-op if already current.

## What does NOT auto-update

- **The `atl` binary itself.** Managed by brew / scoop / winget, not by `atl update`. We show a ⬆ line when a newer release exists; the user runs the upgrade command in their own time.
- **Registry (`teams.json`).** Server-side. Every `atl install` / `atl search` hits it live — no local cache to stale.

## When the hook isn't installed

Some users skip the opt-in on first install, or run in a non-interactive context (CI, piped install). In that case no hooks are configured and no auto-update runs. They can:

- Run `atl update` manually whenever they want to sync
- Run `atl setup-hooks` to enable the automatic flow later
- Run `atl setup-hooks --remove` to disable it after enabling

Absence of auto-update doesn't break anything — it just means the user is responsible for periodic `atl update`.

## History — this used to be a Claude-side rule

Earlier versions of this file asked Claude to run git fetch/pull as part of every prompt. That worked but was unreliable — whether the check actually happened depended on Claude interpreting prose instructions consistently. Moving the behavior into a Claude Code hook made it deterministic: the harness runs it, no interpretation needed.

If you are running in an environment without `atl` installed or without hooks configured, the version-check flow degrades gracefully to "nothing happens" — no attempt to fake the behavior in prose.
