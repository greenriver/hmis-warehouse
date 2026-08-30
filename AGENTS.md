# Open Path HMIS Warehouse

The Rails monolith for the Open Path Platform  — a homeless-services system. It covers HMIS data entry, coordinated entry, data warehousing, HUD-compliant reporting, and analytics. The React front-end (`hmis-frontend`) and CAS matching system (`boston-cas`) are separate repos; `docs/architecture/README.md` has the full repo map.

## Stack

Ruby on Rails 8.1 / RSpec / Ruby 3.4 / PostgreSQL 17

## DB Gotchas

- **HUD composite keys:** HUD record IDs are not unique alone. Identity requires `data_source_id` plus the HUD key (e.g. `(data_source_id, ProjectID)`). Always include `data_source_id` in queries.
- **PascalCase columns:** Table/column names follow HUD spec (`ProjectID`, `PersonalID`). CamelCase columns require quoting in raw SQL — prefer Arel.
- **Query safety:** Associations use non-standard foreign keys and composite keys. Prefer AR relationships over manual joins, and never optimize queries (joins, pluck) without confirming association structure first.
- **Multi-database:** Two primary databases, each with its own base class (`ApplicationRecord`, `GrdaWarehouseBase`). Models must inherit from the correct one.

## Documentation

Before writing code for a feature, find and read its doc

- Touching **HMIS code** → read the matching file in `docs/features/hmis/`.
- Touching a **warehouse feature** — HUD reports, HMIS CSV import/export → read the matching file in `docs/features/warehouse/`.
- **Authorization** (policy-based) → the `*-auth-policies.md` in the matching feature dir above.
- Designing a new subsystem, major refactoring, or making a system-level decision → read `docs/architecture/README.md` and `docs/adr/`.

## Conventions

- **Queries**: Prefer Arel over raw SQL.
- **Locality trumps DRY**: co-locate related code in feature namespaces, not on core models.
- **Ask what an object can do, not what it is.** Use `service.supports_backfill?`, not `obj.is_a?(SomeClass)`.
- **A service should take its config, not fetch it.** Let the caller resolve and pass it in.
- **Soft deletion:** Most models `acts_as_paranoid`.
- **Drivers:** `drivers/` contains modular engines, each with its own app/config/db/spec dirs.
