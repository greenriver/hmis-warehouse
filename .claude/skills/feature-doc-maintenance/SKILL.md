---
name: feature-doc-maintenance
disable-model-invocation: true
description: Use when a PR has the comment "Docs that may need an update", the CI job "Docs that describe changed code" fails on frontmatter errors, someone says "docs are stale", or a code file listed in a doc's `sources:` frontmatter under docs/ or docs/features/ was edited and the doc needs checking.
---

# Feature doc maintenance

Docs in `docs/*.md` and `docs/features/**/*.md` may list code files in `sources:` frontmatter.
On a PR, CI comments with the docs whose listed sources changed, and with docs that list files that
no longer exist. The comment is advisory. The job fails only on frontmatter errors: invalid YAML, a
missing or malformed `sources:` list, or a cited line number.

**What a doc keeps (the Keep rule):** a fact stays only if an engineer or agent could not get it by
reading the code it names, or by searching the code MCP server. Keep: why/rationale, HUD or customer
rules, cross-system behavior (CAS, ETO, external HMISs, SQL Server), non-obvious interactions and
ordering, deprecated patterns still in the code and their replacement. Drop: key-file lists,
entry-point lists, driver catalogs, method-by-method walkthroughs, anything restating a class's own
code. Docs are human-readable, light on technical detail.

Commands run in Docker, never on the host:

```bash
docker compose run --rm --no-deps spec ruby bin/doc_sources check
docker compose run --rm --no-deps spec ruby bin/doc_sources affected <base>
```

The container has no git, so `affected` fails there. Run the diff on the host and match its output
to docs with grep (step 1).

## 1. Get the doc list

Use the PR comment. To rebuild it locally, find the base and the changed files on the host:

```bash
gh pr view <n> --json headRefName,baseRefName,baseRefOid
git branch --show-current
git diff --name-only --no-renames <base>...HEAD > <scratch>/changed.txt
grep -rlF --include='*.md' -f <scratch>/changed.txt docs
```

Confirm the checked-out branch is the PR's `headRefName` before editing. If it is not, stop and
tell the user which branch to check out; do not switch branches with uncommitted work present.

For frontmatter errors, run `check` (above) and fix what it prints: a non-empty `sources:` list of
file paths (quote values containing `: `, including dates), and method, constant, or class names
in place of cited line numbers.

For a source listed as no longer existing, find the new path
(`git log --follow --diff-filter=RD --oneline -- <source>`), update `sources` and any mention of
the old path in the doc body. If it was deleted, remove the facts that depended on it.

## 2. See what changed

For each listed source in the comment:

```bash
git log --oneline <base>..HEAD -- <source>
git diff <base> -- <source>          # includes uncommitted edits
```

Sources are never symlinks. If a listed path turns out to be a symlink, replace it with its target
(`readlink <source>`).

The diff tells you where to look first. It does not bound the review: a small diff can invalidate a
claim far from the hunk.

## 3. Verify the doc's facts against current code

Read each affected doc in full. Treat every concrete claim as a fact to check:

- Class, module, method, constant, scope, and permission names: confirm they exist (`grep`, read
  the file). Renames are the most common drift.
- Behavior statements ("X delegates to Y", "returns nil when...", "only runs for..."): read the code
  path and confirm.
- Deprecated-pattern and gotcha entries: confirm the pattern and its named replacement still exist
  as described.
- When the source is itself a doc, compare the doc's condensed rules to the source's current
  wording; added, removed, or reversed rules matter, rewording doesn't.

A fact is about names and behavior, not position. Code that moved or was reformatted leaves the fact
true. A named method, class, constant, or file that was renamed or removed makes it wrong, even if
the behavior survives under a new name.

Keep a short working list: claim, still true / wrong / new fact worth adding, evidence
(file:line). The line numbers are for your report; they never go into the docs.

## 4. Update the docs

Edit only what the evidence supports. Leave accurate text alone.

- If a change only affects facts derivable from code, the doc likely needs no edit. Report
  "verified, no change needed" with the reason.
- Fix wrong claims; remove claims about deleted code. Add a fact only if it passes the Keep rule.
- Never cite line numbers, line ranges, or commit SHAs, and don't paste code that restates an
  implementation detail. State behavior, not a snapshot of how it is written today.
- Update `sources` if the doc now depends on a new file or no longer on an old one. List files, not
  directories or globs, never a gitignored path or a symlink (list its target). Keep the list
  short: only files whose behavior the doc asserts.
- No bead ids, issue numbers, PR numbers, or branch names in the docs.
- If a doc should be split or a new doc written, say so and ask before restructuring.

## 5. Confirm and report

```bash
docker compose run --rm --no-deps spec ruby bin/doc_sources check    # must print "doc sources are valid"
git diff --stat docs
```

Don't commit. Report to the user, per changed source:

- which docs list it
- what changed in the source (one line)
- what was edited in each doc, or "verified, no change needed" with the reason
- anything uncertain that a human should look at
