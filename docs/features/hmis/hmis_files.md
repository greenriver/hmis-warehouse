# HMIS Files

Client files are documents (IDs, releases, referrals, etc.) uploaded to a client record in the HMIS, optionally linked to one of the client's enrollments. This document covers who can see, open, edit and delete them. For the underlying permission model, see [HMIS Permissions](hmis-permissions.md) and [HMIS Auth Policies](hmis-auth-policies.md).

## Overview

<!-- TODO: What files are, where they appear in the UI, how they relate to Client and Enrollment (Hmis::File belongs_to :client, optionally :enrollment). -->

## File Visibility

Visibility is decided by the `Hmis::File.viewable_by(user)` scope (`drivers/hmis/app/models/hmis/file.rb`). Whether a user can *open* a visible file is a separate check (see [Confidential vs. Nonconfidential](#confidential-vs-nonconfidential)).

### Files linked to an enrollment

A file linked to an enrollment is visible only to users who can see that enrollment. At the enrollment's project, the user needs all of these:

- Can view project
- Can view clients
- Can view enrollment details
- Can view any nonconfidential client files (or can view any confidential client files)

A file permission alone is not enough. Without "can view enrollment details" at the project, the file is hidden. The same happens without "can view project", because "can view enrollment details" doesn't take effect without it (see [Permission requirements](hmis-permissions.md#permission-requirements)).

Implementation: `Hmis::Hud::Enrollment.files_viewable_by` requires `can_view_enrollment_details` and one of the file-viewing permissions at the project. `can_view_project` and `can_view_clients` are enforced through `Hmis::Role` permission requirements, which `HmisPermissionLoader#apply_permission_requirements` applies when permissions are resolved.

### Files not linked to an enrollment

These belong to the client only. They are visible to anyone who can view the client and has a file-viewing permission at one of the client's projects. If the client has no enrollments, a file-viewing permission anywhere in the system is enough. This is much broader than the enrollment-linked case.

Implementation: `Hmis::Hud::Client.files_viewable_by`.

### Confidential vs. nonconfidential

- A user who can see a file can always see that it exists, including a confidential one.
- Opening the file requires the matching permission at the project: "can view any nonconfidential client files" for nonconfidential files, "can view any confidential client files" for confidential ones.
- A user with only the nonconfidential permission sees confidential files in the list but can't open them.

Implementation: `HmisFilePolicy::Instance#can_view_unredacted?`. For an enrollment-linked file the permissions are taken from the enrollment's project; otherwise from the client's aggregated project permissions.

### Files the user uploaded themselves

- "Can manage own client files" applies to the whole system, not to one project.
- A user who has it can see the files they uploaded on any client they can view. This holds even without enrollment access at the project the file is linked to.
- They can also open, edit and delete their own files.
- It does not let them see files other people uploaded.

### Fixing a hidden file

Either grant the missing permissions at the project, or have the file attached to the client without an enrollment link.

## Editing and Deleting

The user must be able to open the file and have "can manage any client files" at the project, or be the uploader with "can manage own client files".

## Uploading Files

<!-- TODO: Who can upload (HmisFilePolicy::Global#can_upload_files?, HmisClientPolicy#can_create_file?), enrollment linking rules. -->

## Permissions Reference

<!-- TODO: Table of file-related permissions (can_view_any_nonconfidential_client_files, can_view_any_confidential_client_files, can_manage_any_client_files, can_manage_own_client_files), their requirements, and whether they are project-scoped or global. -->

## File Tags and Categories

<!-- TODO -->

## Storage and Processing

<!-- TODO: Active Storage / S3, content types, size limits, virus scanning, thumbnails. -->

## GraphQL API

<!-- TODO: Types, queries and mutations; how access flags are exposed to the frontend. -->

## Files and Custom Data Elements

<!-- TODO: File-valued custom data elements (CustomDataElement value_file). -->

## Client Merges

<!-- TODO: What happens to files when clients are merged. -->

## Known Gotchas

<!-- TODO -->

## Testing

<!-- TODO: Relevant specs and fixtures. -->
