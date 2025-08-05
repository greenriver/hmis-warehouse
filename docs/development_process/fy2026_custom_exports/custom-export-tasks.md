# Implementation Tasks: Custom File Export

## Phase 1: Foundation & Testing Infrastructure

### 1.1 Controller Parameter Handling
- [x] **Add custom_file_types parameter to HmisExportsController**
  - Location: `app/controllers/warehouse_reports/hmis_exports_controller.rb:156-161`
  - Add `custom_file_types: []` to `report_params` method
  - Update parameter cleaning logic in `export_source.clean_params`

- [x] **Write controller request tests**
  - Location: `spec/requests/warehouse_reports/hmis_exports_controller_spec.rb` (create if missing)
  - Test custom file parameter acceptance
  - Test parameter validation
  - Test version-specific behavior (only FY2026)
  - Test job scheduling with custom file parameters

### 1.2 Filter Model Updates
- [x] **Add custom_file_types attribute to Filters::HmisExport**
  - Location: `app/models/filters/hmis_export.rb`
  - Add `attribute :custom_file_types, Array, default: []`
  - Update `update` method to handle custom_file_types parameter
  - Update `for_params` method to include custom_file_types

- [x] **Add custom file discovery methods**
  - Add `available_custom_file_types` method using `HmisCsvTwentyTwentySix::CustomFilesConfig.definitions.map(&:filename)`
  - Add `valid_custom_file_types` method for validation
  - Add version checking (only available for FY2026)
  - Add graceful failure for non-FY2026 versions

- [x] **Write filter model unit tests**
  - Location: `spec/models/filters/hmis_export_spec.rb` (create if missing)
  - Test parameter handling and validation
  - Test available custom file type discovery
  - Test version compatibility
  - Test integration with existing filter functionality

### 1.3 Custom File Manager Integration
- [x] **Understand CustomFilesConfig and CustomFileManager**
  - Research `HmisCsvTwentyTwentySix::CustomFilesConfig.initialize`
  - Understand `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!`
  - Identify how custom file types are defined and managed
  - **Found**: YAML files in `drivers/hmis_csv_twenty_twenty_six/config/custom/`
  - **Available files**: CustomGender.csv, CustomSexualOrientation.csv, etc.

- [x] **Create test data factories**
  - Location: `drivers/hmis_csv_twenty_twenty_six/spec/factories/`
  - Ensure custom file factories exist or create them
  - Create sample custom data for testing (CustomGender, etc.)
  - Verify factories work with existing test suite
  - **Note**: Using existing CustomFilesConfig for test validation

## Phase 2: User Interface

### 2.1 View Updates
- [x] **Update shared filter template**
  - Location: `app/views/warehouse_reports/hmis_exports/_shared_filter.haml`
  - Add custom files section after "Export Configuration" 
  - Show only when version is FY2026
  - Use select2 multi-select for file type selection with proper CSS classes

- [x] **Update parameters template for history display**
  - Location: `app/views/warehouse_reports/hmis_exports/_parameters.haml`
  - Show chosen custom files in history for previous exports
  - Display custom file selections clearly

- [x] **Add JavaScript for progressive disclosure**
  - Created `app/javascript/controllers/custom_files_controller.js`
  - Show/hide custom files section based on version selection
  - Stimulus controller following project patterns

- [x] **Update CSS/styling**
  - Custom files section matches existing design
  - Proper HAML syntax with dot notation for classes
  - Single-line input elements following project conventions

### 2.2 View Integration Tests
- [x] **Test UI behavior**
  - Custom files section visibility based on version working
  - Form submission with custom file selections working
  - JavaScript functionality tested and working
  - Follows existing accessibility patterns

## Phase 3: Export Implementation

### 3.1 Exporter Base Classes
- [x] **Create custom file base exporter**
  - Location: `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/custom/base.rb`
  - Define interface for custom file exporters under `HmisCsvTwentyTwentySix::Exporter::Custom` namespace
  - Handle common custom file export logic
  - Integrate with existing export pipeline
  - Use naming convention: `CustomGender.csv` (not `Custom_GenderData.csv`)

- [x] **Update main export orchestration**
  - Location: `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/base.rb`
  - Updated `exportable_files` to include custom files dynamically
  - Added `custom_file_mappings` method for dynamic model discovery
  - Custom files included in ZIP generation
  - Integrated with CustomFileManager for dynamic model discovery

### 3.2 Dynamic Custom Exporters
- [x] **Integrate with CustomFileManager.bootstrap_custom_models!**
  - Extended CustomFileManager to generate exporter model files
  - Models generated dynamically and can be committed to repository
  - Re-running `bootstrap_custom_models!` updates all models
  - Handles new custom file types automatically

- [x] **Implement CustomGender exporter**
  - Location: `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/custom/custom_gender.rb`
  - Export custom gender data as CSV with filename `CustomGender.csv`
  - Uses `HmisCsvTwentyTwentySix::Exporter::Custom::CustomGender` class structure
  - Delegates to Client exporter for proper scope and filtering
  - Avoids N+1 queries by leveraging existing optimized scopes

- [x] **Implement additional custom exporters as needed**
  - CustomSexualOrientation exporter implemented
  - Based on available custom file types from CustomFilesConfig
  - Follow same pattern as CustomGender with delegation
  - Generate dynamically using CustomFileManager bootstrap

### 3.3 Export Job Integration
- [x] **Update export job to handle custom files**
  - Location: `app/jobs/export_base_job.rb`
  - Pass custom file types to export process via `custom_file_types: options[:custom_file_types] || []`
  - Custom files generated and included in export
  - Error handling implemented with graceful failure

### 3.4 File Generation Testing
- [x] **Test custom file generation**
  - CSV format and content verified through delegation to standard exporters
  - Tested with various filter combinations through existing export scopes
  - File naming conventions validated (`CustomGender.csv`, `CustomSexualOrientation.csv`)
  - ZIP file contents include custom files via `exportable_files` integration

## Phase 4: Integration & Quality Assurance

### 4.1 End-to-End Testing
- [ ] **Integration test suite**
  - Full export process with custom files
  - Multiple custom file type combinations
  - Various filter scenarios
  - Error handling and edge cases

- [ ] **Performance testing**
  - Large dataset (100,000+ row) exports with custom files
  - Memory usage monitoring
  - Export time measurement and comparison
  - Concurrent export handling

### 4.2 Data Validation
- [ ] **Verify export data accuracy**
  - Compare custom file contents to database
  - Validate date range filtering works correctly
  - Check project/organization filtering
  - Verify data relationships are maintained
  - Ensure N+1 queries are avoided in custom exports

- [ ] **Format validation**
  - CSV structure follows HUD conventions
  - File naming matches specification (e.g., `CustomGender.csv`, `CustomSexualOrientation.csv`)
  - ZIP archive structure is correct
  - Export metadata includes custom files

### 4.3 Error Handling & Edge Cases
- [ ] **Handle missing custom data**
  - Empty custom files when no data exists
  - Graceful handling of incomplete custom definitions
  - User feedback for data availability issues

- [ ] **Version compatibility testing**
  - Ensure FY2026 version shows custom options
  - Verify older versions don't show custom options and fail gracefully if requested
  - Test version switching behavior
  - Handle case where CustomFileManager.bootstrap_custom_models! hasn't been run

- [ ] **Permission and security testing**
  - Verify access control for custom data matches access to associated records
  - Test with various user permission setups

## Phase 5: Documentation & Deployment

### 5.1 Code Documentation
- [ ] **Update inline documentation**
  - Add comments to new methods and classes
  - Document custom file export process
  - Update README files if needed

- [ ] **API documentation updates**
  - Document new parameters and options
  - Update export format specifications
  - Provide usage examples
  - Document `HmisCsvTwentyTwentySix::Exporter::Custom` namespace

### 5.2 User Documentation
- [ ] **Help text and tooltips**
  - Add explanatory text for custom file options
  - Provide examples of when to use custom files
  - Link to detailed documentation

- [ ] **User guide updates**
  - Update export documentation
  - Add screenshots of new interface
  - Provide troubleshooting information

- [ ] **Developer documentation updates**
  - Update `drivers/hmis_csv_twenty_twenty_six/README.md` with overview of feature
  - Confirm `drivers/hmis_csv_twenty_twenty_six/README.md` contains general HMIS CSV Export documentation
  - Document CustomFileManager bootstrap process

### 5.3 Deployment Preparation
- [ ] **Feature flag implementation**
  - Use AppConfigProperty to indicate if the feature should be enabled
  - Add AppConfigProperty and set to true for non-production environments
  - Test rollback scenarios
  - Prepare monitoring and alerts

- [ ] **CustomFileManager bootstrap**
  - Ensure `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!` is run
  - Document when this needs to be re-run (when new custom file types are added)
  - Add to deployment checklist

## Quality Gates

### Before Phase 2 (UI)
- [x] All Phase 1 tests passing
- [x] Controller parameter handling working
- [x] Filter model validating custom files correctly
- [x] CustomFileManager integration working

### Before Phase 3 (Export)
- [x] UI shows custom file options correctly using select2 multi-select
- [x] Form submission includes custom file selections
- [x] Version compatibility working
- [x] Parameters template shows custom file history correctly

### Before Phase 4 (Integration)
- [x] Custom files generating correctly using `HmisCsvTwentyTwentySix::Exporter::Custom` namespace
- [x] Export process includes custom files in ZIP
- [x] Individual custom exporters working (e.g., CustomGender.csv, CustomSexualOrientation.csv)

### Before Phase 5 (Documentation)
- [ ] All integration tests passing
- [ ] Performance benchmarks acceptable
- [ ] Error handling robust

### Before Production Deploy
- [ ] Full test suite passing
- [ ] Documentation complete including driver README updates
- [ ] Rollback plan tested
- [ ] Monitoring in place
- [ ] AppConfigProperty feature flag configured

## Dependencies & Blockers

### External Dependencies
- Access to `HmisCsvTwentyTwentySix::CustomFilesConfig.initialize` definitions
- Understanding of `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!`
- Understanding of custom file import format from PR #5559
- HUD HMIS CSV specification for custom files

### Internal Dependencies
- FY2026 exporter infrastructure must be stable
- Existing export UI patterns and styling
- Job queue system for export processing

### Potential Blockers
- CustomFilesConfig may not be properly initialized
- CustomFileManager.bootstrap_custom_models! may need to be run before development
- HUD specification for custom files may be unclear
- Performance impact on large exports may be significant (N+1 queries)

## Risk Mitigation

### Technical Risks
- **Backup plan**: AppConfigProperty feature flag allows disabling if issues arise
- **Testing**: Comprehensive test suite catches regressions
- **Performance**: Monitoring and benchmarking prevent surprises
- **Model generation**: CustomFileManager bootstrap must be run before feature works

### User Experience Risks
- **UI complexity**: Progressive disclosure keeps interface simple
- **Data availability**: Clear messaging when custom files not available
- **Error handling**: Graceful degradation with informative messages

## Success Criteria

- [ ] All existing export functionality continues working unchanged
- [ ] Custom file exports generate correct CSV files
- [ ] UI is intuitive and follows existing patterns
- [ ] Performance impact is minimal (<10% increase in export time)
- [ ] Test coverage remains high (>90% for new code)
- [ ] Zero critical bugs in first month of production use
