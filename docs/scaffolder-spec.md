# Scaffolder Spec

> Standard interface for team-scoped `/create-new-project` skills.

Starting with AgentTeamLand Karar #9 (2026-04-17), **scaffolders are team-scoped**, not global. Every team that exposes a `/create-new-project` skill should follow this spec so users get a consistent UX regardless of which team they installed.

## Why a spec?

Different teams will build very different scaffolders (.NET + Docker stack vs. Next.js SaaS vs. Python + Jupyter). But the **shape** of the user experience should be the same: "ask some questions, build the skeleton, start the stack, verify, commit." A shared shape lets users move between teams without relearning the UX.

## Skill location

```
{team-repo}/skills/create-new-project/skill.md
```

And in `team.json`:

```json
{
  "skills": [
    { "name": "create-new-project", "description": "..." }
  ]
}
```

When a user runs `/team install <team>`, `create-new-project` is symlinked into the project's `.claude/skills/` automatically.

## The five phases

Every team's `/create-new-project` MUST walk through these phases in order:

### Phase 1 — Gather information

Use the `AskUserQuestion` tool to collect what you need to scaffold. Typical questions:

- Project name (often passed as an argument — skip asking if already provided)
- Which applications / modules / features to include
- Any deployment target or infrastructure toggles
- Port conflicts / offsets
- License choice
- Any stack-specific toggles (SaaS? Multi-tenant? Language? Framework version?)

**Rules:**
- Keep questions focused; 4-6 is plenty for most scaffolders
- Provide sensible defaults; "Recommended" label on the top option
- If the user passed an argument that answers a question, skip asking it

### Phase 2 — Create project structure

Write every file the new project needs. For large scaffolds, delegate to specialized sub-agents in parallel — one per major concern (API, frontend, infra, mobile, etc.).

**Checklist:**
- Root files (`README.md`, `.gitignore`, `.dockerignore`, language-specific lockfiles)
- Project configuration (`CLAUDE.md`, `.mcp.json`, `.env.example`)
- `.claude/` project directory (`agents/`, `skills/`, `rules/`, `docs/`, `brain-storms/`, `wiki/`, `agent-memory/`, `journal/`, `backlog.md`)
- Source tree (all the files that make the app work)
- Container / deploy configuration if applicable

### Phase 3 — Build and start (optional, stack-dependent)

If your stack has a build step (compile, `npm install`, `docker compose up`), run it:

- Compile and verify there are no build errors
- Start local services
- Wait for health checks to pass (30-60 seconds is typical)

Skip this phase for scaffolders that don't need a build (pure template projects, docs-only skeletons).

### Phase 4 — System verification (MANDATORY)

**Invoke `/verify-system` as a Skill tool call.** This is non-negotiable.

```
Skill(skill="verify-system")
```

The team provides its own `/verify-system` (see `verify-system-spec.md`) that knows how to test the stack end-to-end. The scaffolder must:

1. Call the skill with the Skill tool (not inline bash)
2. Execute every check the skill describes (the skill IS the script — you are the runtime)
3. **Show the user the final verification report block** before moving on
4. If anything fails: diagnose root cause, fix it, re-invoke the skill, show the new report

Do not proceed to Phase 5 until verification is green and the user has seen the report.

### Phase 5 — Git initialize

```bash
cd {project-directory}
git init                    # skip if already a git repo
git add -A
git commit -m "feat: initial project setup with full infrastructure"
```

If the directory was already a git repo (e.g. user pre-cloned an empty remote), skip `git init` and just commit on top of the existing history.

## Cross-cutting requirements

### Docker-first

Projects should default to Docker for every runtime dependency (database, cache, queue, search, etc.). Local SDK installs are for language toolchains only (Flutter, Node for Vite, Xcode for iOS). This keeps "clone → compose up → running" a 5-minute workflow.

### Idempotent

Re-running `/create-new-project` on a partially-created project should either refuse cleanly ("this directory is not empty") or be safe to continue. Don't leave half-written state.

### Seed data

Include a `seed.sql` (or language equivalent) with an admin user and any minimum data needed to log in and test the stack. Use fixed UUIDs for seeds — they make verification scripts reproducible.

### Environment variables

Never commit real secrets. `.env.example` with placeholders goes in git; `.env` with real dev values is gitignored. The scaffolder generates `.env` from `.env.example` with reasonable dev defaults.

### Port offsets

If the stack binds many ports, offer a `+10000` offset option so the project doesn't conflict with other locally-running stacks.

## Reporting

When the scaffolder finishes, emit a single summary block:

```
🎯 ExampleApp scaffolded.

Stack: .NET 9 API + Flutter mobile + React admin panel
Infrastructure: 16 Docker services (postgres, rabbitmq, redis, elasticsearch, kibana, mailpit, minio, adminer, redis-ui, 5 .NET hosts, React Vite dev server)
Verification: /verify-system ALL PASS (4 levels, 7 pipelines)

Test credentials: admin@example-app.local / Admin123!

Next: open the URLs from CLAUDE.md, start building features.
```

## Example implementations

- [`software-project-team`](https://github.com/agentteamland/software-project-team/tree/main/skills/create-new-project) — .NET 9 + Flutter + React + full Docker stack (reference implementation)

If you're building a new team, copy the structure from the reference and adapt Phase 1-3 to your stack.
