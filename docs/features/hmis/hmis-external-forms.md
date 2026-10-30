# HMIS external forms

External forms publish an `EXTERNAL_FORM` definition as a static HTML page that anyone can fill out without logging in, for example a Point-in-Time (PIT) count survey or a prevention screening. Submissions travel through S3 to the HMIS, where staff review them in the project's External Forms tab. Marking a submission reviewed runs it through the form processor, which writes the answers to HMIS records.

Out of scope here:

- The `EXTERNAL_FORM` role and `external_form_object_key` on the definition: [Form definitions](hmis-form-definitions.md)
- The definition JSON, including `mapping`, `link_id` and pick lists: [HMIS form authoring](hmis-form-authoring.md)
- How the processor writes records, and why external forms skip validation: [Form processing](hmis-form-processing.md)

## Pipeline

1. **Publish.** `HmisExternalApis::PublishExternalFormsJob` renders the definition to HTML using `HmisExternalApis::ExternalForms::FormGenerator` and the `hmis_external_apis/external_forms/form` view. It adds hidden `form_definition_id` (encrypted with `ProtectedId`) and `form_content_digest` inputs, then uploads the page as public-read to the `public_bucket` S3 bucket at `external_form_object_key`. Each publish is recorded in `hmis_external_form_publications` (`FormPublication`), with the HTML and a copy of the definition JSON.
2. **Submit.** In the browser, the form gets a reCAPTCHA token and calls `external_forms/presign_url`, an AWS Lambda behind API Gateway. The Lambda checks the token and returns a presigned S3 URL and an encrypted captcha score. The browser uploads the answers as JSON, with `captcha_score` added, to the submissions bucket. Each input is named after its mapping (`FormGenerator.node_name`), for example `Client.firstName`, or the item's `custom_field_key`.
3. **Consume.** `HmisExternalApis::ConsumeExternalFormSubmissionsJob` runs hourly (`grda_warehouse:hourly`), or on demand through the `RefreshExternalSubmissions` mutation behind the refresh button in the HMIS. It downloads each object, decodes the definition ID, decrypts the captcha score, upserts an `HmisExternalApis::ExternalForms::FormSubmission` (`hmis_external_form_submissions`) holding the raw answers in `raw_data`, and deletes the S3 object. It raises if more than 10,000 objects have piled up.
4. **Review.** Submissions show on the project's External Forms tab once the form has an active project rule. Submissions that arrive before the rule exists are still stored, and appear once it's added. A captcha score below 0.5 marks a submission as spam. Marking a submission reviewed (`UpdateExternalFormSubmission`, or `BulkReviewExternalSubmissions` for submissions from a single form identifier) calls `FormSubmission#run_form_processor`, unless the submission is spam. Reviewing needs `can_manage_external_form_submissions` on the project. A reviewed submission can't go back to New.

If the definition maps any item to a `CLIENT` or `ENROLLMENT` field (`Definition#updates_client_or_enrollment?`), review also creates a new client and enrollment in the rule's project, and also needs `can_edit_enrollments`. The entry date is the submission's `created_at`. The enrollment is auto-entered if the project auto-enters; otherwise it's saved as in progress.

## Setting up external forms

There are two kinds of setup. Most of the time you only need the second.

- **Environment setup** happens once per environment (production, staging, and so on): the AWS infrastructure, credentials and site config. If the environment has published external forms before, for example last year's PIT survey, it's already done and nothing needs to change.
- **Form setup** happens for every new form, and again whenever a form changes. A new year's PIT survey only needs form setup.

To check whether the environment is set up, run `HmisExternalApis::ExternalForms::Config.validate_external_forms_setup` in the console. It logs and returns anything missing. An empty array means environment setup is done, so skip to "Form setup".

### Environment setup (once per environment)

The AWS pieces live outside this repository: the presign Lambda and its API Gateway trigger, the submissions bucket, and a public bucket. Each environment needs its own.

1. **Create remote credentials** in the Rails console:

   ```ruby
   # Shared AES key; must match SHARED_SECRET_AES_KEY in the Lambda's environment variables
   GrdaWarehouse::RemoteCredentials::SymmetricEncryptionKey.create!(
     slug: :hmis_external_forms_shared_key,
     algorithm: 'aes-256-cbc',
     active: true,
     key_hex: '<SHARED_SECRET_AES_KEY>',
   )

   # Bucket the Lambda writes submissions to
   GrdaWarehouse::RemoteCredentials::S3.create!(
     slug: 'hmis_external_form_submissions',
     bucket: '<submissions bucket>',
     region: 'us-east-1',
     username: '',
     encrypted_password: '',
     active: true,
   )

   # Bucket published HTML is served from (skip if it already exists)
   GrdaWarehouse::RemoteCredentials::S3.create!(
     slug: 'public_bucket',
     bucket: '<public bucket>',
     region: 'us-east-1',
     username: '',
     encrypted_password: '',
     active: true,
   )
   ```

2. **Add `AppConfigProperty` records** (Warehouse Admin > App Config Properties, or the console):
   - `external_forms/presign_url` (required): the Lambda's API Gateway upload URL, `https://<id>.execute-api.us-east-1.amazonaws.com/uploads`. Find it under the Lambda's Configuration > Triggers.
   - `external_forms/recaptcha_key` (required): the reCAPTCHA site key. Add the environment's domain to the reCAPTCHA site as well.
   - `external_forms/sentry_sdk_url` (required): the Sentry JS loader URL.
   - `external_forms/site_logo_alt`, `site_logo_url`, `site_logo_width`, `site_logo_height`, `csp_content` (optional).
3. **Validate:** `validate_external_forms_setup` should now return `[]`. In production and staging, the publish job runs the same check and raises if anything is missing.

### Form setup (each new or changed form)

**New form:**

1. **Build the form** in the Form Builder with role `EXTERNAL_FORM`, and publish it there. To start from an existing form, such as last year's PIT, see the last item under Gotchas.
2. **Set the object key** in the console. The Form Builder displays it but can't set it:
   `Hmis::Form::Definition.find(id).update!(external_form_object_key: '<folder>/<form_name>')`
   Each form identifier needs its own key; one can't be reused across identifiers.
3. **Add one active form rule** for the project that will review submissions.
4. **Publish the HTML:** `HmisExternalApis::PublishExternalFormsJob.new.perform(definition_id)`. The form is then live at `https://<public bucket>.s3.amazonaws.com/<external_form_object_key>`. The first publish can take a few minutes to become reachable.
5. **Test the whole pipeline** (see Gotchas).

**Changing an existing form:**

1. **Edit and publish a new version** in the Form Builder. New versions keep the `external_form_object_key`, so you don't need to set it again.
2. **Republish the HTML** with the new version's ID: `HmisExternalApis::PublishExternalFormsJob.new.perform(new_definition_id)`. The live page is replaced immediately. ([#6550](https://github.com/open-path/Green-River/issues/6550) is outstanding ticket to automate this)
3. **Test the whole pipeline** (see Gotchas).

**Local development:** set `external_forms/presign_url` to `/hmis_external_api/external_forms/presign`, then open `https://hmis-warehouse.dev.test/hmis_external_api/external_forms/<external_form_object_key>`. In development, the Form Builder's form page links there. That route publishes and serves the form. Submissions go straight into `hmis_external_form_submissions` with a captcha score of `1.0`, with no S3 involved.

## What the generator supports

`FormGenerator` covers a subset of the definition schema and raises on anything else at publish time:

- **Item types:** `STRING`, `TEXT`, `DATE`, `INTEGER`, `BOOLEAN`, `CHOICE`, `GROUP`, `DISPLAY` and `GEOLOCATION`.
- **`CHOICE` components:** `DROPDOWN` (the default) and `RADIO_BUTTONS`.
- **`enable_when`:** only `question` plus `answer_code` with the `EQUAL` operator.
- **`pick_list_reference`:** only HUD enums (`Types::HmisSchema::Enums::Hud::*`) and `Types::HmisSchema::Enums::*`. Anything else needs `pick_list_options`.

## Gotchas

- **External forms are brittle. After any change, test the whole pipeline.** Publish the form, submit it through the generated HTML page (not the Form Builder preview), consume the submission, review it in the project's External Forms tab, then check that every answer landed on the right record and field. Many problems only show up at one of those later steps.
- **PIT submissions feed the HUD PIT report.** Clients and enrollments created from reviewed PIT submissions are counted as unsheltered by the Warehouse [HUD PIT report](../warehouse/hud-pit-report.md). That means:
  - The form rule's project must be a Street Outreach project, because the report counts unsheltered clients from project type 4.
  - The enrollment must be open on the PIT date. Its entry date is the submission's `created_at` (when the consume job stored it), not `submitted_at` (when the person submitted it). If submissions are consumed after the PIT date, their entry dates fall after it and those clients drop out of the count. Check entry dates before running the report.
  - For PIT forms, the end-to-end test goes one step further: run the HUD PIT report for the PIT date, and check that the test clients appear in the expected rows.
- **Answers go straight onto clients and enrollments.** PIT-style forms map items to `CLIENT`, `ENROLLMENT`, `DISABILITY_GROUP` and `GEOLOCATION` fields, so reviewing a submission creates a real client and enrollment. Review skips form validation, so a bad value either raises during review or is saved as-is.
- **`individual_or_family` is a special-cased `link_id`.** If a form has a `CHOICE` item with that `link_id` and a `Family` option (the view raises if the shape doesn't match), the page turns on household handling:
  - Every submission gets a generated `Enrollment.householdId` (`HH` plus 26 characters).
  - Choosing Family offers "Add another household member", which reopens the form with `hh_id` in the URL, so the next submission joins that household.
  - The household ID is added to the payload by JavaScript, not by a form input.
  - The submitter is recorded as head of household, and later members as `DATA_NOT_COLLECTED`, unless the form collects `relationshipToHoH` itself.
  - On review, a malformed household ID, or one already used in a different project, is discarded and a new household is generated.
  - Renaming the `link_id` silently turns all of this off.
  - Once reviewed, all of a family's submissions should end up as enrollments in one household in the rule's project, with the same `HouseholdID` and one head of household. Check this when testing a family submission.
- **`ageRange` on `CLIENT` is parsed, not stored.** If no DOB was given, an age-range answer becomes an approximate DOB (`dob_data_quality: 2`). Option codes must exactly match a key in `HudHelper.util.age_range`, or a missing-data wording ("Doesn't know", "Prefers not to answer", "Data not collected"). Anything else raises at review time.
- **`pick_list_options` codes are the stored values.** For field mappings, the codes must match the target enum or value the processor expects. Rewording a code breaks processing, even though the form still renders and submits.
- **Publishing takes effect immediately and isn't tied to form versions** ([#6550](https://github.com/open-path/Green-River/issues/6550)). The S3 object is overwritten as soon as the job runs. Each submission keeps the definition ID it was submitted with, so CDED keys and mappings that already-collected submissions use must keep working until those submissions are reviewed.
- **Exactly one active project rule.** `FormSubmission#parent_project` uses `.sole`, so with zero rules or more than one, review fails.
- **Use existing forms as reference.** Before building a new PIT or intake-style form, copy a published `EXTERNAL_FORM` definition from the Form Builder. PIT forms namespace their CDED keys by year (for example `external_form_pit_2026_*`), so each year's survey has its own fields.

## Related

- [Form definitions](hmis-form-definitions.md): roles, including `EXTERNAL_FORM`, and `external_form_object_key`
- [Form resolution](hmis-form-resolution.md): form rules, including the single project-scoped rule for external forms
- [HMIS form authoring](hmis-form-authoring.md): the definition JSON
- [Form processing](hmis-form-processing.md): how the processor writes records, and the external-form path
- [HUD PIT report](../warehouse/hud-pit-report.md): the Warehouse report that counts reviewed PIT submissions
