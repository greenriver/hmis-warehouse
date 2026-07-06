# Keycloak user migration (`rails keycloak:*`)

`lib/tasks/keycloak.rake` seeds Keycloak from the legacy Devise/warehouse `User` records before a
Deployment switches to JWT auth. It is **temporary, human-run, console-only** tooling — run by hand,
per Deployment, in the window between migrating data and flipping auth; it never runs on boot or in a
request. It drives `Idp::Keycloak::UserImporter` over `Idp::KeycloakService#partial_import`, and is
deleted along with the importer once every Deployment has migrated.

Run `rails -T keycloak` for the task list and the rake header (`lib/tasks/keycloak.rake`) for usage.

## Scope

`Idp::Keycloak::UserImporter.migration_scope` migrates **confirmed, active** users. The `confirmed_at`
filter also excludes invited-but-not-accepted users — accepting an invitation is what sets
`confirmed_at`, so they have no credential to carry and are instead provisioned on first JWT login.

## Re-running and the pre-flip pass

The importer is safe to re-run, and a final re-run is the intended last step before switching auth.
Both `migrate_users` and `export_users` accept a `since` timestamp to limit the pass to users changed
during migration, keeping the switchover gap to minutes.

Re-imports default to the `OVERWRITE` conflict policy so that edits made after the first pass — a
password reset, a new TOTP secret — are carried over. `SKIP` (`migrate_users[,,SKIP]`) leaves existing
Keycloak users untouched and would silently drop those edits.

## 2FA backup codes are not migrated

The importer carries the TOTP secret but drops `otp_backup_codes`: Keycloak's recovery-code format
differs and there is no clean `partialImport` mapping. A user who relied on backup codes must use their
authenticator app at first login, or have an admin reset 2FA in Keycloak.
