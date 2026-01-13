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
These workflows are generated and updated using the `CeWorkflows::Ph::WorkflowBuilder` utility class. 

These workflows expect client-specific forms to be available. The forms can be loaded with `CLIENT=client rails driver:hmis:seed_definitions` or `HmisUtil::JsonForms.new(env_key: 'client').seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])`

#### Updates

See `CeWorkflows::Ph::WorkflowBuilder` and the associated Rake task `ce_define_ph_workflows.rake`.
- Currently, the code is updated when new versions of the templates are created/published.
- The `build_` methods hard-code a version number, and are intended to be idempotent on that version number. So when run repeatedly, they don't create new templates, but continue updating the template identifier/version the code refers to.
- When ready to publish, the rake task can be run with the `PUBLISH=true` env var. (See usage comment)
- After those workflow template versions have been published, the task will error if you try to run it again.
- When ready to create a new draft version, manually bump the version number(s) in `CeWorkflows::Ph::WorkflowBuilder`.
- In the future, template version management will happen through the UI/mutations, similar to form definitions.
