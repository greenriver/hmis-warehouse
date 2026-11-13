# HMIS Supplemental Data

HMIS Supplemental Data provides a mechanism to attach external data sets to HMIS Clients and Enrollments. This data is uploaded via CSV from S3 and displayed as configurable tabs on the client dashboard.

## Architecture

The feature is implemented as a driver in `drivers/hmis_supplemental`.

### Core Components

- **DataSet** (`HmisSupplemental::DataSet`): Defines the configuration for a supplemental data set, including its owner type (Client or Enrollment), field definitions (JSON config), and S3 credentials.
- **Field** (`HmisSupplemental::Field`): A virtual object representing a single column in the data set. It handles value casting and formatting for different data types (string, int, float, boolean, date).
- **FieldValue** (`HmisSupplemental::FieldValue`): Stores the actual data points for a specific client or enrollment. Values are linked via an `owner_key` (e.g., `client/<personal_id>` or `enrollment/<enrollment_id>`).
- **ImportJob** (`HmisSupplemental::ImportJob`): Core import process, see below

## Data Import

Data import is handled by `HmisSupplemental::ImportJob`.
- Downloads CSV from S3 using credentials stored in `HmisSupplemental::DataSet`.
- Matches rows to clients or enrollments using `personal_id` or `enrollment_id` columns.
- Supports multi-valued fields by joining rows with the same owner and field key.
- Imports data into the `hmis_supplemental_field_values` table in the warehouse database.

## Visibility and Permissions

To view a supplemental data set for a **Destination Client** (warehouse client), the following conditions must be met:

1.  **ACL User**: The user must be using the ACL-based permission system (Legacy role-based permissions are not supported for this feature).
2.  **DataSet Permission**: The user must have the `can_view_supplemental_client_data` permission on a collection containing the specific `HmisSupplemental::DataSet`. Allows administrators to control access to specific types of data independently.
3.  **DataSource Visibility**: The user must have the `can_view_supplemental_client_data` permission on the `GrdaWarehouse::DataSource` that owns the data set, or on any of its related child entities (such as Projects or Organizations).
4.  **Source Client Matching**: The **Source Client** data source must match the data source on the `DataSet`. A destination client might have source records from multiple data sources, each contributing different supplemental data.
5.  **Destination Client ROI**: The **Destination Client** must have an active Release of Information (ROI).

## Integration Points

- **Admin Dashboard**: `HmisSupplemental::DataSetsController` provides the interface for creating and managing data set configurations and S3 credentials.
- **Client Dashboard**: `HmisSupplemental::ClientDataSetsController` renders the data set tabs. The tabs are dynamically injected into the client navigation via `app/views/clients/_default_tab_navigation.haml`.
- **Collection Management**: `app/views/admin/collections/_supplemental_data_sets.haml` allows administrators to include specific data sets in collections.

## Testing and Validation

### Data Configuration and Permissions
1. **Create Data Set**: In "Data -> Data Sources", select a source and use the "Supplemental Data Sets" button to create a new configuration with JSON field definitions.
2. **Assign to Collections**:
    - Add the **DataSet** to a collection (e.g., "Supplemental: Vaccinations").
    - Ensure the **DataSource** associated with the data set is also in a collection (e.g., "Agency: City Hospital").
3. **Configure Access**: Create Access Controls linking both collections to the user's role.
4. **Enable Permission**: Ensure the role has the `can_view_supplemental_client_data` permission enabled for both access controls in "Warehouse Admin -> Access -> Roles & Permissions".
5. **Verify ROI**: Ensure the **Destination Client** has an active ROI matching the user's CoC codes.

### Data Import Verification
- **Direct Upload**: `HmisSupplemental::DataSetUploadsController` allows for manual CSV uploads to bypass S3 for testing. The "upload CSV" action is available in the supplemental data set list.
- **CSV Structure**:
  - Client-based: Must include `personal_id` matching a source client in the data source.
  - Enrollment-based: Must include `enrollment_id` matching a source enrollment.
- **Data Deduplication**:
  - Single-valued fields: The first encountered value for a given owner and field key is preserved.
  - Multi-valued fields: All values are collected and joined with a delimiter (`|`).

## Notes
- feature is also referred to as "Configurable Client Record Pages"
