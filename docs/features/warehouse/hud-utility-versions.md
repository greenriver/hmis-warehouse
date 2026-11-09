---
sources:
  - lib/util/hud_helper.rb
  - lib/util/hud_code_gen.rb
  - lib/util/concerns/hud_validation_util.rb
  - lib/tasks/code.rake
  - lib/data/README.md
  - app/models/grda_warehouse/hud_list_item.rb
  - docs/adr/0005-hud-utility-version-management.md
---

# HUD Utility Versions

HUD code lists (project type, destination, race, funding source, and the rest) change between fiscal years. Code never names a year-specific module. It calls `HudHelper.util`, which returns `HudUtility2026`, `HudUtility2024`, or `HudUtilityLegacy`. The decision is recorded in [ADR 0005](../../adr/0005-hud-utility-version-management.md). The lists themselves are spec content; use the HMIS domain knowledge MCP server for them.

## How a version resolves

- `HudHelper.util` with no argument uses the current version. `HudHelper.util('2024')`, `'2026'`, and `'legacy'` pin a version; any other string raises. Past-year report generators and year-specific CSV drivers pin with a string.
- The current version is chosen once per request, job, or thread and kept in `HudHelper::Current`, so it can't change mid-run if the clock crosses a cutoff.
- Production and staging pick the previous version before a cutoff date and the new one after; development and test always use the newest. Both cutoffs have passed, so every environment resolves to `'2026'`. The date branches are the template for the next transition.
- `HudHelper.hud_csv_version` also selects the `HmisStructure` CSV layout and the default report-generator year (`fy2026`), not just code lists.
- `'legacy'` (FY2022 and earlier) is reached only by explicit request, and is deprecated for new code.

## Adding a HUD version

`lib/data/README.md` has the checklist. `HudCodeGen` generates the list concerns and the GraphQL enums from HUD's machine-readable spec, but it does not do these steps:

1. Copy the previous `HudUtility<year>` module and include the new generated concern. The hand-written part (project type groupings, race and gender column maps, living situation ranges, CE event mapping, funding source groupings) is not generated.
2. Add the `when` branch and cutoff dates in `HudHelper`.
3. Add the year to the hard-coded year list in `lib/tasks/code.rake` and to `GrdaWarehouse::HudListItem::KNOWN_YEARS`. A year that skips them silently produces nothing.
4. Write a spec for the new utility.

The GraphQL enum generator calls each map on `"HudUtility#{year}".constantize`, so the module must exist first. Its output may need manual edits; diff it before committing. Its `'2022'` branch references a `HudUtility` constant that no longer exists.

## Gotchas

- A missing or retired code passes through `_translate` unchanged, so a typo shows up as its own label. Pass `raise_on_missing: true` where a miss should fail.
- Reverse lookups match description text, and HUD rewords descriptions between years. The utilities' own groupings use `raise_on_missing: true` so a rewording fails at load.
- Method sets differ by version. `funding_sources_current` exists only on 2026, so code that works under the current version can raise `NoMethodError` under an explicit `'2024'` pin. ADR 0005 accepts this.
- Specs that depend on the date must pin a version, or use `travel_to` with `HudHelper.util(force_recalculate: true)`. Plain `HudHelper.util` returns whatever is already pinned for the thread.

## Don't

- Name `HudUtility2026` or the other modules in application code, or use `where(project_type: 1)` and other literal HUD codes. Use `HudHelper.util` groupings.
- Bump a year by find-and-replace. Explicit `util('2024')` pins in past-year report code are correct. A new version is a `HudHelper` change plus the generation steps.
- Hand-edit `lib/util/concerns/hud_lists_<year>.rb`. Edit the JSON under `lib/data/` and regenerate with `rails code:generate_hud_lists[<year>]`.
- Compare dates against the cutoff in callers. `HudHelper.current_version` is the only place that decides.
