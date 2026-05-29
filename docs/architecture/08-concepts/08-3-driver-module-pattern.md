# 8.3 Driver Module Pattern

[← 8.2 Security & Access Control](08-2-security.md) | [Table of Contents](../README.md) | [Next: 8.4 Background Processing →](08-4-background-processing.md)

The driver module pattern is the primary mechanism for organizing features within the Rails
monolith. Large or optional features are isolated as self-contained module directories under
`drivers/`, keeping feature-specific logic out of the core `app/` namespace.

## Convention

Each driver lives in `drivers/[module]` and mirrors the standard Rails directory structure
(`app/models/`, `app/controllers/`, `app/views/`, `config/routes.rb`, `lib/`, `spec/`, …). A
driver's own classes are namespaced under the driver's module, inferred from the directory name
(`client_location_history` → `ClientLocationHistory`).

Drivers are a **convention, not Rails engines**. There is no per-driver gem, `Rails::Engine`, or
`.gemspec` — each driver is a plain set of directories that the application registers with Zeitwerk
and the boot sequence. (This replaces the archived `rails_drivers` gem; the application now
replicates its autoloading, route loading, initializer loading, and rake-task loading natively.)

## Isolation model

- Feature-specific models, controllers, views, jobs, GraphQL types, and reports belong in a driver.
- Cross-cutting/shared concepts (the HUD data model, auth policies, the report framework, shared
  concerns) belong in the core `app/`.
- A driver never reaches into another driver's internals directly; it depends on core abstractions
  or on another driver's presence via the feature registry (below).

## Registration and loading

The wiring lives in `config/application.rb` and `config/initializers/driver_setup.rb`:

| Concern | Mechanism |
| --- | --- |
| **Autoloading** | Each driver's `app/{models,controllers,mailers,helpers,jobs,graphql}` and `lib` are added to Zeitwerk autoload paths. `lib/tasks` is ignored (rake files are not autoloadable constants). |
| **Concerns** | `drivers/*/app/{models,controllers,graphql}/concerns` are `collapse`d so files map without a `Concerns::` segment. |
| **Model extensions** | `drivers/*/app/models/*/extensions` are `collapse`d so a driver can extend core models — see below. |
| **Views** | Each driver's `app/views` is registered as a view path. |
| **Routes** | Each `drivers/*/config/routes.rb` is prepended to the routes reloader. |
| **Feature initializers** | `drivers/**/config/initializers/**/*.rb` run after the app's own initializers. |
| **Rake tasks** | `drivers/*/lib/tasks/**/*.rake` are loaded under a `driver:<name>:` namespace (`lib/tasks/driver_tasks.rake`). |

### Feature initializers and extension points

All drivers are always loaded, so there is no per-driver availability gate in new code. A driver's
`*_feature.rb` initializer is where it plugs into core extension points (sub-populations,
monthly-report types, census factories, HUD report registrations, …).

A legacy registry, `RailsDrivers.loaded` (a thin shim in `lib/rails_drivers.rb` left from the former
driver gem), still backs ~150 existing `RailsDrivers.loaded.include?(:driver)` guard checks. Since
every driver is now always present those checks are always true; they are slated for cleanup and new
code should not add them.

### Extending core models

A driver extends a **core** model with an `ActiveSupport::Concern` placed under its models namespace
in a collapsed `extensions/` directory:

```
drivers/my_feature/app/models/my_feature/extensions/grda_warehouse/hud/client_extension.rb
  -> MyFeature::GrdaWarehouse::Hud::ClientExtension
```

The core model includes it explicitly
(`include MyFeature::GrdaWarehouse::Hud::ClientExtension`). Because the `extensions` segment is
collapsed, the file path maps to exactly that constant under the main autoloader, so extensions load
on demand and reload in lockstep with the rest of the app in development.

## Inter-driver dependencies

When one driver legitimately depends on another (e.g. report drivers depending on shared
sub-population filter drivers), the dependency is expressed directly through the depended-on
driver's public constants (every driver is always loaded, so no availability check is needed).
Within a driver's namespace, prefer a leading `::` when referencing another top-level namespace to
avoid constant-resolution shadowing (e.g. `include ::Hmis::ClientLocationHistory::LocationExtension`).

## Creating a new driver

There is no generator (the old `rails g driver` came from the removed gem). Create a driver by hand:
make `drivers/<name>/app/models/<name>/`, add a `config/initializers/<name>_feature.rb` that
registers the driver, declare routes/controllers/views as needed, and restart so new autoload paths
are picked up. See the developer how-to: [Drivers](../../developer/drivers.md).

## Related Building Blocks

- [5.2.1 Warehouse Application](../05-building-blocks/05-2-1-warehouse.md) — the driver catalog
  groups the 88 existing drivers by functional area.
- [Drivers (developer how-to)](../../developer/drivers.md) — practical guide to working with and
  creating drivers.
