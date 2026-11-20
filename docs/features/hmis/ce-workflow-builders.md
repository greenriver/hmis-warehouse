---
sources:
  - drivers/hmis/lib/ce_workflows/shared/ce_builder_utils.rb
  - drivers/hmis/lib/ce_workflows/ac/workflow_builder.rb
  - drivers/hmis/lib/ce_workflows/ph/workflow_builder.rb
  - drivers/hmis/lib/ce_workflows/standard/workflow_builder.rb
  - drivers/hmis/lib/ce_workflows/shared/template_cloner.rb
  - drivers/hmis/app/models/hmis/workflow_definition/template.rb
  - drivers/hmis/app/models/hmis/workflow_execution/engine.rb
  - drivers/hmis/app/models/hmis/unit_group.rb
  - drivers/hmis/app/models/hmis/workflow_definition/user_task.rb
---

# CE Workflow Builders

## Overview

Workflow builders are Rake task dev/setup scripts, not runtime application logic. They create `Hmis::WorkflowDefinition::Template` graphs wired to CE referral forms. Each client/installation may have its own builder under `ce_workflows/{client_key}/`. Eventually we plan to build admin Template management tools and move these out of version control.

For workflow-specific details (diagrams, form identifiers, rake usage), see the per-client README linked from each builder's directory.

## What a template is, and what lives outside it

A template is data. Its graph is stored as `Hmis::WorkflowDefinition::Node` rows (start and end events, `UserTask`, `ScriptTask`, `Gateway`), `Flow` rows that connect them, and `Swimlane` rows. When a referral is created, `Hmis::WorkflowExecution::Engine` runs the stored graph of the unit group's template. Neither the engine nor the CE message and assignment handlers check a template's identifier, so a new template needs no application code change.

Creating that data does need a developer. Builders create templates through `CeBuilderUtils.create_template` and `CeBuilderUtils.find_or_create_draft_template`, and `CeWorkflows::Shared::TemplateCloner` copies an existing template (see [Copying a template](#copying-a-template)). No GraphQL mutation creates, edits, or copies a template.

Other parts of a CE setup live outside the template:

| Part | Where it lives | How it changes |
| --- | --- | --- |
| Steps, gateways, swimlanes, side effects | The template graph | A builder |
| Questions on a step | A `CE_REFERRAL_STEP` form definition. Each `UserTask` references one by `form_definition_identifier`. | Form JSON in `drivers/hmis/lib/form_data/` (see [Updates](#updates)) |
| Eligibility and priority | `Hmis::Ce::Match::Rule`, owned by any type in `Hmis::Ce::Match::Rule::OWNER_PRECEDENCE` | The `CreateCeMatchRule`, `UpdateCeMatchRule`, and `DeleteCeMatchRule` mutations |
| Which template a unit group uses | `Hmis::UnitGroup#workflow_template_identifier` and `#direct_referral_workflow_template_identifier` | The `CreateUnitGroup` and `UpdateUnitGroup` mutations |

Two workflows that differ only in eligibility or priority can share one template, because rules are resolved for the unit group, not stored on the template. Workflows that differ in steps or step names need a second template with its own identifier. One builder can build several templates from shared helpers: the AC builder's `build_housing_workflow` and `build_admin_assign_workflow` both call `build_shared_sub_workflow`. A second template that needs different questions on a step also needs its own form definitions, because a form change reaches every template in the same data source whose steps reference that form's identifier.

## Two workflow builder patterns

Installation-specific workflow builders follow two different patterns. This readme documents the two patterns and our decision about our preferred pattern.

### Background information and constraints

- The Workflow Template table supports a draft/publish/retire lifecycle, similar to Form Definitions, with the following columns:
  - `id`: database primary key that uniquely identifies this template version
  - `version`: integer starting at 0 that increments when a new version of a template is published
  - `identifier`: string identifier such as "housing_workflow" that is shared across versions
  - `status`: "draft" | "published" | "retired"
- However, this lifecycle is not truly in use yet, because draft templates cannot drive real referrals, and we don't yet have admin tools for previewing a draft workflow. For now, you must publish a template to test a workflow, even in dev.
- `delete_template_and_associated_data` is the most efficient way to iterate on a template in dev, but should NOT be run in prod.
- Unit groups reference templates by `identifier`, while referrals reference templates by `id`. At runtime, when a referral is created, it gets associated with the most recent published version of the template identifier stored on the unit group.



### Overview of two patterns


|                                             | **Preferred: destroy-and-recreate (AC-style)**                         | **Legacy: draft idempotent (PH/Standard-style)**                            |
| ------------------------------------------- | ---------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **Template lifecycle**                      | `delete_template_and_associated_data` → `create_template` (published)  | `find_or_create_draft_template` → mutate in place → optional `PUBLISH=true` |
| **Strategy for changing existing template** | Wipes existing template and starts anew                                | Idempotent on hard-coded version while draft; errors once published         |
| **Prod setup**                              | One-time in rails console using `unsafe_run_in_production: true` flag. | `PUBLISH=true`; no destroy in prod                                          |




### Preferred destroy-and-recreate pattern

Use this pattern for new workflows. See `[drivers/hmis/lib/ce_workflows/ac/workflow_builder.rb](../../../drivers/hmis/lib/ce_workflows/ac/workflow_builder.rb)` as a reference implementation.

**Why we prefer it:**

- Modifying an existing template in place via idempotent `find_or_*` calls accumulates cruft and is harder to reason about than a clean graph build.
- Simpler mental model: "the Ruby code *is* the template definition; re-run the rake task to apply changes."

**Implementation shape**:

```ruby
def initialize(data_source, unsafe_run_in_production: false)
  raise '...' if Rails.env.production? && !unsafe_run_in_production
end

def build_my_workflow
  identifier = 'my_workflow'
  CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data(
    identifier, data_source: @data_source, delete_opportunities: false
  ) unless @unsafe_run_in_production

  template = CeWorkflows::Shared::CeBuilderUtils.create_template(identifier, name, @data_source)
  # create! nodes, create_gateway, connect_to!
  template.validate!
  template
end
```

**Local iteration:** run the rake task repeatedly. Expect referrals to be destroyed.
  - Opportunities are destroyed too unless you pass `delete_opportunities: false` to `delete_template_and_associated_data`.
  - The `delete_opportunities` flag is only read in dev/staging. Production first-time setup skips `delete_template_and_associated_data` entirely (`unsafe_run_in_production: true`), so the value is never used there.

**Production:** run once in Rails with `unsafe_run_in_production: true` (not using the rake task). Do not re-run after go-live.

**Rake task shape:** prod guard at top; pass `unsafe_run_in_production:` into builder.

### Non-preferred draft-idempotent pattern

**Why not preferred:**

- In practice, devs used `FORCE_RECREATE` anyway because drafts can't be used for referrals.
- Idempotent `connect_if_not_connected`-style guards add complexity and cruft.
- Implies that we support changing a prod template *without* incrementing the version number, which we don't want to support.

## Copying a template

`CeWorkflows::Shared::TemplateCloner` copies a template's swimlanes, nodes, and flows into a new, independent draft template with a new identifier. It is console tooling, like the builders. The class comment covers usage and exactly what is copied.

Copy when a customer needs a second workflow that starts from one an environment already runs, with small edits such as renamed steps. The copy is taken from the rows the environment actually has, so it doesn't depend on whether the source still matches its builder. Write a builder when the graph itself needs to be designed, or when the template must be rebuilt from code in every environment.

A copy is limited in these ways:

- **Forms, custom statuses, and decline reasons are shared.** Nodes reference them by key (`form_definition_identifier`, a `custom_status_key` in `trigger_config`, pick list options on the step's form), so a change to one reaches both templates. A copy that needs different questions on a step needs its own form definitions.
- **No default contacts.** The copy's swimlanes are new rows, and `Hmis::Ce::DefaultSwimlaneAssignment` matches by `swimlane_id`. Until someone assigns default contacts to them, the copy's referrals start with no participants, and `Hmis::Ce::ReferralTaskAssignmentHandler` assigns its tasks to nobody.
- **Only a new unit group can use it.** `Hmis::UnitGroup` doesn't allow a template identifier to change once set, so an existing unit group can't be moved to the copy.
- **The repo doesn't record it.** A copy has no builder code, so rebuilding an environment means re-running the copy and the edits.

## Updates

Updates to Workflow Templates fall into two categories. See [https://github.com/open-path/Green-River/issues/8515](https://github.com/open-path/Green-River/issues/8515).

- **Form field/label changes** such as label changes, adding a question, or adding a pick list option:
  - Edit JSON in `drivers/hmis/lib/form_data/`.
  - On deploy, forms are re-seeded automatically.
  - No template version bump.
- **Graph changes** such as new steps, gateways, side effects:
  - We don't yet have an established pattern for handling this in production.
  - The non-preferred draft-idempotent pattern was partly built to handle this, but due to the downsides listed above, we're retiring that pattern and will cross this bridge when we re-encounter it.

## Gotchas

- Deleting a template does not clear `UnitGroup.workflow_template_identifier`. The builder is expected to recreate the same identifier immediately.
- Republishing a template does not move in-flight referrals, because they are bound by template `id` at creation.
- There is no admin UI for templates; they are published from builder scripts.
