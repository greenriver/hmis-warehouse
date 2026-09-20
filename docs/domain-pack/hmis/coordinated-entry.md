---
title: "HMIS coordinated entry: dirty tracking, match engine, workflows, referrals"
summary: "How CE runs inside HMIS. Change markers flag dirty clients, self-scheduling jobs rebuild candidate pools, the match engine evaluates rules through a SQL-translated expression layer, workflow templates define referral steps, and opportunities and referrals tie matches to units."
area: hmis
tags: [hmis, coordinated-entry, ce, ChangeMarker, MarkClientAsDirtyBehavior, ProcessPoolsJob, ProcessClientsJob, CandidatePoolBuilder, UnitGroupRuleResolver, Engine, MatchApplicability, SqlExpressionTranslator, FieldMap, PsdeFieldRegistry, WorkflowDefinition::Template, WorkflowExecution::Step, SubmitCeReferralStep, Opportunity, Referral, UnitGroup, ProjectCeConfig, CeBuilderUtils]
sources:
  - drivers/hmis/app/models/hmis/ce/change_marker.rb
  - drivers/hmis/app/models/concerns/hmis/mark_client_as_dirty_behavior.rb
  - drivers/hmis/app/models/hmis/ce/configuration.rb
  - drivers/hmis/app/jobs/hmis/ce/process_pools_job.rb
  - drivers/hmis/app/jobs/hmis/ce/process_clients_job.rb
  - drivers/hmis/app/models/hmis/ce/match/candidate_pool.rb
  - drivers/hmis/app/models/hmis/ce/match/candidate_pool_builder.rb
  - drivers/hmis/app/models/hmis/ce/match/unit_group_rule_resolver.rb
  - drivers/hmis/app/models/hmis/ce/match/candidate_pool_repository.rb
  - drivers/hmis/app/models/hmis/ce/match/engine.rb
  - drivers/hmis/app/models/hmis/ce/match/match_applicability.rb
  - drivers/hmis/app/models/hmis/ce/match/rule.rb
  - drivers/hmis/app/models/hmis/ce/match/internal/sql_prefilter.rb
  - drivers/hmis/app/models/hmis/ce/match/expression/field_map.rb
  - drivers/hmis/app/models/hmis/ce/match/expression/sql_expression_translator.rb
  - drivers/hmis/app/models/hmis/ce/match/expression/psde_field_registry.rb
  - drivers/hmis/app/models/hmis/ce/opportunity.rb
  - drivers/hmis/app/models/hmis/ce/referral.rb
  - drivers/hmis/app/models/hmis/ce/referral_message_handler.rb
  - drivers/hmis/app/models/hmis/unit_group.rb
  - drivers/hmis/app/models/hmis/project_ce_config.rb
  - drivers/hmis/app/models/hmis/workflow_definition/template.rb
  - drivers/hmis/app/models/hmis/workflow_execution/step.rb
  - drivers/hmis/app/models/hmis/hud/processors/workflow_step_processor.rb
  - drivers/hmis/app/graphql/mutations/ce/create_ce_referral.rb
  - drivers/hmis/app/graphql/mutations/ce/submit_ce_referral_step.rb
  - drivers/hmis/app/graphql/mutations/ce/mark_units_available.rb
  - drivers/hmis/lib/ce_workflows/shared/ce_builder_utils.rb
  - drivers/hmis/lib/ce_workflows/ac/workflow_builder.rb
  - lib/tasks/grda_warehouse.rake
  - drivers/hmis/lib/tasks/ce_candidate_pools.rake
related:
  - hmis/data-model.md
  - hmis/forms.md
  - warehouse/cas-integration.md
---

## Purpose

Coordinated entry (CE) inside HMIS matches destination clients to housing units and moves a
referral through a configurable workflow. The code lives under `drivers/hmis/app/models/hmis/ce`,
`drivers/hmis/app/models/hmis/workflow_definition`, `drivers/hmis/app/models/hmis/workflow_execution`,
and `drivers/hmis/lib/ce_workflows`. It is gated by the `hmis_ce/enabled` `AppConfigProperty`,
read through `Hmis::Ce.configuration.enabled?` (`drivers/hmis/app/models/hmis/ce/configuration.rb`).

Four pieces:

- Dirty tracking. `Hmis::Ce::ChangeMarker` rows record a `current_version` and
  `processed_version` per destination client and per candidate pool. Saves on HUD models bump the
  client version; rule and unit-group changes rebuild pools.
- Pools and the match engine. A `Hmis::Ce::Match::CandidatePool` is one unique pair of
  `[priority_expression, requirement_expression]` derived from `Hmis::Ce::Match::Rule` rows.
  `Hmis::Ce::Match::Engine` evaluates destination clients against a pool and writes
  `Candidate` rows with priority scores.
- Workflows. `Hmis::WorkflowDefinition::Template` is a versioned graph of nodes (user tasks,
  script tasks, gateways, events). `Hmis::WorkflowExecution::Instance` and `Step` run one
  referral through that graph.
- Opportunities and referrals. `Hmis::Ce::Opportunity` is an available `Hmis::Unit`;
  `Hmis::Ce::Referral` ties a client to an opportunity and to a workflow instance.

Use this doc when a client is missing from a waitlist, when a rule change does not take effect,
when adding a match-expression field, when building or changing a workflow template, or when a
referral is stuck in a step. Units and unit groups themselves are covered in `hmis/data-model.md`.

## Entry points

Public API of the match engine (`drivers/hmis/app/models/hmis/ce/match/`, top level):
`Engine.call(pool, clients: nil)`, `CandidatePoolBuilder.call(unit_group_ids: nil,
force_reprocessing: false)`, `UnitGroupRuleResolver#key_for_unit_group`,
`CandidatePoolRepository`, `MatchApplicability`, and the models `CandidatePool`, `Candidate`,
`CandidateEvent`, `Rule`. Classes under `match/internal/` (`SqlPrefilter`,
`ClientPoolEvaluator`, `CandidateRepository`, `CandidateEventWriter`) are implementation details
of `Engine` and are not called from outside `Hmis::Ce::Match`.

Jobs: `Hmis::Ce::ProcessPoolsJob` (queue from `DJ_LONG_QUEUE_NAME`, default `long_running`)
and `Hmis::Ce::ProcessClientsJob` (queue from `DJ_SHORT_QUEUE_NAME`, default `short_running`).
Both expose `enqueue_if_not_already_running(...)`, which calls `perform_later` only when
`Delayed::Job.jobs_for_class(name)` is empty.

Cron: `lib/tasks/grda_warehouse.rake` `grda_warehouse:hourly` enqueues `ProcessClientsJob` with
`wait_time: 2.minutes` every hour. A separate daily cron entry (`config/schedule.rb`) runs
`drivers/hmis/lib/tasks/ce_candidate_pools.rake`'s `driver:hmis:ce_candidate_pool_builder`, which
runs `CandidatePoolBuilder.call(force_reprocessing: true)` under `CandidatePool.lock_for_maintenance!`.
The builder itself enqueues `ProcessPoolsJob.perform_later(wait_time: 10.minutes)` when any pool
marker is dirty.

Dirty marking: `Hmis::Ce::ChangeMarker.upsert_or_bump_version(type, trackable_ids:)`; the
`Hmis::MarkClientAsDirtyBehavior` concern; `CandidatePool.mark_all_dirty`;
`GrdaWarehouse::Tasks::ClientCleanup` and `IdentifyDuplicates` mark destination clients dirty after
merging source clients.

GraphQL mutations under `drivers/hmis/app/graphql/mutations/ce/`: `MarkUnitsAvailable` (creates
an `Opportunity` per unit), `CreateCeReferral` (waitlist origin), `CreateDirectCeReferral`
(direct-send origin), `StartCeReferralStep`, `SubmitCeReferralStep`, `CreateCeMatchRule`,
`UpdateCeMatchRule`, `DeleteCeMatchRule`, `CalculateClientCeEligibility` (provisional, no writes).
Every CE mutation starts with `raise unless Hmis::Ce.configuration.enabled?`.

Workflow builders: `CeWorkflows::{Ac,Az,Ph,Standard}::WorkflowBuilder` under
`drivers/hmis/lib/ce_workflows/`, driven by `drivers/hmis/lib/tasks/ce_define_*.rake`, with shared
helpers in `CeWorkflows::Shared::CeBuilderUtils`. `CeBuilderUtils.build_candidate_pools` runs the
builder and both jobs inline for development.

## How it works

### Dirty tracking

`Hmis::Ce::ChangeMarker` (`hmis_ce_change_markers`) is polymorphic on `trackable`, limited to
`GrdaWarehouse::Hud::Client` and `Hmis::Ce::Match::CandidatePool`. A row is dirty when
`current_version > processed_version`. `upsert_or_bump_version` bulk-imports with
`current_version = current_version + 1` on conflict; `mark_processed` copies `current_version`
into `processed_version`. Both sort by trackable id so concurrent upserts lock rows in the same
order. `Hmis::MarkClientAsDirtyBehavior` adds `after_save` and `after_destroy` callbacks that look
up the destination client through `GrdaWarehouse::WarehouseClient` and bump it; it is included in
`Hmis::Hud::Client`, `Enrollment`, `Exit`, `Assessment`, and `CustomAssessment`. If no destination
exists yet the callback is a no-op and `IdentifyDuplicates` marks the client later.

### Pools and jobs

`CandidatePoolBuilder` computes each waitlist-enabled unit group's key via
`UnitGroupRuleResolver` (`Hmis::UnitGroup.with_ce_waitlists_enabled`: project has a
`ProjectCeConfig` supporting waitlists and the group has a `workflow_template_identifier`).
The key is `[priority_expression, requirement_expression]`; a group with no priority rules or no
eligibility rules gets `nil` and `candidate_pool_id = NULL`. Pools are created idempotently via
`CandidatePoolRepository.create_for_keys` (unique index on the two expressions). Unit-group
assignments are bulk-updated and history is written to `CandidatePoolUnitGroupAssignment`. Newly
created pools are marked dirty; `force_reprocessing` marks all pools dirty.

`ProcessPoolsJob` takes a batch of dirty pool markers, skips inactive pools (no waitlist-enabled
unit group), acquires `pool.lock_for_processing(timeout_seconds: 60)`, runs `Engine.call(pool)`
as a full refresh, marks the pool processed, and re-enqueues itself while dirty pools remain.
`ProcessClientsJob` takes up to 1,000 dirty client markers, runs `Engine.call(pool, clients:)`
against every active pool with a 5-second lock timeout, and marks the clients processed only if
no pool was skipped. Both jobs hold a job-level advisory lock (timeout 0) and reconcile untracked
records before each batch.

### Rules and expressions

`Hmis::Ce::Match::Rule` (`ce_match_rules`) has `rule_type` `eligibility_requirement` or
`priority_scheme`, a Dentaku `expression`, a polymorphic `owner`, and `applicability_config`
(`project_types`, `project_funders`). `OWNER_PRECEDENCE` is `Hmis::UnitGroup` (1),
`Hmis::Hud::Project` (2), `Hmis::Hud::Organization` (3), `GrdaWarehouse::DataSource` (4).
`MatchApplicability` decides whether a rule applies to a unit group, project, or organization by
walking its ancestors; `Rule.unit_groups_for_owner` is the SQL mirror and must stay in sync.
Eligibility expressions from all applicable owners are ANDed; priority schemes come only from
the most specific owner level, ordered by `priority_rank`.

`Engine` runs `Internal::SqlPrefilter`, which uses `Expression::SqlExpressionTranslator` to turn
the requirement expression into Arel (untranslatable nodes become `1 = 1`), then
`Internal::ClientPoolEvaluator` in memory. A client fails when any priority score is nil.
`Expression::FieldMap` dispatches field names by namespace: bare or `client.` to
`ClientFieldMap`, `cde.` to `CdeFieldMap`, `custom_assessment.` to `CustomAssessmentFieldMap`,
`psde.` to `PsdeFieldMap`. The PSDE namespace is the preferred shape for new namespaces:
`PsdeField` (metadata), `PsdeFieldRegistry` (inventory), `PsdeValueResolver` (batch values),
`PsdeFieldMap` (adapter). `Expression::ExpressionTranslator` converts between free text and the
structured clauses the front-end edits; `Expression::Validator` is called from
`ManagesCeMatchRules` when a rule is saved.

### Workflows

`Hmis::WorkflowDefinition::Template` has `identifier`, integer `version`, `status`
(`draft`, `published`, `retired`), `template_type` (`ce_referral` for CE), and `data_source`.
One draft and one published row per identifier. Nodes (`UserTask`, `ScriptTask`, `Gateway`,
`StartEvent`, `EndEvent`) connect through `Flow` rows; `UserTask` names a
`form_definition_identifier` of a `CE_REFERRAL_STEP` form and a `Swimlane`. Node
`trigger_config` entries send messages (`accept_referral`, `create_enrollment`,
`set_custom_referral_status`, ...) that `Hmis::Ce::ReferralMessageHandler` handles.
`Hmis::UnitGroup` references templates by identifier through `belongs_to :workflow_template,
-> { published.latest_versions }`, so a referral binds to the latest published version at
creation. `Hmis::WorkflowExecution::Instance` holds `Step` rows, one per visited node, with
`status` `unavailable`, `available`, `in_progress`, `completed`. `Step` includes
`Hmis::Hud::Concerns::FormSubmittable`; its form values are written by
`Hmis::Hud::Processors::WorkflowStepProcessor`, registered as `WorkflowStep` in
`Hmis::Form::FormProcessor`.

Templates are built by scripts under `drivers/hmis/lib/ce_workflows/<client_key>/`. The preferred
pattern is destroy-and-recreate: `CeBuilderUtils.delete_template_and_associated_data` (raises in
production) then `CeBuilderUtils.create_template` (published, version 0), then `template.validate!`.

### Referrals and opportunities

`Hmis::Ce::Opportunity` belongs to a `Hmis::Unit`; project, unit group, and candidate pool are
resolved through the unit (`project_id`, `candidate_pool_id`, `stale`, `assignment_rules` are
`ignored_columns`). Status: `open`, `locked` (reserved by a referral), `closed`; one open or
locked opportunity per unit. `Opportunity.for_client(client)` lists open opportunities whose unit
group's pool contains the client's destination client as a `Candidate`, minus opportunities the
client was already referred to and those sharing an `OpportunityCategory` with an active referral.

`Hmis::Ce::Referral` has `referral_origin` `waitlist` or `direct_send`, `status` `initialized`,
`in_progress`, `accepted`, `rejected`, a unique `workflow_instance`, and `assignment_rules`, a
snapshot of the unit group's effective rules at creation used by `resolve_match_rule_fields`.
`CreateCeReferral` locks the opportunity, creates the instance from
`opportunity.unit_group.workflow_template`, creates default participants from
`DefaultSwimlaneAssignment`, and calls `workflow_engine.start_workflow!`. `SubmitCeReferralStep`
locks the opportunity, checks `policy_for(referral, policy_type: :ce_referral).can_perform?(step:)`,
validates values with `engine.validate_step`, runs the step's form processor, then
`engine.complete_step!`. `Referral.viewable_by(user)` unions target-project `can_view_referrals`,
own assigned or swimlane steps with `can_view_own_referrals`, and source-project
`can_view_outgoing_referral_details`.

## Key files

- `drivers/hmis/app/models/hmis/ce/change_marker.rb`: `dirty`, `clients`, `pools`,
  `batch_by_trackable_id`, `mark_processed`, `upsert_or_bump_version`, `KNOWN_TRACKABLE_TYPES`.
- `drivers/hmis/app/models/concerns/hmis/mark_client_as_dirty_behavior.rb`:
  `mark_destination_client_dirty`.
- `drivers/hmis/app/models/hmis/ce/configuration.rb`: `enabled?`, `eligibility_lookback_months`,
  `eligibility_project_group`, `bulk_void_enabled?`.
- `drivers/hmis/app/jobs/hmis/ce/process_pools_job.rb`,
  `drivers/hmis/app/jobs/hmis/ce/process_clients_job.rb`: `perform`,
  `enqueue_if_not_already_running`, `reconcile_untracked_*`.
- `drivers/hmis/app/models/hmis/ce/match/candidate_pool.rb`: `active`, `mark_all_dirty`,
  `lock_for_maintenance!`, `lock_for_processing`, `relevant_form_definition_identifiers`.
- `drivers/hmis/app/models/hmis/ce/match/candidate_pool_builder.rb`: `call`,
  `upsert_unit_group_pools!`.
- `drivers/hmis/app/models/hmis/ce/match/unit_group_rule_resolver.rb`: `key_for_unit_group`,
  `compose_priority_expression`, `compose_requirement_expression`.
- `drivers/hmis/app/models/hmis/ce/match/candidate_pool_repository.rb`: `create_for_keys`,
  `all_by_key`.
- `drivers/hmis/app/models/hmis/ce/match/engine.rb`: `call`, `Snapshot`.
- `drivers/hmis/app/models/hmis/ce/match/match_applicability.rb`: `call`, `gather_parents`.
- `drivers/hmis/app/models/hmis/ce/match/rule.rb`: `OWNER_PRECEDENCE`, `by_owner_precedence`,
  `most_specific_priority_schemes_from`, `eligibility_and_priority_rules_for_entity`,
  `unit_groups_for_owner`, `rebuild_candidate_pools`.
- `drivers/hmis/app/models/hmis/ce/match/internal/sql_prefilter.rb`: `call` returning
  `eligible_clients` and `lost_eligibility_clients`.
- `drivers/hmis/app/models/hmis/ce/match/expression/field_map.rb`: `NAMESPACES`,
  `field_type_for`, `resolve_field_for_display`.
- `drivers/hmis/app/models/hmis/ce/match/expression/sql_expression_translator.rb`: `call`,
  `to_arel`, `joins`, `ALWAYS_TRUE`.
- `drivers/hmis/app/models/hmis/ce/match/expression/psde_field_registry.rb`: field constants,
  `VALUES_IN_WINDOW_SUFFIX`.
- `drivers/hmis/app/models/hmis/ce/opportunity.rb`: state machine, `for_client`,
  `unique_opportunity_per_unit`.
- `drivers/hmis/app/models/hmis/ce/referral.rb`: `viewable_by`, state machine,
  `workflow_engine`, `create_default_participants!`, `resolve_match_rule_fields`.
- `drivers/hmis/app/models/hmis/ce/referral_message_handler.rb`: message names and routing.
- `drivers/hmis/app/models/hmis/unit_group.rb`: `with_ce_waitlists_enabled`,
  `workflow_template`, `direct_referral_workflow_template`, `rebuild_candidate_pool`.
- `drivers/hmis/app/models/hmis/project_ce_config.rb`: `supports_waitlist_referrals?`,
  `receives_direct_referrals?`, `rebuild_candidate_pool`.
- `drivers/hmis/app/models/hmis/workflow_definition/template.rb`: state machine,
  `latest_versions`, `graph`, `validate!`, `entry_user_tasks`.
- `drivers/hmis/app/models/hmis/workflow_execution/step.rb`: state machine, `open`,
  `excluding_unavailable`.
- `drivers/hmis/app/models/hmis/hud/processors/workflow_step_processor.rb`.
- `drivers/hmis/app/graphql/mutations/ce/create_ce_referral.rb`,
  `drivers/hmis/app/graphql/mutations/ce/submit_ce_referral_step.rb`,
  `drivers/hmis/app/graphql/mutations/ce/mark_units_available.rb`.
- `drivers/hmis/lib/ce_workflows/shared/ce_builder_utils.rb`: `build_candidate_pools`,
  `delete_template_and_associated_data`, `create_template`, `find_or_create_start_event`,
  `find_or_create_accept_event`, `find_or_create_decline_event`.
- `drivers/hmis/lib/ce_workflows/ac/workflow_builder.rb`: reference destroy-and-recreate builder.
- `lib/tasks/grda_warehouse.rake`: hourly `ProcessClientsJob` enqueue.
- `drivers/hmis/lib/tasks/ce_candidate_pools.rake`: daily full candidate-pool rebuild.

## Gotchas

- Callbacks rebuild pools synchronously. `Rule` (`after_create`, `after_destroy`, `after_update`
  when expression, type, or applicability changed), `UnitGroup` (`after_create`, `after_update`
  when the template identifier changed), and `ProjectCeConfig` (`after_save` when waitlists are
  supported) each call `CandidatePoolBuilder` inside `CandidatePool.lock_for_maintenance!`
  (10-second timeout). Bulk-creating rules in a loop rebuilds once per save.
- Everything is a no-op when `Hmis::Ce.configuration.enabled?` is false: change markers are not
  written, jobs raise, mutations raise. Specs must set the `hmis_ce/enabled` property.
- The engine works on destination `GrdaWarehouse::Hud::Client` records, not `Hmis::Hud::Client`.
  A client with no destination yet is not matched until `IdentifyDuplicates` runs.
- `ProcessClientsJob` leaves the whole batch dirty if any pool lock was busy, so a long
  `ProcessPoolsJob` delays all client updates rather than some.
- `Hmis::Ce::Configuration#eligibility_lookback_months` and `eligibility_project_group_id` change
  match results but do not trigger a rebuild; the hour-23 full refresh picks them up.
- `Rule.unit_groups_for_owner` (SQL) and `MatchApplicability` (Ruby) implement the same
  applicability logic; change both.
- `SqlExpressionTranslator` replaces functions and untranslatable fields with `1 = 1`, so the
  prefilter is a superset; correctness comes from `ClientPoolEvaluator`.
- `UnitGroup.candidate_pool_id` may remain set after a project stops supporting waitlists;
  `CandidatePool.active` filters through `with_ce_waitlists_enabled`.
- Draft templates cannot drive referrals; there is no admin UI for templates. Templates are
  published from builder scripts. Unit groups reference templates by `identifier`, referrals by
  `id`, so republishing does not move in-flight referrals.
- `Template` deletion does not nullify `UnitGroup.workflow_template_identifier`; the builder
  is expected to recreate the same identifier immediately.
- `Opportunity.ignored_columns` includes `project_id`, `candidate_pool_id`, `stale`,
  `assignment_rules`; go through `unit`.
- `Referral#resolve_match_rule_fields` intentionally bypasses `viewable_by` scopes.
- `MarkUnitsAvailable` still enforces a legacy `ReferralPosting` count check for
  installations running both systems.

## Do not repeat

- The draft-idempotent builder idiom: `CeBuilderUtils.find_or_create_draft_template` plus
  `FORCE_RECREATE` / `PUBLISH=true` environment flags and `find_or_create_*` node guards.
  Remaining examples: `drivers/hmis/lib/ce_workflows/standard/workflow_builder.rb:60` and
  `drivers/hmis/lib/ce_workflows/ph/workflow_builder.rb:89`. New builders use
  destroy-and-recreate: `drivers/hmis/lib/ce_workflows/ac/workflow_builder.rb:61`
  (`delete_template_and_associated_data` unless `unsafe_run_in_production`, then
  `create_template`).
- Calling classes under `drivers/hmis/app/models/hmis/ce/match/internal/` from outside
  `Hmis::Ce::Match`. Use `Engine.call`, `CandidatePoolBuilder.call`, or the `Rule` class helpers.
- A monolithic field map for a new expression namespace. `ClientFieldMap`, `CdeFieldMap`, and
  `CustomAssessmentFieldMap` predate the split; new namespaces follow
  `drivers/hmis/app/models/hmis/ce/match/expression/psde_field_registry.rb` plus `PsdeField`,
  `PsdeValueResolver`, `PsdeFieldMap`.
- Storing pool or project ids on `Opportunity`. The columns exist but are ignored; resolve
  through `unit.unit_group`.
- Reading `Opportunity.candidate_pool_id` or per-opportunity rules. Rules live on unit groups and
  are snapshotted onto `Referral.assignment_rules` at creation.
- Writing `ChangeMarker` rows with `create`/`update`. Use `upsert_or_bump_version` and
  `mark_processed`, which sort by conflict target to avoid deadlocks.
- Calling `CandidatePoolBuilder.call` without `CandidatePool.lock_for_maintenance!`. Every
  existing caller wraps it: `drivers/hmis/app/models/hmis/ce/match/rule.rb:209`.

## Related

- `hmis/data-model.md`: `Hmis::Unit`, `Hmis::UnitGroup`, `Hmis::UnitType`, `Hmis::UnitOccupancy`,
  and `Hmis::ProjectConfig`, the parent of `ProjectCeConfig`.
- `hmis/forms.md`: `Hmis::Form::Definition` with role `CE_REFERRAL_STEP`, `FormProcessor`, and
  how custom data elements from step forms feed `cde.` match fields.
- `hmis/assessments.md`: `Hmis::Hud::Assessment` (GraphQL `CeAssessment`) and
  `CustomAssessment`, both of which include `MarkClientAsDirtyBehavior`.
- `warehouse/client-identity.md`: `IdentifyDuplicates` and `ClientCleanup`, which produce the
  destination clients the engine evaluates.
- `warehouse/cas-integration.md`: the separate warehouse-to-CAS matching path.
- `docs/features/hmis/ce-processing.md`, `docs/features/hmis/ce-match-engine.md`,
  `docs/features/hmis/ce-workflow-builders.md`, `docs/features/hmis/hmis-units.md`: human docs
  with sequence diagrams and per-client workflow READMEs.
