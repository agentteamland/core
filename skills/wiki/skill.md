---
name: wiki
description: "Project knowledge base — living, cross-referenced, always current. Ingest new knowledge, query existing, lint for staleness. Powered by Karpathy's LLM Wiki pattern."
argument-hint: "<ingest|query|lint> [topic or question]"
---

# /wiki Skill

## Purpose

Maintains a living knowledge base for the project. Unlike memory (append-only historical notes) or docs (static decision records), the wiki is **actively maintained** — pages are updated when knowledge changes, cross-references are kept current, stale information is cleaned up.

The wiki answers: "What is the current truth about X in this project?"

## Location

```
.claude/wiki/
├── index.md                    ← Auto-maintained table of contents
├── {topic-1}.md                ← Knowledge pages (kebab-case)
├── {topic-2}.md
└── ...
```

## Three Modes

### `ingest` Mode

**Usage:** `/wiki ingest` (no argument needed)

Scans all project knowledge sources and updates wiki pages:

**Sources scanned:**
1. `.claude/agent-memory/*.md` — agent learnings
2. `.claude/journal/*.md` — inter-agent notes
3. `.claude/docs/*.md` — finalized decisions from brainstorms
4. `.claude/brain-storms/*.md` (completed only) — decision context
5. Recent conversation context — what was just discussed/built

**Process:**
1. Read all sources
2. For each piece of knowledge, determine the topic (e.g., "caching", "authentication", "order-management")
3. If wiki page exists for that topic → **update** (merge new info, resolve contradictions, keep latest truth)
4. If no wiki page exists → **create** new page
5. Update cross-references (backlinks between related pages)
6. Update `index.md` with new/changed pages

**Page format:**

```markdown
# {Topic Title}

> Last updated: {date}
> Sources: [agent-memory](../agent-memory/api-agent-memory.md), [brainstorm](../brain-storms/auth-design.md)

## Summary
{2-3 sentence overview of this topic in the project}

## Current State
{What is true RIGHT NOW — not history, not plans, just current reality}

## Key Decisions
{Important decisions made about this topic, with brief reasoning}

## Patterns & Rules
{Established patterns, conventions, rules for this topic}

## Known Issues
{Current problems or limitations}

## Related
- [{related-topic-1}]({related-topic-1}.md)
- [{related-topic-2}]({related-topic-2}.md)
```

**Important:** Wiki pages reflect **current truth.** If old memory says "we use pattern X" but later memory says "pattern X caused problems, switched to Y" — the wiki page says "we use Y" (not both).

---

### `query` Mode

**Usage:** `/wiki query how does caching work in this project?`

1. Read `index.md` to find relevant pages
2. Read those pages
3. Synthesize an answer from wiki content
4. Cite which wiki pages the answer came from

This is useful when:
- New developer (or new Claude session) needs to understand a topic
- You forgot how something was decided/implemented
- You want a quick refresher before making changes

---

### `lint` Mode

**Usage:** `/wiki lint`

Health check for the entire wiki:

**Checks performed:**
1. **Stale pages** — last updated > 30 days ago, source files have changed since → flag for review
2. **Contradictions** — two pages say conflicting things → flag for resolution
3. **Orphan pages** — page exists but no other page references it → suggest connections
4. **Missing pages** — topic referenced in another page but no page exists → suggest creation
5. **Duplicate topics** — two pages cover the same topic → suggest merge
6. **Index sync** — index.md matches actual files in wiki/ → fix if out of sync

**Output:**
```
Wiki Health Report:
──────────────────────────
📊 Total pages: 12
✅ Healthy: 9
⚠️  Stale (>30 days): 2 (caching-patterns.md, email-setup.md)
❌ Contradiction found: auth.md says "15min token" but jwt-config.md says "30min token"
🔗 Orphan: database-indexes.md (no incoming links)
📝 Missing: "rate-limiting" referenced in api-endpoints.md but no page exists
──────────────────────────

Fixing automatically...
✅ index.md synced
✅ Created rate-limiting.md (stub)
⚠️  Review needed: auth.md vs jwt-config.md contradiction
⚠️  Review needed: 2 stale pages
```

Auto-fixable issues are fixed silently. Contradictions and stale content are reported for human review.

---

## Integration with Other Systems

### /save-learnings → Wiki

When `/save-learnings` runs, it also updates relevant wiki pages:

```
Learning: "Redis cache TTL should be 30 min, not 15"
  → agent-memory: append historical note
  → wiki/caching-patterns.md: UPDATE "TTL is 30 minutes" (replace old "15 minutes")
```

### Agent Startup → Wiki

Agents read relevant wiki pages at session start (per memory-system rule). Agent doesn't read ALL pages — only those related to its domain:
- API Agent → pages about api patterns, database, auth, caching
- Flutter Agent → pages about ui patterns, state management, navigation
- Selection is based on page topics matching agent's responsibility area

### /brainstorm done → Wiki

When a brainstorm completes, its decisions are ingested into the wiki automatically.

---

## Wiki Page Lifecycle

```
New knowledge discovered (conversation, brainstorm, learning)
    ↓
Determine topic
    ↓
Page exists?
├── Yes → Update page (merge, resolve contradictions, update date)
└── No → Create new page (from template)
    ↓
Update cross-references (backlinks)
    ↓
Update index.md
```

## Important Rules

1. **Wiki = current truth.** Not history, not plans. What is true RIGHT NOW.
2. **Update, don't append.** If a fact changes, the old version is replaced, not kept alongside.
3. **Cross-reference always.** Every page should link to related pages. Orphans are flagged by lint.
4. **Auto-maintained.** Humans rarely edit wiki directly. It's maintained by /save-learnings, /brainstorm done, and /wiki ingest.
5. **Agent-readable.** Pages are structured for both human and AI consumption — clear sections, no ambiguity.
6. **Topic-based, not date-based.** Unlike journal (date-based) or memory (date-based), wiki is organized by topic. One page per concept.
7. **Lint regularly.** Run `/wiki lint` periodically (monthly or when something feels off).
