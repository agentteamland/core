# Learning capture (inline marker protocol)

## Who runs this

**You (the agent) drop markers inline as you speak.** The Claude Code harness runs `atl learning-capture` at session end (and on `PreCompact`) and processes whatever markers the scan finds — you do not call a separate tool for each learning.

Markers are the "save it if you see it" mechanism. They are cheap to drop (~40 tokens) and free to ignore when nothing interesting happened.

## What counts as a learning moment

Any of these, when they happen during a conversation, is a learning moment:

- **Bug fix** — a real bug was reproduced and fixed
- **Decision** — a choice was made between alternatives (JWT vs session, Redis vs memcached, 7d vs 15d refresh)
- **Pattern** — an approach turned out to be clean and reusable
- **Anti-pattern** — something was tried, failed, and we know why
- **Discovery** — a non-obvious fact about the system, library, or external service
- **Convention** — "from now on, we always / never do X"

Routine Q&A, file lookups, and mechanical edits are NOT learning moments. Don't mark every response.

## How to mark

Drop an HTML comment in your response text when a learning moment occurs. The comment is invisible in rendered output but preserved in the transcript the hook scans.

```
<!-- learning
topic: auth-refresh
kind: decision
doc-impact: readme
body: 7-day JWT refresh chosen because we want long sessions; user logs in once a week max.
-->
```

**Fields:**

- `topic` — kebab-case, one concept (auth-refresh, redis-ttl, build-pipeline). Becomes the wiki page name.
- `kind` — one of `bug-fix | decision | pattern | anti-pattern | discovery | convention`
- `doc-impact` — one of `none | readme | docs | both | breaking`. Default `none` when unsure.
- `body` — one to three sentences. **Always include the WHY.** A 6-month-old "we chose X" without reasoning is useless.

Multiple markers per response are fine when multiple learnings happen. Do NOT bundle unrelated learnings into one marker — each topic deserves its own.

## What happens after

When the session ends (or `PreCompact` fires), `atl learning-capture` scans the transcript:

- **0 markers** → silent exit. Zero tokens, zero cost. The common case.
- **1+ markers with `doc-impact: none`** → `/save-learnings` runs on the marked regions only (not the whole transcript). Wiki pages update, agent-memory appends, journal gets a summary.
- **1+ markers with `doc-impact` ≠ `none`** → in addition, draft README / doc-site changes are prepared and surfaced for review. **No auto-commit to public repos.**

You (and the user) see output like this injected at session close or the next turn:

```
📝 learning-capture: 3 markers processed
  • wiki: caching.md updated, auth.md updated, rate-limiting.md (new)
  • memory: api-agent-memory.md +3 entries
  • docs-impact: 1 README draft awaiting review (core/README.md)
```

## Why inline markers, not a tool call?

A tool call per learning would double token cost and slow conversation. Inline markers are embedded in text you were going to produce anyway. A grep-level hook finds them at ~0 cost; the AI-heavy save-learnings work only runs when markers exist — boring sessions stay free.

## When to skip

- Purely conversational turns (greetings, clarifications, status questions)
- Reading a file and summarizing its contents (no decision, no discovery)
- Routine edits where nothing surprising happened
- A learning already captured by a recent marker in the same session (don't duplicate)

## Dual with docs-sync

The `doc-impact` field ties this rule to [docs-sync](docs-sync.md). If you mark `doc-impact: readme` or `docs`, docs-sync takes over at session end to prepare the actual README / doc-site changes. You don't need to update docs manually in the same turn — marking is enough, as long as you do mark.

## When the hook isn't installed

Markers are harmless when no hook processes them — they're HTML comments, invisible in rendered output, inert as text. The capture habit is still valuable (markers are legible even to a human reader of the transcript). For automatic processing, the user runs `atl setup-hooks`.

## History

This used to be proposed as "Claude should proactively save learnings at the end of every session" (see [memory-system.md](memory-system.md) "End of Conversation Routine"). That worked but was unreliable — whether Claude remembered depended on interpretation of prose instructions. Moving to inline markers + a harness-owned hook makes it deterministic AND cheaper: we only process what was explicitly flagged, instead of re-analyzing the whole transcript.
