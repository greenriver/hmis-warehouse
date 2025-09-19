# ADR 0005: HUD Utility Version Management with HudHelper Factory Pattern

## Status

- Current Status: Proposed
- Date of last update: 2025-09-18
- Decision-makers: OP Engineering team

## Context

The Open Path HMIS Warehouse handles HUD (U.S. Department of Housing and Urban Development) data specifications that change annually or bi-annually. These specifications define data structures, validation rules, and enumerated values used throughout the system for reporting and compliance.

### Current Challenges

1. **Multiple HUD Utility Modules**: The codebase contains `HudUtility` (legacy/2022), `HudUtility2024`, and `HudUtility2026` modules which provide specific details for each fiscal year
2. **Widespread Code Churn**: Each year's specification change requires updating references throughout the codebase
3. **Maintenance Burden**: Managing the use of multiple utility classes and their usage patterns across the codebase means we need revisit each usage each year.  As the codebase grows, this leads to additional review requirements, extending the time it takes to upgrade each year
4. **Current Year Determination**: The determination of what constitutes a current year is currently spread across the application.  This makes it difficult during critical times to find and update ALL of the places the codebase needs to be version aware

### Considerations
In identifying a solution, we would like to:
1. **Decrease Maintenance Time**: The time it takes to upgrade each year should not grow significantly over time.  We know these changes are coming, we should prioritize making the switch as efficient as possible
2. **Decrease Code Churn**: While we need parts of the application pinned to a specific fiscal year, much of the application can operate in the "current" fiscal year.  As long as there aren't breaking changes, we shouldn't need to update all of the usage of the utility
3. **Long-running Job Consistency**: Jobs that span fiscal year transitions (October 1st) should consistently reference the same fiscal year information throughout
4. **Thread Safety**: There shouldn't be a way to accidentally switch between current fiscal years. This might occur due to time-based roll over (current HUD standard changes independent of a deployment).
5. **Utility Naming**: It should be easy to find all instances of the utility's use and the class loader should not confuse the utility with other classes or modules

### Constraints

- Must maintain backward compatibility with existing HUD specifications
- Must handle fiscal year transitions gracefully (October 1st cutoff dates)
- Must work correctly with long-running background jobs
- Must be thread-safe for concurrent operations
- Must minimize future code churn when new HUD specifications are released
- Must support explicit version specification when needed for specific use cases
- Must be named uniquely
- Must centralize, as much as possible, the logic for what constitutes the current version

## Decision

Implement a factory pattern using `HudHelper` as the primary interface for HUD utility access:

### Core Implementation

1. **Factory Method**: `HudHelper.util(version = nil)` serves as the primary access point
2. **Automatic Version Resolution**: When no version is specified, automatically determines the appropriate HUD specification based on environment and current date
3. **Explicit Version Override**: Supports explicit version specification: `HudHelper.util('2024').ethnicities`
4. **Thread-Safe Current Version**: Uses `HudHelper::Current` (ActiveSupport::CurrentAttributes) to maintain stable version context within request/job scope
5. **Centralized Version Logic**: All version determination logic consolidated in the factory method, referenced as necessary elsewhere

### Naming Decision

- **HudHelper**: Chosen as a unique, non-conflicting module name that doesn't collide with existing `Hud` modules and isn't a substring of other `HudUtilityXXXX` modules
- **Legacy Renaming**: `HudUtility` renamed to `HudUtilityLegacy` to clarify its scope (pre-2024 specifications)

## Consequences

### Benefits

1. **Reduced Code Churn**: Future HUD specification updates require minimal changes to calling code
2. **Thread Safety**: `ActiveSupport::CurrentAttributes` provides proper thread isolation
3. **Long-Running Job Stability**: Jobs maintain consistent version context throughout execution
4. **Clear Version Management**: Explicit factory pattern makes version usage transparent
5. **Flexible Override**: Supports both automatic and explicit version selection
6. **Maintainable**: Centralized version logic reduces maintenance burden. Supports future changes, such as replacing class methods with a singleton instance.
7. **Backward Compatible**: Existing utility modules remain available

### Challenges

1. **Additional Indirection**: Adds one level of method call indirection
2. **Name**: `HudHelper` isn't a great name
3. **Risk of Breaking Changes**: Because we are no longer required to review all usage of the utility each year, if a method is removed in a future utility, it could break code.  We can mitigate this by expanding test coverage, and careful review of yearly updates

### Neutral

1. **Method Call Changes**: `HudUtility2024.ethnicities` becomes `HudHelper.util.ethnicities`
2. **Explicit Calls**: `HudHelper.util('2024').ethnicities` when specific version needed

## Alternatives Considered

### 1. Method Missing Proxy (HudUtilityCurrent)

**Approach**: Create a proxy object that delegates method calls to appropriate utility module using `method_missing`

**Pros**:
- Transparent method delegation
- Simple calling interface
- Similar pattern to existing code

**Cons**:
- **Fragile**: Breaking changes in underlying modules wouldn't surface until runtime
- **Thread Safety**: Difficult to implement proper thread isolation
- **Long-Running Jobs**: Version could change mid-execution during fiscal year transitions
- **Debugging**: Method missing makes stack traces less clear
- **Performance**: Additional method resolution overhead

**Rejected**: Too fragile and prone to runtime errors

### 2. Annual Code Updates

**Approach**: Create new `HudUtilityXXXX` module each year and update all references throughout codebase

**Pros**:
- Explicit version usage
- No indirection

**Cons**:
- **Massive Code Churn**: Requires updating hundreds of references across the codebase annually
- **Error Prone**: Easy to miss references during updates
- **Maintenance Burden**: Significant developer time required for each specification update
- **Inconsistency Risk**: Partial updates could leave system in inconsistent state

**Rejected**: Proven to cause excessive maintenance burden

## Additional Info

### Implementation Notes

- The factory pattern allows easy addition of new HUD specification versions without changing calling code
- `ActiveSupport::CurrentAttributes` provides request/job-scoped version pinning
- Version determination logic can be easily adjusted for different deployment environments
- Legacy utility modules remain available for backward compatibility

### Related Documents

- [PR #5756: Review of HudUtility2024](https://github.com/greenriver/hmis-warehouse/pull/5756)
- HUD HMIS CSV Format Specifications (annual updates)

### Migration Strategy

1. Implement `HudHelper` factory pattern
2. Update all existing `HudUtility*` code paths to use factory
