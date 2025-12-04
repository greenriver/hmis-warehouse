# PH CE Workflows

## Overview
This directory contains utilities and workflow definitions specific to the PH installation of Coordinated Entry (CE) workflows.

### Workflow Templates
- **Direct Referral Workflow**: Supports inter-project direct referrals.

### Usage
These workflows are generated using the `CeWorkflows::Ph::WorkflowBuilder` utility class.

These workflows expect client-specific forms to be available.

The forms can be loaded with `CLIENT=client rails driver:hmis:seed_definitions` or `HmisUtil::JsonForms.new(env_key: 'client').seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])`

### Direct Referral Workflow

```mermaid
flowchart TD
start_referral_6631(("Start Referral<br/><br/>EFFECT: Start Workflow → Start Referral"))
start_referral_6631--> send_referral_6634
send_referral_6634("Send Referral")
send_referral_6634--> provider_decision_6635
provider_decision_6635("Provider Decision")
provider_decision_6635--> exclusive_gateway_provider_decision_6637
exclusive_gateway_provider_decision_6637{"Exclusive Gateway: provider_decision"}
exclusive_gateway_provider_decision_6637--> referral_declined_6633
exclusive_gateway_provider_decision_6637-- IF decision = 1 --> create_enrollment_6636
create_enrollment_6636("Create Enrollment (script)<br/><br/>EFFECT: Complete Step → Create Enrollment")
create_enrollment_6636--> referral_accepted_6632
referral_accepted_6632(("Referral Accepted<br/><br/>EFFECT: End Workflow → Accept Referral"))
referral_declined_6633(("Referral Declined<br/><br/>EFFECT: End Workflow → Reject Referral"))
```
