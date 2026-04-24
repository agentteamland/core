# Team-repo maintenance (governance)

## Who runs this

**You (the agent).** Whenever you change a file inside `~/.claude/repos/agentteamland/{team}/` (team repo cache) or any other cached public repo, these steps apply. The rule covers the discipline gap that existed before branch protection was added to all public repos on 2026-04-24.

Branch protection is the **safety net** — it refuses direct commits to `main` on every public repo in the `agentteamland/` org. This rule is the **method**: how to produce a clean change that satisfies the safety net AND is useful to the next maintainer reading the git log.

## When this applies

Any time you modify a file in a cached team repo or global repo (core, brainstorm, rule, team-manager, software-project-team, design-system-team, starter-extended, cli, docs, registry, create-project, workspace, .github). NOT:

- Your own local project's `.claude/` (that's project memory, not shared)
- `homebrew-tap` / `scoop-bucket` / `winget-pkgs` (goreleaser-managed, direct-push allowed for the release pipeline)

## Four sabit adım

### 1. Bump `team.json` version (or `internal/config.Version` for the CLI)

Follow semver strictly:

| Bump | When | Example |
|---|---|---|
| **Patch** (0.4.1 → 0.4.2) | Bug fix, no API change, behavior restored to advertised | `fix(dst-new-ds): Q3 cap` |
| **Minor** (0.4.2 → 0.5.0) | New skill / agent / rule / command, backward-compatible | `feat(core): new rule learning-capture` |
| **Major** (0.4.2 → 1.0.0) | Breaking: removed/renamed command, incompatible config, behavior change users depend on | `feat(cli)!: rename atl install-team → atl install` |

For the CLI, version lives in `internal/config/config.go` (ldflags override at build time via goreleaser tag). For teams, version lives in `team.json`.

**Never** ship a behavior change without a version bump — it silently breaks `atl update`'s "X → Y" notification, defeating the whole update pipeline.

### 2. Conventional commit format

```
<type>(<scope>): <one-line summary under 70 chars>

<body — WHY the change, not WHAT (diff shows the what)>
<context — which project / session revealed the need>

<footer — co-author, issue refs, breaking-change notes>
```

Types: `fix`, `feat`, `docs`, `chore`, `style`, `refactor`, `test`, `perf`. Add `!` after type for breaking: `feat(cli)!: …`.

Scope is the sub-module being changed (agent name, skill name, CLI command, repo area).

### 3. "Discovered via" context in the body

When a fix to a shared repo was found while working on a different project, **always** surface that context:

```
Discovered while scaffolding a design system for WalkingForMe.
The bug is not project-specific; every project running /dst-new-ds
hits the same wall.
```

This audit trail lets future-you (or another maintainer) understand the motivation without having to reconstruct it from memory. The team repo git log becomes self-documenting.

### 4. PR flow (default, enforced by branch protection)

All public `agentteamland/` repos require a pull request to merge to `main`. Direct pushes are refused by branch protection. So:

```bash
cd ~/.claude/repos/agentteamland/{team}
git checkout -b <fix|feat|chore>/<short-description>
# … make changes, bump version …
git add <files>
git commit -m "<conventional message>"
git push -u origin <branch-name>
gh pr create --title "<type>(<scope>): <summary>" --body "<see PR body template below>"
```

**PR body template:**

```markdown
## Summary
<What changed and why — 2-4 bullet points>

## Discovered via
<Which project / session / scenario revealed this>

## Version bump
<version: X.Y.Z → X.Y.Z+1> (patch | minor | major — reason)

## Test plan
- [ ] <how to verify the fix works>
- [ ] <regression check>
```

Surface the PR URL to the user. They review on GitHub and click merge. For solo maintainer flow, approvals are not required (count: 0) — the PR exists as **ceremony + audit trail**, not as external gate.

## Escape hatches

### Admin bypass (emergency only)

Branch protection allows admin to push directly when `enforce_admins` is false (our default). Use this only when:

- Release-pipeline-breaking issue blocks `brew upgrade atl` / `scoop install atl`
- A revert must land within minutes to stop a public regression

When using this, still:
- Bump version
- Use conventional commit
- Follow up with a retrospective: `chore(postmortem): ...` commit or issue

### Trivial direct commit

Some changes are too small for PR ceremony — fixing a typo, re-running `gofmt`, correcting a broken link. For these, you *can* create a one-file PR with title `chore: <trivial-thing>` and self-merge instantly. **You cannot direct-push** (branch protection refuses) but the minimal PR is cheap.

## What this rule does NOT cover

- **Private project repos** — your own project's git workflow is up to you. This rule is specifically for `agentteamland/` public repos.
- **Release-pipeline repos** (`homebrew-tap`, `scoop-bucket`, `winget-pkgs`) — goreleaser auto-pushes; branch protection is intentionally not applied.
- **Tag-based releases** — when tagging `cli v0.2.1`, the tag push triggers goreleaser. No PR needed for tag creation itself (it points at an already-merged commit on main).

## Related

- [learning-capture.md](learning-capture.md) — the sibling rule for inline marker protocol
- [docs-sync.md](docs-sync.md) — the sibling rule for proactive doc updates
- [memory-system.md](memory-system.md) — 4-layer knowledge model (where learnings get categorized as project vs. general — general → team repo, which this rule then governs how to ship)

## History

Before 2026-04-24, team-repo writes via `/save-learnings` could land directly on `main` with an ad-hoc commit message. This let real bug fixes ship quickly but also meant version bumps were frequently forgotten (breaking `atl update`'s diff notifications) and commit-message discipline depended on whoever happened to be at the keyboard.

On 2026-04-24 Mesut added branch protection to every public repo in the org and requested a principled workflow; this rule is that workflow. Direct push is enforcement-refused; PR ceremony is lightweight (no external approvals needed for solo maintainer) but mandatory — ensuring every team-repo change has a version bump, a conventional message, and a "Discovered via" context.
