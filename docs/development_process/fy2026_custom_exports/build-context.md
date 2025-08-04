# Build Context: Custom File Export Implementation

## Pre-Implementation Research Checklist

When starting implementation, verify these key assumptions:

### **1. CustomFileManager Architecture**
- [ ] Confirm `HmisCsvTwentyTwentySix::CustomFilesConfig.initialize` exists
- [ ] Verify `HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!` method
- [ ] Understand if models are truly "static" (committed to repo) vs dynamic
- [ ] Check what custom file types currently exist in the system

### **2. Existing FY2026 Export Structure**
- [ ] Examine current exporter patterns in `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/`
- [ ] Identify main export orchestration class/method
- [ ] Understand how existing exporters are registered and discovered
- [ ] Check how ZIP files are currently generated

### **3. Key File Locations to Examine**
```
app/controllers/warehouse_reports/hmis_exports_controller.rb:138-163    # Current report_params
app/models/filters/hmis_export.rb:50-79                                 # Current update method
app/views/warehouse_reports/hmis_exports/_shared_filter.haml:29-63      # Current UI
drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/export.rb  # Main export class
```

## Important Implementation Notes

### **Model Generation Strategy**
Based on tasks document clarification:
- Models should be **static** (committed to repository)
- Running `bootstrap_custom_models!` updates existing models
- This differs from purely dynamic generation approach

### **Performance Requirements**
- Export performance must not degrade by >10%
- Large dataset testing required (100,000+ rows)
- N+1 query prevention is critical

### **UI Integration Points**
- Use `app/inputs/select_two_input.rb` for multi-select
- Show only for FY2026 version
- Update both `_shared_filter.haml` and `_parameters.haml`

### **Testing Strategy Priority**
1. **Phase 1**: Controller and Filter tests (foundation)
2. **Phase 2**: UI behavior and form submission
3. **Phase 3**: Export generation and ZIP inclusion
4. **Phase 4**: Performance and integration testing

## Quick Start Commands

When resuming implementation:

```bash
# 1. Examine current FY2026 structure
find drivers/hmis_csv_twenty_twenty_six -name "*.rb" | head -10

# 2. Check for CustomFileManager
grep -r "CustomFileManager" drivers/hmis_csv_twenty_twenty_six/

# 3. Look at existing export job structure
grep -r "ExportJob" drivers/hmis_csv_twenty_twenty_six/

# 4. Check current test structure
ls drivers/hmis_csv_twenty_twenty_six/spec/
```

## Key Success Indicators

- [ ] All existing exports continue working unchanged
- [ ] Custom files appear in ZIP alongside standard files
- [ ] UI shows/hides custom options based on version
- [ ] Performance benchmarks meet <10% degradation
- [ ] Test coverage remains >90%

## Rollback Plan

- AppConfigProperty feature flag for immediate disable
- Static model files can remain (no database changes needed)
- UI changes are purely additive

## Open Questions to Resolve

1. **How are custom file types defined?** (through configuration or database?)
2. **What's the exact relationship between CustomFilesConfig and CustomFileManager?**
3. **Are there existing custom file types in the current system?**
4. **How does the current export job queue system work?**

These should be answered in Phase 1.3 (Custom File Manager Integration) before proceeding to UI work.