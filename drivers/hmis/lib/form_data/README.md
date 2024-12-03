# Form Configuration Guidelines

Here are some form "gotchas" that we, as developers and Super-Admins of the config tool, should stay aware of when configuring client forms. This documentation lives in here near the code, for now, as opposed to in the Config Tool documentation, since our hope is to smooth these details over before handing off the related admin capabilities to users.

- This directory contains form configuration for "system-managed" forms, aka forms that are `managed_in_version_control`.
  - Don't put service forms or custom assessments in here. They should be managed in the Config Tool.
- Don't create multiple Occurrence Point form instances that record the same data on enrollments. (Such as Move-in Date or Date of Engagement.)
  - This would result in duplicate data showing on the enrollment dash, as described here: https://github.com/open-path/Green-River/issues/6972#issuecomment-2512299899
  - This has not yet come up in a client environment. Non-Super Admins cannot yet Duplicate forms in the config tool, nor set data collection onto Enrollment Record fields (as opposed to Custom Data Elements). We should solve this before turning on either of those features outside of Super-Admin mode.
  - This affects Occurrence Point Forms but not Data Collection Features because we don't have Form Roles for Occurrence Point Forms. With Data Collection Features, we would only ever return the best (most specific) form for that Role. (Maybe this points to a problem with the Occurrence Point Form implementation, and they should be transitioned to using Form Roles.)
- Don't create a form definition where all questions are ruled out for a given project context by custom item rules.
  - If we ever do this, and then enable the form in such a project, we see an error like this: [GraphQL GetEnrollmentDetails] message: "Cannot return null for non-nullable field FormDefinition.definition" [example](https://greenriver.slack.com/archives/C061SAW3LFJ/p1733158338135599)
  - This has not yet come up in a client environment. Non-Super Admins cannot yet create custom form item rules in the Config Tool. We should solve this before enabling that functionality for more clients.
