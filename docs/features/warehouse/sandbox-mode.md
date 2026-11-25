---
sources:
  - app/models/sandbox_mode.rb
  - app/models/sandbox_mode/scrubber.rb
  - app/mail_interceptors/sandbox_email_interceptor.rb
  - config/initializers/sandbox_mode.rb
  - config/initializers/sandbox_email_interceptor.rb
  - lib/tasks/sandbox.rake
  - config/schedule.rb
  - app/controllers/application_controller.rb
  - app/models/grda_warehouse/remote_credential.rb
  - app/models/grda_warehouse/recurring_hmis_export.rb
  - app/controllers/user_training_controller.rb
  - app/models/talentlms/config.rb
  - app/models/talentlms/course.rb
  - drivers/eccovia_data/app/models/eccovia_data/fetch.rb
  - drivers/hmis_supplemental/app/models/hmis_supplemental/data_set.rb
---

# Sandbox Mode

Sandbox mode lets an environment built from a production snapshot run without contacting external partners. It has three parts: the `SANDBOX_MODE` switch (`SandboxMode`), the `sandbox:scrub` rake task (`SandboxMode::Scrubber`), and an email domain allow-list (`SandboxEmailInterceptor`). This doc does not cover the training-site email banner that `SandboxEmailInterceptor` also adds when `Rails.configuration.sandbox_email_mode` is on.

## The three switches

| Switch | What it does |
|---|---|
| `SANDBOX_MODE=true` | `SandboxMode.enabled?` is true only for the exact value `true`. Any other value, such as `1` or `TRUE`, is ignored and logged. |
| `SANDBOX_EMAIL_ALLOWED_DOMAINS` | Turns on the email domain filter when the variable is set at all. The value is a comma-separated list of domains. Set but empty means no domain is allowed, so all mail is dropped. |
| `rails sandbox:scrub` | Blanks credentials in the database and empties `delayed_jobs`. |

The switches are independent. `SANDBOX_MODE` does not turn on the email filter, and the email filter does not depend on `RAILS_ENV`. On boot, `config/initializers/sandbox_mode.rb` logs a warning for each state: sandbox mode on, `SANDBOX_MODE` set to an ignored value, and the number of allowed email domains (never the domains).

## How sandbox mode blocks a call

Two mechanisms, chosen by whether the outbound call has a config lookup to hang a scope on.

- **`active` scopes.** Integration config models (`GrdaWarehouse::RemoteCredential`, `RemoteConfig`, `HmisImportConfig`, `EtoApiConfig`, `CustomImports::Config`, `Health::ImportConfig`, `TextMessage::Topic`, and the scopes added for `LftpS3Sync` and `RecurringHmisExport`) wrap their `active` scope in `SandboxMode.filter`, which returns `none` when sandbox mode is on. A path gated this way fails the same way it fails when the config is missing, for example `RecordNotFound` or a silent no-op. CSG Engage, Built for Zero, Eccovia, and HMIS supplemental select the same rows they always did, wrapped in `SandboxMode.filter` (`RemoteCredential.outbound_allowed`, `EccoviaData::Fetch.outbound_allowed`, `HmisSupplemental::DataSet.syncable`), so outside sandbox mode an inactive credential is still used.
- **Direct guards.** Where no config lookup exists, the method that makes the call uses `SandboxMode.guard!(name)`, which raises `SandboxMode::IntegrationDisabled`. Scheduled and background paths return early instead of raising.

## What goes dark in sandbox mode

- Scheduled data pulls and pushes: ETO, Eccovia, LFTP-to-S3 sync, HMIS import and custom import S3 reads, HMIS supplemental S3 sync, health import and MassHealth SOAP, recurring HMIS exports.
- Outbound messages: SMS through SNS (`TextMessage::Message`) and TalentLMS calls.
- Public report publishing to S3 (`WarehouseReports::S3Toolset`), and geocoding through Nominatim (`GrdaWarehouse::Place` and the TC HMIS demographics loader).
- The TalentLMS training requirement. `ApplicationController#require_training!` returns early, so users reach normal pages without completing training. `/user_training` redirects instead of contacting TalentLMS, and saving a TalentLMS config or course skips the remote check.
- Features that read an active `RemoteCredential` and so find none: HMIS external forms, the ClientView link on HMIS clients (`HmisExternalApis::AcHmis::Clientview.link_base`), the CSG Engage menu item, app stats collection, `GrdaWarehouse::Tasks::GrStaffReport`, and the data-source stall warning for sources the scrub pauses.
- The `driver:hmis_simulation:run_all` schedule entry. A staging-env sandbox would otherwise run the simulation against the cloned data, so with `SANDBOX_MODE=true` it is scheduled only when `ENABLE_HMIS_SIMULATION=true`.

## Decisions that shape behavior

- **Identity providers stay on.** The scrub sets `idp_service_configs.manage_users` to false on every row and leaves `active` and the other columns alone. Logins keep working and the sandbox stops creating or changing users in the provider.
- **Recurring HMIS exports.** `GrdaWarehouse::RecurringHmisExport.active` is empty in sandbox mode, so scheduled runs stop. `RecurringHmisExport#store` also returns before any S3 call, so an export run by hand never uploads.
- **Scrub refusals.** `SandboxMode::Scrubber.authorize!` raises `Refused` when the environment is `production`, when `SANDBOX_MODE` is not on, or when `SANDBOX_SCRUB_CONFIRM` does not equal `Rails.env`. The rake task aborts with that message.
- **Manual uploads still import.** `HmisSupplemental::ImportJob` skips only the S3 read in sandbox mode, and logs that it did. A CSV passed in directly still imports.

## Internal integrations that stay on

CAS (database writes and `configs.cas_url`), Superset (Doorkeeper and the Superset API), identity providers (oauth2-proxy, omniauth, `idp_service_configs`, Keycloak and Okta), and the HMIS frontend. The scrub and the `active` scopes do not touch their tables, ENV, or code paths, except for `manage_users` above. Inbound credentials (`oauth_applications`, `inbound_api_configurations`) are left as they are.

## What the scrub changes

`SandboxMode::Scrubber#run!` runs in separate transactions against the warehouse, app, and health databases and returns a hash of table name to rows changed. It logs the three database names and each count at `warn`, never row contents.

- Credentials, hosts, and buckets in the warehouse integration tables are replaced with `sandbox-scrubbed`, `sandbox.invalid`, or `NULL`, and `active` is set false. `SandboxMode::Scrubber` is the authority on which tables and columns.
- Soft-deleted rows are scrubbed too, so restoring a deleted row cannot bring back working credentials.
- Secrets are written through the `attr_encrypted` writer, so scrubbed values still decrypt and admin pages that render them do not raise.
- Data sources get `import_paused`. `delayed_jobs` is emptied. External-form settings in `AppConfigProperty` are pointed at `sandbox.invalid` or removed. `GrdaWarehouse::Config.invalidate_cache` runs afterward.
- Health tables are reported as `skipped` when the health database is missing or has no `import_configs` table.

## Email

`SandboxEmailInterceptor` is registered from an initializer when `Rails.configuration.sandbox_email_mode` is on or the domain filter is on.

- Addresses in `to`, `cc`, and `bcc` are kept only when the domain after `@` matches an allowed domain exactly, ignoring case. `example.org` does not allow `mail.example.org`. A field that fails to parse is cleared, including any valid addresses in it. Display names are preserved. When `sandbox_email_mode` is also on, `bcc` is then replaced with `SANDBOX_RECIPIENTS`. Those addresses skip the domain check and receive every mail that still has an allowed recipient, and any `bcc` address the filter kept is dropped.
- When all three fields end up empty on a real transport, delivery is cancelled. Logs carry counts, not addresses.
- The outer `Mail::DatabaseDelivery` pass is not filtered, so in-app `Message` rows are kept. Each recipient's real email goes through `ImmediateMailer`, which the interceptor filters.
- Keycloak and CAS send their own email outside this interceptor.

## Order of operations

The steps depend on each other in this order:

1. Background workers are stopped, so no queued job runs against restored data.
2. The snapshot is restored.
3. `SANDBOX_MODE=true` is set before the scrub, because `sandbox:scrub` refuses to run without it.
4. `SANDBOX_SCRUB_CONFIRM=<RAILS_ENV> rails sandbox:scrub` runs. It refuses `production`, so a clone that runs as `production` has to be scrubbed under another environment name pointed at the same databases.
5. The remaining ENV is set (checklist below).
6. Workers start. Starting them earlier lets queued jobs and scheduled tasks use the restored credentials.

## ENV checklist

The scrub changes database rows only. These are set by the deployment:

| Variable | Why it matters |
|---|---|
| `SANDBOX_MODE`, `SANDBOX_EMAIL_ALLOWED_DOMAINS`, `SANDBOX_RECIPIENTS` | The switches above, and the BCC list for sandbox email mode. |
| SMTP or SES endpoint and credentials | Real mail reaches this transport. |
| ActiveStorage bucket, AWS role | File storage otherwise points at production. |
| Slack exception webhook, Sentry DSN | Errors otherwise report into production channels. |
| `FQDN` | Links in mail and exports otherwise point at production. |
| `NO_LSA_RDS`, `LSA_DB_HOST` | The LSA database host is outside the scrub. |
| `DATABASE_CAS_DB`, `CAS_DATABASE_*` | CAS is an internal integration and the scrub does not touch it. These select which CAS database the sandbox writes to. |
| `KEYCLOAK_*`, `OKTA_*`, `HMIS_OKTA_*`, `ISS_URL`, `JWKS_URL` | Identity provider endpoints for the sandbox's own login. |
| `SUPERSET_*` | Superset connection for the sandbox. |
| `ENABLE_HMIS_API` | Selects whether the sandbox serves the HMIS API. |
| `S3_PUBLIC_*` | Public report bucket credentials come from ENV, not the database. |
| `CENSUS_API_KEY`, `WEATHER_TOKEN` | Read-only public APIs with no PII. They stay on, using whatever keys the deployment sets. |
| `ENABLE_HMIS_SIMULATION` | Overrides the simulation schedule exclusion. |

## Adding an integration

New code that calls an external partner picks one of two routes:

- Look up its config through an `active` scope wrapped in `SandboxMode.filter`.
- Call `SandboxMode.guard!('Name')` at the outbound call when there is no config lookup.

Add its credential columns to `SandboxMode::Scrubber` so the clone does not carry working secrets.

## Limits

- Saving an MCI ID from the HMIS frontend in an install with MCI enabled raises in sandbox mode, because the MCI credential lookup finds no active credential.
- The snapshot, any backup taken before the scrub, and the production `ENCRYPTION_KEY` (the clone uses the same key) all hold live secrets. The scrub protects the running sandbox, not those copies.
- Inbound credentials (`oauth_applications`, `inbound_api_configurations`) are not rotated, so a clone accepts the same inbound credentials as production.
- `SANDBOX_MODE` and the email filter are separate switches. A sandbox with only one of them set can still send real mail or call partners.

## Related

- [Recurring HMIS Exports](recurring-hmis-exports.md): the scheduled runs that stop in sandbox mode.
- [HMIS Supplemental Data](hmis-supplemental.md): the S3 sync that stops in sandbox mode.
- [Background Jobs](background-jobs.md): the schedule and queues the runbook order refers to.
- [HMIS Simulation](hmis-simulation.md): the schedule entry sandbox mode suppresses.
