---
name: save-learnings
description: "Save learnings at the end of a conversation. Automatically writes to project memory, wiki (mandatory), team repo, and journal. Can auto-create new skills, agent children files, and rules when patterns are discovered. Supports --from-markers mode for hook-driven invocation. No confirmation needed — acts autonomously."
argument-hint: "[agent-name] [--from-markers]"
---

# /save-learnings Skill

## Purpose

Called at the end of each conversation (manually, or automatically by the `atl learning-capture` hook when inline `<!-- learning -->` markers are present). Persists everything learned — patterns, anti-patterns, discoveries, process improvements. Also **auto-creates new skills, children files, and rules** when repeating patterns are detected. No user confirmation needed — acts autonomously and reports what was done.

## Two invocation modes

**Manual mode (user-initiated):** `/save-learnings [agent-name]` — full transcript is analyzed for learnings, every category scanned.

**Marker mode (hook-initiated):** `/save-learnings --from-markers` — only the content inside `<!-- learning ... -->` blocks in the transcript is processed. This is cheaper (less context to re-analyze) and is the default path when `atl setup-hooks` drives end-of-session capture. See [learning-capture rule](../../rules/learning-capture.md) for the marker format.

In marker mode, skip steps 1-2 (agent detection + analysis) and jump straight to categorizing the marker bodies.

## Flow

### 1. Identify the Active Agent

If an agent name is given as an argument, use it. If not, infer from context which agent was working in this conversation (which files were edited, which directories were touched).

### 2. Analyze the Conversation

Scan for learnings in these categories:

- **Patterns that worked** — "We did it this way and it worked well"
- **Patterns that didn't work** — "We tried this but it caused problems"
- **Emerging patterns** — "Not certain yet but there's this tendency"
- **Process improvements** — "This step was missing / unnecessary in the agent's workflow"
- **New rules** — "From now on we should always / never do this"
- **Repeating workflows** — "We did this same sequence of steps again" → **auto-create skill or children**
- **New conventions** — "We established a naming/structure convention" → **auto-create rule**

### 3. Auto-Save (No Confirmation)

**Do NOT ask for confirmation.** Analyze, decide, save, report. The user should see a summary of what was done, not be asked what to do.

Decision logic for each learning:

| Learning Type | Where It Goes | Auto-Create |
|--------------|---------------|-------------|
| Project-specific pattern | `.claude/agent-memory/{agent}-memory.md` | — |
| General pattern (all projects) | Team repo agent/children file | — |
| Repeating workflow (done 2+ times) | Team repo | ✅ New children file |
| New convention/standard | Team repo or project rules | ✅ New rule (via /rule) |
| Reusable procedure | Project `.claude/skills/` | ✅ New skill |
| Bug fix / known issue | Team repo `known-issues.md` | ✅ Append to known-issues |

### 4. Write to Project Memory

File: `.claude/agent-memory/{agent-name}-memory.md`

Create if it doesn't exist. Append with date heading:

```markdown
## {Date}

### What Worked
- {learning} — Evidence: {what happened}

### What Didn't Work
- {learning} — Evidence: {what happened}

### Emerging Patterns
- {observation} — Not yet verified
```

### 5. Write to Team Repo (General Learnings)

The agent file is edited via symlink — updates `~/.claude/repos/agentteamland/{team}/agents/{agent}/...`.

Types of updates:
- **Existing children file** → append the new learning to the relevant section
- **New children file** → create if the topic doesn't fit any existing children (e.g., a completely new pattern area)
- **Known issues** → append to `children/known-issues.md`
- **Agent.md knowledge base** → add summary + link if new children file was created

### 6. Auto-Create New Artifacts

#### Auto-Create Children File
When a new topic area emerges that doesn't fit existing children:

```bash
# Create new children file in team repo
echo "{content}" > ~/.claude/repos/agentteamland/{team}/agents/{agent}/children/{topic}.md
```

Update agent.md's Knowledge Base section with summary + detail link.

#### Auto-Create Rule
When a convention or standard is established, invoke the `/rule` skill internally:

```
/rule --team {the convention in natural language}
```

This writes a structured rule to the team repo (or project rules if project-specific).

#### Auto-Create Skill
When a repeating workflow is identified (same sequence of steps done 2+ times), create a skill:

```
.claude/skills/{skill-name}/skill.md
```

With frontmatter (name, description) and the step-by-step workflow captured from the conversation.

### 7. Update Project Wiki — MANDATORY

For **every** learning processed, determine its topic and update the relevant wiki page. This step is not optional — the wiki is how Claude (and the user) sees current truth in future sessions, and skipping it loses the benefit.

```
Learning: "Redis TTL should be 30 min not 15"
  → Topic: redis-cache
  → Wiki page: .claude/wiki/redis-cache.md
  → Action: UPDATE (replace "15 min" with "30 min" if it exists, or add new entry)
```

- If `.claude/wiki/` exists → update relevant pages, create new pages for topics that don't have one yet
- If `.claude/wiki/` doesn't exist → run `/wiki init` first (creates scaffold), then proceed
- Update `index.md` with any new pages
- Update cross-references between related pages
- Wiki pages reflect **current truth** — if a fact changed, old info is replaced, not appended (see [wiki skill](../wiki/skill.md) for page format and rules)

### 8. Sync Docs (for doc-impact markers)

When processing in marker mode, scan each marker's `doc-impact` field:

| `doc-impact` value | Action |
|---|---|
| `none` (or missing) | Skip — no doc work needed |
| `readme` | Prepare a draft `README.md` update in the affected repo(s) |
| `docs` | Prepare a draft update to the doc site (e.g., `repos/docs/site/...`) including bilingual mirrors if present |
| `both` | Prepare drafts for both README and doc site |
| `breaking` | Prepare drafts for README, doc site, AND a `CHANGELOG.md` / migration-note entry |

Drafts are **not auto-pushed to public repos**. They are either:

- Applied locally in the workspace so the user can review the diff before committing
- Or, if the workspace is read-only in this context, surfaced as a bulleted "proposed changes" list in the final report

See [docs-sync rule](../../rules/docs-sync.md) for what qualifies as user-facing and how bilingual mirrors are handled.

If in manual mode (no markers), skip this step — manual `/save-learnings` focuses on knowledge capture; docs updates happen in the turn the change is made (Phase 1 of docs-sync).

### 9. Write to Journal

File: `.claude/journal/{date}_{agent-name}.md`

```markdown
---
date: {date}
agent: {agent-name}
tags: [learning, {categories}]
---

## Summary
{What was done in this conversation}

## Learnings
- {learning list}

## Auto-Created
- {list of new files/skills/rules created, if any}

## Notes for Other Agents
- {cross-cutting information if any}
```

### 10. Push Team Repo

If any team repo files were modified (children, rules, agent.md, known-issues) — after wiki, docs-sync, and journal all wrote their outputs:

```bash
cd ~/.claude/repos/agentteamland/{team-name}
git add -A
git commit -m "learn: {short summary of all learnings}"
git push
```

**Project-local changes** (`.claude/wiki/`, `.claude/agent-memory/`, `.claude/journal/`) are committed in the project repo if one exists, but pushing them is the project's responsibility, not this skill's.

**Doc-impact drafts** prepared in step 8 are **never auto-committed to public repos** — they wait for review.

### 11. Report to User

Show a brief summary of everything that was done:

```
📝 Learnings saved:
  • Markers processed: 3 (2 decision, 1 bug-fix)
  • Project memory: 3 entries added
  • Wiki: 2 pages updated (redis-cache.md, auth.md)
  • Wiki: 1 new page created (rate-limiting.md)
  • Team repo: 1 children file updated (caching-strategy.md)
  • New rule created: "batch-imports-use-bulk-insert" (team)
  • Journal entry written
  • Docs drafts: 1 README draft in core/ awaiting review
  • Team repo pushed (v1.3.1)
```

One block, no interaction, conversation continues (or ends).

## Important Rules

1. **NO confirmation asked.** Analyze → save → report. User sees the result, not a question.
2. **Auto-create is safe.** New children files, rules, and skills don't break anything — they add knowledge.
3. **Git push is automatic.** Team repo changes are committed and pushed immediately.
4. **Sensitive information filter.** Passwords, tokens, secrets, API keys are NEVER written anywhere.
5. **Append for memory/journal, replace for wiki.** Memory and journal are historical (append-only). Wiki is current truth (old facts get replaced). Doc drafts (step 8) are never auto-committed to public repos.
6. **De-duplicate.** Check if a similar learning already exists before adding. Don't create duplicate children or rules.
7. **Skill creation threshold.** Only create a skill when the same workflow pattern appears 2+ times. One-time procedures go to memory, not skills.
8. **Rule creation criteria.** Only create a rule when a clear "always do X" or "never do Y" convention is established. Observations go to memory, conventions go to rules.
