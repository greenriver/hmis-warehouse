---
title: HMIS external APIs driver
summary: "drivers/hmis_external_apis holds integrations that cross the HMIS boundary. Public external forms (generate, publish to S3, accept submissions, process later without validation), the AC HMIS integration (MCI clearance, MPER lookups, inbound referral posting, the mostly deprecated LINK client, data warehouse API and SFTP exports, report API), and the TC HMIS spreadsheet importers."
area: hmis
tags: [hmis, external-apis, HmisExternalApis, external-forms, FormGenerator, FormPublication, FormSubmission, ac_hmis, MCI, MPER, ReferralPosting, LinkApi, DataWarehouseApi, ReportApi, WarehouseChangesJob, ExternalId, UnitAvailabilitySync, tc_hmis, RemoteCredential, InboundApiConfiguration]
sources:
  - drivers/hmis_external_apis/app/controllers/hmis_external_apis/base_controller.rb
  - drivers/hmis_external_apis/app/controllers/hmis_external_apis/external_forms_controller.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/external_forms/config.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/external_forms/form_generator.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/external_forms/form_publication.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/external_forms/form_submission.rb
  - drivers/hmis_external_apis/app/jobs/hmis_external_apis/publish_external_forms_job.rb
  - drivers/hmis_external_apis/app/jobs/hmis_external_apis/consume_external_form_submissions_job.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/mci.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/mper.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/referral.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/referral_posting.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/configuration.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/link_api.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/data_warehouse_api.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/report_api.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/unit_availability_sync.rb
  - drivers/hmis_external_apis/app/jobs/hmis_external_apis/ac_hmis/warehouse_changes_job.rb
  - drivers/hmis_external_apis/app/controllers/hmis_external_apis/ac_hmis/referrals_controller.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/external_id.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/oauth_client_connection.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/extensions/grda_warehouse/remote_credential_extension.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/tc_hmis/importers/importer.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/tc_hmis/importers/loaders/custom_data_element_helper.rb
  - drivers/hmis_external_apis/lib/tasks/tc_hmis.rake
related:
  - hmis/forms.md
  - hmis/coordinated-entry.md
  - warehouse/driver-architecture.md
---

## Purpose

`drivers/hmis_external_apis` is where HMIS data crosses the application boundary to or from a
system that is not the React front-end. It holds three unrelated integrations under one
`HmisExternalApis` namespace:

- **External forms**: an `Hmis::Form::Definition` with role `EXTERNAL_FORM` is rendered to a
  static HTML page, published to a public S3 bucket, and filled out by the public. Submissions
  land in a second S3 bucket, are pulled into `HmisExternalApis::ExternalForms::FormSubmission`,
  and are processed by HMIS staff at review time.
- **AC HMIS**: outbound OAuth clients for MCI client clearance, the AC data
  warehouse (MCI Unique IDs), the LINK referral system (now mostly deprecated) and a reports
  API; inbound API-key endpoints that receive referral postings and answer involvement queries;
  nightly SFTP exports to the county data warehouse.
- **TC HMIS**: one-directional spreadsheet importers that load legacy
  assessments, services, and demographics into custom data elements.

Every outbound connection reads its secrets from a `GrdaWarehouse::RemoteCredential` STI row
found by `slug`; every inbound endpoint validates a hashed API key from
`HmisExternalApis::InboundApiConfiguration`. Local records that mirror an external identity
(MCI IDs, MCI Unique IDs, MPER unit-type IDs) live in `HmisExternalApis::ExternalId`, a
polymorphic table keyed by `namespace` + `value` + `source`.

The driver extends core models through concerns under
`drivers/hmis_external_apis/app/models/hmis_external_apis/extensions/`, so `Hmis::Hud::Client`
gains `external_ids` and `ac_hmis_mci_ids`, `Hmis::Hud::Enrollment` gains `external_referrals`,
and `GrdaWarehouse::RemoteCredential` gains `external_ids`. The `hmis` driver calls into this
driver directly (for example `HmisExternalApis::AcHmis::Mci.enabled?` in
`Hmis::Hud::Processors::ClientProcessor`), but the reverse dependency is what this driver is
for: anything county-specific belongs here, not in `drivers/hmis`.

## Entry points

External forms:

- `HmisExternalApis::PublishExternalFormsJob#perform(definition_id)`
  (`drivers/hmis_external_apis/app/jobs/hmis_external_apis/publish_external_forms_job.rb`) renders
  and uploads one published `EXTERNAL_FORM` definition. Run manually; not scheduled.
- `HmisExternalApis::ConsumeExternalFormSubmissionsJob` pulls submissions from S3. Called every
  hour from the `grda_warehouse:hourly` rake task (`lib/tasks/grda_warehouse.rake`) when HMIS is
  enabled, and on demand by the `Mutations::RefreshExternalSubmissions` GraphQL mutation.
- `HmisExternalApis::ExternalFormsController` (`external_forms_controller.rb`) is development
  only; its `before_action` raises outside `Rails.env.development?`. Routes are wrapped in the
  same guard in `drivers/hmis_external_apis/config/routes.rb`.
- Review happens in the `hmis` driver: `Mutations::UpdateExternalFormSubmission` sets status to
  `reviewed` and calls `FormSubmission#run_form_processor`.

AC HMIS inbound (API key, no session):

- `POST /hmis_external_api/ac_hmis/referrals` ->
  `HmisExternalApis::AcHmis::ReferralsController#create`, which validates against
  `drivers/hmis_external_apis/public/schemas/referral.json` and runs
  `HmisExternalApis::AcHmis::CreateReferralJob.perform_now`.
- `GET /hmis_external_api/ac_hmis/program_involvements` and `client_involvements` ->
  `HmisExternalApis::AcHmis::InvolvementsController`.

AC HMIS outbound:

- `HmisExternalApis::AcHmis::Mci#clearance`, `#create_mci_id`, `#update_client`, called from
  `Mutations::AcHmis::ClearMci`, `Hmis::Hud::Processors::ClientProcessor#process_mci`, and
  `HmisExternalApis::AcHmis::UpdateMciClientJob`.
- `HmisExternalApis::AcHmis::WarehouseChangesJob`, run by the `import:remote_data` rake task
  (`lib/tasks/import.rake`) through `driver:hmis_external_apis:import:ac_warehouse_changes`.
- `HmisExternalApis::AcHmis::DataWarehouseUploadJob`, enqueued at 20:00 by
  `grda_warehouse:hourly` via `driver:hmis_external_apis:export:ac_clients`.
- `HmisExternalApis::AcHmis::UpdateReferralPostingJob`, called from
  `Mutations::AcHmis::UpdateReferralPosting` for LINK-originated postings.

TC HMIS:

- `HmisExternalApis::TcHmis::Importers::Importer.perform(dir:, clobber:, log_file:)`, run by
  hand from a console against an unpacked directory of spreadsheets.

## How it works

### External forms

Publishing starts from a form built in the Form Builder with role `EXTERNAL_FORM`, a unique
`external_form_object_key`, and `published` status. `PublishExternalFormsJob` re-validates the
definition with `Hmis::Form::DefinitionValidator`, checks setup through
`HmisExternalApis::ExternalForms::Config.validate_external_forms_setup`, then renders
`hmis_external_apis/external_forms/form.haml` with the controller renderer. The view walks the
definition's items and hands each to `HmisExternalApis::ExternalForms::FormGenerator#render_node`,
which maps item types (`STRING`, `DATE`, `CHOICE`, `GROUP`, `GEOLOCATION`, ...) onto helpers in
`HmisExternalApis::ExternalFormsHelper`. Input `name` attributes come from
`FormGenerator.node_name`: `RecordType.processor_name` + `.` + `field_name` or
`custom_field_key`, so a submission arrives already keyed like `hud_values`
(`Client.firstName`). Pick lists resolve against `Types::HmisSchema::Enums::Hud::*` constants or
inline `pick_list_options`; `enable_when` supports only `EQUAL` on `answer_code`.

`process_content` parses the HTML with Nokogiri, appends hidden `form_content_digest` (MD5) and
`form_definition_id` (`ProtectedId::Encoder` encoded) inputs, strips comments, and saves a
`FormPublication` row (`content`, `content_digest`, `content_definition` snapshot). Outside
development and test the HTML is `put` with `acl: 'public-read'` to the bucket in
`GrdaWarehouse::RemoteCredentials::S3.for_active_slug('public_bucket')`. Runtime page config
(reCAPTCHA key, presign URL, Sentry SDK URL, CSP) is read from `AppConfigProperty` rows keyed
`external_forms/<name>` by `Config`.

Submissions do not hit Rails. The published page posts JSON to a presigned URL and the object
lands in the bucket behind `RemoteCredentials::S3` slug `hmis_external_form_submissions`.
`ConsumeExternalFormSubmissionsJob` lists up to 10,000 objects (raising above that as a spam
signal), parses each body with size and shape preflight checks, decodes `form_definition_id`,
decrypts `captcha_score` with `RemoteCredentials::SymmetricEncryptionKey` slug
`hmis_external_forms_shared_key`, and upserts a `FormSubmission` by `object_key` via
`from_raw_data`. Successful rows are deleted from S3. `spam_score < 0.5` marks spam.

Processing is deferred to review. `FormSubmission#run_form_processor` builds an enrollment when
the definition `updates_client_or_enrollment?` (normalising `Enrollment.householdId` and
`Enrollment.relationshipToHoH` first), then runs `Hmis::Form::FormProcessor#run!` with
`collect_form_validations` and `collect_processing_validations` skipped: the submitter is gone and
cannot correct anything, so invalid data is stored and fixed afterwards in the HMIS.

### AC HMIS

Credentials: each client class names a `SYSTEM_ID` slug and loads
`GrdaWarehouse::RemoteCredential.active.where(slug:)`. `RemoteCredentials::Oauth` aliases the
generic columns (`username` -> `client_id`, `encrypted_password` -> `client_secret`, `path` ->
`token_url`, `endpoint` -> `base_url`, `bucket` -> `oauth_scope`, `region` -> JSON
`other_values`). `HmisExternalApis::OauthClientConnection` wraps the `oauth2` gem, caches the
access token per `client_id` in a class-level hash, and logs every call to
`HmisExternalApis::ExternalRequestLog` through `ExternalApiLogger`. `enabled?` on each class is
"an active credential with that slug exists", which is also how the HMIS front-end feature
flags are derived.

**MCI** (`Mci`, slug `ac_hmis_mci`): outbound. `clearance` posts name, SSN, DOB and gender and
gets candidate matches back with scores; `create_mci_id` posts a new client and stores the
returned ID as an `ExternalId` in namespace `ac_hmis_mci`; `update_client` pushes demographic
edits. Project types 1, 4 and 7 do not require clearance before enrollment.

**Data warehouse API** (`DataWarehouseApi`, slug `ac_hmis_warehouse_api`, Basic auth built
from the Oauth credential): inbound data. `WarehouseChangesJob` pages `each_change`, upserts
`ExternalId` rows in namespace `ac_hmis_mci_unique_id` keyed by warehouse destination client
id, then merges HMIS clients that share an MCI Unique ID with `GrdaWarehouse::Hud::Client#merge_from`.

**Referrals** (inbound): LINK posts a referral to `ReferralsController`; `CreateReferralJob`
creates `Referral`, `ReferralPosting` (status `assigned_status`), `ReferralHouseholdMember`
rows and creates or updates clients by MCI ID. Postings from LINK have an `identifier`;
HMIS-originated postings (`ReferralPosting.new_with_referral`) do not. Status changes follow
`OLD_STATUS_TO_VALID_NEW_STATUS`.

**LINK** (`LinkApi`, slug `ac_hmis_link`): outbound, deprecated. Every method except
`update_referral_posting_status` reports to Sentry when called. That one still sends status
changes for LINK-originated postings via `UpdateReferralPostingJob`.

**MPER** (`Mper`, slug `ac_hmis_mper`): no HTTP client. Local lookups only: `ProjectID` is the
MPER id; unit types resolve through `ExternalId` namespace `ac_hmis_mper`.

**Reports** (`ReportApi`, slug `ac_reports`): outbound GETs/POSTs for prevention assessment
and consumer summary PDFs by referral id.

**SFTP exports**: `DataWarehouseUploadJob` runs the `Exporters::*` CSV classes and uploads zips
through `RemoteCredentials::Sftp` slug `ac_data_warehouse_sftp_server`; `hmis_csv_export_full_refresh`
runs quarterly.

**Unit availability sync** (`UnitAvailabilitySync`): deprecated model, no longer written.

### TC HMIS

`HmisExternalApis::TcHmis::Importers::Importer` is a batch loader for spreadsheets exported from
the previous TC HMIS. `perform` iterates a fixed list of `Loaders::*Loader` classes
(scan cards, SPDAT, HAT, UHA, meal services, case management notes, demographics, ...), each
subclassing `Loaders::BaseLoader` and reading its file through `Loaders::FileReader`. Loaders
skip themselves when their file is absent, unless `clobber` is true. Paper trail is disabled
for the run and imported tables are `ANALYZE`d afterwards.

Most loaders write `Hmis::Hud::CustomAssessment` or `Hmis::Hud::CustomService` rows plus custom
data elements. `Loaders::CustomDataElementHelper` centralises that: `find_or_create_cded` finds or
creates a `Hmis::Hud::CustomDataElementDefinition` per `(owner_type, key)` with a memoised
cache, and `new_cde_record` returns a bulk-insertable hash with every `value_*` column present
(nil except the one matching the definition's `field_type`), because `activerecord-import`
requires uniform columns. `SyntheticCeAssessmentsForCustomAssessment` backfills
`Hmis::Hud::Assessment` (the `CeAssessment` GraphQL type) rows for imported custom assessments
so they count as CE assessments; a rake task in `drivers/hmis_external_apis/lib/tasks/tc_hmis.rake` runs it once for the
diversion crisis assessment. The data source is `GrdaWarehouse::DataSource.hmis.sole`; the
importer is not multi-HMIS aware.

## Key files

- `drivers/hmis_external_apis/app/controllers/hmis_external_apis/base_controller.rb:34`
  `authorize_request` (Bearer key -> `InboundApiConfiguration.validate`); `:47` `request_log`.
- `drivers/hmis_external_apis/app/controllers/hmis_external_apis/external_forms_controller.rb:16`
  development-only guard; `show` re-publishes and renders; `create` stands in for the S3 presign
  flow.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/external_forms/config.rb:11`
  `PROPERTIES` read from `AppConfigProperty`; `:38` `validate_external_forms_setup` lists every
  credential slug the feature needs.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/external_forms/form_generator.rb:47`
  `render_node_by_type`; `:127` `node['text'].html_safe` in `render_display_node`; `:200`
  `node_name`; `:228` `resolve_pick_list`.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/external_forms/form_publication.rb`:
  `hmis_external_form_publications`, one row per publish.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/external_forms/form_submission.rb:34`
  `SPAM_THRESHOLD`; `:46` `parent_project` (`instances.active.for_projects.sole`); `:54`
  `from_raw_data`; `:93` `run_form_processor`.
- `drivers/hmis_external_apis/app/jobs/hmis_external_apis/publish_external_forms_job.rb:53`
  `process_content`; `:68` `upload_to_s3`.
- `drivers/hmis_external_apis/app/jobs/hmis_external_apis/consume_external_form_submissions_job.rb:20`
  `_perform`; `:93` `parse_json` preflight.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/mci.rb:45` `clearance`;
  `:99` `create_mci_id`; `:128` `update_client`; `:202` `build_route`.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/mper.rb`: local lookups only.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/referral.rb:29` enrollment
  link is null for LINK-originated referrals.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/referral_posting.rb:41` status
  enum; `:65` `OLD_STATUS_TO_VALID_NEW_STATUS`; `:188` `exit_origin_household`; `:220`
  `new_with_referral`.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/configuration.rb`:
  `AppConfigProperty` keys `ac_hmis/*`; currently only `esg_funding_report_enabled`.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/link_api.rb:64` the one
  non-deprecated method.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/data_warehouse_api.rb:46`
  `each_change`; `:74` `src_sys_key` from `other_values`.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/report_api.rb`.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/unit_availability_sync.rb`:
  deprecated.
- `drivers/hmis_external_apis/app/jobs/hmis_external_apis/ac_hmis/warehouse_changes_job.rb:22`
  `NAMESPACE`; `:138` `merge_clients_by_mci_unique_id`.
- `drivers/hmis_external_apis/app/controllers/hmis_external_apis/ac_hmis/referrals_controller.rb:45`
  JSON schema validation.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/external_id.rb`: polymorphic
  external identity; values are not unique.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/oauth_client_connection.rb:62`
  token cache.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/extensions/grda_warehouse/remote_credential_extension.rb`:
  `has_many :external_ids, dependent: :restrict_with_exception`.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/tc_hmis/importers/importer.rb:34`
  loader list.
- `drivers/hmis_external_apis/app/models/hmis_external_apis/tc_hmis/importers/loaders/custom_data_element_helper.rb:24`
  `find_or_create_cded`; `:46` `new_cde_record`.

## Gotchas

- The JSON schema that validates every HMIS form definition,
  `drivers/hmis_external_apis/public/schemas/form_definition.json`, lives in this driver even
  though `Hmis::Form::Definition.validate_schema` in `drivers/hmis` is its only caller. Editing
  form-definition structure means editing a file here.
- `FormGenerator#render_display_node` marks `node['text']` from the stored definition
  `html_safe`, and `form.haml` marks the whole rendered node `html_safe`. Form definitions are
  admin-authored, but this is unescaped DB text in a public page. Do not extend the pattern.
- External form submissions skip both `FormProcessor` validation phases on purpose. Records
  created at review can be invalid by HMIS rules and are meant to be corrected afterwards.
- `FormSubmission#parent_project` uses `.sole`: an `EXTERNAL_FORM` definition with zero or two
  active project instances raises at review time.
- `ExternalFormsController` and its routes exist only in development. Production never serves
  forms from Rails; the S3 object is the page.
- `ExternalId.value` is not unique. Two clients can hold the same MCI ID;
  `Mci#find_client_by_mci` picks the earliest `DateCreated`.
- `Mci.enabled?`, `LinkApi.enabled?`, `DataWarehouseApi.enabled?` and `ReportApi.enabled?`
  mean "an active `RemoteCredential` row with that slug exists". Feature behavior in the
  HMIS front-end flips on and off by editing credential rows, not code.
- `RemoteCredentials::Oauth` reuses generic columns under aliases (`bucket` is the OAuth
  scope, `region` is a JSON blob). Read the alias list before querying the table directly.
- `LinkApi` and `UnitAvailabilitySync` are deprecated. Calling a deprecated `LinkApi` method
  sends a Sentry message. `Mper` is marked "to be removed" but is still used for ID lookups.
- `HmisExternalApis::AcHmis.data_source` and `TcHmis.data_source` call
  `GrdaWarehouse::DataSource.hmis.sole`; neither integration works with more than one HMIS data
  source.
- Client-specific behavior (AC, TC) belongs in this driver. `drivers/hmis` may call
  `HmisExternalApis::*.enabled?` guards, but must not grow county-specific branches of its own.

## Do not repeat

- Marking database-sourced text `html_safe` when rendering external forms. Existing instance:
  `FormGenerator#render_display_node`. Replace with:
  escape by default and allow a fixed markup subset through a sanitizer if rich text is
  required. Repo-wide rule in `conventions/do-not-repeat.md`.
- Storing API credentials, tokens, bucket names or SFTP passwords anywhere other than a
  `GrdaWarehouse::RemoteCredential` subclass row looked up by `slug` (existing examples:
  `Mci#creds`, `PublishExternalFormsJob#s3`,
  `Exporters::DataWarehouseUploader#credentials`). `ENV`, `AppConfigProperty`, and constants
  are not acceptable for secrets; `AppConfigProperty` is for non-secret settings such as
  `external_forms/presign_url`.
- Hard-coding an external route when the credential can carry it. `Mci#build_route` accepts
  either a bare host or a host that already includes `/api/`; follow that when adding an
  endpoint so the URL can change without a deploy.
- Adding new callers to deprecated `LinkApi` methods or writing to `UnitAvailabilitySync`.
- Adding county-specific behavior (AC or TC) to `drivers/hmis`. Put it here and expose an
  `enabled?`-style guard for the HMIS side to check.

## Related

- `hmis/forms.md`: `Hmis::Form::Definition`, roles, `FormProcessor` and the validation phases
  that external submissions skip.
- `hmis/coordinated-entry.md`: how referral postings and unit types are used inside the HMIS.
- `warehouse/driver-architecture.md`: the `drivers/` layout and the `extensions/` concern
  pattern this driver uses to add associations to core models.
- `docs/features/hmis/hmis-form-processing.md` and `docs/features/hmis/hmis-form-definitions.md`:
  human-facing descriptions of the external-form path and the `EXTERNAL_FORM` role.
