# ADR 002: PII Management Strategy

## Status

- Current Status: Proposed
- Date of last update: 2024-11-18
- Decision-makers: [Project Team]

## Context

The Open Path Warehouse and HMIS handle sensitive personally identifiable information (PII) for clients and program staff. As our system grows and privacy requirements evolve, we need a comprehensive strategy for managing PII.

### Current State

- PII is distributed across multiple tables and models
- No systematic tracking of where PII exists
- Limited ability to audit PII
- No standardized approach to PII protection
- Growing need for sanitized development/testing environments

### Constraints

1. Must maintain HMIS compliance and data standards
2. Must support multiple environments (production, staging, development)
3. Must maintain referential integrity across the system
4. Must support privacy regulations and audit requirements
5. Must work with existing application patterns and data models
6. Must support both direct identifiers (names, SSN) and quasi-identifiers (age, location)

## Decision

Implement a multi-phase approach to PII management:

### Phase 1: Inventory and Access Control

- Improve PII access control implementation for common reports and dashboards
- Implement systemic PII tracking mechanism in application code
- Define sensitivity levels and other metadata for PII fields
- Create inventory of data models containing PII
- Investigate PII requirements in our BI tooling

### Phase 2: Enhanced Tooling & Management

- Implemnent systemic PII access control across all locations that expose level 1 PII (dashboards and reports)
- Implement and deploy PII scrubbing for our development and testing needs
- Support for tracking PII in key-value PII storage, such as CustomDataElements
- Create tools to support auditing PII

### Phase 3: Data Model Refactoring

- Evaluate data model refactoring to better secure PII
- Enhance PII access controls

## Consequences

### Positive

1. Clear roadmap for improving PII handling
2. Ability to systematically enhance privacy protections
3. Better support for compliance requirements
4. Foundation for automated PII management
5. Improved development and testing workflows

### Negative

1. Significant development effort across multiple phases
2. May require changes to existing data models and access patterns
3. Additional operational complexity
4. Performance implications of enhanced security measures

## Alternatives Considered

### 1. Status Quo with Enhanced Documentation

**Pros:**

- Minimal changes to existing system
- Lower implementation cost

**Cons:**

- Doesn't address our privacy requirements
- Continued manual handling of PII
- Increasing technical debt

## Additional Info

### Implementation Notes

The phased approach allows us to:

1. Start with low-risk tracking improvements
2. Gather data to inform protection strategies
3. Incrementally enhance security measures
4. Maintain system stability throughout changes

### Related Documents

- [#6730](https://github.com/open-path/Green-River/issues/6730)
