# Updating codebase for HUD specs

This is a guide for creating "list" and utility classes when HUD specs are released for a new year.

## 1) Create data files
* Review the HUD data dictionary change log
* For a new year, copy the previous `[year]_hud_lists.json` file and modify it according to the data dictonary
* Add any deprecated fields or values not present in the HUD spec to `[year]_hud_deprecations.json`.

## 2) Create HUDLists ruby module
After changes to the JSON files have been completed, run the following tasks to generate a the hud lists ruby module

```bash
# example for 2026
rails code:generate_hud_lists['2026']
```

## 3) Create a new utility class
* Manually create a `HudUtility[year]` class and modify it to include the new HudLists concern (`HudLists[year]`)
* Create a new spec for the utility `spec/lib/util/hud_utility_[year].rb`
* Update code base to use the new utility class, excluding previous year's HUD reporting code which should continue to use the prior year

## 4) Update the HMIS GraphQL API

```bash
# example for 2026
rails driver:hmis:generate_graphql_enums['2026']
rails driver:hmis:dump_graphql_schema
```

Using the updated schema.json, regenerate the front-end types on the HMIS front-end. See documentation in the hmis-frontend repository.
