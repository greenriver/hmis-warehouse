# HMIS Client Merges

## Overview

Client merging allows users to combine multiple client records that represent the same person into a single client.

When clients are merged:
- One client is selected as the **retained client** (the oldest by `DateCreated`, then by ID)
- Other clients are **soft-deleted**
- Related records are updated to point to the retained client
- An audit trail is maintained

## Key Concepts

### Related Code

- **Hmis::MergeClientsJob:** `drivers/hmis/app/jobs/hmis/merge_clients_job.rb`
  - Validates all clients are from the same data source
  - Determines client to retain
  - Creates an audit trail
  - Updates the retained client's attributes with "best" values from all merging clients
  - Updates related records to point to retained client
  - Deduplicates related records where applicable
  - Soft-deletes non-retained clients
  - Destroys `WarehouseClient` linking records for deleted clients
  - If CE is enabled, marks the retained client's destination client as dirty
- **Hmis::ClientMergeAudit:** `drivers/hmis/app/models/hmis/client_merge_audit.rb`
  - Stores audit information for each merge operation, including:
    - `pre_merge_state`: JSON storing attributes of clients before merge
    - `pre_merge_mappings`: JSON storing original foreign key values for updated records
- **Hmis::ClientMergeHistory:** `drivers/hmis/app/models/hmis/client_merge_history.rb`
  - Links merge audits to the affected clients
  - Each merge creates one `ClientMergeAudit`, and one or more `ClientMergeHistory` (one per deleted client).
  - **Chain Handling**: When a previously-retained client is later merged into another client, all related `ClientMergeHistory` records are updated to point to the new retained client, preserving the complete merge chain.

### Related Records involved

The following table lists all record types that are updated during a merge, along with their foreign key field:

| Record Type | Foreign Key Field | Notes |
|------------|-------------------|-------|
| **Enrollments** | `PersonalID` | Not deduplicated - see warning below |
| **Names** (CustomClientName) | `PersonalID` | Deduplicated |
| **Addresses** (CustomClientAddress) | `PersonalID` | Deduplicated |
| **Contact Points** (CustomClientContactPoint) | `PersonalID` | Deduplicated |
| **Custom Data Elements** | `owner_id` | Non-repeating CDEDs are deduplicated |
| **Files** | `client_id` | |
| **Scan Card Codes** | `client_id` | Includes soft-deleted cards |
| **Client Locations** | `client_id` | |
| **MCI IDs** (External IDs) | `source_id` | Deduplicated by value |
| **MCI Unique IDs** (External IDs) | `source_id` | Max 1 per client, extras destroyed |
| **Referral Household Members** | `client_id` | Legacy - deduplicated |
| **Disabilities** | `PersonalID` |  |
| **Employment Education** | `PersonalID` | |
| **Events** | `PersonalID` | |
| **Health and DV** | `PersonalID` | |
| **Income Benefits** | `PersonalID` | |
| **Services** | `PersonalID` | |
| **Current Living Situations** | `PersonalID` | |
| **Youth Education Status** | `PersonalID` | |
| **Exits** | `PersonalID` | |
| **Assessments** | `PersonalID` | |
| **Assessment Questions** | `PersonalID` | |
| **Assessment Results** | `PersonalID` | |
| **Custom Assessments** | `PersonalID` | |
| **Custom Case Notes** | `PersonalID` | |
| **Custom Services** | `PersonalID` | |

### Deduplication

Some record types are **deduplicated** during the merge process to avoid having multiple identical records on the retained client:

- **Names**: Duplicate names are identified and removed. The retained client's name becomes the primary name.
- **Addresses**: Addresses with matching attributes (address_type, line1, line2, city, state, etc.) are deduplicated.
- **Contact Points**: Contact points with matching system, use, and value are deduplicated. Email comparisons are case-insensitive.
- **Custom Data Elements**: Only **non-repeating** custom data elements are deduplicated. The newest value (by `DateUpdated`) is kept.
- **MCI IDs**: External IDs with duplicate values are deduplicated.

**Note:** Enrollments and other related records are **not** deduplicated. 
All enrollments from merged clients are preserved on the retained client,
because the merge job doesn't have a straightforward way to determine which one to keep.
If both merged clients have enrollments in the same project that overlap,
post-merge this would be bad data that needs to be cleaned up manually by the user.

### Warehouse Clients and Client Merges

The interaction between HMIS client merges and warehouse clients works as follows:

1. When clients are merged in HMIS, the `WarehouseClient` linking records for the **source clients that are being deleted** are destroyed immediately as part of the merge.
2. The destruction of `WarehouseClient` records may leave some warehouse destination clients without any remaining source clients
3. Later, when the `IdentifyDuplicates` job runs, it identifies and cleans up "orphaned" warehouse clients that no longer have any source clients

However, note that **warehouse clients are not necessarily deleted** because:
- A warehouse destination client may have multiple source clients
- Even if one HMIS source client is merged away, the warehouse client remains active if it still has other source clients pointing to it
- Only warehouse clients with no remaining source clients are cleaned up
