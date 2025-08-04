# Technical Specification: Custom File Export

## Architecture Overview

The custom file export functionality will extend the existing HMIS CSV export infrastructure to include optional custom data files. The implementation follows the established patterns in the codebase while maintaining clear separation between standard and custom export logic.

Custom file definitions will be managed through `HmisCsvTwentyTwentySix::CustomFilesConfig.initialize` and models will be dynamically generated using `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!`.

### Key Components

1. **Controller Layer**: `WarehouseReports::HmisExportsController`
   - Accept custom file type parameters
   - Validate user selections
   - Pass parameters to filter layer

2. **Filter Layer**: `Filters::HmisExport`
   - Store custom file selections
   - Validate custom file availability
   - Pass configuration to export jobs

3. **Export Layer**: `HmisCsvTwentyTwentySix::Exporter`
   - Generate custom CSV files
   - Include custom files in ZIP archive
   - Follow HUD naming conventions

4. **View Layer**: `_shared_filter.haml` and `app/views/warehouse_reports/hmis_exports/_parameters.haml`
   - Display available custom file types
   - Provide selection interface
   - Show only for FY2026 version
   - Show chosen custom files in history for previous exports

## Database Schema

### Custom File Configuration
Custom files are defined through `HmisCsvTwentyTwentySix::CustomFilesConfig.initialize` and models are generated dynamically using `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!`.

### Data Discovery
```ruby
# Method to find available custom file types
def available_custom_file_types
  return [] unless version == '2026'

  # Get available custom files from configuration
  HmisCsvTwentyTwentySix::CustomFilesConfig.custom_file_types
end
```

## API Changes

### Controller Parameters

Add to `HmisExportsController#report_params`:
```ruby
def report_params
  export_source.clean_params(
    params.require(:filter).permit(
      # ... existing parameters ...
      custom_file_types: [],
    ),
  )
end
```

### Filter Model Updates

Add to `Filters::HmisExport`:
```ruby
attribute :custom_file_types, Array, default: []

def update(filters)
  # ... existing code ...
  self.custom_file_types = filters.dig(:custom_file_types) || []
  # ... existing code ...
end

def available_custom_file_types
  return [] unless version == '2026'

  # Get available custom files from configuration
  HmisCsvTwentyTwentySix::CustomFilesConfig.custom_file_types
end

def def for_params
  # ... existing code ...
  custom_file_types: custom_file_types,
  # ... existing code ...
end

def valid_custom_file_types
  custom_file_types & available_custom_file_types
end
```

## File Format Specifications

### Naming Convention
Custom files will follow HUD naming patterns:
- `CustomGender.csv` - Custom gender data
- `CustomSexualOrientation.csv` - Custom SexualOrientation data
- `CustomService.csv` - Custom service data
- etc.

### File Structure
Each custom CSV file will include:
1. Standard HUD CSV headers (ExportID, PersonalID, etc.)
2. Custom data element columns
3. Data rows matching the export date range and project filters

### Export Integration
Custom files will be:
- Generated alongside standard HMIS files
- Included in the same ZIP archive
- Listed in the export manifest/summary

## Implementation Strategy

### Phase 1: Foundation (Tests & Parameters)
1. Add controller tests for custom file parameters
2. Add filter model tests for custom file handling
3. Update controller to accept custom file parameters
4. Update filter model to store and validate selections
5. Integrate with `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!`

### Phase 2: UI Integration
1. Update `_shared_filter.haml` to show custom file options
2. Add version detection (only show for FY2026)
3. Implement selection interface (select2 multi-select using `app/inputs/select_two_input.rb`)
4. Add JavaScript for progressive disclosure if needed

### Phase 3: Export Implementation
1. Create base custom file exporter class
2. Dynamically generate custom file exporters using CustomFileManager
3. Integrate custom files into main export process
4. Update ZIP generation to include custom files
5. Ensure efficient querying to avoid N+1 problems

### Phase 4: Testing & Validation
1. Integration tests for end-to-end export
2. Performance testing with large datasets
3. File format validation
4. Error handling and edge cases

## Exporter Architecture

### Base Custom Exporter
```ruby
module HmisCsvTwentyTwentySix::Exporter::Custom
  class Base < HmisCsvTwentyTwentySix::Exporter::Base
    def self.custom_file_type
      raise NotImplementedError
    end

    def self.csv_file_name
      "#{custom_file_type}.csv"
    end

    def self.should_export?(export:, **)
      export.filter.custom_file_types.include?(custom_file_type)
    end
  end
end
```

### Dynamic Custom Exporters
Custom exporters will be generated dynamically using `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!`:

```ruby
module HmisCsvTwentyTwentySix::Exporter::Custom
  class Gender < Base
    def self.custom_file_type
      'CustomGender'
    end

    def self.export_scope(export:, **_)
      # Query custom gender data efficiently
      # Apply date range and project filters
      # Return formatted records
    end
  end
end
```

## Testing Strategy

### Unit Tests
- `Filters::HmisExport` model tests
  - Custom file type validation
  - Parameter handling
  - Available file type discovery

### Controller Tests
- `HmisExportsController` request tests
  - Parameter acceptance
  - Validation handling
  - Job scheduling with custom files

### Integration Tests
- End-to-end export tests
  - Export generation with custom files
  - ZIP file contents validation
  - File format verification

### Performance Tests
- Large dataset export with custom files
- Memory usage monitoring
- Export time comparison

## Error Handling

### Validation Errors
- Invalid custom file type selections
- Version compatibility issues
- Permission/access control

### Runtime Errors
- Missing custom data
- Export generation failures
- File system issues

### User Feedback
- Clear error messages
- Graceful degradation
- Progress indicators

## Security Considerations

### Access Control
- Verify user permissions for custom data
- Respect existing project/organization restrictions
- Maintain confidentiality settings

### Data Protection
- Same encryption/hashing as standard exports
- No additional PII exposure
- Audit logging for custom file exports

## Performance Considerations

### Query Optimization
- Efficient custom data retrieval avoiding N+1 queries
- Proper indexing on custom tables
- Batch processing for large datasets
- Use includes/joins for related data

### Memory Management
- Stream large custom files
- Avoid loading all custom data into memory
- Garbage collection considerations

### Caching Strategy
- Cache available custom file types
- Reuse query results where possible
- Clear caches appropriately

## Configuration

### Feature Flags
- Use AppConfigProperty to indicate if the feature should be enabled
- Add AppConfigProperty and set to true for non production environments

### Environment Variables
- No new environment variables required
- Leverage existing export configuration

## Migration Strategy

### Rollout Plan
1. Run `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!` to generate custom models
2. Deploy with feature flag disabled
3. Enable for testing/staging environments
4. Gradual rollout to production users
5. Monitor performance and error rates

### Rollback Plan
- Feature flag for immediate disable
- Database rollback not required (additive changes)
- UI changes are non-breaking

## Documentation Updates

### User Documentation
- Help text for custom file selection
- Export format documentation
- Troubleshooting guide

### Developer Documentation
- API documentation updates
- Code examples for custom exporters
- Testing guidelines
- Update `drivers/hmis_csv_twenty_twenty_six/README.md` with over view of feature
- Confirm `drivers/hmis_csv_twenty_twenty_six/README.md` contains general HMIS CSV Export documentation
