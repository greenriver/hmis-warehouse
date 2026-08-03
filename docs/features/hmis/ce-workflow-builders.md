# CE Workflow Builders

## Overview

Workflow builders are Rake task dev/setup scripts, not runtime application logic. They create `Hmis::WorkflowDefinition::Template` graphs wired to CE referral forms. Each client/installation may have its own builder under `ce_workflows/{client_key}/`. Eventually we plan to build admin Template management tools and move these out of version control.

For workflow-specific details (diagrams, form identifiers, rake usage), see the per-client README linked from each builder's directory.

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

**Production:** run once in Rails with `unsafe_run_in_production: true` (not using the rake task). Do not re-run after go-live.

**Rake task shape:** prod guard at top; pass `unsafe_run_in_production:` into builder.

### Non-preferred draft-idempotent pattern

**Why not preferred:**

- In practice, devs used `FORCE_RECREATE` anyway because drafts can't be used for referrals.
- Idempotent `connect_if_not_connected`-style guards add complexity and cruft.
- Implies that we support changing a prod template *without* incrementing the version number, which we don't want to support.

## Updates

Updates to Workflow Templates fall into two categories. See [https://github.com/open-path/Green-River/issues/8515](https://github.com/open-path/Green-River/issues/8515).

- **Form field/label changes** such as label changes, adding a question, or adding a pick list option:
  - Edit JSON in `lib/form_data/`.
  - On deploy, forms are re-seeded automatically.
  - No template version bump.
- **Graph changes** such as new steps, gateways, side effects:
  - We don't yet have an established pattern for handling this in production.
  - The non-preferred draft-idempotent pattern was partly built to handle this, but due to the downsides listed above, we're retiring that pattern and will cross this bridge when we re-encounter it.
