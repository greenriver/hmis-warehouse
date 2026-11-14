---
sources:
  - drivers/hmis/app/jobs/hmis/auto_exit_job.rb
  - drivers/hmis/app/models/hmis/enrollment_exit_creator.rb
  - drivers/hmis/app/models/hmis/project_auto_exit_config.rb
  - drivers/hmis/app/models/hmis/project_config.rb
---

# HMIS Auto-Exit

## Overview

Auto-Exit exits household enrollments that have had no contact with a project for a configured number of days. It is a nightly job (`driver:hmis:auto_exit`, scheduled in `config/schedule.rb`) that runs `Hmis::AutoExitJob` across all HMIS projects.

- **Configuration:** `Hmis::ProjectAutoExitConfig` (`Hmis::ProjectConfig` with `config_type` `AUTO_EXIT`) stores `length_of_absence_days`, which must be at least 30. `Hmis::ProjectConfig.detect_best_config_for_project` picks the most specific config: project, then organization, then project type. The job skips entirely when no config exists.
- **Who is exited:** `Hmis::AutoExitJob` decides who to exit and the exit date. It works per household, skips households with incomplete (WIP) enrollments or an active CE referral, and finds each member's most recent contact. Night-by-Night Emergency Shelters only consider bed nights and entry date.
- **How they are exited:** `Hmis::EnrollmentExitCreator` creates the Exit record and an associated Exit Assessment for every open household member. Bulk-exit and `BulkVoider` flows reuse it.
- **HUD guidance:** HUD only specifies auto-exit for Night-by-Night shelters: exit after a community-set length of absence (e.g. 90 days), Exit Date the day after the last bed night, Destination "No exit interview completed" (FY2026 Data Standards Manual 2.02 and 3.11). Other project types, household-level exits, and the 30-day minimum are Open Path decisions.

## Support reference

> This section explains Auto-Exit for support staff and HMIS administrators, in plain language with no code details. Use it to answer customer questions about why a household was or wasn't auto-exited and how the exit date was chosen.

Auto-Exit closes enrollments for households that have had no recorded contact with a project for a set number of days. It runs automatically every night for every project with Auto-Exit turned on.

### When a household is exited

An administrator turns on Auto-Exit and sets a **Length of Absence**, which must be at least 30 days. The setting can apply to:

- a single project
- every project in an organization
- every project of a given project type

If more than one setting applies, the most specific one wins: project first, then organization, then project type.

A household is exited when its most recent contact is at least the Length of Absence days ago. Auto-Exit treats the household as a unit:

- If **any** member has recent contact, **nobody** in the household is exited.
- Otherwise **every** open member is exited on the same exit date.

A household is never auto-exited if:

- any member's enrollment is incomplete (for example, an intake that hasn't been submitted yet)
- any member's enrollment is the source or target of an active Coordinated Entry referral

### What counts as contact

Which records count depends on whether the project is a Night-by-Night Emergency Shelter. Deleted records never count.

| Record | Night-by-Night Emergency Shelter | All other projects |
| --- | --- | --- |
| Bed Night service | Yes | Yes |
| Any other HUD service | No | Yes |
| Custom service | No | Yes |
| Current Living Situation | No | Yes |
| Assessment of any kind (HUD or Custom), including drafts | No | Yes |
| Case note (with a date) | No | Yes |
| Project Start (entry) date | Yes, when there are no Bed Nights | Yes |

Files and any other records do not count as contact for any project.

### How the exit date is chosen

The exit date starts as the date of the household's most recent contact. It moves one day later in either of these cases:

1. **The most recent contact is a Bed Night.** A Bed Night means the client stayed that night, so the exit is the next morning. This applies in any project where Bed Nights are recorded.
2. **The exit date would be the same as the Project Start date in a project that doesn't allow same-day exits.** HUD treats same-day exits in residential projects as a data quality error, so the exit moves to the next day.

The exit date never moves more than one day. A Bed Night on the Project Start date gives an exit the next day, not two days later.

#### Projects that allow same-day exits

| Project type | Same-day exit allowed? |
| --- | --- |
| Emergency Shelter (Entry/Exit and Night-by-Night) | No |
| Transitional Housing | No |
| Safe Haven | No |
| Permanent Supportive Housing and other Permanent Housing | No |
| Rapid Re-Housing (housing and services) | No |
| Rapid Re-Housing (services only) | Yes |
| Street Outreach | Yes |
| Services Only, Coordinated Entry, Day Shelter, Homelessness Prevention, Other | Yes |

### What gets recorded

For each exited member, Auto-Exit records:

- an exit on the chosen exit date, with Destination "No exit interview completed"
- an exit assessment dated the exit date
- a marker showing the exit was made by Auto-Exit
- the release of any unit assigned to the member

### Things to know

- **Same-day ties:** if two records share the most recent date and one is a Bed Night, the Bed Night is used and the exit moves to the next day. When the tied records belong to different household members, the system may use either member's record, so the date may or may not move. If a Bed Night and another HUD service share the most recent date, either may be used.
- **Members who started later:** the same-day-exit rule only looks at the Project Start of the member whose record set the date. In a shelter, another member whose Project Start falls on the exit date can end up with the same entry and exit date.
- **No other date checks:** the exit date isn't compared against the project's operating end date or any funder rules.
