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

These workflows expect client-specific forms to be available. The forms can be loaded with `CLIENT=client rails driver:hmis:seed_definitions` or `HmisUtil::JsonForms.new(env_key: 'client', data_source_id: 1).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])`

#### Updates

Updates to these workflows fall into two categories:

**Form definition updates**: Updates to the form definitions, such as adding a collected field or changing the text on a form label.
- These forms are "managed in version control", and unversioned (as opposed to the versioned forms that are published using the Form Builder tool). So updates can be made by modifying the form definitions directly in source control.
- When the release containing those changes is deployed, referral workflows will start to use the new form definitions.
- In the future, these forms will be moved into the Form Builder so users can manage them.

**Workflow template updates**: Updates to the workflow structure itself, including adding or removing nodes or modifying side effects.
- See `CeWorkflows::Ph::WorkflowBuilder` and the associated Rake task `ce_define_ph_workflows.rake`.
- Currently, the code is updated when new versions of the templates are created/published.
- The `build_` methods hard-code a version number, and are intended to be idempotent on that version number. So when run repeatedly, they don't create new templates, but continue updating the template identifier/version the code refers to.
- When ready to publish, the rake task can be run with the `PUBLISH=true` env var. (See usage comment)
- After those workflow template versions have been published, the task will error if you try to run it again.
- When ready to create a new draft version, manually bump the version number(s) in `CeWorkflows::Ph::WorkflowBuilder`.
- In the future, template version management will happen through the UI/mutations, similar to form definitions.
