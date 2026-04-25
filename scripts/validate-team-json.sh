#!/usr/bin/env bash
# validate-team-json.sh — pre-push validation for team.json against the official schema.
#
# Run this before EVERY git push that touches a team.json. The CI runs the same
# (stricter) ajv check on the PR; catching length/pattern errors locally avoids
# a failed PR check + a follow-up "trim description" commit.
#
# Usage:
#   ./scripts/validate-team-json.sh                    # validates team.json in cwd
#   ./scripts/validate-team-json.sh path/to/team.json  # validates a specific file
#
# Background — this exists because we hit the maxLength=200 description limit
# THREE times in production (commits d430d13, 6630157, b044eba). The schema is
# clear, the CI is clear; we just kept forgetting to check locally. Hence: a
# script. One command, no excuse.

set -euo pipefail

TARGET="${1:-team.json}"
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEMA="${CORE_DIR}/schemas/team.schema.json"

if [[ ! -f "$TARGET" ]]; then
  echo "✗ Target not found: $TARGET" >&2
  exit 2
fi

if [[ ! -f "$SCHEMA" ]]; then
  echo "✗ Schema not found: $SCHEMA" >&2
  echo "  (This script must live inside ~/.claude/repos/agentteamland/core/scripts/)" >&2
  exit 2
fi

# Quick length-only check (always available — pure Python stdlib).
python3 - "$TARGET" <<'PYEOF'
import json, re, sys
target = sys.argv[1]

try:
    d = json.load(open(target))
except Exception as e:
    print(f"✗ JSON parse error in {target}: {e}", file=sys.stderr); sys.exit(1)

errs = []

def check_desc(label, s, maxlen=200, minlen=None):
    if not isinstance(s, str):
        errs.append(f"  ✗ {label}: not a string"); return
    n = len(s)
    if n > maxlen:
        errs.append(f"  ✗ {label}: {n} chars > {maxlen} (schema maxLength)")
    elif minlen is not None and n < minlen:
        errs.append(f"  ✗ {label}: {n} chars < {minlen} (schema minLength)")

check_desc("description (top-level)", d.get("description", ""), 200, 10)
for a in d.get("agents", []):
    check_desc(f"agents.{a.get('name','?')}.description", a.get("description", ""))
for s in d.get("skills", []):
    check_desc(f"skills.{s.get('name','?')}.description", s.get("description", ""))
for r in d.get("rules", []):
    check_desc(f"rules.{r.get('name','?')}.description", r.get("description", ""))

if not re.match(r"^[a-z][a-z0-9-]{1,38}[a-z0-9]$", d.get("name", "")):
    errs.append(f"  ✗ name pattern: {d.get('name','')!r} (must be kebab-case 3-40)")
if not re.match(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", d.get("version", "")):
    errs.append(f"  ✗ version pattern: {d.get('version','')!r} (must be MAJOR.MINOR.PATCH)")

for kw in d.get("keywords", []):
    if not isinstance(kw, str) or not (1 <= len(kw) <= 40):
        errs.append(f"  ✗ keyword: {kw!r} (must be 1-40 chars)")

if errs:
    print(f"✗ {target} — {len(errs)} schema violation(s):")
    for e in errs: print(e)
    sys.exit(1)
else:
    print(f"✓ {target} — quick check passed (all description lengths within bounds)")
PYEOF

# Optional: full ajv validation if ajv-cli is on PATH (matches what CI runs).
if command -v ajv >/dev/null 2>&1; then
  ajv validate -c ajv-formats -s "$SCHEMA" -d "$TARGET" --spec=draft2020 --strict=false
  echo "✓ $TARGET — ajv full-schema validation passed"
elif command -v npx >/dev/null 2>&1; then
  if npx --no-install ajv-cli --version >/dev/null 2>&1; then
    npx --no-install ajv-cli validate -c ajv-formats -s "$SCHEMA" -d "$TARGET" --spec=draft2020 --strict=false
    echo "✓ $TARGET — ajv (via npx) full-schema validation passed"
  else
    echo "ℹ ajv-cli not installed; quick check covers description lengths but not full schema."
    echo "  Install with: npm install -g ajv-cli ajv-formats   (one-time)"
  fi
else
  echo "ℹ Neither ajv nor npx found; quick check only. Install ajv-cli for full validation:"
  echo "    npm install -g ajv-cli ajv-formats"
fi
