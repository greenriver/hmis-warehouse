# PH CE Workflows

## Overview
This directory contains utilities and workflow definitions specific to the PH installation of Coordinated Entry (CE) workflows.
See README_FOR_CE_WORKFLOW_BUILDERS.md for general documentation on the CE workflow builder pattern.

### Workflow Templates
- **Direct Referral Workflows**:
  - Benefits Referral
  - Shelter Referral
  - Outreach Referral

These 3 referrals have differing first steps, but the workflows are the same after that with a "Provider Decision" and "Create Enrollment" step.

### Usage
These workflows are generated and updated using the `CeWorkflows::Ph::WorkflowBuilder` utility class. 

These workflows expect client-specific forms to be available. The forms can be loaded with `CLIENT=client rails driver:hmis:seed_definitions` or `HmisUtil::JsonForms.new(env_key: 'client', data_source_id: 1).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])`

