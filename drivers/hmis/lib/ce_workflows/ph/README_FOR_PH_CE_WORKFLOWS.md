# PH CE Workflows

## Overview
This directory contains utilities and workflow definitions specific to the PH installation of Coordinated Entry (CE) workflows.

### Workflow Templates
- **Direct Referral Workflows**:
  - Benefits Referral
  - Shelter Referral
  - Outreach Referral

These 3 referrals have differing first steps, but the workflows are the same after that with a "Provider Decision" and "Create Enrollment" step.

### Usage
These workflows are generated and updated using the `CeWorkflows::Ph::WorkflowBuilder` utility class. See also the rake task `ce_define_ph_workflows`.
- Currently, that task is updated when new versions of the templates are created/published.
- The task's `build_` methods hard-code a version number, and are intended to be idempotent on that version number. When run repeatedly, they update the template version they point to, instead of creating a new template every time they are run. This should happen while the template is a draft.
- When ready to publish, use the `CeWorkflows::Shared::CeBuilderUtils.publish_template` shared util.
- When ready to create a new draft version, manually bump the version number(s) in `CeWorkflows::Ph::WorkflowBuilder`.
- In the future, template version management will happen through the UI/mutations, similar to form definitions.

These workflows expect client-specific forms to be available. The forms can be loaded with `CLIENT=client rails driver:hmis:seed_definitions` or `HmisUtil::JsonForms.new(env_key: 'client').seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])`
