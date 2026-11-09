---
name: feature-doc-maintenance
disable-model-invocation: true
description: Use when the CI job "Documented sources match the manifest" fails, someone pastes a failed run/job link for it, says "docs are stale", "restamp the docs", or "source changed since last stamp", or edits a code file listed in a doc's `sources:` frontmatter under docs/ or docs/features/ and needs the doc brought back in line.
---

# Feature doc maintenance

Docs in `docs/*.md` and `docs/features/**/*.md` may list code files in `sources:` frontmatter.
`docs/doc_sources_manifest.json` records a SHA-256 of each source. CI runs `bin/doc_sources check`
and fails when a source changed but was not re-stamped.

The check exists so docs get re-read when their code changes. A bare `stamp` silences it without
doing that, so the job is: verify, fix the docs, then stamp.

**What a doc keeps (the Keep rule):** a fact stays only if an engineer or agent could not get it by
reading the code it names, or by searching the code MCP server. Keep: why/rationale, HUD or customer
rules, cross-system behavior (CAS, ETO, external HMISs, SQL Server), non-obvious interactions and
ordering, deprecated patterns still in the code and their replacement. Drop: key-file lists,
entry-point lists, driver catalogs, method-by-method walkthroughs, anything restating a class's own
code. Docs are human-readable, light on technical detail.

Commands run in Docker, never on the host:

```bash
docker compose run --rm --no-deps spec ruby bin/doc_sources check
docker compose run --rm --no-deps spec ruby bin/doc_sources stamp
```

## 1. Get the failure list

From a URL like `https://github.com/greenriver/hmis-warehouse/actions/runs/<run_id>/job/<job_id>?pr=<n>`:

```bash
gh run view <run_id> --log-failed > <scratch>/doc_sources_ci.log
gh pr view <n> --json headRefName,baseRefName
git branch --show-current
```

Confirm the checked-out branch is the PR's `headRefName` before editing. If it is not, stop and
tell the user which branch to check out; do not switch branches with uncommitted work present.

Then reproduce locally with `check` (above). The local run is the source of truth. If CI failed but
the local check passes, CI likely ran on the PR merge commit, so the drift came from `main`. Tell
the user to merge or rebase `main` and re-run; don't guess at changes you can't see.

Group the problems by message:

| Message | Meaning | Action |
|---|---|---|
| `source X changed since last stamp` | File edited | Steps 2-4 |
| `source X does not exist` | File renamed or deleted | Find the new path (`git log --follow --diff-filter=RD --oneline -- X`), update `sources` and any mention of the old path in the doc body; if deleted, remove the facts that depended on it |
| `source X is not in docs/doc_sources_manifest.json` | Doc newly lists a source | Verify the doc's claims about X (step 3), then stamp |
| `X is not listed by any doc` | Orphan manifest entry | Stamp only |
| ``frontmatter missing `sources` `` / `` `sources` must be a non-empty list of file paths `` / `frontmatter is not valid YAML` / `frontmatter must be a mapping` | Malformed frontmatter | Fix it: a non-empty `sources:` list of file paths (quote values containing `: `, including dates) |
| `cites line number ...` | A fact is anchored to a line | Replace it with the method, constant, or class name at that line (step 4) |

## 2. Map changed sources to docs, and see what changed

For each changed source, find every doc that lists it (the check prints one line per doc, but grep
to be sure):

```bash
grep -rln --include='*.md' -- '<source path>' docs
```

Every stamp rewrites the manifest, so the last commit that touched it is the baseline:

```bash
base=$(git log -1 --format=%H -- docs/doc_sources_manifest.json)
git log --oneline "$base"..HEAD -- <source>
git diff "$base" -- <source>          # includes uncommitted edits
```

If the diff is empty or unrelated to the source's current state (e.g. the manifest was stamped on
another branch), fall back to `git diff $(git merge-base HEAD origin/main) -- <source>`.

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

- If a change only affects facts derivable from code, the doc likely needs no edit. Say so in the
  report and stamp.
- Fix wrong claims; remove claims about deleted code. Add a fact only if it passes the Keep rule.
- Never cite line numbers, line ranges, or commit SHAs, and don't paste code that restates an
  implementation detail. State behavior, not a snapshot of how it is written today; stable wording
  means the next stamp failure is about a real change.
- Update `sources` if the doc now depends on a new file or no longer on an old one. List files, not
  directories or globs, never a gitignored path or a symlink (list its target). Keep the list
  short: only files whose behavior the doc asserts.
- No bead ids, issue numbers, PR numbers, or branch names in the docs.
- If a doc should be split or a new doc written, say so and ask before restructuring.

## 5. Stamp and confirm

```bash
docker compose run --rm --no-deps spec ruby bin/doc_sources stamp
docker compose run --rm --no-deps spec ruby bin/doc_sources check    # must print "doc sources are in sync"
git diff --stat docs
```

Don't commit. Report to the user, per changed source:

- which docs list it
- what changed in the source (one line)
- what was edited in each doc, or "verified, no change needed" with the reason
- anything uncertain that a human should look at

Reviewers push back on a manifest change with no doc change, so the "verified, no change needed"
lines are what let a stamp-only diff through review.
