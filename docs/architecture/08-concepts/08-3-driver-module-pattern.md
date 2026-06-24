# 8.3 Driver Module Pattern

[← 8.2 Security & Access Control](08-2-security.md) | [Table of Contents](../README.md) | [Next: 8.4 Background Processing →](08-4-background-processing.md)

## Motivation

The Warehouse contains a large number of features that each bring their own models, controllers, views, routes, and specs. Rails namespacing (`app/models/my_feature/`) can keep constants separated, but a feature's code is still scattered across `app/models`, `app/controllers`, `app/views`, `spec`, which makes it hard to discover and navigate.

The driver module pattern addresses this by giving each feature its own self-contained directory under `drivers/`, keeping features out of `app/`. The drivers pattern provides soft namespace isolation. While many drivers are specific to certain communities, there are no optional drivers, all code is loaded.

## What constitutes a feature

A "feature" in this context is any cohesive unit of functionality that can be namespaced away from
the core application. The existing drivers span a wide range of scope and complexity.

The boundary for "this should be a driver" is whether the code can live entirely under its own
namespace without polluting core models and controllers. A driver can be as small as a single
report or as large as the entire HMIS module.

## Design decisions

**Convention over engines.** Drivers are plain directories, not `Rails::Engine` subclasses. This
avoids the overhead of per-driver gems, gemspecs, and engine configuration while still providing
namespace isolation. The application wires drivers into Zeitwerk and the boot sequence itself,
replacing the archived `rails_drivers` gem.

**Always loaded.** Every driver is present on every boot — there is no conditional loading or
feature-flag gating at the driver level. This eliminates an entire class of "is this driver
available?" checks and makes the constant graph deterministic. Drivers that provide optional
behavior register themselves with core extension points (sub-population registries, report
catalogs, census factories) at boot; if no driver registers, the extension point is simply empty.

**Core owns inclusion.** A driver may extend a core model (e.g. adding associations or scopes to
`GrdaWarehouse::Hud::Client`), but it does so via an `ActiveSupport::Concern` that the core model
explicitly `include`s. The core model controls what gets mixed in — drivers cannot silently
monkey-patch shared classes.

**No cross-driver coupling.** A driver depends on `app/` (core) abstractions, never on another
driver's internals. When two drivers need to interact (e.g. a report driver using a sub-population
filter driver), the dependency flows through the depended-on driver's public constants or through
a core extension point. There is no formal dependency graph enforced at boot; this is a convention
maintained through code review.

## Tradeoffs

| Accepted | Consequence |
| --- | --- |
| No engine-level isolation | Drivers share the same database connections, route namespace, and middleware stack. A misbehaving driver can affect the whole app. |
| All drivers always loaded | Boot time and memory footprint scale with the number of drivers (~88 today), even if a deployment doesn't use all of them. |
| No enforced dependency graph | Inter-driver dependencies are implicit. Circular references are possible and must be caught in review. |
| Core model `include` statements grow | High-touch models like `Client` and `Enrollment` accumulate many extension includes. This is visible clutter but keeps the coupling explicit. |
| Deep file paths | The mirrored Rails layout inside each driver produces long paths, (e.g. `drivers/client_access_control/app/models/client_access_control/extensions/grda_warehouse/hud/client_extension.rb`). This is the cost of co-location and Zeitwerk-compatible naming. |

## Relationship to other concepts

- **HUD Data Model (8.1)** — Core HUD models live in `app/`; drivers extend them with
  feature-specific associations and scopes via the extension mechanism.
- **Security & Access Control (8.2)** — Authorization policies live in `app/`; drivers register
  their controllers and resources with the shared policy framework.
- **Report Framework (8.5)** — Each report is a driver. The report lifecycle (setup, compute,
  persist, render) is defined in core; drivers supply the report-specific logic.
- **Background Processing (8.4)** — Driver jobs inherit from the core `BaseJob` and run on the
  shared job infrastructure.

## Further reading

- [5.2.1 Warehouse Application](../05-building-blocks/05-2-1-warehouse.md) — driver catalog grouped
  by functional area.
- [Drivers (developer how-to)](../../developer/drivers.md) — practical guide to directory layout,
  loading mechanics, and creating new drivers.
