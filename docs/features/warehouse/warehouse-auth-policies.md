# Warehouse Auth Policies

Warehouse Auth Policies contain the business rules for determining user access to warehouse resources such as clients, projects, and data sources.

## Overview

The authorization system decouples permission checks from the underlying data models and the specific authentication mechanism (Legacy Role-based or ACL-based). Policies are initialized with a context object that resolves permissions for the current user.

## Architecture

The system consists of three main components:

- **Entry Point**: `User#policy_for(resource)` or `User#reporting_policy_for_project(project_id)` are the primary ways to obtain a policy.
- **Context Objects**: `UserAclContext` and `UserLegacyContext` encapsulate permission lookups. They provide a common interface for policies to query permissions without knowing how they are stored or resolved.
- **Context Loaders**: Specialized objects (e.g., `ClientRoiLoader`) that provide cached data loading for policies to avoid N+1 queries.
- **Policies**: Concrete classes inheriting from `BasePolicy` that define domain-specific authorization logic.

### Relationship Diagram

```mermaid
graph TD
    User -->|policy_for| Policy
    Policy -->|queries| Context
    Context -->|resolves| ACLs[ACL System]
    Context -->|resolves| Legacy[Legacy System]
    Context -->|uses| Loaders[Context Loaders]
    Loaders -->|optimizes| DB[(Database)]
    Policy -->|validates| Resource
```

## Policy Implementation

Policies are located in `app/models/grda_warehouse/auth_policies/`.

- `BasePolicy`: Abstract base class providing common initialization and validation helpers.
- **Resource Policies**: for warehouse resources (e.g., `ProjectPolicy`, `SourceClientPolicy`, `DataSourcePolicy`).
- **Specialized Policies**: optimized for controlling access to sensitive data in reporting contexts (e.g., `ProjectPiiPolicy`).

## Usage

Policies are typically invoked through the `User` model.

```ruby
# Get a policy for a specific project
policy = current_user.policy_for(@project)
policy.can_view?
policy.can_edit?

# Get a PII policy for reporting
pii_policy = current_user.reporting_policy_for_project(project_id)
pii_policy.can_view_full_ssn?
```

### Preloading

When checking policies for multiple resources (e.g., in a list view), the context provides helpers to preload dependencies to avoid N+1 queries.

```ruby
context = current_user.policy_context

# Preload resource permissions
context.preload_some_dependencies(resource_ids)

# Preload through a context loader
context.some_loader.preload(resource_ids)
```
