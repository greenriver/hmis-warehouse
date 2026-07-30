# AZ CE Workflows

## Overview
This directory contains utilities and workflow definitions specific to the AZ installation of Coordinated Entry (CE) workflows.

### Workflow Templates
- **MC Direct Referral**: Four sequential tasks (Send Referral → Initial Review → Client Outreach → Provider Outcome), with CE Event create/update and enrollment on accept.

### Usage
These workflows are generated and updated using the `CeWorkflows::Az::WorkflowBuilder` utility class.

**CAUTION:** Building these workflows deletes existing referrals and opportunities associated with the templates. Do not run in production after the first time.

These workflows expect client-specific forms to be available. The forms live under `form_data/az/ce_referral_steps/`. Load them with:

```bash
CLIENT=az rails driver:hmis:seed_definitions
```

or:

```ruby
HmisUtil::JsonForms.new(env_key: 'az', data_source_id: 1).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
```

Then recreate the template:

```bash
rails driver:hmis:ce_define_az_workflows
```

After creating, attach the template on unit groups via `direct_referral_workflow_template_identifier = 'mc_direct_referral'`.

### MC Direct Referral Workflow

```mermaid
flowchart TD
  start(["Start Referral"]) --> send["Send Referral\nstatus: Assigned"]
  send --> review["Initial Review\nstatus: Initial Review"]
  review --> gw2{"decision"}
  gw2 -->|"approve"| createEvt["Create CE Event\nno result"]
  gw2 -->|"provider_rejected"| createEvtDenied["Create CE Event\nresult 3"]
  gw2 -->|"canceled"| decline(["Decline"])
  createEvtDenied --> decline
  createEvt --> outreach["Client Outreach\nstatus: Outreach"]
  outreach --> gw3{"outcome"}
  gw3 -->|"intake_scheduled"| providerOut["Provider Outcome\nstatus: Pending Provider Decision"]
  gw3 -->|"client_rejected"| setRes2["CE Event result 2"]
  gw3 -->|"provider_rejected"| setRes3["CE Event result 3"]
  setRes2 --> decline
  setRes3 --> decline
  providerOut --> gw4{"decision"}
  gw4 -->|"approved"| enroll["Create Enrollment"]
  gw4 -->|"client_rejected"| setRes2b["CE Event result 2"]
  gw4 -->|"provider_rejected"| setRes3b["CE Event result 3"]
  enroll --> accept(["Accept"])
  setRes2b --> decline
  setRes3b --> decline
```

#### Updates

**Form definition updates**: Forms are managed in version control under `form_data/az/ce_referral_steps/`. Modify them in source control and re-seed.

**Workflow template updates**: See `CeWorkflows::Az::WorkflowBuilder` and `ce_define_az_workflows.rake`. Each local run deletes and recreates the template and associated referral data.
