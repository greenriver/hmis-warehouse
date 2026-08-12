# HMIS assessments

The word "assessment" can refer to several related but distinct record types. This document clarifies what "assessment" may mean in different contexts.

The UI instructions below are developer documentation, intended to help new developers orient themselves in a local environment. They should not be taken as-is for customer-facing feature documentation.

## Quick reference


| Concept | Model | Table/Details | Where to find examples in the HMIS UI |
| --- | --- | --- | --- |
| HUD intake, update, annual, exit, or post-exit assessment | `Hmis::Hud::CustomAssessment` | `CustomAssessments` where `DataCollectionStage` is `1`, `2`, `3`, `5`, or `6` | Visit a Client or Enrollment -> Assessments -> rows where Assessment Type is one of the HUD stages (intake, update, etc.) |
| Fully custom assessment | `Hmis::Hud::CustomAssessment` | `CustomAssessments` where `DataCollectionStage` is `99` | Visit a Client or Enrollment -> Assessments -> rows where Assessment Type is *not* one of the HUD stages |
| HUD Coordinated Entry assessment | `Hmis::Hud::Assessment` | `Assessment` | Visit an Enrollment -> CE Assessments |


`CustomAssessments` is an Open Path table. Despite its HUD-style PascalCase name, it is not part of the HUD CSV specification. See [HMIS CSV-Structured Tables](../../developer/data.md#hmis-csv-structured-tables).

## HUD-stage `CustomAssessment` records

A `CustomAssessment` with a HUD data collection stage is not itself a HUD-specified record type, but it ties together data from HUD PSDEs (Program-Specific Data Elements) such as `IncomeBenefits`, `HealthAndDV`, `Disabilities`, and `EmploymentEducation`.

The `CustomAssessment` is therefore an envelope, not another copy of the answers. Its associated `Hmis::Form::FormProcessor` points to the HUD records that were created or updated when the form was submitted.

The supported stages are:

- `1`: intake
- `2`: update
- `3`: exit
- `5`: annual
- `6`: post-exit

For data entered in Open Path, submitting an assessment form creates the `CustomAssessment`, its `FormProcessor`, and the applicable HUD records. For imported HUD CSV data, `Hmis::MigrateAssessmentsJob` reconstructs the `CustomAssessment` and `FormProcessor` by grouping related records.

These records are called "HUD assessments" in parts of the codebase, but they are not rows in HUD's `Assessment.csv`. That file is specifically for Coordinated Entry assessments (see below).

In the HMIS UI, HUD-stage `CustomAssessment`s are created in several ways:

- **Intake only:** A new Intake Assessment is required for an Enrollment to be considered "complete." Visit an incomplete Enrollment and it will prompt you in several places — on the Enrollment Overview, Household, and Assessments pages — to finish the Intake.
- **All stages:** Visit the Enrollment, navigate to the Assessments page, click "New Assessment" in the top right, and select a HUD stage (Annual, Update, etc.).



## Fully custom `CustomAssessment` records

A `CustomAssessment` with `DataCollectionStage` of `99` represents a fully custom, non-HUD assessment. It is collected using a form with the `CUSTOM_ASSESSMENT` role, which is generally created and maintained in the Admin Form Builder.

We don't yet support auto-importing custom assessments; see #9451. Existing records in HMIS may have been imported through community-specific integrations.

Custom answers are generally stored as Custom Data Elements associated with the `CustomAssessment`. A custom form may also map selected fields to HUD records. Consequently, "custom" describes the form and assessment type; it does not guarantee that the submission only writes custom data. An example would be a `CustomAssessment` that collects a CE Event.

In the HMIS UI, fully custom `CustomAssessment`s are created as follows:

- **Initial setup:**
  - Visit the Admin Form Builder: Admin -> Forms -> New Form -> select "Custom Assessment" as the form type.
  - Build and publish a form.
  - On the Form Details page, click "New Rule" and create a rule that applies the form in the desired projects. (For example, "This form can be collected for adults and Heads of Household in Project A," or "This form can be collected for All Clients in Coordinated Entry projects.")
- Navigate to an Enrollment in one of the projects -> Assessments -> New Assessment -> select the form you created -> fill out and submit the form.



## HUD CE assessments

`Hmis::Hud::Assessment` represents the HUD-defined Coordinated Entry Assessment record from the HUD CSV spec's `Assessment.csv` file. It stores fields such as assessment date, location, type, level, and prioritization status, and may have related `Hmis::Hud::AssessmentQuestion` and `Hmis::Hud::AssessmentResult` records.

GraphQL naming is inverted relative to what developers may expect: the `Assessment` type wraps `Hmis::Hud::CustomAssessment`, while the `CeAssessment` type wraps `Hmis::Hud::Assessment`.

In the HMIS UI, HUD CE Assessments can be created as follows:

- **Initial setup:**
  - Visit the Admin Forms list: Admin -> Forms, then search for CE Assessment.
  - Click into the form with form type "CE Assessment" and form tag "System Form."
  - On the Form Details page, click "New Rule" and create a rule that applies the form in the desired projects.
- Navigate to an Enrollment in one of the projects -> CE Assessments -> Add Coordinated Entry Assessment -> fill out and submit the form.



## Appendix: Custom CE Assessments

Caveat: Some communities use a *fully custom assessment*, i.e. a `Hmis::Hud::CustomAssessment`, to collect data into a HUD CE Assessment record.

For example, a community might create a custom assessment form that asks custom questions (which get stored as Custom Data Elements) as well as CE assessment questions like "Assessment Level" and "Prioritization Status" (which get stored on an `Hmis::Hud::Assessment` record).

The Form Builder UI can't be used to set this up; it must be configured in the JSON builder by GR developers. Here is a simplified JSON example. Individual questions use `mapping` to write to different record types. HUD CE fields use `"record_type": "ASSESSMENT"`; custom questions use `"custom_field_key"`:

```json
{
  "item": [
    {
      "type": "GROUP",
      "text": "My Assessment",
      "link_id": "my_assessment",
      "item": [
        {
          "type": "DATE",
          "text": "Assessment Date",
          "link_id": "ce_assessment_date",
          "required": true,
          "assessment_date": true,
          "mapping": { "record_type": "ASSESSMENT", "field_name": "assessmentDate" }
        },
        {
          "type": "TEXT",
          "text": "Assessment Location",
          "link_id": "ce_assessment_location",
          "required": true,
          "mapping": { "record_type": "ASSESSMENT", "field_name": "assessmentLocation" }
        },
        // ... other required fields on Assessment
        {
          "type": "CHOICE",
          "text": "What is the household composition?",
          "link_id": "household_composition",
          "mapping": { "custom_field_key": "my_assessment_household_composition" }
        }
      ]
    }
  ]
}
```

