# Memory, Journal & Wiki System Rules

## Three-Layer Knowledge

### Project Memory (project-specific)
**Location:** `.claude/agent-memory/{agent-name}-memory.md`

Each project can have its own memory file for each agent. This file stores what was learned in that project. The agent reads this file at the start of a conversation.

**Rules:**
- The agent should read its own memory file at the start of a conversation (if it exists)
- Updated only via `/save-learnings` (manual editing is also possible)
- Project-based — different projects have different memories
- Format: date-headed, categorized (what worked / what didn't work / emerging)

### Team Knowledge Base (global)
**Location:** `~/.claude/repos/agentteamland/{team}/agents/{agent}.md`

The agent's knowledge that applies across all projects. Rarely changes but learnings from any project can be added here as well.

**Rules:**
- Updated when "all projects" is selected via `/save-learnings`
- Automatic git commit + push after update
- This file is accessed via symlink from `~/.claude/agents/`

## Journal (cross-agent sharing)

**Location:** `.claude/journal/{date}_{agent-name}.md`

Information sharing between agents. When an agent discovers something, it writes to the journal; other agents read it in subsequent conversations.

**Rules:**
- Every agent can read the journal
- Every agent can write to the journal under its own name
- Journal files are never deleted (historical record)
- Date-based file name: `2026-04-13_api-agent.md`
- Journal is different from brainstorm files — journal contains short notes, brainstorm contains long discussions

## Project Wiki (current truth)

**Location:** `.claude/wiki/{topic}.md`

The project's living knowledge base. Unlike memory (historical) or docs (static decisions), wiki reflects **current truth** — pages are updated when facts change, cross-referenced, and periodically linted for staleness.

**Rules:**
- Organized by topic, not by date (one page per concept)
- Updated from `<!-- learning -->` markers via `/save-learnings` (driven by session-end hook when `atl setup-hooks` is installed; manual via `/wiki ingest` or `/save-learnings` otherwise)
- Pages reflect what is true NOW — old info is replaced, not appended
- Cross-referenced: related pages link to each other
- `index.md` auto-maintained as table of contents
- Bootstrap: run `/wiki init` in a project without `.claude/wiki/` to scaffold it
- Lint with `/wiki lint` periodically

**Difference from other layers:**
| Layer | Purpose | Updates | Style |
|-------|---------|---------|-------|
| Memory | Historical record (what happened) | Append-only | Date-based |
| Journal | Inter-agent signals | Append-only | Date-based |
| Docs | Finalized brainstorm decisions | Rarely changes | Topic-based, static |
| **Wiki** | **Current truth** | **Replace/update** | **Topic-based, living** |

## Agent Startup Routine

At the start of every conversation, the agent should read the following files (if they exist):

1. Its own agent file (from team, via symlink)
2. **Project wiki pages relevant to its domain:** `.claude/wiki/` (read pages matching agent's area)
3. Project memory: `.claude/agent-memory/{agent-name}-memory.md`
4. Recent journal entries: `.claude/journal/` (last 5-10 entries)
5. Project-specific rules: `.claude/docs/coding-standards/{app}.md`

**Wiki reading strategy:** Agent does NOT read all wiki pages. It reads `index.md` first, then only pages relevant to the current task or its domain (e.g., API Agent reads auth, caching, database pages — not flutter or react pages).

## End of Conversation Routine — now hook-driven

Capture at session end is no longer a prose-instruction "remember to save" asked of the agent. The mechanism moved to inline markers + a harness-owned hook:

- **During conversation:** when you identify a learning moment, drop a `<!-- learning -->` marker. See [learning-capture.md](learning-capture.md) for the exact format.
- **At session end / PreCompact:** `atl learning-capture` scans the transcript, runs `/save-learnings` only on marked regions, and prepares doc-impact drafts.
- **When a change is user-facing:** in the same turn, also update the matching README / doc-site page. See [docs-sync.md](docs-sync.md).

This replaces the earlier "ask the user at session end" dance — the hook is deterministic, cheaper (zero cost when no markers exist), and doesn't rely on Claude remembering an unstructured prose rule.

If the hook is not installed (`atl setup-hooks` not run), markers still get captured into the transcript but are not processed automatically. The user can run `/save-learnings` manually at any time.
