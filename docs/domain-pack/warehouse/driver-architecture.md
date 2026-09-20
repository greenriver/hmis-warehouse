---
title: Driver architecture
summary: "Features live as drivers under drivers/<name>, each mirroring the Rails layout with its own app, lib, config, and spec. Covers how config/application.rb autoloads and eager loads driver code, the feature initializer and the extension points it registers into, the extensions pattern that mixes behavior into core models through explicit includes, driver-local base controllers for HUD reports, the README convention, and a catalog of all 82 drivers grouped by kind."
area: warehouse
tags: [drivers, driver-architecture, RailsDrivers, feature-initializer, extensions, autoload_paths, eager_load_paths, collapse, hud_reports registration, sub_pop, extension-points, driver_setup, driver rake tasks, README]
sources:
  - docs/developer/drivers.md
  - docs/architecture/08-concepts/08-3-driver-module-pattern.md
  - config/application.rb
  - config/initializers/driver_setup.rb
  - lib/tasks/driver_tasks.rake
  - spec/spec_helper.rb
  - drivers/hud_apr/config/initializers/hud_apr_feature.rb
  - drivers/veterans_sub_pop/config/initializers/veterans_sub_pop_feature.rb
  - drivers/hmis_csv_twenty_twenty_six/config/initializers/hmis_csv_twenty_twenty_six_feature.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/extensions/grda_warehouse/upload_extension.rb
  - drivers/adults_with_children_sub_pop/app/models/adults_with_children_sub_pop/extensions/reporting/housed_extension.rb
  - app/models/grda_warehouse/upload.rb
  - app/models/reporting/housed.rb
  - app/controllers/hud_reports/base_controller.rb
  - drivers/hud_apr/app/controllers/hud_apr/base_controller.rb
  - drivers/hud_apr/config/routes.rb
  - drivers/hmis/README.md
related:
  - hud-reporting/report-framework.md
  - hud-reporting/report-drivers.md
  - conventions/do-not-repeat.md
  - conventions/house-style.md
---

## Purpose

How feature code is organized and wired into the application. A driver is a plain directory under `drivers/<name>/` that mirrors the Rails layout (`app/models`, `app/controllers`, `app/views`, `app/graphql`, `config/routes.rb`, `config/initializers`, `lib/tasks`, `spec`). Its constants live under the module Zeitwerk infers from the directory name (`hud_apr` -> `HudApr`). Drivers are not Rails engines and there is no driver gem; `config/application.rb`, `config/initializers/driver_setup.rb`, and `lib/tasks/driver_tasks.rake` wire them in by convention. As of 2026-09 there are 82 driver directories and no reference to `RailsDrivers` anywhere in the repository's Ruby code (`grep -rn RailsDrivers --include='*.rb' .` returns nothing).

Every driver is always loaded. There is no per-installation toggle at the driver level; a driver that provides optional behavior registers itself into a core extension point at boot, and an empty registry is the "off" state. Community-specific code is still present in every deployment; what differs is which reports are seeded and assigned.

This doc covers loading, the feature initializer, the extensions pattern for adding behavior to core models, driver-local base controllers for HUD-report drivers, the README convention, and a catalog of every driver directory grouped by kind. Fiscal-year registration of HUD report generators and the `UniverseMember`/`ReportInstance` extensions are described in `hud-reporting/report-framework.md`; per-report detail is in `hud-reporting/report-drivers.md`.

## Entry points

- `config/application.rb`: the driver block that adds each driver's `app/{models,controllers,mailers,helpers,jobs,graphql}` and `lib` to `autoload_paths` and `eager_load_paths`, declares the `config.*` extension-point registries, and defines the `load_driver_routes` and `load_driver_feature_initializers` initializers.
- `config/initializers/driver_setup.rb`: collapses `concerns/` and `app/models/<driver>/extensions/` directories in the main Zeitwerk loader and prepends every `drivers/*/app/views` as a view path.
- `lib/tasks/driver_tasks.rake`: loads `drivers/*/lib/tasks/**/*.rake` under `driver:<name>:`.
- `drivers/<name>/config/initializers/<name>_feature.rb`: where a driver registers into extension points (36 drivers have one; `drivers/hmis` has two initializer files).
- `drivers/<name>/app/models/<name>/extensions/**/*_extension.rb`: concerns a core model includes (170 files).
- `spec/spec_helper.rb`: requires `drivers/*/spec/support/*.rb`, adds `drivers/*/spec/factories` to FactoryBot, and adds driver directories to `project_source_dirs`. Specs run with `--pattern "spec/**/*_spec.rb,drivers/*/spec/**/*_spec.rb"`.
- `docs/developer/drivers.md` (how-to) and `docs/architecture/08-concepts/08-3-driver-module-pattern.md` (design rationale) are the human-facing docs.

## How it works

### Loading

`config/application.rb` iterates `Dir[root.join('drivers', '*', 'app')]` and, for each of `models`, `controllers`, `mailers`, `helpers`, `jobs`, `graphql` that exists, appends the directory to both `config.autoload_paths` and `config.eager_load_paths`. Every `drivers/*/lib` directory is appended to `autoload_paths` only, and its `tasks` subdirectory is ignored by the main autoloader (`Rails.autoloaders.main.ignore`) because rake files do not define constants. `app/views` is not an autoload path; `config/initializers/driver_setup.rb` calls `ActionController::Base.prepend_view_path` for each one instead.

Two `initializer` blocks in the same file finish the wiring. `load_driver_routes` (`before: :add_routing_paths, after: :bootstrap_hook`) unshifts every `drivers/*/config/routes.rb` onto `app.routes_reloader.paths`, so driver routes are part of the normal routes reload. `load_driver_feature_initializers` (`after: :load_config_initializers`) `load`s every `drivers/**/config/initializers/**/*.rb` in sorted order, so driver initializers run after everything in the core `config/initializers/` directory and can rely on the `config.*` registries already existing.

`config/initializers/driver_setup.rb` runs as an ordinary core initializer. It collapses the immediate `concerns/` child of each driver's `app/models`, `app/controllers`, and `app/graphql` (deeper `concerns/` directories such as `drivers/hmis/app/models/hmis/concerns/` keep their namespace segment), and collapses every `drivers/*/app/models/*/extensions` directory. Collapsing removes the directory from the constant path, which is what lets `drivers/cas_access/app/models/cas_access/extensions/user_extension.rb` define `CasAccess::UserExtension` rather than `CasAccess::Extensions::UserExtension`.

Because extension files sit under an autoload path owned by the main Zeitwerk loader, they load on demand and reload with the rest of the app; the comment in `driver_setup.rb` records that the earlier approach of `load`ing extensions from a `to_prepare` block could not survive a console `reload!`. New autoload paths are computed at boot, so adding a new driver directory or a new `app/<component>` directory requires a server restart; adding a file inside an existing path does not.

Rake tasks are the one place the driver name is used at runtime: `lib/tasks/driver_tasks.rake` extracts it from the path with a regex and nests the file's tasks under `namespace(:driver) { namespace(driver_name) { ... } }`, giving names like `driver:hmis:dump_graphql_schema`.

### Feature initializer

A driver hooks into core behavior from `drivers/<name>/config/initializers/<name>_feature.rb`. The file is plain Ruby loaded by `load_driver_feature_initializers`; most are a few lines. Two shapes appear. Registrations that only write into a `Rails.application.config.*` hash or array run at top level; registrations that call a core class method are wrapped in `Rails.application.reloader.to_prepare do ... end` so they re-run after a code reload (18 of the 37 files use `to_prepare`).

The registries are declared in `config/application.rb` under the comment `# Extension points`: `sub_populations`, `census`, `monthly_reports`, `hud_reports`, `hmis_exporters`, `synthetic_event_types`, `synthetic_assessment_types`, `synthetic_youth_education_status_types`, `patient_dashboards`, `hmis_migrations`, `hmis_data_lakes`, `custom_imports`, `supplemental_enrollment_importers`, `help_links`, `location_processors`, `queued_tasks`, `report_archival_types`. Counting across the 37 feature files as of 2026-09: `hud_reports` (33 writes, from `hopwa_caper`, `hud_apr`, `hud_hic`, `hud_lsa`, `hud_path_report`, `hud_pit`, `hud_spm_report`), `help_links` (11; consumed by `GrdaWarehouse::Help`), `queued_tasks` (5), `hmis_data_lakes` (4), `custom_imports` (4), `synthetic_assessment_types` (3), `synthetic_event_types` (2), `location_processors` (2).

Examples, each verified against the file:

- `drivers/hud_apr/config/initializers/hud_apr_feature.rb` sets `Rails.application.config.hud_reports['HudApr::Generators::Apr::Fy2026::Generator'] = { title:, helper: }` once per report type per fiscal year. Year registration and how `HudReports::BaseController` reads it are in `hud-reporting/report-framework.md`.
- `drivers/veterans_sub_pop/config/initializers/veterans_sub_pop_feature.rb` wraps four class-method calls in `to_prepare`: `AvailableSubPopulations.add_sub_population`, `GrdaWarehouse::Census.add_population`, `SubpopulationHistoryScope.add_sub_population`, and `Reporting::MonthlyReports::Base.add_available_type`. Those methods store into `config.sub_populations`, `config.census`, and `config.monthly_reports`.
- `drivers/hmis_csv_twenty_twenty_six/config/initializers/hmis_csv_twenty_twenty_six_feature.rb` registers an export version (`Filters::HmisExport.register_version('HMIS 2026', '2026', 'HmisCsvTwentyTwentySix::ExportJob')`), a data lake class name, and, gated on environment and date, a `queued_tasks` lambda.
- The three `hud_twenty_*_to_twenty_*` drivers call `Importers::HmisAutoMigrate.add_migration(version_string, transformer_class)` for every `CSVVersion` string they have seen.

Menu items are not registered here; a report appears in the UI through `GrdaWarehouse::WarehouseReports::ReportDefinition.report_list` and seeding, as `docs/developer/drivers.md` describes. Nothing in a feature initializer should test whether another driver is present.

### Extensions

A driver adds associations, scopes, or methods to a core model through an `ActiveSupport::Concern` that the core model includes explicitly. The concern lives at `drivers/<driver>/app/models/<driver>/extensions/<target namespace path>/<model>_extension.rb` and is named `<Driver>::<TargetNamespace>::<Model>Extension`; the `extensions` segment is collapsed by `config/initializers/driver_setup.rb`, so the path and constant match. As of 2026-09 there are 170 such files; the most-extended targets are `GrdaWarehouse::Hud::Client` (20 extensions), `GrdaWarehouse::Hud::Enrollment` (17), `GrdaWarehouse::ServiceHistoryEnrollment` (9), `Reporting::Housed` (8), and `GrdaWarehouse::Hud::Project` (8).

Two examples:

- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/extensions/grda_warehouse/upload_extension.rb` defines `HmisCsvImporter::GrdaWarehouse::UploadExtension`. Its `included` block adds `has_one :importer_log, through: :import_log`, `has_one :loader_log, through: :import_log`, and the `status` and `import_time` instance methods that the upload list renders. `app/models/grda_warehouse/upload.rb` includes it, next to `HmisCsvTwentyTwenty::GrdaWarehouse::UploadExtension`, under a comment marking the block as driver extensions.
- `drivers/adults_with_children_sub_pop/app/models/adults_with_children_sub_pop/extensions/reporting/housed_extension.rb` defines `AdultsWithChildrenSubPop::Reporting::HousedExtension`, whose `included` block defines `client_source` as `GrdaWarehouse::Hud::Client.destination.adults_with_children`. `app/models/reporting/housed.rb` includes all eight `*SubPop::Reporting::HousedExtension` concerns in a row.

Rules that follow from the mechanism:

- The core model owns the include list. Adding an extension means editing the core file (`app/models/grda_warehouse/hud/client.rb` has a block of 20 includes) and creating the concern at the conventional path. Nothing registers extensions automatically.
- Inside a driver namespace, an unqualified constant can resolve to a same-named child of that driver instead of the top-level namespace. Cross-driver includes use a leading `::`, for example `include ::ClientLocationHistory::Hmis::Hud::ClientExtension` in `drivers/hmis/app/models/hmis/hud/client.rb`.
- Drivers may extend other drivers' models the same way (the `hmis` driver includes `HmisExternalApis::Hmis::Hud::ProjectExtension` and similar), but the design rule in `docs/architecture/08-concepts/08-3-driver-module-pattern.md` is that a driver depends on core abstractions, not another driver's internals; it is enforced by review, not by code.
- `HudReports::UniverseMember` and `HudReports::ReportInstance` follow the same pattern for report snapshot associations; see `hud-reporting/report-framework.md`.

### Driver-local base controllers for HUD-report drivers

`app/controllers/hud_reports/base_controller.rb` (`HudReports::BaseController < ApplicationController`) holds the shared HUD report actions: `index`, `show`, `running`, `history`, `new`, `create`, and the version-selection helpers `available_report_versions`, `default_report_version`, `active_report_versions`. Each HUD-report driver builds on it in one of two ways.

Five drivers define a driver-local base class and subclass it from their resource controllers: `HudApr::BaseController`, `HopwaCaper::BaseController`, `HudDataQualityReport::BaseController`, `HudPathReport::BaseController`, and `HudSpmReport::BaseController`, each at `drivers/<name>/app/controllers/<name>/base_controller.rb`. `drivers/hud_apr/app/controllers/hud_apr/base_controller.rb` is the smallest useful example: it declares `class BaseController < ::HudReports::BaseController`, adds `before_action :filter`, and overrides `active_report_versions` to return `{ fy2026: 'FY 2026' }.invert.freeze`, which is what limits the "new report" form to the currently active year while `available_report_versions` still lists every registered year for viewing history. The leading `::` matters for the same namespace reason as extensions: `HudApr::HudReports` would otherwise be a candidate constant.

Three drivers skip the intermediate class and subclass `::HudReports::BaseController` directly from the resource controller: `HudHic::HicsController`, `HudLsa::LsasController`, and `HudPit::PitsController` (plus `HudPit::CellsController`).

Routes follow one shape. `drivers/hud_apr/config/routes.rb` opens `OpenPath::Application.routes.draw`, calls `extend HudReports::RouteConcerns` (defined in `lib/hud_reports/route_concerns.rb`, which `config/application.rb` requires early to avoid load-order problems in development), then declares `scope module: :hud_apr, path: :hud_reports, as: :hud_reports` with one `resources` block per report type, each using `concerns :hud_report_actions` and a nested `scope module:` with `concerns :hud_drilldown_actions`. The result is URLs under `/hud_reports/<plural>` and helpers such as `hud_reports_aprs_path`, which is the `helper:` string the feature initializer registers.

Authorization for all of these is the legacy `require_can_view_hud_reports!` flag check in the core base controller, not a policy; `hud-reporting/report-framework.md` has the detail.

### README convention

Every driver except `hmis_csv_importer`, `hmis_simulation`, and `performance_measurement` has a `README.md` (79 of 82 as of 2026-09), but most are two- or three-line stubs, many still containing the template sentence "This README file should be used to explain the functionality of the driver." The eight `*_sub_pop` READMEs are a copy-this-directory template listing the strings to replace. Do not treat a stub as evidence that a driver is trivial; `performance_measurement` has no README and a dozen model files.

READMEs with substantive content, in decreasing length: `ma_yya_report` (508 lines), `hmis_csv_twenty_twenty_six` (224), `hud_lsa` (176), `core_demographics_report` (71, and it points to `docs/features/warehouse/core-demographics-report.md`), `hmis` (67), the three older `hmis_csv_twenty_twenty*` drivers (57-58 each), `datalab_testkit` (46), and `access_logs` (30). Mid-length READMEs worth opening before touching the driver: `start_date_dq`, `user_directory_report`, `client_access_control`, `cas_ce_data`, the three `hud_twenty_*` translators, and `inactive_client_report`.

`drivers/hmis/README.md` is the operational reference for the HMIS driver: the environment variables that enable the HMIS API locally (`ENABLE_HMIS_API=true`, `HMIS_HOSTNAME=...`, comma-separated for multiple frontends), the multi-HMIS local setup, where end-to-end specs live (`drivers/hmis/spec/system/hmis`), and the manual checklist for a new deployment (HMIS data source, administrator role, permissions, file tags, unit types, custom service types, custom data element definitions, remote credentials, inbound API configurations, theme).

The catalog table records, for each driver, the first sentence of its README so an agent can tell a stub from a described driver without opening 82 files.

### Driver catalog

Generated from the `drivers/` directory listing on 2026-09-20 (82 directories). Grouping is a reading aid chosen for this doc; the code has no notion of driver groups. The "README, first sentence" column is taken from each driver's `README.md`; "README stub" means the file still holds only the template sentence.

#### HUD reports (8)

| Driver | README, first sentence |
| --- | --- |
| `hopwa_caper` | HOPWA CAPER; README points at docs/features/warehouse/hopwa-caper.md. |
| `hud_apr` | Plug-in for the Continuum of Care Annual Performance Report (CoC - APR), Emergency Solutions Grant Consolidated Annual Performance and... |
| `hud_data_quality_report` | The HUD Data Quality Report as described in the HMIS Standard Reporting Terminology Glossary. |
| `hud_hic` | HUD Report to generate data to be entered for the HIC. |
| `hud_lsa` | This module generates HUD LSA (Longitudinal System Analysis) reports by exporting data to an external MSSQL Server, using the HUD Sample... |
| `hud_path_report` | The 2021 HUD PATH Annual Report as described in... |
| `hud_pit` | HUD Report to generate data to be entered for the PIT. |
| `hud_spm_report` | HUD System Performance Measures. |

#### HMIS CSV import, export, and version migration (8)

| Driver | README, first sentence |
| --- | --- |
| `hmis_csv_importer` | No README. |
| `hmis_csv_twenty_twenty` | Exporting logic for HMIS CSV files in the 2020 HUD format. |
| `hmis_csv_twenty_twenty_four` | Exporting logic for HMIS CSV files in the 2024 HUD format. |
| `hmis_csv_twenty_twenty_six` | The `HmisCsvTwentyTwentySix` driver provides support for the FY2026 HUD HMIS CSV format. |
| `hmis_csv_twenty_twenty_two` | Exporting logic for HMIS CSV files in the 2022 HUD format. |
| `hud_twenty_twenty_four_to_twenty_twenty_six` | CSV translator between the HUD HMIS 2024 and 2026 standards. |
| `hud_twenty_twenty_to_twenty_twenty_two` | CSV translator between the HUD HMIS 2020 and 2022 standards. |
| `hud_twenty_twenty_two_to_twenty_twenty_four` | CSV translator between the HUD HMIS 2022 and 2024 standards. |

#### HMIS (2)

| Driver | README, first sentence |
| --- | --- |
| `hmis` | This driver contains all the backend logic for supporting the HMIS Frontend. |
| `hmis_external_apis` | This driver provides interfaces to query external APIs |

#### Sub-populations (8)

| Driver | README, first sentence |
| --- | --- |
| `adult_only_households_sub_pop` | Sub-population; README is the copy-this-directory template. |
| `adults_with_children_sub_pop` | Sub-population; README is the copy-this-directory template. |
| `adults_with_children_twentyfive_plus_hoh_sub_pop` | Sub-population; README is the copy-this-directory template. |
| `adults_with_children_youth_hoh_sub_pop` | Sub-population; README is the copy-this-directory template. |
| `child_only_households_sub_pop` | Sub-population; README is the copy-this-directory template. |
| `clients_sub_pop` | Sub-population; README is the copy-this-directory template. |
| `non_veterans_sub_pop` | Sub-population; README is the copy-this-directory template. |
| `veterans_sub_pop` | Sub-population; README is the copy-this-directory template. |

#### Custom imports and external data (10)

| Driver | README, first sentence |
| --- | --- |
| `cas_ce_data` | Propagate CAS generated CE assessments and events from CAS generated assessments (in the `cas_ce_assessments` table), and referral... |
| `custom_imports_boston_assessment_lookups` | This file format contains lookups used to turn AssessmentQuestion.AssessmentAnswer values into human-readable answers for display and... |
| `custom_imports_boston_community_of_origin` | Custom importer for Boston community of origin report. |
| `custom_imports_boston_contacts` | Custom import routines for contacts provided from an external source HMIS. |
| `custom_imports_boston_service` | This file format is specific to data used to augment HMIS Clients with service records which are collected outside of the enrollment... |
| `eccovia_data` | This driver provides a mechanism to fetch and store data via the Eccovia API. |
| `hmis_supplemental` | Support external data sets that supplement client and enrollment data. |
| `manual_hmis_data` | This driver provides the ability to create manual associations for Projects: Funders, Inventories and Project CoC Records. |
| `medicaid_hmis_interchange` | Adds the ability to query MassHealth for MedicaidIDs and generates a file to assist in verifying homelessness of patients at MassHealth. |
| `supplemental_enrollment_data` | This driver provides import facilities, and access hooks for supplemental enrollment data. |

#### Community-specific reports (8)

| Driver | README, first sentence |
| --- | --- |
| `all_neighbors_system_dashboard` | Implements the All Neighbors System Dashboard. |
| `boston_project_scorecard` | Implementation of the Boston CoC's Project Scorecard. |
| `boston_reports` | This driver will contain reports developed for Boston MA that may or may not be relevant to other installations. |
| `hap_report` | Implements the Pennsylvania Homeless Assistance Program Annual Report as described in the 2020 Instructions and Requirements. |
| `ma_reports` | This driver contains custom reports for the state of MA. |
| `ma_yya_followup_report` | The YYA Follow Up Report is used to identify youth clients who are due for a 3-month follow up. |
| `ma_yya_report` | Implementation of the quarterly report required for Massachusetts Executive Office of Health and Human Services (MA EOHHS) Youth and... |
| `tx_client_reports` | - Implementation of the 'Attachment III – Client Data Report' for Tarrant County. |

#### Platform tools and integrations (9)

| Driver | README, first sentence |
| --- | --- |
| `access_logs` | Audit reporting over who used the Warehouse, the HMIS, or CAS. |
| `cas_access` | CasAccess provides a minimal interface to CAS data to assist in reporting on said data. |
| `client_access_control` | This driver provides mechanisms to control access to client pages. |
| `datalab_testkit` | The Datalab Test Kit is a collection of HUD CSVs that describe a standard set of HMIS inputs and the outputs from running the HUD APR,... |
| `hmis_simulation` | No README. |
| `superset` | A very simple wrapper for a report that can be assigned to users so they can launch Superset from within the warehouse. |
| `text_message` | README stub. |
| `user_directory_report` | A searchable by name and email directory of users across the warehouse (and - in a later iteration - CAS). |
| `user_permission_report` | README stub. |

#### Warehouse reports and features (29)

| Driver | README, first sentence |
| --- | --- |
| `analysis_tool` | Report to analyze the cross-cut between two client sub-populations. |
| `built_for_zero_report` | Generate the monthly reporting data for Built For Zero using the change history for the BFZ system cohorts. |
| `ce_performance` | A reporting tool to track Coordinated Entry performance and utilization. |
| `census_tracking` | Census tracking worksheets. |
| `client_documents_report` | A report for identifying clients clients with specific documents, or clients who are missing specific documents. |
| `client_location_history` | README stub. |
| `core_demographics_report` | README points at docs/features/warehouse/core-demographics-report.md. |
| `data_source_report` | README stub. |
| `destination_report` | README stub. |
| `disability_summary` | README stub. |
| `financial` | An importer, processor, and view logic for financial transactions involved in housing clients. |
| `hmis_data_quality_tool` | The HMIS Data Quality tool is a screening tool to identify data quality issues that will affect the LSA or similar analyses. |
| `homeless_summary_report` | A summary of SPMs 1, 2, and 7 with sub-population and demographic details. |
| `inactive_client_report` | This driver provides a report for tracking down clients who are still enrolled but no longer active at the project, or in the homeless... |
| `income_benefits_report` | README stub. |
| `longitudinal_spm` | Compare quarterly System Performance Measurement Reports for length of time homeless, returns to homelessness, and successful placements... |
| `override_summary` | This driver provides a report to expose all overridden values for organizations, projects, project CoCs, inventories, and funding sources. |
| `performance_measurement` | No README. |
| `performance_metrics` | README stub. |
| `prior_living_situation` | README stub. |
| `project_pass_fail` | README stub. |
| `project_scorecard` | README stub. |
| `public_reports` | README stub. |
| `service_scanning` | README stub. |
| `start_date_dq` | This data quality report analyzes the relationship between a client's self-reported date homelessness started (DateToStreetESSH) and... |
| `synthetic_ce_assessment` | This driver provides an interface for configuring and generating synthetic CE assessments. |
| `system_pathways` | Reporting for pathways clients take through the continuum. |
| `vispdats` | README stub. |
| `zip_code_report` | A report that identifies the number of clients and households within a zip code. |


## Key files

- `config/application.rb:170` `driver_app_components`; `:172` autoload and eager-load loop over each driver app directory; `:184` driver lib autoload with the tasks subdirectory ignored; `:210` to `:227` the `config.*` extension-point registries; `:229` `load_driver_routes`; `:235` `load_driver_feature_initializers`.
- `config/initializers/driver_setup.rb:20` collapse of driver `concerns/`; `:31` collapse of driver extensions directories; `:36` `prepend_view_path`.
- `lib/tasks/driver_tasks.rake:14` `driver:<name>:` namespacing.
- `spec/spec_helper.rb:143` driver spec support files; `:146` driver factories; `:149` to `:151` driver `project_source_dirs`.
- `drivers/hud_apr/config/initializers/hud_apr_feature.rb`: `config.hud_reports` registration per fiscal year.
- `drivers/veterans_sub_pop/config/initializers/veterans_sub_pop_feature.rb`: the `to_prepare` registration shape for sub-populations, census, history scopes, monthly reports.
- `drivers/hmis_csv_twenty_twenty_six/config/initializers/hmis_csv_twenty_twenty_six_feature.rb`: export version, data lake, and gated `queued_tasks` registration.
- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/extensions/grda_warehouse/upload_extension.rb` and `app/models/grda_warehouse/upload.rb:85`: an extension and its include.
- `drivers/adults_with_children_sub_pop/app/models/adults_with_children_sub_pop/extensions/reporting/housed_extension.rb` and `app/models/reporting/housed.rb:15`: the sub-population extension shape and its include block.
- `app/controllers/hud_reports/base_controller.rb:115` `available_report_versions`; `:141` `default_report_version`; `:328` `active_report_versions`.
- `drivers/hud_apr/app/controllers/hud_apr/base_controller.rb:10` `class BaseController < ::HudReports::BaseController`; `:13` `active_report_versions` override.
- `drivers/hud_apr/config/routes.rb:10` `extend HudReports::RouteConcerns`; `:12` `scope module: :hud_apr, path: :hud_reports, as: :hud_reports`.
- `drivers/hmis/README.md`: HMIS driver local setup and deployment checklist.
- `docs/developer/drivers.md`, `docs/architecture/08-concepts/08-3-driver-module-pattern.md`: human-facing how-to and design rationale.

## Gotchas

- All drivers always load. Any check that a driver "is loaded" is dead code; the `RailsDrivers` constant no longer exists in the repository, so such a check would raise `NameError`.
- Autoload and eager-load paths are computed at boot from the directories that exist. A new driver, or a new `app/graphql` or `app/jobs` directory inside an existing driver, needs a server restart. `spring` or a long-running console will not see it either.
- The `extensions` directory segment is collapsed, so `drivers/foo/app/models/foo/extensions/bar/baz_extension.rb` must define `Foo::Bar::BazExtension`, not `Foo::Extensions::Bar::BazExtension`. Zeitwerk raises at eager load in CI if the constant name does not match.
- Only the immediate `concerns/` child of `app/models`, `app/controllers`, and `app/graphql` is collapsed. `drivers/hmis/app/models/hmis/concerns/` is a namespace (`Hmis::Concerns::...`) because it is one level deeper.
- The include-block comment in `app/models/reporting/housed.rb` and `app/models/grda_warehouse/upload.rb` reads "Extensions from drivers, see ADR 0007", but `docs/adr/0007-hmis-hud-import-cleanups-via-importer-extensions.md` is about HMIS CSV importer cleanup extensions, a different mechanism. The driver-extension design is documented in `docs/architecture/08-concepts/08-3-driver-module-pattern.md`, not in an ADR.
- Inside a driver module, `HudReports`, `GrdaWarehouse`, or `Hmis` can resolve to a nested namespace of the same name created by the driver's own extension files. Use `::HudReports::BaseController`, `::Hmis::...` when the target is top-level.
- Feature initializers load in sorted path order after core initializers. A registration into a `config.*` registry is safe at top level; a call to a core class method belongs in `Rails.application.reloader.to_prepare` or it will not survive a development reload.
- `spec/rails_helper.rb` treats specs under `hud_path_report`, `hud_spm_report`, and `hud_data_quality_report` specially (fixpoint loading), so moving a spec between those drivers and elsewhere can change its fixtures.
- Most driver READMEs are stubs. Substantive ones exist for `hud_lsa`, `hmis`, `hmis_csv_twenty_twenty_six`, `ma_yya_report`, `core_demographics_report`, `access_logs`, and `datalab_testkit`; do not assume the README describes the current code without checking dates and class names in it.

## Do not repeat

- Gating behavior on whether a driver is loaded (`RailsDrivers.loaded.include?(...)` or any equivalent). The shim is gone and every driver loads; call the driver's code directly. Repo-wide entry: `conventions/do-not-repeat.md`, entry 3.
- Reopening a core class from a driver (`class GrdaWarehouse::Hud::Client; def foo ...`) or `class_eval`/`prepend` from an initializer. Instead: an `ActiveSupport::Concern` at `drivers/<driver>/app/models/<driver>/extensions/<path>/<model>_extension.rb`, included from the core model. Example: `HmisCsvImporter::GrdaWarehouse::UploadExtension` included at `app/models/grda_warehouse/upload.rb:85`.
- Loading extension files from a `to_prepare` block or `require`ing them by path. The main Zeitwerk loader owns `app/models/<driver>/extensions/` via the collapse in `config/initializers/driver_setup.rb`; manual loading breaks `reload!`.
- Putting community-specific reports or importers in `app/`. They belong in a driver (`boston_reports`, `ma_reports`, `tx_client_reports`, `custom_imports_boston_*` are the existing examples). Core `app/` code is what every driver may depend on.
- A driver reaching into another driver's internals. Depend on core abstractions or the other driver's registered extension point; where a cross-driver include is unavoidable, qualify it with a leading `::`.
- Registering a HUD report year by editing an existing `FyXXXX` generator instead of adding a sibling namespace and a new `config.hud_reports` entry; see `hud-reporting/report-framework.md` and `conventions/do-not-repeat.md`, entry 12.

## Related

- `hud-reporting/report-framework.md`: fiscal-year registration, `UniverseMember` and `ReportInstance` driver extensions, `HudReports::BaseController` version selection.
- `hud-reporting/report-drivers.md`: per-driver status of the HUD report drivers in the catalog.
- `conventions/do-not-repeat.md`: entries 3 (driver-loaded checks) and 12 (fiscal-year generators).
- `conventions/house-style.md`: where new JavaScript and controllers go, which applies inside drivers too.
