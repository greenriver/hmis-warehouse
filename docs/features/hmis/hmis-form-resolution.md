# HMIS form resolution

Several published form definitions can share a role, so "which form does the user get?" is a real question with a non-obvious answer. Resolution happens in three separate layers, and conflating them is the most common source of confusion in this subsystem:

1. **Which definition applies** for new data entry in a project — decided by form rules.
2. **Which definition is used** to view or edit an existing record — decided by what that record was collected with, mostly.
3. **Which items inside the form** are shown — decided by per-item rules, evaluated partly on the server and partly in the browser.

For the definition model and its statuses, see [Form definitions](hmis-form-definitions.md).

## Form rules

`Hmis::Form::Instance` (table `hmis_form_instances`), called a **Form Rule** in the UI, binds a form to a scope. A rule references a definition by `definition_identifier`, **not** by `id`, so publishing a new version changes which definition is live without any rule being touched.

A rule's scope is expressed through these columns, all optional:

| Column | Scope |
| --- | --- |
| `entity_type` / `entity_id` | A specific Project or Organization |
| `project_type` | HUD project type |
| `funder` / `other_funder` | HUD funding source |
| `custom_service_type_id` / `custom_service_category_id` | Which service(s) a `SERVICE` form can collect |
| `data_collected_about` | Which household members the form is collected for |

A rule with none of the scope columns set is a **default** rule: it matches every project.

Two flags matter. `system: true` rules are created by the seeding pipeline for HUD compliance and cannot be removed in the admin UI. `active: false` is how deletion works — rules are deactivated, not destroyed. Rules also cannot be edited in the UI; users deactivate one and create another.

Validation enforces two role-specific requirements: a `SERVICE` rule must name a service type or category, and an `EXTERNAL_FORM` may have only one active rule, which must be Project-scoped.

## Choosing a definition for new data entry

`Hmis::Form::Definition.for_project` does this in three steps:

1. Take all definitions for the role that are published, in the project's data source, and have at least one active rule.
2. Of the rules pointing at those definitions, find the best match for this project.
3. Return the published definition belonging to that rule's identifier.

### Rule ranking

`InstanceProjectMatch` ranks matches from most to least specific. `detect_best_instance_for_project` sorts by rank and takes the first, with a stable sort so ties resolve by scope order rather than at random.

| Rank | Match | Meaning |
| --- | --- | --- |
| 0 | `project` | Rule names this project |
| 1 | `organization` | Rule names this project's organization |
| 2 | `project_type_and_funder` | Rule names both, and both match |
| 3 | `project_type` | Rule names a project type only |
| 4 | `project_funder` | Rule names a funder only |
| 5 | `default` | Non-system rule with no scope |
| 6 | `default_system` | System rule with no scope |

System defaults rank last on purpose, so a community's own default rule beats the HUD-compliance one.

Note that funder matching uses *all* of a project's funders, not just active ones, so a rule can still apply through a funder the project no longer has. That is a known wart, flagged in `instance_project_match.rb`.

### Exclusive and inclusive roles

The ranking above picks a single winner, which is right for some roles and wrong for others. The distinction is implemented in the GraphQL query layer, not on the model:

- **Exclusive** roles (Project, Client, Enrollment, assessments): only the single best-matching form is used.
- **Inclusive** roles (Services, custom assessments): every matching rule applies, so several forms are offered at once.

`OCCURRENCE_POINT` is the exception that fits neither. Occurrence point forms behave inclusively but have no role-based exclusivity to fall back on, because there is no distinct role per occurrence point. The consequence is a configuration footgun: **two occurrence point rules that collect the same enrollment field will both apply, and the field appears twice on the enrollment dashboard** ([#6972](https://github.com/open-path/Green-River/issues/6972#issuecomment-2512299899)). This has not yet happened in a client environment, because non-super-admins cannot duplicate forms or map questions onto enrollment fields — both should be solved before those capabilities are opened up. `OccurrencePointFormCollection` also has a legacy path that surfaces retired HUD forms (move-in date, date of engagement, PATH status) when an enrollment has data for them but no active rule.

### Enrollment-level matching

For enrollment forms, a rule that matches the project must also match the enrollment. `InstanceEnrollmentMatch` evaluates the rule's `data_collected_about` against the enrollment: `ALL_CLIENTS`, `HOH_AND_ADULTS`, `HOH`, `ALL_VETERANS`, or `VETERAN_HOH`. Unset means `ALL_CLIENTS`.

### Service forms

Service forms resolve by service type through `Definition.for_service_type`, which prefers a rule naming the specific `custom_service_type` and falls back to one naming the `custom_service_category`. Because `SERVICE` is inclusive, a project can legitimately offer several service forms.

### When nothing matches

For system roles (Client, Project, Enrollment, and the rest), finding nothing is a fatal misconfiguration and raises. For optional roles like Current Living Situation, finding nothing simply means the feature is off in that project.

The GraphQL resolvers go a step further: if no rule matches, `recordFormDefinition` and `serviceFormDefinition` fall back to *any* version-controlled published form for the role, on the reasoning that showing data with an imperfect form beats erroring. This is a deliberate safety net, and it also means a misconfigured project can look like it is working.

## Choosing a definition for an existing record

Every submitted form leaves a `Hmis::Form::FormProcessor` recording the exact definition used, which is what allows a record to be re-rendered in the shape it was collected in. What the UI does with that record varies by entry point.

**Assessments upgrade on unlock.** `Assessment.upgradedDefinitionForEditing` returns the published version of the same identifier, but only when the original definition is retired and the assessment is not work-in-progress. The front-end views a submitted assessment with its original definition and swaps to the upgraded one when the user clicks Unlock — a client-side state change, not a server mutation — and submits against that newer id. So retiring an assessment form does not freeze old assessments. If no published version of the identifier exists, the upgrade resolves nil and the original definition is used for editing too.

**Dialog-based record forms stay pinned.** Case notes, services, current living situations, and CE participations are edited in a dialog that passes the record's `formDefinitionId` back to `recordFormDefinition`, so they are always rendered and submitted with the definition they were collected with, retired or not, active rule or not. A retired record form therefore keeps its records editable in their original shape indefinitely.

**Full-page record forms do not.** `EditRecord`, used for Client, Project, Organization, Inventory, and File, resolves by `role` and `projectId` and never passes the record's stored definition. Editing a Client can therefore submit against a newer published definition than the one the data was collected with. This looks unintentional rather than designed, and it is worth knowing before relying on "record forms are pinned" as a general rule.

Nothing in the UI tells a user that the form in front of them is retired.

## Item-level filtering

A form can be resolved and still not show all of its questions. Two mechanisms do this, and they run in different places.

**`rule` and `custom_rule` are evaluated on the server.** `DefinitionItemFilter` removes items when the definition is resolved, using the project and funders from `filter_context`. `rule` is HUD-derived and written by `set_hud_requirements`; `custom_rule` is installation-specific. When an item has both, either one passing is enough. With no project in context — the Client form outside a project, for instance — rules pass and nothing is filtered. The filtered result is what `FormDefinition.definition` returns; `raw_definition` is the unfiltered original.

This has a sharp edge: **if every item is filtered out for a project, the GraphQL field is non-null and the query fails** with `Cannot return null for non-nullable field FormDefinition.definition` ([discussion](https://greenriver.slack.com/archives/C061SAW3LFJ/p1733158338135599)). Don't build a form whose questions are all conditioned away. Like the occurrence point issue, this is currently gated by non-super-admins being unable to author custom item rules.

**`data_collected_about` on an item is evaluated in the browser.** For household assessments the server returns the full definition and the front-end strips items per client, in `applyDefinitionRulesForClient`. Do not expect the definition delivered over GraphQL to reflect it.

### `data_collected_about` means two different things

The same name is used at two layers, with different jobs:

- **On a form rule**, it decides which household members the whole form is collected for. This is the `InstanceEnrollmentMatch` behavior above, and it is the only place `ALL_VETERANS` and `VETERAN_HOH` exist.
- **On an item**, it is a HUD requirement about which clients a specific question applies to. `set_hud_requirements` reconciles the HUD requirement with whatever the form specifies and keeps the *less* strict of the two — so HUD does not simply win.

`filter_context` is the ephemeral carrier for all of this: an attribute set on the definition by GraphQL resolvers, holding the project and sometimes an active date. It is easy to forget when exercising definitions outside of GraphQL, and it participates in the definition's cache key.

## Related

- [Form definitions](hmis-form-definitions.md) — the model, roles, and status lifecycle
- [Form processing](hmis-form-processing.md) — what happens once a form is submitted
- [Form seeding](hmis-form-seeding.md) — where system rules come from
- [Form authoring](hmis-form-authoring.md) — the item properties referenced here
- [HMIS assessments](hmis-assessments.md) — assessment record types and work-in-progress behavior
