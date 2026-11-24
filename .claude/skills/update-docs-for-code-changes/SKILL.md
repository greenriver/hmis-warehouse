---
name: update-docs-for-code-changes
disable-model-invocation: true
description: Use when a PR has the comment "Docs that may need an update", the CI job "Docs that describe changed code" fails on frontmatter errors, someone says "docs are stale", or a code file listed in a doc's `sources:` frontmatter under docs/ or docs/features/ was edited and the doc needs checking.
---

# Update docs for code changes

Docs in `docs/*.md` and `docs/features/**/*.md` may list code files in `sources:` frontmatter.
On a PR, CI keeps one comment listing the docs whose listed sources changed, and the docs that list
files that no longer exist. Each push updates it. The comment is advisory. The job fails only on
frontmatter errors: invalid YAML, a missing or malformed `sources:` list, or a cited line number.

**Read `docs/features/writing-feature-docs.md` before editing any doc.** It defines what a doc
keeps, what it leaves out, its shape and voice, how it refers to code, and the `sources:` rules.

## 1. Get the doc list

```bash
git fetch origin main
ruby bin/doc_sources affected origin/main
```

`affected` prints the same markdown CI posts as the PR comment: docs whose `sources:` include a
changed file, and docs whose `sources:` name files that no longer exist.

This checks the current branch against `main`. If the user names a different branch to compare
against, use it in place of `origin/main` here and below. `<base>` in the steps below is the
merge base, not the tip of main, so the diffs show only this branch's changes even when main has
moved ahead:

```bash
git merge-base origin/main HEAD
```

`affected` diffs from the merge base to `HEAD`, so it misses docs that cite files with uncommitted
edits. List those docs too, and treat each one like an `affected` doc:

```bash
git diff --name-only HEAD | xargs -r -I{} sh -c 'grep -lF "$1" docs/*.md; grep -rlF --include="*.md" "$1" docs/features' _ {}
```

This searches the same docs `affected` does (`docs/*.md` and `docs/features/**/*.md`) and matches
the path anywhere in a doc, not only in `sources:`. Skip docs that mention it only in passing. Empty output from both commands means no doc lists a changed file.

For frontmatter errors, run `ruby bin/doc_sources check` and fix what it prints.

For a source listed as no longer existing, find the new path
(`git log --follow --diff-filter=RD --oneline -- <source>`), update `sources` and any mention of
the old path in the doc body. If it was deleted, remove the facts that depended on it.

## 2. See what changed

For each source listed in the `affected` output:

```bash
git log --oneline <base>..HEAD -- <source>
git diff <base> -- <source>          # includes uncommitted edits
```

The diff tells you where to look first. It does not bound the review: a small diff can invalidate a
claim far from the hunk, including claims about the feature's purpose or its integration points.

## 3. Verify the doc's facts against current code

Read each affected doc in full. Treat every concrete claim as a fact to check:

- Class, module, method, constant, scope, and permission names: confirm they exist (`grep`, read
  the file). Renames are the most common drift; code that only moved or was reformatted leaves
  the fact true.
- Behavior statements ("X delegates to Y", "returns nil when...", "only runs for..."): read the code
  path and confirm.
- Integration points (jobs, other features, CAS, external systems, the HMIS/warehouse boundary):
  confirm each connection the doc describes still exists.
- Deprecated-pattern and footgun entries: confirm the pattern and its named replacement still exist
  as described.
- When the source is itself a doc, compare the doc's condensed rules to the source's current
  wording; added, removed, or reversed rules matter, rewording doesn't.

Give every concrete claim one verdict:

| verdict | meaning | where it goes |
|---|---|---|
| `true` | still accurate | counted, no row |
| `fixed` | wrong; doc edited to match code | doc edit |
| `removed` | describes deleted code; claim deleted | doc edit; drop the file from `sources` if no other claim depends on it |
| `added` | new fact the guide says a doc keeps, confirmed in code | doc edit; add the file to `sources` if it isn't listed |
| `flagged` | unsure whether it's right or what the author meant | report only; doc unchanged |

Every non-`true` verdict needs evidence (file:line). Line numbers are for the report; they never go
into the docs.

## 4. Update the docs

Apply each verdict from step 3, following "Updating an existing doc" in
`docs/features/writing-feature-docs.md`.

## 5. Confirm and report

```bash
ruby bin/doc_sources check    # must print "doc sources are valid"
```

Don't commit. Report to the user:

- per changed source: which docs list it, and what changed in it (one line)
- per affected doc: the count of `true` claims, one row for every other verdict, and a `sources:`
  line. A doc with no count line was not reviewed.

Example (made-up doc and rename, real format):

```
docs/features/hmis/enrollments.md — 11 claims true
| claim | verdict | evidence |
|---|---|---|
| "`Hmis::Hud::Enrollment#exit_date` derives from Exit" | fixed (now `#exited_on`) | drivers/hmis/app/models/hmis/hud/enrollment.rb:88 |
| "CAS sync runs nightly" | flagged — job exists, schedule not found | — |
sources: unchanged
```

If every claim is `true`, the count line and `sources: unchanged` are the whole entry.
