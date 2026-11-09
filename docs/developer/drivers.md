# Drivers

Drivers are a code structure we use to isolate features to improve the developer experience.  Code in a driver lives within a sub-directory under
`drivers/` that mirrors the standard Rails layout (`app/models`, `app/controllers`, `app/views`,
`config/routes.rb`, `lib`, `spec`, …). Drivers allow us to keep feature-specific code out of the core `app/`
tree and help engineers compartmentalize work such that all code relating to a feature is in one directory and not mixed in with other feature code.

Drivers are **not** Rails engines and there is no longer a driver gem. They are plain directories that the
app wires into Zeitwerk and the boot process by convention. (This replaced the archived
`rails_drivers` gem, whose autoloading the app now replicates natively.) For the architectural
overview, see [8.3 Driver Module Pattern](../architecture/08-concepts/08-3-driver-module-pattern.md).

## Anatomy of a driver

```
drivers/my_feature/
  app/
    models/my_feature/...          # MyFeature::SomeModel
    controllers/my_feature/...
    views/my_feature/...
    models/my_feature/extensions/  # extensions to CORE models (see below)
  config/
    routes.rb                      # mounted into the app's routes
    initializers/my_feature_feature.rb
  lib/
    tasks/*.rake                   # exposed as `driver:my_feature:*`
  spec/
```

A driver's own code is namespaced under the driver's module (e.g. `MyFeature::SomeModel`), inferred
from the directory name by Zeitwerk (`my_feature` → `MyFeature`).

## How drivers are loaded

Everything is wired up natively (no gem). The relevant code:

- **Autoloading** (`config/application.rb`): each driver's `app/{models,controllers,mailers,helpers,jobs,graphql}`
  and `lib` are added to Zeitwerk's autoload paths. `lib/tasks` is ignored (rake files, not constants).
- **Concerns & extensions** (`config/initializers/driver_setup.rb`): only the immediate `concerns/`
  child of a driver's `app/models`, `app/controllers`, and `app/graphql`, and
  `app/models/<driver>/extensions/` directories, are *collapsed* so they don't add a namespace
  segment. Deeper ones such as `drivers/hmis/app/models/hmis/concerns/` keep it (`Hmis::Concerns::...`). Driver `app/views` are registered as view paths.
- **Routes** (`config/application.rb`): each `drivers/*/config/routes.rb` is prepended to the routes
  reloader, so drivers can declare their own routes.
- **Feature initializers** (`config/application.rb`): `drivers/**/config/initializers/**/*.rb` run
  after the app's own initializers.
- **Rake tasks** (`lib/tasks/driver_tasks.rake`): `drivers/*/lib/tasks/**/*.rake` are loaded under a
  `driver:<name>:` namespace (e.g. `bundle exec rake driver:hmis:dump_graphql_schema`).

## Feature initializers and extension points

All drivers are always loaded, so new code does not need to check whether a driver is available. A
driver's feature initializer (`drivers/<name>/config/initializers/<name>_feature.rb`) is where the
driver hooks into core **extension points** — registering sub-populations, monthly-report types,
census factories, and similar — typically inside `Rails.application.reloader.to_prepare do … end`.

A feature initializer is plain Ruby, loaded in sorted path order after all core initializers, so the
`config.*` registries declared under `# Extension points` in `config/application.rb` already exist.
Registrations that only write into a registry hash or array can run at top level. Registrations that
call a core class method (for example `GrdaWarehouse::Census.add_population`) belong in `to_prepare`;
otherwise they are lost on a development reload. A registry with no entries is the "off" state.
Don't test whether another driver is present.

Menu items are not registered in the initializer; reports appear through `ReportDefinition` seeding
(see "Adding a new report driver").

## Extending core models (extensions)

A driver can add behavior to a **core** model (e.g. `GrdaWarehouse::Hud::Client`, `User`) via an
*extension* concern. Extensions live under the driver's models namespace, in an `extensions/`
directory whose path segment is collapsed away:

```
drivers/my_feature/app/models/my_feature/extensions/grda_warehouse/hud/client_extension.rb
```

```ruby
module MyFeature::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    included do
      has_many :my_feature_things
    end
  end
end
```

The core model includes it explicitly:

```ruby
# app/models/grda_warehouse/hud/client.rb
include MyFeature::GrdaWarehouse::Hud::ClientExtension
```

Because the `extensions` directory is collapsed, the file at
`app/models/my_feature/extensions/grda_warehouse/hud/client_extension.rb` autoloads as the constant
`MyFeature::GrdaWarehouse::Hud::ClientExtension` — exactly matching the `include`. Extensions are
owned by the main Zeitwerk autoloader, so they load on demand and reload correctly in development
(`reload!` works). They live under `app/models/<driver>/extensions/` (rather than a top-level
`drivers/<name>/extensions/` directory) specifically so the main autoloader owns them.

> **Namespace gotcha:** inside one driver's namespace, an unqualified reference to *another*
> top-level namespace can resolve to a same-named child. Prefer a leading `::` when including a
> cross-namespace extension, e.g. `include ::Hmis::ClientLocationHistory::LocationExtension`.

The core model owns the include list; nothing registers extensions automatically, so a new extension
means editing the core model. Drivers may extend each other's models the same way, but the design rule
(see the architecture doc above) is that a driver depends on core abstractions, not another driver's
internals. That rule is enforced by review, not code.

The include-block comment in `app/models/reporting/housed.rb` and `app/models/grda_warehouse/upload.rb`
cites ADR 0007. That ADR covers HMIS CSV importer cleanup extensions, a different mechanism. Driver
extensions are documented in the architecture doc, not in an ADR.

## Driver-local base controllers for HUD reports

HUD report drivers build on `HudReports::BaseController`. `HudApr`, `HopwaCaper`,
`HudDataQualityReport`, `HudPathReport`, and `HudSpmReport` define a driver-local `BaseController`
and subclass it. `HudHic`, `HudLsa`, and `HudPit` subclass `::HudReports::BaseController` directly.
Always use the leading `::`; inside the driver namespace `HudReports` can resolve to a same-named child.

A local base controller overrides `active_report_versions` to limit the "new report" form to the
current fiscal year, while `available_report_versions` still lists every registered year so older
reports stay viewable. Routes use `extend HudReports::RouteConcerns` and
`concerns :hud_report_actions`, producing `/hud_reports/<plural>` URLs. Fiscal-year registration is
in [HUD report framework](../features/warehouse/hud-report-framework.md).

## Creating a new driver

There is no generator (the old `rails g driver` came from the removed gem). Create a driver by hand:

1. `mkdir -p drivers/my_feature/app/models/my_feature` and add code under the `MyFeature` namespace.
2. If the driver hooks into core extension points (sub-populations, report types, census factories,
   etc.), add `drivers/my_feature/config/initializers/my_feature_feature.rb` and register them there
   (copy an existing `*_feature.rb` as a template).
3. Add `drivers/my_feature/config/routes.rb`, controllers, and views as needed (namespaced under the
   driver).
4. Restart the server (autoload paths are computed at boot). This also applies to a new `app/graphql`
   or `app/jobs` directory in an existing driver; adding a file inside an existing path does not.

### Adding a new report driver

For a report, after the steps above, register it with the report framework:

1. Add the report to `report_list` in
   `app/models/grda_warehouse/warehouse_reports/report_definition.rb`.
2. Seed it: `bundle exec rails db:seed`, or run the two steps individually:
   ```ruby
   GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
   AccessGroup.maintain_system_groups
   ```

## Gotchas

- Driver READMEs are mostly stubs, and the `*_sub_pop` READMEs are a copy-this-directory template. A
  stub is not evidence a driver is trivial. Check dates and class names in the substantive ones
  before trusting them. `drivers/hmis/README.md` is the reference for local HMIS API setup and the
  new-deployment checklist.
- Specs under `hud_path_report`, `hud_spm_report`, and `hud_data_quality_report` trigger fixpoint
  loading in `spec/rails_helper.rb`; moving a spec in or out of those drivers can change its fixtures.
- Community-specific reports and importers belong in a driver, not core `app/`. Which reports a
  deployment sees depends on seeding and assignment, not on which drivers load.
