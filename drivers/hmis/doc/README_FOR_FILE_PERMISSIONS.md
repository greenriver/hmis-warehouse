# File Permissions Quirks

This document captures non-obvious behaviors of HMIS file permissions. See also [`PERMISSIONS.md`](./PERMISSIONS.md) for the general HMIS permissions model.

Relevant code:
- `drivers/hmis/app/models/hmis/file.rb` — the `File#viewable_by` scope
- `drivers/hmis/app/models/hmis/auth_policies/hmis_file_policy.rb` — per-instance and global file policy checks

## Files can be attached to either a Client or an Enrollment

`Hmis::File` belongs to a `Client` (currently always present for HMIS files, even though the DB column is nullable) and optionally to an `Enrollment`. This drives which permissions apply:

- **Enrollment-attached files:** permissions come from the enrollment's project. TODO @martha - this is not currently true, needs more work if desired
- **Client-only files:** permissions come from the client, which aggregates permissions across the projects the client is enrolled in, falling back to global permissions for unenrolled clients.

## Confidential files are listable but not readable

The `File#viewable_by` scope intentionally includes confidential files even when the user lacks `can_view_any_confidential_client_files`. Users see that a confidential file exists, but cannot read it. The per-instance `can_view?` check enforces the read restriction. TODO @martha what about can_view_unredacted?

## `can_manage_own_client_files` is a global permission

`can_manage_own_client_files` is treated as a **global** permission within a data source.

- If a user has `can_manage_own_client_files` granted in **any** access control within the data source, they can view and manage files they uploaded for **any client they can view** — even if they do not have `can_manage_own_client_files` (or any file permission) in the projects that client is enrolled in.
- Visibility of the file is still gated by the user's ability to view the underlying `Client` (via `Hmis::Hud::Client.viewable_by`). Users cannot see "own" files for clients they have no access to.

# TODO @martha - add more detail about https://github.com/open-path/Green-River/issues/8999#issuecomment-4462530709 depending on discussion