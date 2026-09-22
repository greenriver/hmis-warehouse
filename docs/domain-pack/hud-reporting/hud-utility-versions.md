---
title: HUD utility versions (HudHelper.util)
summary: "HUD code lists (race, project type, destinations, and every other HUD enumeration) are version-specific. HudHelper.util(version) resolves to HudUtility2024, HudUtility2026, or HudUtilityLegacy by date or explicit version, with a thread-safe current-version override. Explains generation from the spec and how to add a new HUD version."
area: hud-reporting
tags: [hud, HudHelper, HudHelper.util, HudUtility2024, HudUtility2026, HudUtilityLegacy, HudCodeGen, CurrentAttributes, hud_version, enumerations, ADR-0005]
sources:
  - docs/adr/0005-hud-utility-version-management.md
  - lib/util/hud_helper.rb
  - lib/util/hud_utility_2024.rb
  - lib/util/hud_utility_2026.rb
  - lib/util/hud_utility_legacy.rb
  - lib/util/hud_code_gen.rb
  - lib/util/concerns/hud_validation_util.rb
  - lib/util/concerns/hud_lists_2026.rb
  - lib/data/README.md
  - lib/data/2026_hud_lists.json
  - lib/data/2026_hud_deprecations.json
  - lib/tasks/code.rake
  - drivers/hmis/lib/tasks/graphql.rake
  - drivers/hmis/app/graphql/types/hmis_schema/enums/hud.rb
  - app/models/grda_warehouse/hud_list_item.rb
  - app/models/concerns/hmis_structure/base.rb
  - spec/lib/util/hud_helper_spec.rb
related:
  - conventions/do-not-repeat.md
  - conventions/house-style.md
  - hud-reporting/report-framework.md
  - hmis/data-model.md
---

## Purpose

Every HUD-coded value in this codebase (project type, destination, race, gender, funding
source, data collection stage, and about 200 other lists) is looked up through a fiscal-year
utility module: `HudUtility2026`, `HudUtility2024`, or `HudUtilityLegacy`
(`lib/util/hud_utility_*.rb`). `HudHelper.util` (`lib/util/hud_helper.rb`) is the factory that
picks one, so calling code does not name a year. `docs/adr/0005-hud-utility-version-management.md`
records the decision.

This doc covers how the factory resolves a version, what a utility module contains, how the
generated list concerns are produced from HUD's machine-readable spec by `HudCodeGen`
(`lib/util/hud_code_gen.rb`), and what adding a new HUD version requires. The HUD lists
themselves (which codes exist and what they mean) are spec content and out of scope; use the
HMIS domain knowledge MCP server (`search_docs`) for that.

## Entry points

- `HudHelper.util` with no argument returns the module for the current version. Chain the
  lookup: `HudHelper.util.project_type(1)`, `HudHelper.util.races`,
  `HudHelper.util.data_collection_stages`.
- `HudHelper.util('2026')`, `HudHelper.util('2024')`, `HudHelper.util('legacy')` return a fixed
  version. Any other string raises `RuntimeError` ("Unknown HUD utility version"). Past-year HUD
  report generators and the year-specific CSV drivers pin this way.
- `HudHelper.hud_csv_version` (alias of `HudHelper.current_version`) returns the version string
  (`'2024'` or `'2026'`) without a module. `HmisStructure::Base.hud_csv_version`
  (`app/models/concerns/hmis_structure/base.rb`) delegates to it, and
  `HudReports::BaseController` builds the `:fy2026` generator key from it.
- `HudHelper::Current.hud_csv_version` is the `ActiveSupport::CurrentAttributes` slot that pins
  the resolved version for the current request, job, or thread. Set it directly only in specs.
- `HudHelper.util(force_recalculate: true)` bypasses the pin and re-resolves from the date. It
  exists for `spec/lib/util/hud_helper_spec.rb`.
- Utility methods are class-level (`module_function`). Each generated list has a map method
  (`funding_sources`) and a lookup (`funding_source(id, reverse = false, raise_on_missing:
  false)`); `reverse = true` maps a description back to its code.
- `HudHelper.ssn_rgx` and `HudHelper.show_gender_in_reports?` (reads `AppConfigProperty`
  `show_gender_in_reports`) also live on the factory module.
- Regeneration: `rails code:generate_hud_list_json[year,xlsx_path]`,
  `rails code:generate_hud_lists[year]` (`lib/tasks/code.rake`), and
  `rails driver:hmis:generate_graphql_enums[year]` (`drivers/hmis/lib/tasks/graphql.rake`).

## How it works

### Version resolution

`HudHelper.util(version = nil, force_recalculate: false)` does `version ||= current_version`
then a `case version.to_s`: `'2026'` returns `HudUtility2026`, `'2024'` returns
`HudUtility2024`, `'legacy'` returns `HudUtilityLegacy`, anything else raises.

`HudHelper.current_version` first reads `HudHelper::Current.hud_csv_version`; if set and
`force_recalculate` is false, that pinned string is returned. Otherwise it computes one from the
environment and date: production returns `'2024'` when `Date.current` is before
`HudHelper.production_cutoff` (2025-10-01) and `'2026'` after; staging uses
`HudHelper.staging_cutoff` (2025-09-01); every other environment (test, development) returns
`'2026'` unconditionally. The result is written to `HudHelper::Current.hud_csv_version` before
returning, so later calls in the same request, job, or thread get the same answer even if the
clock crosses a cutoff. `ActiveSupport::CurrentAttributes` is reset by the Rails executor
around each request and job execution; there is no reset in this codebase.

Both cutoffs are in the past as of 2026-09, so every environment resolves to `'2026'`. The
date branches are not a live switch; they are the template for the next transition, which adds a
`when` for the new year, moves both cutoffs, and changes the default branch.

### What a utility module contains

`HudUtility2026` includes `Concerns::HudValidationUtil` (`lib/util/concerns/hud_validation_util.rb`)
and `Concerns::HudLists2026` (`lib/util/concerns/hud_lists_2026.rb`), then declares
`module_function` so every `def` is a class method. `HudValidationUtil` supplies `_translate`
(the shared forward/reverse lookup; unknown ids return unchanged unless `raise_on_missing:
true`, reverse lookups match descriptions through `forgiving_regex`), `fiscal_year`,
`fiscal_year_start`, `fiscal_year_end`, and SSN/DOB validity checks. `HudLists2026` is generated
and holds one map and one lookup per HUD list, keyed by the list's spec code in a comment.

The hand-written part of each utility is the grouping and derived logic HUD does not ship as a
list: project type groupings (`residential_project_type_numbers_by_code`,
`homeless_project_types`, `permanent_housing_project_types`, `project_types_without_inventory`),
race and gender column maps (`race_fields`, `gender_id_to_field_name`), living situation ranges
(`SITUATION_HOMELESS_RANGE` and siblings), CE event mapping (`project_to_ce_event_type`), and
funding source groupings that reverse-look-up description strings with `raise_on_missing: true`.

`HudUtility2026` also defines `funding_sources_current` and `funding_source_current` as aliases
of the generated `funding_sources` and `funding_source`; the generated 2026 list already merges
retired codes from `lib/data/2026_hud_deprecations.json`. `HudUtility2024` has no such aliases,
so a caller that uses them under a `'2024'` pin gets `NoMethodError`. `HudUtilityLegacy`
includes `HudLists2022` and, per its header, stands in for FY2022, FY2020, and CSV 6.x/5.x; it
is deprecated for new code and reached only through `HudHelper.util('legacy')`.

### Generation pipeline and adding a year

Source of truth is `lib/data/<year>_hud_lists.json`, optionally plus
`lib/data/<year>_hud_deprecations.json` (retired codes merged into the matching list, or added
as a new list) and `lib/data/<year>_additional_lists/*.json` (only 2024 has one).
`HudCodeGen` (`lib/util/hud_code_gen.rb`) has three generators, each invoked from a rake task:

- `generate_hud_list_json(year, xlsx_path)`: reads HUD's machine-readable CSV specification
  workbook with `roo`, merges it with the existing JSON, drops lists no longer in the workbook,
  and rewrites the JSON. Lists found only on the values sheet get the name `Unknown` for manual
  naming.
- `generate_hud_lists(year)`: writes `lib/util/concerns/hud_lists_<year>.rb` from the JSON,
  validating no duplicate list codes or duplicate keys. Method names come from the list name via
  `MAP_NAME_OVERRIDES` and `LOOKUP_FN_OVERRIDES`. The rake task hard-codes `['2022', '2024',
  '2026']` and runs `rubocop -A` on the output.
- `generate_graphql_enums(year)`: writes `drivers/hmis/app/graphql/types/hmis_schema/enums/hud.rb`
  by calling each map on `"HudUtility#{year}".constantize`, so the utility module must exist
  first. Skips race, gender (3.6.1), 2.4.2, and 1.6, and appends an `INVALID` value to every
  enum. The file header says manual edits may follow generation. The `year == '2022'` branch
  references `HudUtility`, a constant that no longer exists.

`HudCodeGen.lists_with_method_names(year)` also feeds `GrdaWarehouse::HudListItem.maintain!`
(`app/models/grda_warehouse/hud_list_item.rb`), which copies the lists into a warehouse table for
SQL consumers; `KNOWN_YEARS` is hard-coded to `['2026']`.

`HudCodeGen` is still the path for a new year, and `lib/data/README.md` lists the steps. It does
not produce the `HudUtility<year>` module (copy the previous one and include the new concern),
the `when` branch and cutoffs in `HudHelper`, the year in the rake task, `HudListItem::KNOWN_YEARS`,
or a `spec/lib/util/hud_utility_<year>_spec.rb`. The README step "update code base to use the new
utility class" predates the factory; callers on `HudHelper.util` need no edit.

## Key files

- `lib/util/hud_helper.rb`: `HudHelper.util`, `current_version`, `HudHelper::Current`,
  `production_cutoff`, `staging_cutoff`.
- `lib/util/hud_utility_2026.rb`: current utility; hand-written groupings plus
  `Concerns::HudLists2026`.
- `lib/util/hud_utility_2024.rb`: prior utility, pinned by FY2024 report code.
- `lib/util/hud_utility_legacy.rb`: FY2022 and earlier; `Concerns::HudLists2022`; deprecated.
- `lib/util/concerns/hud_validation_util.rb`: `_translate`, `forgiving_regex`, fiscal year
  helpers, SSN/DOB validation shared by all three utilities.
- `lib/util/concerns/hud_lists_2026.rb`: generated map and lookup methods; header says do not
  edit.
- `lib/util/hud_code_gen.rb`: `generate_hud_list_json`, `generate_hud_lists`,
  `generate_graphql_enums`, `lists_with_method_names`.
- `lib/data/2026_hud_lists.json`, `lib/data/2026_hud_deprecations.json`: generator input.
- `lib/data/README.md`: the new-year checklist.
- `lib/tasks/code.rake`: `code:generate_hud_list_json`, `code:generate_hud_lists`.
- `drivers/hmis/lib/tasks/graphql.rake`: `driver:hmis:generate_graphql_enums`,
  `dump_graphql_schema`.
- `drivers/hmis/app/graphql/types/hmis_schema/enums/hud.rb`: generated GraphQL enums.
- `app/models/grda_warehouse/hud_list_item.rb`: warehouse table copy of the lists.
- `app/models/concerns/hmis_structure/base.rb`: `hud_csv_version` delegation that ties CSV
  structure to the same pin.
- `spec/lib/util/hud_helper_spec.rb`: cutoff and delegation specs; the model for pinning a
  version in a test.
- `docs/adr/0005-hud-utility-version-management.md`: the decision record.

## Gotchas

- Specs must pin a version when the date matters. Use `HudHelper.util('2024')` for a fixed
  expectation, or `travel_to` plus `HudHelper.util(force_recalculate: true)` to exercise the
  cutoff; a plain `HudHelper.util` returns whatever `HudHelper::Current` already holds for the
  thread. Test and development always resolve to `'2026'`, so cutoff behavior only appears with
  `Rails.env.production?`/`staging?` stubbed, as `spec/lib/util/hud_helper_spec.rb` does.
- Direct constant references are rare: `HudUtility2024` or `HudUtility2026` appears in 8 files
  (the two utilities, `hud_helper.rb`, one JSON comment in `drivers/hmis_simulation`, and four
  specs), while 258 files call `HudHelper.util(` and 722 mention `HudHelper.util` in any form.
  Explicit pins are strings: `HudHelper.util('2024')` on 214 lines, `HudHelper.util('legacy')`
  on 229, `HudHelper.util('2026')` on 222, mostly in `drivers/hud_apr`, `drivers/hmis_csv_*`,
  and `app/models/report_generators`.
- `_translate` returns the input unchanged when a code is missing unless `raise_on_missing:
  true`. A typo in a code or a retired value passes through silently as its own label.
- Reverse lookups (`funding_source('HUD: ESG - RUSH', true)`) match description text. HUD
  rewords descriptions between years; the utilities' own groupings use `raise_on_missing: true`
  so a reworded description fails loudly at load time rather than returning `nil`.
- Method sets differ across versions (`funding_sources_current` exists only on 2026). A caller
  that works under the current pin can raise `NoMethodError` under an explicit older pin; ADR
  0005 accepts this in exchange for not revisiting every call site each year.
- `HudHelper.hud_csv_version` never returns `'legacy'`; the legacy utility is reachable only by
  explicit request.
- A pinned version selects more than code lists: `HudHelper.hud_csv_version` also picks the
  `HmisStructure` CSV layout and the `fy2026` report generator key.
- The generated GraphQL enum file is regenerated in place and may need manual edits after; diff
  it before committing. `generate_graphql_enums('2022')` raises `NameError` on the removed
  `HudUtility` constant.
- `code:generate_hud_lists` and `HudListItem::KNOWN_YEARS` hard-code the year list; a new year
  that skips them silently produces nothing.

## Do not repeat

- Rails `enum` or a literal integer for a HUD-coded column. Use `HudHelper.util` groupings such
  as `homeless_project_types` or `residential_project_type_numbers_by_code[:es]` instead of
  `where(project_type: 1)`. Legacy example: `where(client_gender: 1)` with a comment naming the
  code in `app/models/grda_warehouse/warehouse_reports/youth/homeless_youth_report.rb`. Entry 7
  in `conventions/do-not-repeat.md`; the HMIS-side replacement is in `hmis/data-model.md`.
- Naming `HudUtility2026`, `HudUtility2024`, or `HudUtilityLegacy` in application code. Use
  `HudHelper.util` for current-version code and `HudHelper.util('2024')` (a string) where a
  past fiscal year's report or CSV driver must stay on its year. No application file currently
  names the constant; `object_double(HudUtility2026)` in a spec is fine.
- A repo-wide find-and-replace year bump (`HudUtility2024` to `HudUtility2026`, or
  `util('2024')` to `util('2026')`). A new version is a `when` branch and cutoff change in
  `HudHelper`, plus the generation steps; existing explicit pins in past-year report code are
  correct and stay.
- Hand-editing `lib/util/concerns/hud_lists_<year>.rb`. Edit `lib/data/<year>_hud_lists.json` or
  `<year>_hud_deprecations.json` and run `rails code:generate_hud_lists[<year>]`.
- Deciding the current version anywhere but `HudHelper.current_version`: no `Date.current`
  comparisons against October 1 in callers, no second `CurrentAttributes` for the year.
- Comparing a HUD description string inline instead of a reverse lookup with `raise_on_missing:
  true` when a code is genuinely needed as a constant.

## Related

- `conventions/do-not-repeat.md`: entry 7 (HUD enums and literal codes).
- `conventions/house-style.md`: the positive rule for HUD-coded fields.
- `hud-reporting/report-framework.md`: fiscal-year generator registration and why past years
  pin `HudHelper.util('2024')`.
- `hmis/data-model.md`: `Hmis::Hud::Concerns::HasEnums.use_enum`, the HMIS enum layer built on
  `HudHelper.util`.
- `docs/adr/0005-hud-utility-version-management.md`: decision record and rejected alternatives.
- `lib/data/README.md`: human-facing new-year checklist.
