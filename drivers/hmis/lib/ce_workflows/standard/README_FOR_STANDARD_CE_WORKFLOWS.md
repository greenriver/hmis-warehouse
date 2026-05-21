# Standard CE Workflows

## Overview
This directory contains utilities and workflow definitions for the Standard Referral CE workflow template.

This workflow is intended as an out-of-the-box baseline for QA, staging, demo, and new client onboarding. It can be customized per customer as needed.

### Workflow Templates
- **Standard Referral**: A baseline referral workflow with CE team initial review, provider decision, enrollment, placement confirmation, and decline review.

### Usage
These workflows are generated using the `CeWorkflows::Standard::WorkflowBuilder` utility class and the `ce_define_standard_workflows` rake task.

### Standard Referral Workflow
This is a simplified diagram of the standard referral workflow. To see the full generated diagram, run the Standard WorkflowBuilder or inspect the template mermaid output after running the rake task.

```mermaid
flowchart TD
start_referral(("Start Referral"))
start_referral--> initial_review
initial_review("Initial Review"):::yellow_node
initial_review--> referral_declined
initial_review--> provider_decision
referral_declined(("Referral Declined"))
provider_decision("Provider Decision"):::blue_node
provider_decision--> review_decline
provider_decision--> create_enrollment
review_decline("Review Decline"):::pink_node
review_decline--> referral_declined
review_decline--> provider_decision
create_enrollment("Create Enrollment")
create_enrollment--> confirm_placement
confirm_placement("Confirm Placement"):::yellow_node
confirm_placement--> referral_accepted
referral_accepted(("Referral Accepted"))

classDef pink_node fill:#ffe6e6,stroke:#ffcccc,stroke-width:2px;
classDef yellow_node fill:#ffffcc,stroke:#ffeb99,stroke-width:2px;
classDef blue_node fill:#e6f7ff,stroke:#99d6ff,stroke-width:2px;
```
