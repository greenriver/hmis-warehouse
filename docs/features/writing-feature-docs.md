# Writing Feature Docs

How to write and update the docs in `docs/features/hmis/` and `docs/features/warehouse/`. It applies to engineers and to AI agents.

## Where a doc goes

- `docs/features/hmis/`: code that serves the HMIS app. That means `Hmis::` classes, the HMIS GraphQL API used by `hmis-frontend`, and `drivers/hmis`.
- `docs/features/warehouse/`: everything else. That means warehouse features, HUD reports, HMIS CSV import and export, and app-wide infrastructure such as background jobs and CI.

Don't add new docs at the top level of `docs/`. The docs there are legacy and are waiting to be moved into these directories.

A feature with both an HMIS side and a warehouse side gets one doc. It goes in the directory of the side that owns the feature's core model or process, and it covers both sides.

## Accuracy comes first

A feature doc is worth reading only if it is right. An undocumented behavior costs a reader some time in the code. A wrong one sends them the wrong way, and they have no reason to doubt it.

- Write only what you have confirmed in the code, a spec, a HUD document, or from the person who owns the feature.
- Keep the author's intent. If you can't tell why something works the way it does, don't supply a reason.
- When you are unsure, leave it out and flag it for a human in the PR or your report. A doc can say plainly that something is not covered yet.

## What a doc is for

By default, feature docs are for engineers who maintain the code. Some are also read by support staff.

A doc's main job is to explain the feature as part of the system. These are the facts readers most need, and they are usually not in the code:

- **Purpose.** What problem the feature solves, who uses it, and what it is not for. For example, a project group is a named list of projects that administrators reuse across report filters, cohorts, the CAS sync, and project access grants.
- **How it works within the system.** Where it sits, what triggers it (a user action, a nightly job, an import, an API call), what data it reads and writes, and what happens afterward. For example, chronic-at-start results are cached per enrollment by `GrdaWarehouse::ChEnrollment.maintain!`, which runs during the nightly import in `Importing::RunDailyImportsJob`, after service history is generated.
- **Integration points.** The other features, jobs, repos, and external systems it depends on or feeds, and what crosses each boundary. This includes the HMIS and warehouse sides of one feature, CAS, external HMISs, the identity provider, and the `hmis-frontend` repo. For example, the warehouse idle-session timeout depends on the IdP's idle timeout, passed through Dex and oauth2-proxy, and the HMIS frontend keeps its own countdown from the `X-app-session-remaining-secs` response header.

Also keep these, which the code doesn't explain:

- **Why.** The reason a rule exists, or why the obvious alternative was rejected. For example, when `Hmis::RestrictedRecord.mark!` restricts an HMIS record that was restricted before, it creates a new row instead of restoring the old one, because Paranoia's `restore` writes through `update_columns` and skips PaperTrail, so the audit trail would lose the change.

  When an ADR in `docs/adr/` records the decision, give the reason in a sentence and link the ADR instead of restating it. For example, `hmis-csv-importer.md` says cleanups run on every import instead of as console runs that someone has to remember to run, and links ADR 0007 for the rest.
- **HUD and customer rules**, quoted and cited when they come from a HUD document, then mapped to the code that implements them.
- **Ordering and interactions** that no single file shows, such as the order of steps in a nightly job or a form submission.
- **Limits and footguns**, each with what goes wrong and why. For example, saving a `Hmis::Form::FormProcessor` does not save the enrollment, so every caller has to save it.
- **Deprecated patterns still in the code**, and what replaced them. For example, the enrollment-based homeless-episode calculation in `ClientHistory::Calculator#new_episode?` is deprecated, and new work uses `GrdaWarehouse::ChEnrollment` where possible.

Leave out what the code already says: key-file lists, method-by-method walkthroughs, every column or argument a class takes, and prose that restates one class's body. When a list lives in code, point to the constant or method that holds it instead of copying the list, so the doc can't drift from it.

## Shape

- **Title and opening.** An H1, then one or two sentences on what the feature is and what the doc covers. Name the central class or table. Say what is out of scope and link to where it is covered, for example "This doc covers the warehouse `GrdaWarehouse::ProjectGroup`. HMIS has its own `Hmis::ProjectGroup`, which isn't covered here."
- **Sections named for the reader's question**, such as "What counts as activity" or "Who can view a restricted client". Avoid generic headings like "Details" or "Notes".
- **Tables** for comparisons and enumerations: arms of a feature, roles, who enforces what. **Numbered lists** for sequences. Prose for rationale.
- **Length follows the feature.** A small feature can be 40 lines. Don't pad it.
- **Each fact goes in the section it belongs to**, next to its reason. Don't append a catch-all "Gotchas" or "Behavior notes" list of unrelated bullets to the end of a doc.
- **Related** at the end: links to other docs, each with a few words on why to follow it. Include the ADRs in `docs/adr/` and the `docs/architecture/` sections that cover the feature, such as `08-concepts/08-2-security.md` for access control. Check an ADR's status before linking it. If it is superseded, link the ADR that replaced it.

## Voice

Plain, declarative, present tense. Short sentences. State what the code does, not what it "aims to" do. No filler like robust, seamless, leverage, comprehensive, or efficiently.

Describe behavior rather than giving orders. "`form_processor.save!` does not save the enrollment, so every caller has to save it itself" is more useful than "Always save the enrollment."

## Referring to code

- Name classes, methods (`Class#method`, `Class.method`), constants, scopes, tables, config flags, and permissions. The reader can search for a name.
- Use a file path only where a name won't do: config files, views, JSON, other repos.
- Never cite line numbers or line ranges. Lines move; names don't.
- No issue, PR, or ticket numbers, branch names, or commit SHAs. If a fact depends on one, write the fact.

## `sources:` frontmatter

A doc may start with YAML frontmatter listing the code files whose behavior it asserts:

```yaml
---
sources:
  - app/models/grda_warehouse/client_retention_mark.rb
  - app/jobs/client_retention_job.rb
---
```

- `sources` is a non-empty list of file paths relative to the repo root. Quote any value containing a colon and a space.
- List files, not directories or globs. List a symlink's target rather than the link.
- Don't list a gitignored path. It isn't in the repo, so changes to it never show up in a diff.
- Keep the list short: the few files whose behavior the doc states, not every file it mentions.
- Don't list generated files or files that change in most PRs, such as `db/*structure.sql`, `drivers/hmis/app/graphql/schema.graphql`, or `Gemfile.lock`. They would flag the doc on unrelated changes. List the migration, model, or type that defines the behavior instead.

## Updating an existing doc

1. Read the whole doc, then check each claim it makes against the current code. A renamed method or removed class makes a claim wrong even when the behavior survives.
2. Edit only what the evidence supports. Leave accurate text alone, including wording you would have written differently.
3. Fix wrong claims. Remove claims about deleted code.
4. Describe only the current behavior. Don't say how it used to work, what changed, or that something is "now" or "no longer" true; overwrite the old claim instead. Git history records the change. The exception is a deprecated pattern still in the code (see [What a doc is for](#what-a-doc-is-for)).
5. Add a new fact only if it passes the rules in [Accuracy comes first](#accuracy-comes-first) and [What a doc is for](#what-a-doc-is-for), and you have confirmed it.
6. Ask before splitting, merging, or reorganizing a doc.
7. Update `sources` if the doc now depends on a new file or no longer on an old one.
