---
name: save-learnings
description: "Save learnings at the end of a conversation. Automatically writes to project memory, team repo, and journal. Can auto-create new skills, agent children files, and rules when patterns are discovered. No confirmation needed — acts autonomously."
argument-hint: "[agent-name]"
---

# /save-learnings Skill

## Purpose

Called at the end of each conversation (or triggered by the memory-system rule automatically). Persists everything learned — patterns, anti-patterns, discoveries, process improvements. Also **auto-creates new skills, children files, and rules** when repeating patterns are detected. No user confirmation needed — acts autonomously and reports what was done.

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

The agent file is edited via symlink — updates `~/.claude/repos/mkurak/{team}/agents/{agent}/...`.

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
echo "{content}" > ~/.claude/repos/mkurak/{team}/agents/{agent}/children/{topic}.md
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

### 7. Push Team Repo

If any team repo files were modified (children, rules, agent.md, known-issues):

```bash
cd ~/.claude/repos/mkurak/{team-name}
git add -A
git commit -m "learn: {short summary of all learnings}"
git push
```

### 8. Write to Journal

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

### 9. Report to User

Show a brief summary of everything that was done:

```
📝 Learnings saved:
  • Project memory: 3 entries added
  • Team repo: 1 children file updated (caching-strategy.md)
  • Team repo: 1 new children file created (batch-processing.md)
  • New rule created: "batch-imports-use-bulk-insert" (team)
  • Journal entry written
  • Team repo pushed (v1.1.0)
```

One block, no interaction, conversation continues (or ends).

## Important Rules

1. **NO confirmation asked.** Analyze → save → report. User sees the result, not a question.
2. **Auto-create is safe.** New children files, rules, and skills don't break anything — they add knowledge.
3. **Git push is automatic.** Team repo changes are committed and pushed immediately.
4. **Sensitive information filter.** Passwords, tokens, secrets, API keys are NEVER written anywhere.
5. **Append, never overwrite.** Existing files get new content appended, never replaced.
6. **De-duplicate.** Check if a similar learning already exists before adding. Don't create duplicate children or rules.
7. **Skill creation threshold.** Only create a skill when the same workflow pattern appears 2+ times. One-time procedures go to memory, not skills.
8. **Rule creation criteria.** Only create a rule when a clear "always do X" or "never do Y" convention is established. Observations go to memory, conventions go to rules.
