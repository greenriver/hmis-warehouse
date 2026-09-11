# Open Path HMIS Warehouse

The Rails monolith for the Open Path Platform — a homeless-services system. It covers HMIS data entry, coordinated entry, data warehousing, HUD-compliant HMIS reporting, and analytics. The React front-end (`hmis-frontend`) and CAS matching system (`boston-cas`) are separate repos.

Application code is in `/app` or organized as modules under `/drivers`.

## Stack

Ruby on Rails 8.1 / RSpec / Ruby 3.4 / PostgreSQL 17

## DB and Active Record Gotchas

- **Query safety:** Associations may use non-standard foreign keys and composite keys, so prefer AR relationships over manual joins and verify the relationship in the model.
- **Shared tables:** HMIS and Warehouse models may back the same table — `Hmis::User` and `User` both map to `users`, as do the HUD data models.
- **Multi-database:** There are two primary databases, each with its own base class (`ApplicationRecord`, `GrdaWarehouseBase`), and a model must inherit from the correct one.
- **Soft deletion:** Most models use `acts_as_paranoid`.

### Unconventional HMIS HUD models

- The models under `GrdaWarehouse::Hud` and `Hmis::Hud` are roughly 1:1 with the HUD CSV specification, and their relationships can be complex.
- **HUD keys are not db primary keys:** these models keep Rails' `id` as the primary key, but relationships are expressed through HUD IDs like `ProjectID`, `PersonalID`, and `EnrollmentID`.
- **Data source scoping:** a HUD ID is not unique on its own — identity requires `data_source_id` plus the HUD ID, so scope by both.
- **Column aliases:** AR models may provide snake_case aliases for the PascalCase HUD fields (`project_id` == `ProjectID`).

## Documentation

Before writing or reviewing code, find and read its doc.

Match on the subject matter of the code in front of you — whether you're writing it or reviewing it.

- **HMIS code** → read the matching file in `docs/features/hmis/`.
- **Warehouse features** — HUD reports, HMIS CSV import/export → read the matching file in `docs/features/warehouse/`.
- **Authorization** (policy-based) → the `*-auth-policies.md` in the matching feature dir above.
- **New subsystems, major refactors, or system-level decisions** → read `docs/architecture/README.md`
- **HAML, the warehouse frontend, or GraphQL** → read `docs/code_patterns_and_conventions.md`
- **Database queries** — Arel vs. raw SQL, HUD case-sensitive columns, date/time comparisons → read `docs/active-record-arel-and-queries.md`

## Conventions

- **Locality trumps DRY**: co-locate related code in feature namespaces, not on core models.
- **Ask what an object can do, not what it is.** Use `service.supports_backfill?`, not `obj.is_a?(SomeClass)`.
- **Exceptions:** Never `rescue` bare or `rescue StandardError`; let them bubble to Sentry.
- **HUD-coded fields:** Use `HudHelper.util(hud_version)` when referencing HUD data elements, avoid hard-coding race, project-type, destination, etc.
