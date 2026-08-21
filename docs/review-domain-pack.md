# Review Domain Pack

This file opts hmis-warehouse in to the `domain-compliance` lens of the `gr-sw-multi-lens-review` skill (`gr-catalog`). It lists this repo's HUD/HMIS domain reference material — the context-builder digests these into `.claude/review-context/domain-compliance.md`, which the lens actually reads at review time. It does not itself contain the domain rules.

Only list content here that's publicly available or already checked into this repo. Confidential or not-yet-public material belongs in `.claude/review-context/domain-pack.local.md` instead — see "Local supplement" below.

## Sources

- `docs/hud_data_model.md` — markdown-authored summary of the HMIS CSV FORMAT Specifications (currently FY2024 v1.4).
- `docs/adr/*` — architecture decisions with domain implications, notably `0002-pii-management-strategy.md`, `0005-hud-utility-version-management.md`, `0007-hmis-hud-import-cleanups-via-importer-extensions.md`.
- `docs/code_patterns_and_conventions.md` — includes the PII-tracking and authorization sections referenced by domain rules.
- `drivers/hud_apr/doc/APR-HMIS-Programming-Specifications-2022.pdf`
- `drivers/hud_apr/doc/HMIS-Programming-Specifications-for-Coordinated-Entry-APR-CE-APR-CSV.pdf`
- `drivers/cas_ce_data/doc/HMIS-Programming-Specifications-for-Coordinated-Entry-APR-CE-APR-CSV.pdf`
- `drivers/hud_path_report/doc/HMIS-Programming-Specifications-PATH-Annual-Report.pdf`
- `drivers/hud_data_quality_report/doc/HMIS-Standard-Reporting-Terminology-Glossary.pdf`

## Known staleness

Confirmed via HUD Exchange (2026-08-21): HUD, HHS, and VA released the **FY2026 HMIS Data Standards**, effective 2025-10-01 — a full final release, not a draft. The material listed above is older: `docs/hud_data_model.md` documents FY2024 v1.4, and `drivers/hud_apr/doc/APR-HMIS-Programming-Specifications-2022.pdf` is named for the 2022 spec. So domain-compliance findings from this pack are checked against an out-of-date standard until these are refreshed — treat any finding that depends on spec version specifics accordingly. Updating the checked-in HUD material to FY2026 is a separate, substantive effort (well beyond this pack) and is out of scope here; this note exists so the gap isn't silently assumed away.

## Local supplement (per-engineer, not for this file)

Additional non-public or pre-release HUD material (e.g. draft specs ahead of a HUD Exchange release) goes in a personal, gitignored `.claude/review-context/domain-pack.local.md` at the repo root instead — never listed here. See the `gr-sw-multi-lens-review` plugin README for the format. Teammates without that file still get the full domain-compliance lens from the sources above; they just don't get whatever a colleague added personally.
