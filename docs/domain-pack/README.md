# Domain pack

Agent-oriented documentation of how this repository implements its features. Written for AI
coding agents and for later ingestion into a retrieval index. Human-facing docs stay in
`docs/features/`, `docs/architecture/`, and `docs/adr/`; docs here copy from them but are
organized around what an agent needs before touching the code.

## Layout

`<area>/<slug>.md`, areas: `conventions`, `authorization`, `roi`, `hmis`, `hud-reporting`,
`warehouse`. `manifest.json` is generated; do not edit it by hand.

## Frontmatter (required)

    ---
    title: Access Controls
    summary: One or two sentences an agent uses to decide whether to open this doc.
    area: authorization
    tags: [acl, access-control, collection, viewable_by]
    sources:
      - app/models/access_control.rb
      - app/models/collection.rb
    related:
      - authorization/warehouse-legacy-roles.md
    ---

`sources` are the repo-relative files this doc describes. When any of them changes, the doc is
presumed stale. List files, never directories or globs. Never list a gitignored path.

## Body sections, in this order

`## Purpose`, `## Entry points`, `## How it works`, `## Key files`, `## Gotchas`,
`## Do not repeat`, `## Related`. Each section must read on its own: no "above" or "below",
roughly 300 words or fewer. Long topics become two docs.

## Keeping it current

    ruby bin/domain_pack check   # what CI runs on every pull request
    ruby bin/domain_pack stamp   # after updating a doc, records current source hashes

CI fails when a listed source file changed and the manifest was not re-stamped, when a doc
lists a file that does not exist, when frontmatter is missing a required key, or when the
manifest holds a file no doc lists. Re-stamping without reading the doc defeats the check;
reviewers should ask for the doc change when they see a bare manifest change.

## Adding a doc

1. Copy the frontmatter block above. Pick the area directory.
2. Write the sections. Verify every statement against the current source.
3. Fill `sources` with the files you read.
4. `ruby bin/domain_pack check`, fix problems, `ruby bin/domain_pack stamp`.
