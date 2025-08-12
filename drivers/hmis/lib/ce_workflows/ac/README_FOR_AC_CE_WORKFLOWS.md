# Ac CE Workflows

## Overview
This directory contains utilities and workflow definitions specific to the AC implementation of Coordinated Entry (CE) workflows.

### Workflow Templates
- **Housing Workflow**: Handles referrals for housing opportunities, including multiple stages of client engagement, provider outcomes, and denial reviews.
- **Admin Assign Workflow**: Supports direct referrals to non-housing programs. This template shares common steps with the housing workflow (provider outcome and denial review process).

### Usage
These workflows are generated using the `AcWorkflowBuilder` utility class.

These workflows expect client-specific forms to be available.

The forms can be loaded with `CLIENT=client rails driver:hmis:seed_definitions` or `HmisUtil::JsonForms.new(env_key: 'client').seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])`

### Housing Workflow
This is a simplified diagram of the housing workflow. To see the full generated diagram, run the AcWorkflowBuilder.

```mermaid
flowchart TD
start_referral(("Start Referral"))
start_referral--> initial_review
initial_review("Initial Review"):::yellow_node
initial_review--> referral_declined
initial_review--> client_engagement_start_date
referral_declined(("Referral Declined"))
client_engagement_start_date("Initial Client Engagement Start Date"):::yellow_node
client_engagement_start_date--> client_engagement
client_engagement("Client Engagement"):::yellow_node
client_engagement-->client_offer_outcome
client_offer_outcome("Client Offer Outcome"):::yellow_node
client_offer_outcome--> referral_declined
client_offer_outcome--> provider_outcome
provider_outcome("Provider Outcome"):::blue_node
provider_outcome--> denial_review
provider_outcome--Client Enrolled-->confirm_success
denial_review("Denial Review"):::pink_node
denial_review--> referral_declined
denial_review--> provider_outcome_2
confirm_success--> referral_declined
provider_outcome_2("Provider Outcome (2)"):::blue_node
provider_outcome_2--> denial_review_2
provider_outcome_2--Client Enrolled-->confirm_success
denial_review_2("Denial Review (2)"):::pink_node
denial_review_3("Denial Review (3)"):::pink_node
denial_review_3-->referral_declined
denial_review_2-->provider_outcome_3
denial_review_2-->referral_declined
provider_outcome_3("Provider Outcome (3)"):::blue_node
provider_outcome_3-->denial_review_3
provider_outcome_3--Client Enrolled-->confirm_success
client_engagement-->referral_declined
confirm_success("Confirm Success")
confirm_success--> referral_accepted
referral_accepted(("Referral Accepted"))

classDef pink_node fill:#ffe6e6,stroke:#ffcccc,stroke-width:2px;
classDef yellow_node fill:#ffffcc,stroke:#ffeb99,stroke-width:2px;
classDef blue_node fill:#e6f7ff,stroke:#99d6ff,stroke-width:2px;
```

### Admin Assign Workflow (Direct Referrals to non-Housing Programs)
This is a simplified diagram of the admin assign workflow. To see the full generated diagram, run the AcWorkflowBuilder.
```mermaid
flowchart TD
start_referral(("Start Referral"))
start_referral--> initial_review
referral_declined(("Referral Declined"))
initial_review("Admin Assign"):::yellow_node
initial_review-->provider_outcome
provider_outcome("Provider Outcome"):::blue_node
provider_outcome--> denial_review
provider_outcome--Client Enrolled-->confirm_success
denial_review("Denial Review"):::pink_node
denial_review--> referral_declined
denial_review--> provider_outcome_2
confirm_success--> referral_declined
provider_outcome_2("Provider Outcome (2)"):::blue_node
provider_outcome_2--> denial_review_2
provider_outcome_2--Client Enrolled-->confirm_success
denial_review_2("Denial Review (2)"):::pink_node
denial_review_3("Denial Review (3)"):::pink_node
denial_review_3-->referral_declined
denial_review_2-->provider_outcome_3
denial_review_2-->referral_declined
provider_outcome_3("Provider Outcome (3)"):::blue_node
provider_outcome_3-->denial_review_3
provider_outcome_3--Client Enrolled-->confirm_success
confirm_success("Confirm Success")
confirm_success--> referral_accepted
referral_accepted(("Referral Accepted"))

classDef pink_node fill:#ffe6e6,stroke:#ffcccc,stroke-width:2px;
classDef yellow_node fill:#ffffcc,stroke:#ffeb99,stroke-width:2px;
classDef blue_node fill:#e6f7ff,stroke:#99d6ff,stroke-width:2px;

```