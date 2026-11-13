---
sources:
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/mci.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis/link_api.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/external_id.rb
  - drivers/hmis_external_apis/app/jobs/hmis_external_apis/ac_hmis/warehouse_changes_job.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/ac_hmis.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/tc_hmis.rb
  - drivers/hmis_external_apis/app/models/hmis_external_apis/tc_hmis/importers/loaders/custom_data_element_helper.rb
---

# HMIS external integrations

`drivers/hmis_external_apis` holds integrations that cross the HMIS boundary. Public forms are covered in [HMIS external forms](hmis-external-forms.md). This doc covers the two county-specific integrations: AC HMIS and the TC HMIS importers.

County-specific behavior belongs in this driver. `drivers/hmis` may call `HmisExternalApis::*.enabled?` guards but should not grow county-specific branches. The driver adds associations to core models through concerns in its `extensions/` directory.

## Conventions shared by all integrations

- **Secrets live in `GrdaWarehouse::RemoteCredential` rows** looked up by `slug`; never in `ENV`, constants, or `AppConfigProperty`. `AppConfigProperty` is for non-secret settings only. Inbound endpoints validate a hashed API key from `InboundApiConfiguration`.
- **`enabled?` means a credential exists.** `Mci.enabled?`, `LinkApi.enabled?`, `DataWarehouseApi.enabled?`, and `ReportApi.enabled?` are true when an active credential row with that slug exists. HMIS front-end features switch on and off by editing credential rows, not code.
- **OAuth credentials reuse generic columns under aliases** (`bucket` is the OAuth scope, `region` is a JSON blob). Read the alias list in `RemoteCredentials::Oauth` before querying the table directly.
- **Build routes from the credential.** `Mci#build_route` accepts a bare host or a host that already includes `/api/`, so the URL can change without a deploy. Follow that when adding an endpoint.
- **`ExternalId` mirrors external identities** (MCI IDs, MCI Unique IDs, MPER unit-type IDs). Its `value` is not unique: two clients can hold the same MCI ID, and `Mci#find_client_by_mci` picks the earliest `DateCreated`.
- **One HMIS data source only.** `AcHmis.data_source` and `TcHmis.data_source` use `GrdaWarehouse::DataSource.hmis.sole`; neither integration works with more than one HMIS data source.
- **The form-definition JSON schema lives here**, in `public/schemas/form_definition.json`, although `Hmis::Form::Definition.validate_schema` in `drivers/hmis` is its only caller. Changing form-definition structure means editing a file in this driver.

## AC HMIS

- **MCI (client clearance).** Outbound. `clearance` sends name, SSN, DOB, and gender and gets scored candidate matches. Creating a client in MCI stores the returned ID as an `ExternalId`. Enrollment requires clearance, except in project types listed in `Mci::PROJECT_TYPES_NOT_REQUIRING_CLEARANCE`.
- **Data warehouse API.** `WarehouseChangesJob` pulls changes and stores each client's MCI Unique ID as an `ExternalId`. It then soft-merges, in the warehouse, HMIS clients that share an MCI Unique ID: each source client is pointed at the lowest destination client with `GrdaWarehouse::Hud::Client#merge_from`, and pairs in `ClientSplitHistory` are skipped. The HMIS client records are not combined. The job used to hard-merge them with `Hmis::MergeClientsJob`; GH#6239 replaced that with the warehouse merge, deployed 2026-02-26.
- **Legacy referral postings.** The inbound LINK referral endpoint was removed (it was last called 2025-09-30). Existing postings remain. Postings from LINK have an `identifier`; HMIS-originated postings do not. Status changes are restricted to the transitions in `ReferralPosting::OLD_STATUS_TO_VALID_NEW_STATUS`.
- **Client involvements (inbound).** `GET /hmis_external_api/ac_hmis/client_involvements` returns enrollment history, including client names, for a list of MCI IDs. It is authorized only by an API key from `InboundApiConfiguration`, so treat it as PII-sensitive. The program involvements endpoint was removed.
- **LINK client is deprecated.** Its only method, `update_referral_posting_status`, is still used for legacy postings. Don't add new `LinkApi` methods or write to `UnitAvailabilitySync`.
- **MPER** has no HTTP client. It is local lookups only: `ProjectID` is the MPER id, and unit types resolve through `ExternalId`. It is marked for removal but still used.
- **Exports.** SFTP exports to the county data warehouse use the `ac_data_warehouse_sftp_server` credential.

## TC HMIS importers

One-directional, run by hand from a console against a directory of spreadsheets exported from the previous TC HMIS. They load legacy assessments, services, and demographics as `CustomAssessment` and `CustomService` rows plus custom data elements.

- Each loader skips itself when its file is absent, unless `clobber` is true.
- Bulk-inserted custom data element rows must have every `value_*` column present (nil except the one matching the definition's field type), because `activerecord-import` requires uniform columns; `CustomDataElementHelper#new_cde_record` does this.
- Imported custom assessments get synthetic `Hmis::Hud::Assessment` rows where they need to count as CE assessments (see [HMIS assessments](hmis-assessments.md)).
