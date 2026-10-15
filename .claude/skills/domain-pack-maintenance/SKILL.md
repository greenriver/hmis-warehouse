---
name: domain-pack-maintenance
disable-model-invocation: true
description: Repair a failing "Domain Pack" CI check (`ruby bin/domain_pack check`) in hmis-warehouse. Takes a GitHub Actions run/job URL (or PR number, or nothing, to use the current branch), finds each source file whose stamp no longer matches, re-verifies the facts in every docs/domain-pack doc that lists it against the current code, updates the docs where they drifted, and re-stamps the manifest. Use whenever someone pastes a failed "Domain pack manifest is current" job link, says "fix the domain pack", "domain pack is stale", "restamp the domain pack", "source changed since last stamp", or edits a file listed in docs/domain-pack/manifest.json and needs the docs brought back in line.
---

# Domain pack maintenance

`docs/domain-pack/` holds agent-oriented docs. Each doc's frontmatter lists `sources`;
`docs/domain-pack/manifest.json` records a SHA-256 of each source. CI (`.github/workflows/domain_pack.yml`)
runs `ruby bin/domain_pack check` and fails when a source changed but was not re-stamped.

The check exists so docs get re-read when their code changes. A bare `stamp` silences it without
doing that, so the job here is: verify, fix the docs, then stamp. Read `docs/domain-pack/README.md`
for the doc format before editing anything.

## 1. Get the failure list

From a URL like `https://github.com/greenriver/hmis-warehouse/actions/runs/<run_id>/job/<job_id>?pr=<n>`:

```bash
gh run view <run_id> --log-failed > <scratch>/domain_pack_ci.log
gh pr view <n> --json headRefName,baseRefName
git branch --show-current
```

Confirm the checked-out branch is the PR's `headRefName` before editing. If it is not, stop and
tell the user which branch to check out; do not switch branches with uncommitted work present.

Then reproduce locally (plain Ruby, no Docker needed; `lib/domain_pack.rb` is stdlib only):

```bash
ruby bin/domain_pack check
```

The local run is the source of truth. If CI failed but the local check passes, CI likely ran on
the PR merge commit (`actions/checkout` on `pull_request` does), so the drift came from `main`.
Tell the user to merge or rebase `main` and re-run; don't guess at changes you can't see.

Group the problems by type:

| Message | Meaning | Action |
|---|---|---|
| `source X changed since last stamp` | File edited | Steps 2–4 |
| `source X does not exist` | File renamed or deleted | Find the new path (`git log --follow --diff-filter=RD --oneline -- X`), update `sources` and every mention of the old path in the doc body; if deleted, remove the facts that depended on it |
| `source X is not in manifest` | Doc newly lists a source | Verify the doc's claims about X (step 3), then stamp |
| `X is not listed by any doc` | Orphan manifest entry | Stamp only |
| `frontmatter missing ...` / `area must be ...` | Malformed doc | Fix the frontmatter per the README |
| `cites line number ...` | A fact is anchored to a line | Replace it with the method, constant, or class name at that line (step 4) |

## 2. Map changed sources to docs, and see what changed

For each changed source, find every doc that lists it (the check prints one line per doc, but grep
to be sure):

```bash
grep -rln --include='*.md' -- '<source path>' docs/domain-pack
```

Find what changed since the last stamp. Every stamp rewrites `manifest.json`, so the last commit
that touched it is the baseline:

```bash
base=$(git log -1 --format=%H -- docs/domain-pack/manifest.json)
git log --oneline "$base"..HEAD -- <source>
git diff "$base" -- <source>          # includes uncommitted edits
```

If the diff is empty or unrelated to the source's current state (e.g. the manifest was stamped on
another branch), fall back to `git diff $(git merge-base HEAD origin/main) -- <source>`.

A source may be a symlink (`CLAUDE.md` links to `AGENTS.md`). The stamp hashes the target's
content, but `git log`/`git diff` on the link only show the link itself, so run them on the target
(`readlink <source>`).

The diff tells you where to look first. It does not bound the review: a doc can also be wrong
because of code that changed long ago, and a small diff can invalidate a claim far from the hunk.

## 3. Verify the doc's facts against current code

Read each affected doc in full. Treat every concrete claim as a fact to check:

- File paths, class/module/method/constant names, scopes, and permission names: confirm they exist
  (`grep`, read the file). Renames are the most common drift.
- Behavior statements ("X delegates to Y", "returns nil when...", "only runs for..."): read the code
  path and confirm.
- `Do not repeat` and `Gotchas` entries: confirm the deprecated pattern and its named replacement
  still exist as described.
- When the source is itself a doc (`CLAUDE.md`, `docs/*.md`), compare the domain pack's condensed
  rules to the source's current wording; added, removed, or reversed rules matter, rewording doesn't.

A fact is about names and behavior, not position. A method that moved within its file, or code
that was reordered or reformatted, leaves the fact true. A method, class, constant, or file that a
fact names being renamed or removed makes it wrong, even if the behavior survives under a new name.

Check claims in the doc that rest on other listed sources too, when the diff touches shared
behavior. Keep a short working list: claim, still true / wrong / new fact worth adding, evidence
(file:line). The line numbers are for your report and the reviewer; they never go into the docs.

## 4. Update the docs

Edit only what the evidence supports. Leave accurate text alone; churn makes review harder.

- Fix wrong claims; remove claims about deleted code; add a fact only if an agent working in that
  area would need it (a new entry point, a new gotcha, a new deprecated pattern).
- Write facts to stay true until the code they describe actually changes. Anchor them to stable
  identifiers: file paths, class and method names, constants, scopes, permission names. Never cite
  line numbers, line ranges, commit SHAs, "the third method in", or verbatim code that restates an
  implementation detail the fact doesn't depend on. State the behavior an agent needs to know
  ("`Foo.viewable_by` scopes through `AccessControl`"), not a snapshot of how it is written today.
  Stable wording is the point: it means the next stamp failure is about a real change.
- Update `sources` if the doc now depends on a new file, or no longer on an old one. List files, not
  directories or globs, and never a gitignored path.
- Keep the README rules: required sections in order, each section readable on its own (no "above"
  or "below"), roughly 300 words per section.
- No bead ids, issue numbers, PR numbers, or branch names in the docs; state the fact itself.
- If the change is large enough that a doc should be split or a new doc written, say so and ask
  before restructuring.

It is fine for a source change to need no doc edit (formatting, a change outside what the doc
describes). Record that in the summary so the reviewer sees the doc was checked, not skipped.

## 5. Stamp and confirm

```bash
ruby bin/domain_pack stamp
ruby bin/domain_pack check    # must print "domain pack is in sync"
git diff --stat docs/domain-pack
```

Don't commit. Report to the user, per changed source:

- which docs list it
- what changed in the source (one line)
- what was edited in each doc, or "verified, no change needed" with the reason
- anything uncertain that a human should look at

Reviewers are told to push back on a manifest change with no doc change, so the "verified, no
change needed" lines are what let a stamp-only diff through review.
