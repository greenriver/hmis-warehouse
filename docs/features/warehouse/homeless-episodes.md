# Homeless Episodes

An **episode** is a continuous period of homelessness. The warehouse has multiple chronic-homelessness calculations that depend on how episodes are counted, and they are deliberately different:

- **The official calculation** (`GrdaWarehouse::ChEnrollment`) implements HUD's chronic-at-project-start and chronic-at-point-in-time algorithm from the client's own 3.917 answers.
- **The enrollment-based calculation** (`ClientHistory::Calculator#new_episode?`) decides from collected enrollment data on file whether an ES, Safe Haven, or Street Outreach entry starts a new episode. It predates the official implementation. This was an attempt to bypass the self-reported 3.917 data, which at the time was thought to be unreliable.  This version is now deprecated, new work should use `GrdaWarehouse::ChEnrollment` where possible.

## Where the enrollment-based calculation is used

| Consumer | What it does with the result |
|---|---|
| Client dashboard enrollment roll-up — `app/views/clients/_enrollment_table.haml`, via `new_episode` in `ClientAccessControl::GrdaWarehouse::Hud::ClientExtension#enrollments_for` | Highlights rows that start a new episode (`enrollment__new-episode`) |
| **Potentially Chronic Clients** report — `GrdaWarehouse::Tasks::ChronicallyHomeless#chronic?`, listed at `warehouse_reports/chronic` and stored as `GrdaWarehouse::Chronic` | For clients with 12+ homeless months in the last 36 who were not homeless in every one of the last 12, counts `homeless_episodes_between` over three years and marks them potentially chronic when there are 4 or more. This is the pre-3.917, data-based chronic list; the CAS sync includes everyone on the most recent list (`clients/cas_readiness/_chronic.haml`) |
| Per-client chronic calculator — `app/views/clients/chronic/_chronic_calculator.haml` | Shows "Homeless episodes in the last 3 years" |
| Ad-hoc, anonymized ad-hoc, and youth exports — `WarehouseReport::ExportEnrollmentCalculator` (`episode_counts_past_3_years_for`, `episode_length_for`, `average_episode_length_for`), used by `GrdaWarehouse::WarehouseReports::Exports::AdHoc`, `Exports::AdHocAnon`, `Youth::Export` | Episode count and episode-length columns |
| `GrdaWarehouse::Hud::Client#homeless_episodes_between`, `#length_of_episodes`, `#new_episode?`; `GrdaWarehouse::Hud::Enrollment#new_episode?` | Wrappers the consumers above call |

## HUD's definition

HUD does not define "episode" as a standalone term. The operative definition is the one behind 3.917 Prior Living Situation, field 4, *Number of times the client has been on the streets, in ES, or SH in the past three years*:

> number of times the client was on the streets, in an emergency shelter, or in a Safe Haven in the last 3 years where there are full breaks in between (i.e., breaks that are 90 days or more in an institution or 7 nights or more in permanent or transitional housing).
> — FY 2026 HMIS Data Standards Manual, 3.917 Prior Living Situation

The same thresholds appear as operating rules in the LSA specification:

> a client may not be counted as experiencing homelessness on any date between PSH move-in and the day prior to exit … The only exception to this is for stays of less than seven days, and only if the dates fall between two dates less than seven days apart on which the client is otherwise documented as being on the street or in ES/SH.
> — FY 2026 LSA Programming Specifications, §1.3 (PSH; the RRH and TH entries read the same)

and in the System Performance Measures, where a housed PH stay "negates" homeless nights and "introduces a break in homelessness" (SPM Programming Specifications, Measure 1, worked example).

Three consequences of the official definition:

1. **Housed time breaks an episode after 7 nights.** Time in transitional housing or in permanent housing after move-in is not homeless time; 7 or more consecutive such nights end the episode.
2. **Institutional time breaks an episode after 90 days.** Shorter jail, hospital, or treatment stays do not.
3. **Unaccounted time never breaks an episode.** HUD assumes a client with no recorded contact is still on the street and fills the gap with the self-reported *Approximate date this episode of homelessness started* (`DateToStreetESSH`).

HUD applies these through the client's own 3.917 answers. There is no fixed lookback window.

## Potentially Chronic definition

In the locations noted above, the warehouse computes episodes from **enrollment data on file** rather than from the client's self-reported 3.917 history. The self-reported duration fields (`DateToStreetESSH`, `TimesHomelessPastThreeYears`, `MonthsHomelessPastThreeYears`) are not consulted for this calculation. Two categorical fields are included: the exit `Destination` (3.12) of the stay that ended the previous homeless night, and `LivingSituation` (3.917 field 1) of the enrollment being evaluated.

For an entry into a project whose type is in `HudHelper.util.chronic_project_types` (ES, SH, SO), with entry night `entry_date`:

- **Homeless nights** are service-history nights, ES, SO, and SH, plus nights in a PH enrollment before its move-in date when that PH enrollment's `LivingSituation` is a homeless situation. TH nights are *not* homeless nights.
- **Housed nights** are nights in PH after move-in, plus every night in TH.
- The **last homeless night** is the latest homeless night before `entry_date`. The **gap** is the nights strictly between the two.

The entry starts a new episode when any one of these holds:

| Rule | Condition | HUD basis |
|---|---|---|
| (a) | There is no earlier homeless night | First occasion |
| (b) | The gap contains 7 or more consecutive housed nights | 3.917 "7 nights or more in permanent or transitional housing" |
| (c) | The gap is 7 or more nights long, and either the new entry's `LivingSituation` is a permanent situation or the stay holding the last homeless night exited to a permanent-housing `Destination` | Same 7-night rule, for housing that is not an HMIS enrollment |
| (d) | The gap is 90 or more nights long, whatever it contained | 3.917 "90 days or more in an institution" |

Otherwise the entry continues the previous episode. Entries into non-chronic project types (TH, PH, services-only, etc.) are never flagged as a new episode.

**(e) Same-day tie-break.** Rules (a)–(d) only look at nights before the entry date. Two ES/SH/SO records with the same entry date, one stay present in two data sources, or entered twice in one, both qualify. The record with the lowest `ServiceHistoryEnrollment#id` starts the episode. The enrollment roll-up sorts rows by entry date descending and then id descending, so the marked row is the lowest of the same-day rows in the table.

## The official calculation

`GrdaWarehouse::ChEnrollment.chronically_homeless_at_start(enrollment, date:)` implements the HMIS Reporting Glossary's "Chronic Homelessness at Project Start" flowchart line by line: disabling condition (3.08), project type, then — depending on whether the client entered from a homeless, institutional, or other situation — `DateToStreetESSH`, `TimesHomelessPastThreeYears`, `MonthsHomelessPastThreeYears`, `LOSUnderThreshold`, and `PreviousStreetESSH`. It answers `:yes`, `:no`, `:dk_or_r`, or `:missing` for one enrollment; it does not count episodes and does not read service history except to extend ES/SO time to a point-in-time date. Results are cached per enrollment in the `ch_enrollments` table by `GrdaWarehouse::ChEnrollment.maintain!`, which runs at the end of the nightly import (`Importing::RunDailyImportsJob`) and from the `ch_enrollment_exited_rebuild` task in `TaskQueue`.

It is not affected by the enrollment-based rules on this page.

### HUD reports that use the official calculation

| Report | Driver |
|---|---|
| CoC APR, ESG CAPER, CE APR (Q26 chronic questions, household chronic status) | `hud_apr` — `HudApr::Generators::Shared::*::Base` |
| HUD Data Quality Report | `hud_data_quality_report` |
| PATH Annual Report | `hud_path_report` |
| Point-in-Time (PIT) count | `hud_pit` |
| HOPWA CAPER | `hopwa_caper` |
| Shared HUD report household context | `app/models/concerns/hud_reports/households.rb`, `HudReports::HouseholdContextBuilder` |

The **LSA** computes chronic status inside its own SQL (`drivers/hud_lsa/.../table_concern.rb`) following the LSA specification, and does not read `ch_enrollments`. The **System Performance Measures** do not report chronic status.

### Other places that use the official calculation

| Feature | Location |
|---|---|
| Chronic system cohorts | `GrdaWarehouse::SystemCohorts::Chronic`, `::ChronicAdultOnly` |
| CAS client push (chronic flag) | `GrdaWarehouse::Tasks::PushClientsToCas`, `GrdaWarehouse::CasProjectClientCalculator::Mdha` |
| Report filter "chronic at entry" | `Filters::Criteria::FilterForChronicAtEntry` |
| Client dashboard chronic-at-entry / chronic-at-most-recent icons and enrollment detail page | `client_extension.rb#enrollments_for` (`chronically_homeless_at_start`), `app/views/clients/enrollments/show.haml`, `Clients::EnrollmentsController` |
| Core Demographics report | `drivers/core_demographics_report` (`ChronicCalculations`) |
| HMIS Data Quality Tool | `drivers/hmis_data_quality_tool` |
| MA monthly performance, public state-level report, System Pathways | `drivers/ma_reports`, `drivers/public_reports`, `drivers/system_pathways` |
| HMIS (React front end) client chronic status | `drivers/hmis/app/graphql/types/hmis_schema/client.rb`, `Hmis::ChEnrollment` |

## Where things live

| Concern | Location |
|---|---|
| Rule implementation | `app/models/client_history/calculator.rb` — `#new_episode?`, `HOUSED_BREAK_NIGHTS`, `UNACCOUNTED_BREAK_NIGHTS` |
| Same-day row ordering that pairs with rule (e) | `client_extension.rb#enrollments_for` — `order(first_date_in_program: :desc, id: :desc)` |
| Night classification consumed by the rules | `GrdaWarehouse::Tasks::ServiceHistory::Enrollment#build_service_days`; see [Service History › Homelessness Classification](service-history.md#homelessness-classification) |
| HUD code lists | `HudHelper.util` — `chronic_project_types`, `residential_project_type_numbers_by_code`, `permanent_destinations`, `permanent_situations(as: :prior)`, `homeless_situations(as: :prior)` |
| Dashboard consumer | `drivers/client_access_control/app/models/client_access_control/extensions/grda_warehouse/hud/client_extension.rb` (`enrollments_for`), `app/views/clients/_enrollment_table.haml`; see [Client Dashboards](client-dashboards.md) |
| Episode counters | `GrdaWarehouse::Hud::Client#homeless_episodes_between`, `#length_of_episodes` |
| Specs | `spec/models/client_history/calculator_spec.rb`, `spec/models/grda_warehouse/hud/client_spec.rb` ("New episode checks") |
