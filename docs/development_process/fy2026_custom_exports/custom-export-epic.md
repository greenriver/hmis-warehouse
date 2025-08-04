# Custom File Export Epic

## Problem Statement

The HMIS warehouse has recently implemented the ability to import custom files via PR #5559, using database-driven custom data element definitions. Now we need to provide the ability to optionally export any known custom files alongside the standard HMIS CSV export, allowing users to create complete exports that include both standard HUD files and organization-specific custom data.

## Goals

- Enable users to select custom file types for export alongside standard HMIS CSV files
- Maintain compatibility with existing export functionality
- Include a mechanism to choose custom files alongside the standard export for both immediate exports and recurring exports
- Follow HUD HMIS CSV specification for custom file formats
- Provide comprehensive test coverage for the new functionality
- Ensure only FY2026 version supports custom files (prior versions should not support export of custom files, but should fail gracefully if requested)

## User Stories

### As an HMIS administrator
- I want to select which custom file types to include in my export
- I want to see which custom files are available for export
- I want custom files to be included in the same ZIP as standard HMIS files
- I want the export process to remain familiar and intuitive

### As a developer
- I want comprehensive test coverage for custom export functionality
- I want the implementation to follow existing patterns in the codebase
- I want clear separation between standard and custom export logic

## Acceptance Criteria

### Functional Requirements
- [ ] Users can view available custom file types in the export interface
- [ ] Users can select/deselect which custom file types to include
- [ ] Custom files are exported as separate CSV files in the export ZIP
- [ ] Custom files follow HUD naming conventions (e.g., `CustomGender.csv`)
- [ ] Only FY2026 exports support custom file selection
- [ ] Prior HMIS CSV versions (2024, 2022) do not show custom file options
- [ ] Export works correctly with no custom files selected (existing behavior)
- [ ] Export works correctly with some or all custom files selected

### Technical Requirements
- [ ] Request tests validate custom file parameter handling
- [ ] Model tests verify export logic with custom files
- [ ] Integration tests confirm end-to-end export functionality
- [ ] Custom file selection persists in export history
- [ ] Custom file parameters are validated appropriately
- [ ] Custom file models should be generated using `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!`
- [ ] If new custom file types are defined, running `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!` should be sufficient to make them available to the exporter

### Quality Requirements
- [ ] No breaking changes to existing export functionality
- [ ] Performance impact is minimal for exports without custom files
- [ ] Custom files are exported efficiently avoiding N+1 queries
- [ ] Error handling provides clear feedback for invalid selections
- [ ] UI is intuitive and follows existing design patterns

## Success Metrics

- All existing export functionality continues to work unchanged
- Custom file exports complete successfully with correct file contents
- Test coverage remains high (>90% for new code)
- Export performance degrades by <10% when including custom files
- Zero critical bugs in production after 1 month

## Risks & Mitigation

### Risk: Breaking existing export functionality
**Mitigation:** Comprehensive regression testing, feature flags for rollback

### Risk: Performance impact on large exports
**Mitigation:** Performance testing, optional nature of custom files

### Risk: Custom file format compatibility issues
**Mitigation:** Follow HUD specifications, validate against known importers

### Risk: Complex UI for file selection
**Mitigation:** Progressive disclosure, user testing, clear documentation

## Out of Scope

- Import functionality for custom files (already implemented in PR #5559)
- Support for custom files in HMIS CSV versions prior to FY2026
- Custom file validation during export (assume data is valid)
- Real-time preview of custom file contents

## Dependencies

- Definitions of custom files are available in `HmisCsvTwentyTwentySix::CustomFilesConfig.initialize`
- FY2026 HMIS CSV exporter infrastructure
- Existing export UI and controller patterns
- Custom file import functionality from PR #5559

## Future Considerations

- Support for custom files in future HMIS CSV versions
- Advanced filtering of custom file contents
- Custom file export scheduling and automation
- Integration with external systems expecting custom files
