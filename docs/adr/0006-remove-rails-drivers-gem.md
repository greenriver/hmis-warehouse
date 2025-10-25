# ADR 0006: Replace rails_drivers Gem with Native Rails/Zeitwerk

## Status

- Current Status: Proposed
- Date of last update: 2025-10-25
- Decision-makers: OP Engineering team

## Context

The Open Path HMIS Warehouse uses the `rails_drivers` gem to organize related features into modular "driver" directories with their own MVC structure. This provides a way to extend models in the main application from driver code, allowing for feature modularity and organization.

### Current Challenges

1. **Archived Gem**: The rails_drivers gem has been archived upstream (https://github.com/komoju/rails_drivers) and is no longer actively maintained
2. **Maintenance Burden**: Maintaining an archived gem adds risk and technical debt, especially during Rails upgrades
3. **Limited Usage**: We only use two features from rails_drivers:
   - Mini MVC containers for organizing features in `drivers/` directories
   - Model extensions using `include RailsDrivers::Extensions`
4. **Magic Behavior**: The gem's automatic extension loading is not explicit, making it harder to understand which drivers extend which models
5. **Modern Rails**: Rails has evolved since rails_drivers was created; Zeitwerk (Rails 6+) provides better autoloading mechanisms

### Considerations

In identifying a solution, we would like to:
1. **Remove Technical Debt**: Eliminate dependency on archived gem
2. **Maintain Feature Organization**: Keep the driver-based organization that works well for our codebase
3. **Improve Explicitness**: Make model extensions more discoverable and explicit
4. **Support Future Growth**: Enable easier addition of new drivers and extensions
5. **Minimize Breaking Changes**: Keep existing structure and patterns as much as possible
6. **Rails Native**: Use standard Rails patterns that are well-documented and supported

### Current Scale

- 88 driver directories under `drivers/`
- 176 extension files extending models
- ~50 models that include extensions across main app and drivers
- Extensions target 44 unique model classes

### Constraints

- Roughly maintain existing driver organization structure
- Preserve the ability to extend core classes
- Must work with Rails 7.2+ and Zeitwerk autoloading
- Must not impact application performance
- Should minimize code churn during migration

## Decision

Replace the rails_drivers gem with native Rails/Zeitwerk functionality using three approaches:

### 1. Custom Zeitwerk Configuration for Autoloading

Configure Zeitwerk to autoload driver code by adding driver paths to autoload configuration in `config/application.rb`:
This replaces rails_drivers' automatic driver discovery with explicit Zeitwerk configuration.

### 2. Explicit Concern Inclusion in Models

Replace the magic `include RailsDrivers::Extensions` with explicit concern inclusion:
Extensions are already using `ActiveSupport::Concern`, so no changes needed to extension implementation.

### 3. Manual Route Loading

Load driver routes explicitly in main `config/routes.rb`.

## Consequences

### Benefits

1. **Removes Technical Debt**: Eliminates dependency on archived gem, reducing maintenance burden and upgrade risks
2. **Explicit Extension Loading**: Makes it immediately clear which drivers extend which models by reading the model file
3. **Rails Native**: Uses standard Rails patterns that are well-documented, tested, and supported
4. **Future Rails Upgrades**: Reduces risk during Rails version upgrades since we're using core functionality
5. **Discoverable**: Developers can easily find which extensions apply to a model without searching
6. **No Performance Impact**: Zeitwerk autoloading is as efficient or more efficient than rails_drivers
7. **Maintainable Long-term**: Solution based on standard Rails idioms that won't become obsolete

### Challenges

1. **Migration Effort**: Requires updating ~50 model files with explicit includes
2. **More Verbose**: Each model needs explicit includes instead of single magical line
3. **Manual Route Loading**: Routes must be explicitly loaded instead of automatic discovery
4. **Risk of Missing Extensions**: During migration, could accidentally omit an extension

### Neutral

1. **Similar Structure**: Driver organization remains largely unchanged, but is still non-standard
2. **Extension Implementation**: Extensions continue using `ActiveSupport::Concern` pattern
3. **Directory Layout**: `drivers/` or similar can be used
4. **Feature Organization**: Same logical grouping of related functionality

## Alternatives Considered

### 1. Keep rails_drivers Gem

**Approach**: Continue using the archived rails_drivers gem

**Pros**:
- No migration effort required
- Existing code works fine
- Team familiar with current approach

**Cons**:
- **Technical Debt**: Archived gem with no upstream maintenance
- **Rails Upgrade Risk**: May break during future Rails upgrades with no upstream fix available
- **Limited Support**: No community support or bug fixes
- **Magic Behavior**: Implicit extension loading makes code harder to understand
- **Fork Maintenance**: Would need to fork and maintain ourselves if issues arise

**Rejected**: Technical debt and maintenance risk outweigh short-term convenience

### 2. Convert to Rails Engines

**Approach**: Convert each driver to a proper Rails Engine

**Pros**:
- True Rails-native modularity
- Better isolation between drivers
- Can extract to separate gems later
- Well-documented Rails pattern

**Cons**:
- **Massive Refactoring**: Much larger change than necessary
- **Overkill**: Engines provide features we don't need (separate namespace, gemification)
- **Complexity**: Adds significant complexity for minimal benefit
- **Migration Time**: Would take significantly longer (months vs weeks)
- **Testing Overhead**: Each engine needs independent testing setup

**Rejected**: Too much change for the problem we're solving; could revisit in future if drivers need true isolation

### 3. Monkeypatch Approach

**Approach**: Use Ruby's module prepend/include to extend models without concern pattern

**Pros**:
- Could be more flexible than concerns
- No explicit includes needed in models

**Cons**:
- **Anti-pattern**: Monkeypatching is discouraged in modern Rails
- **Hard to Debug**: Modified behavior not visible in model file
- **Load Order Issues**: Requires careful management of load order
- **Not Maintainable**: Future developers would struggle to understand
- **IDE Unfriendly**: Tools can't detect monkeypatched methods

**Rejected**: Modern Rails encourages explicit concerns over monkeypatching

## Additional Info

### Related Documents

- [Rails Drivers Migration Plan](..implementatino-working-documents/rails_drivers_migration_plan.md) - Detailed implementation plan
- [Zeitwerk Autoloading Guide](https://guides.rubyonrails.org/autoloading_and_reloading_constants.html)
- [ActiveSupport::Concern Documentation](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html)
