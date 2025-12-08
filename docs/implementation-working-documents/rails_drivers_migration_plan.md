# Rails Drivers Migration Plan

## Executive Summary

This document outlines a plan to remove the `rails_drivers` gem dependency and replace it with native Rails/Zeitwerk functionality. The gem is archived upstream and difficult to maintain, but we only use two key features that can be replicated with standard Rails approaches.

## Current State

### What We Use Rails Drivers For

1. **Mini MVC Containers**: Organizing related features in `drivers/` directory with their own MVC structure
2. **Model Extensions**: Extending main app models from driver code using `include RailsDrivers::Extensions`

### Current Structure

```
drivers/
  access_logs/
    app/
      models/
      controllers/
      views/
    config/
      routes.rb
      initializers/
    extensions/
      grda_warehouse/
        hud/
          client_extension.rb
    spec/
    lib/
    db/
```

### Scale
- 88 driver directories
- 176 extension files
- ~50 models that include extensions
- Extensions target 44 unique model classes

## Proposed Solution

### Overview

Replace rails_drivers with three native Rails approaches:

1. **Custom Zeitwerk configuration** for autoloading driver code
2. **Explicit concern inclusion** for model extensions
3. **Manual route loading** for driver routes

### Detailed Design

#### 1. Autoload Configuration

**File**: `config/application.rb`

Add after existing autoload configuration:

```ruby
# Load all driver components into autoload paths
Dir[Rails.root.join('drivers/*/app')].each do |driver_app|
  # Add the app directory
  config.autoload_paths << driver_app

  # Explicitly add concerns directory if it exists
  concerns_dir = File.join(driver_app, 'concerns')
  config.autoload_paths << concerns_dir if File.directory?(concerns_dir)
end

# Optionally: Add driver lib directories to eager load paths
Dir[Rails.root.join('drivers/*/lib')].each do |driver_lib|
  config.eager_load_paths << driver_lib if File.directory?(driver_lib)
end
```

**Alternative approach** (more explicit):

```ruby
# Define which drivers are enabled
ENABLED_DRIVERS = %w[
  access_logs
  client_access_control
  hmis
  # ... list all active drivers
].freeze

ENABLED_DRIVERS.each do |driver|
  driver_app = Rails.root.join('drivers', driver, 'app')
  config.autoload_paths << driver_app if driver_app.directory?
end
```

#### 2. Reorganize Extensions to Concerns

**Option A**: Keep current structure, just ensure proper namespacing

Extensions are already using `ActiveSupport::Concern`. Just ensure they're in the autoload path:

```
drivers/client_access_control/
  app/
    concerns/  # Move extensions here
      client_access_control/
        grda_warehouse/
          hud/
            client_extension.rb
```

**Option B**: Keep in extensions directory, add to autoload path explicitly

```ruby
Dir[Rails.root.join('drivers/*/extensions')].each do |ext_dir|
  config.autoload_paths << ext_dir if File.directory?(ext_dir)
end
```

#### 3. Explicit Concern Inclusion in Models

**Current**:
```ruby
# app/models/grda_warehouse/hud/client.rb
include RailsDrivers::Extensions  # Magically includes all extensions
```

**Proposed**:
```ruby
# app/models/grda_warehouse/hud/client.rb

# Include extensions at the end so they can override default behavior
include ClientAccessControl::GrdaWarehouse::Hud::ClientExtension
include CustomImportsBostonService::GrdaWarehouse::Hud::ClientExtension
# ... etc for each driver that extends this model
```

**Helper Pattern** (optional, to reduce boilerplate):

```ruby
# lib/driver_extensions.rb
module DriverExtensions
  def include_driver_extensions(model_path)
    # Auto-detect and include extensions for this model
    driver_pattern = Rails.root.join("drivers/*/app/concerns/**/#{model_path}_extension.rb")

    Dir[driver_pattern].each do |extension_file|
      # Parse the module name from file path
      relative_path = extension_file.sub(Rails.root.join('drivers').to_s + '/', '')
      parts = relative_path.split('/')
      driver_name = parts[0]

      # Convert to module constant name
      module_name = driver_name.camelize
      concern_path = parts[3..-1].join('/').sub('_extension.rb', '_extension').camelize
      full_constant = "#{module_name}::#{concern_path}"

      include full_constant.constantize
    end
  end
end

# In models:
class Client < Base
  extend DriverExtensions
  # ... model code ...
  include_driver_extensions('grda_warehouse/hud/client')
end
```

#### 4. Route Loading

**File**: `config/routes.rb`

Add near the top of the routes file:

```ruby
Rails.application.routes.draw do
  # Load all driver routes
  Dir[Rails.root.join('drivers/*/config/routes.rb')].sort.each do |routes_file|
    instance_eval(File.read(routes_file), routes_file)
  end

  # ... rest of main routes ...
end
```

**Note**: Driver route files should be written to work standalone:
```ruby
# drivers/access_logs/config/routes.rb
BostonHmis::Application.routes.draw do
  namespace :access_logs do
    # routes here
  end
end
```

#### 5. Feature Detection

**Current**:
```ruby
if RailsDrivers.loaded.include?(:access_logs)
  # do something
end
```

**Proposed**:
* Not needed, all files will be loaded and explicitly included as necessary.


## Implementation Plan

### Phase 1: Preparation (No Breaking Changes)
**Goal**: Set up parallel system without breaking existing functionality

1. **Add Zeitwerk configuration** (1 hour)
   - Add driver autoload paths to `config/application.rb`
   - Test that driver classes are still loadable
   - Run full test suite to ensure no regressions

2. **Audit extensions** (2-3 hours)
   - Generate list of all models that need explicit includes
   - Document which drivers extend which models
   - Create mapping: Model → List of extension concerns

3. **Create helper utilities** (1-2 hours)
   - Build `DriverExtensions` helper module (optional)
   - Create driver detection utilities
   - Write specs for new utilities

### Phase 2: Model Updates (Main Work)
**Goal**: Replace `include RailsDrivers::Extensions` with explicit includes

1. **Update models batch by batch** (8-12 hours)
   - Update 5-10 models at a time
   - For each model:
     ```ruby
     # Remove:
     include RailsDrivers::Extensions

     # Add explicit includes:
     include DriverName::Path::To::Extension
     ```
   - Run model-specific specs after each batch
   - Commit after each successful batch

2. **Models to update** (~50 files):
   - `app/models/user.rb`
   - `app/models/grda_warehouse/hud/client.rb`
   - `app/models/grda_warehouse/hud/enrollment.rb`
   - `app/models/grda_warehouse/hud/project.rb`
   - ... and ~46 others (see appendix for full list)

### Phase 3: Routes Migration
**Goal**: Consolidate route loading

1. **Update main routes file** (1 hour)
   - Add driver route loading code to `config/routes.rb`
   - Test all driver routes still work
   - Check for route conflicts

2. **Test routing** (1 hour)
   - Manual testing of driver routes
   - Check route helpers are available
   - Verify nested routes work correctly

### Phase 4: Feature Detection
**Goal**: Replace `RailsDrivers.loaded` checks

1. **Find all usages** (30 min)
   ```bash
   grep -r "RailsDrivers.loaded" --include="*.rb" .
   ```

2. **Remove checks** (1-2 hours)
   - Test each replacement

### Phase 5: Remove rails_drivers
**Goal**: Remove gem dependency

1. **Remove gem** (15 min)
   ```ruby
   # Gemfile - remove:
   gem 'rails_drivers', github: 'greenriver/rails_drivers', branch: 'rails-7'
   ```

2. **Bundle update** (5 min)
   ```bash
   bundle install
   ```

3. **Remove initializer references** (30 min)
   - Remove or update `RailsDrivers.loaded <<` lines in initializers
   - These can stay as-is or be removed (they become no-ops)

4. **Full test suite** (time varies)
   - Run complete test suite
   - Integration tests
   - Manual smoke testing of key features

### Phase 6: Cleanup and Documentation
**Goal**: Polish and document

1. **Update documentation** (1-2 hours)
   - Document new extension pattern
   - Update CLAUDE.md or developer docs
   - Create examples for new drivers

2. **Code cleanup** (1 hour)
   - Remove unused initializer code
   - Clean up any TODOs introduced
   - Ensure consistent patterns across drivers

## Risk Assessment

### High Risk
❌ None identified - changes are incremental and testable

### Medium Risk
⚠️ **Missing extensions after migration**
- **Mitigation**: Comprehensive testing, batch updates with tests between
- **Detection**: Extensions use `replace_scope` which will fail loudly if not loaded

⚠️ **Route loading order conflicts**
- **Mitigation**: Use sorted loading, test thoroughly
- **Detection**: Route specs will fail, manual testing

⚠️ **Zeitwerk autoloading issues in production**
- **Mitigation**: Test in staging with eager loading enabled
- **Detection**: Boot-time errors in production-like environment

### Low Risk
✓ **Feature detection changes**
- Simple find/replace with clear pattern
- Easy to verify

✓ **Driver isolation**
- Each driver is mostly independent
- Can be updated individually

## Testing Strategy

### Unit Tests
- Test each modified model individually
- Verify extension methods are available
- Check `replace_scope` overrides work

### Integration Tests
- Run driver-specific test suites
- Test cross-driver interactions
- Verify feature flags work

### Manual Testing Checklist
- [ ] Load a page from each major driver
- [ ] Test client search (uses extensions heavily)
- [ ] Check model scopes work correctly
- [ ] Verify report generation
- [ ] Test HMIS import functionality
- [ ] Check route helpers in views

### Staging Deployment
- Deploy to staging after Phase 5
- Run for 1-2 days with monitoring
- Check for autoloading errors in logs
- Performance testing (autoloading impact)

## Rollback Plan

### If Issues Found in Phase 1-4
- Simple git revert of changes
- `bundle install` to restore rails_drivers
- No data loss risk

### If Issues Found in Phase 5-6
- Revert commits
- Add rails_drivers back to Gemfile
- `bundle install`
- Redeploy

### Emergency Rollback in Production
1. Revert to previous release
2. No database changes involved
3. Should be standard rollback procedure

## Timeline Estimate

| Phase | Time Estimate | Can Parallelize? |
|-------|---------------|------------------|
| Phase 1: Preparation | 4-6 hours | No |
| Phase 2: Model Updates | 8-12 hours | Partially (different models) |
| Phase 3: Routes | 2 hours | No |
| Phase 4: Feature Detection | 2-3 hours | Yes |
| Phase 5: Remove Gem | 1 hour | No |
| Phase 6: Cleanup | 2-3 hours | Yes |
| **Total** | **19-27 hours** | |
| Testing/Buffer | +8-10 hours | |
| **Grand Total** | **27-37 hours** | |

Recommended approach: **1-2 weeks** with thorough testing between phases.

## Success Criteria

✓ All existing tests pass
✓ No rails_drivers gem dependency
✓ All driver features work correctly
✓ Extensions properly loaded in all models
✓ Routes work for all drivers
✓ Staging deployment successful
✓ Production deployment successful
✓ No performance degradation

## Future Considerations

### Engine Pattern (Alternative Future Direction)

If drivers continue to grow, consider migrating to Rails Engines:
- Each driver becomes a proper Rails Engine
- Better isolation
- Can be extracted to gems later
- More Rails-native

This would be a larger refactor but provides better long-term maintainability.

### Component Architecture

Alternative: Move to a component-based architecture like ViewComponent + concerns
- Better encapsulation
- Easier testing
- More modern Rails approach

## Appendix A: Models Requiring Updates

Full list of ~50 models that need `include RailsDrivers::Extensions` replaced:

```
app/models/user.rb
app/models/grda_warehouse/hud/client.rb
app/models/grda_warehouse/hud/enrollment.rb
app/models/grda_warehouse/hud/project.rb
app/models/grda_warehouse/hud/organization.rb
app/models/grda_warehouse/hud/service.rb
app/models/grda_warehouse/hud/exit.rb
app/models/grda_warehouse/hud/assessment.rb
app/models/grda_warehouse/hud/disability.rb
app/models/grda_warehouse/hud/income_benefit.rb
app/models/grda_warehouse/hud/inventory.rb
app/models/grda_warehouse/hud/project_coc.rb
app/models/grda_warehouse/hud/enrollment_coc.rb
app/models/grda_warehouse/hud/event.rb
app/models/grda_warehouse/hud/employment_education.rb
app/models/grda_warehouse/hud/affiliation.rb
app/models/grda_warehouse/hud/assessment_question.rb
app/models/grda_warehouse/hud/assessment_result.rb
app/models/grda_warehouse/hud/ce_participation.rb
app/models/grda_warehouse/hud/current_living_situation.rb
app/models/grda_warehouse/hud/export.rb
app/models/grda_warehouse/hud/funder.rb
app/models/grda_warehouse/hud/health_and_dv.rb
app/models/grda_warehouse/hud/hmis_participation.rb
app/models/grda_warehouse/hud/site.rb
app/models/grda_warehouse/hud/user.rb
app/models/grda_warehouse/hud/youth_education_status.rb
app/models/grda_warehouse/hud/custom_data_element.rb
app/models/grda_warehouse/hud/custom_data_element_definition.rb
app/models/grda_warehouse/data_source.rb
app/models/grda_warehouse/service_history_enrollment.rb
app/models/grda_warehouse/import_log.rb
app/models/grda_warehouse/upload.rb
app/models/grda_warehouse/hmis_form.rb
app/models/grda_warehouse/hmis/assessment.rb
app/models/grda_warehouse/remote_credential.rb
app/models/grda_warehouse/health_emergency/vaccination.rb
app/models/health/patient.rb
app/models/health/vaccination.rb
app/models/hud_reports/universe_member.rb
app/models/hud_reports/report_instance.rb
app/models/reporting/housed.rb
app/models/simple_reports/universe_member.rb
drivers/hmis/app/models/hmis/hud/client.rb
drivers/hmis/app/models/hmis/hud/enrollment.rb
drivers/hmis/app/models/hmis/hud/project.rb
drivers/hmis/app/models/hmis/unit_type.rb
drivers/hmis/app/models/hmis/access_group.rb
drivers/client_location_history/app/models/client_location_history/location.rb
```

## Appendix B: Extension Mapping

Generate this during Phase 1 with:

```bash
# Script to map models to their extensions
for model in $(grep -l "include RailsDrivers::Extensions" app/models/**/*.rb drivers/*/app/models/**/*.rb); do
  echo "Model: $model"
  # Find matching extensions
  model_path=$(echo $model | sed 's|app/models/||' | sed 's|.rb||')
  find drivers/*/extensions -name "*${model_path##*/}_extension.rb" -o -name "*${model_path}_extension.rb" 2>/dev/null
  echo ""
done
```

## Questions for Team Discussion

1. **Timeline**: Is 1-2 weeks acceptable for this migration?
2. **Risk tolerance**: Comfortable with incremental approach?
3. **Helper pattern**: Use `DriverExtensions` helper or explicit includes?
4. **Directory structure**: Keep `drivers/` or rename to `components/`?
5. **Testing**: How much manual testing is required vs. automated?
6. **Staging duration**: How long should we soak in staging?
7. **Future direction**: Should we consider Engine pattern for long term?

## References

- Rails Zeitwerk documentation: https://guides.rubyonrails.org/autoloading_and_reloading_constants.html
- Rails Engines: https://guides.rubyonrails.org/engines.html
- ActiveSupport::Concern: https://api.rubyonrails.org/classes/ActiveSupport/Concern.html
