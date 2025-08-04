# Implementation Tasks: Custom File Export

## Phase 1: Foundation & Testing Infrastructure

### 1.1 Controller Parameter Handling
- [ ] **Add custom_file_types parameter to HmisExportsController**
  - Location: `app/controllers/warehouse_reports/hmis_exports_controller.rb:156-161`
  - Add `custom_file_types: []` to `report_params` method
  - Update parameter cleaning logic in `export_source.clean_params`

- [ ] **Write controller request tests**
  - Location: `spec/requests/warehouse_reports/hmis_exports_controller_spec.rb` (create if missing)
  - Test custom file parameter acceptance
  - Test parameter validation
  - Test version-specific behavior (only FY2026)
  - Test job scheduling with custom file parameters

### 1.2 Filter Model Updates
- [ ] **Add custom_file_types attribute to Filters::HmisExport**
  - Location: `app/models/filters/hmis_export.rb`
  - Add `attribute :custom_file_types, Array, default: []`
  - Update `update` method to handle custom_file_types parameter
  - Update `for_params` method to include custom_file_types

- [ ] **Add custom file discovery methods**
  - Add `available_custom_file_types` method using `HmisCsvTwentyTwentySix::CustomFilesConfig.custom_file_types`
  - Add `valid_custom_file_types` method for validation
  - Add version checking (only available for FY2026)
  - Add graceful failure for non-FY2026 versions

- [ ] **Write filter model unit tests**
  - Location: `spec/models/filters/hmis_export_spec.rb` (create if missing)
  - Test parameter handling and validation
  - Test available custom file type discovery
  - Test version compatibility
  - Test integration with existing filter functionality

### 1.3 Custom File Manager Integration
- [ ] **Understand CustomFilesConfig and CustomFileManager**
  - Research `HmisCsvTwentyTwentySix::CustomFilesConfig.initialize`
  - Understand `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!`
  - Identify how custom file types are defined and managed

- [ ] **Create test data factories**
  - Location: `drivers/hmis_csv_twenty_twenty_six/spec/factories/`
  - Ensure custom file factories exist or create them
  - Create sample custom data for testing (CustomGender, etc.)
  - Verify factories work with existing test suite

## Phase 2: User Interface

### 2.1 View Updates
- [ ] **Update shared filter template**
  - Location: `app/views/warehouse_reports/hmis_exports/_shared_filter.haml`
  - Add custom files section after "Export Configuration" (around line 63)
  - Show only when version is FY2026
  - Use select2 multi-select for file type selection (using `app/inputs/select_two_input.rb`)

- [ ] **Update parameters template for history display**
  - Location: `app/views/warehouse_reports/hmis_exports/_parameters.haml`
  - Show chosen custom files in history for previous exports
  - Display custom file selections clearly

- [ ] **Add JavaScript for progressive disclosure**
  - Show/hide custom files section based on version selection
  - Dynamic loading of available custom file types if needed
  - Form validation on client side

- [ ] **Update CSS/styling**
  - Ensure custom files section matches existing design
  - Add appropriate spacing and visual groupings
  - Responsive design considerations

### 2.2 View Integration Tests
- [ ] **Test UI behavior**
  - Custom files section visibility based on version
  - Proper form submission with custom file selections
  - JavaScript functionality works correctly
  - Accessibility compliance

## Phase 3: Export Implementation

### 3.1 Exporter Base Classes
- [ ] **Create custom file base exporter**
  - Location: `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/custom/base.rb`
  - Define interface for custom file exporters under `HmisCsvTwentyTwentySix::Exporter::Custom` namespace
  - Handle common custom file export logic
  - Integrate with existing export pipeline
  - Use naming convention: `CustomGender.csv` (not `Custom_GenderData.csv`)

- [ ] **Update main export orchestration**
  - Location: `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/`
  - Identify where export file list is generated
  - Add custom files to export file list
  - Ensure custom files are included in ZIP generation
  - Integrate with CustomFileManager for dynamic model discovery

### 3.2 Dynamic Custom Exporters
- [ ] **Integrate with CustomFileManager.bootstrap_custom_models!**
  - Use static model generation for custom exporters
  - Models should be committed to the repository
  - Models should be updated with any changes when re-running `bootstrap_custom_models!`
  - Handle case where new custom file types are added

- [ ] **Implement CustomGender exporter**
  - Location: `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/custom/gender.rb`
  - Export custom gender data as CSV with filename `CustomGender.csv`
  - Use `HmisCsvTwentyTwentySix::Exporter::Custom::Gender` class structure
  - Apply date range and project filters efficiently
  - Avoid N+1 queries through proper includes/joins

- [ ] **Implement additional custom exporters as needed**
  - Based on available custom file types from CustomFilesConfig
  - Follow same pattern as CustomGender
  - Ensure consistent naming and formatting
  - Generate dynamically using CustomFileManager when possible

### 3.3 Export Job Integration
- [ ] **Update export job to handle custom files**
  - Location: Look for FY2026 export job class
  - Pass custom file types to export process
  - Ensure custom files are generated and included
  - Handle errors gracefully

### 3.4 File Generation Testing
- [ ] **Test custom file generation**
  - Verify CSV format and content
  - Test with various filter combinations
  - Validate file naming conventions
  - Check ZIP file contents include custom files

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
- [ ] All Phase 1 tests passing
- [ ] Controller parameter handling working
- [ ] Filter model validating custom files correctly
- [ ] CustomFileManager integration working

### Before Phase 3 (Export)
- [ ] UI shows custom file options correctly using select2 multi-select
- [ ] Form submission includes custom file selections
- [ ] Version compatibility working
- [ ] Parameters template shows custom file history correctly

### Before Phase 4 (Integration)
- [ ] Custom files generating correctly using `HmisCsvTwentyTwentySix::Exporter::Custom` namespace
- [ ] Export process includes custom files in ZIP
- [ ] Individual custom exporters working (e.g., CustomGender.csv, CustomSexualOrientation.csv)

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
