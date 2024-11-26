# ADR 002: PII Management Strategy

## Status

- Current Status: Accepted
- Date of last update: 2024-11-26
- Decision-makers: OP engineering team

## Context

The Open Path Warehouse and HMIS handle sensitive personally identifiable information (PII) for clients and program staff with robust security measures. As our system grows and privacy requirements evolve, we are expanding our strategy for managing PII.

### Current State

- PII is managed across multiple database tables with existing controls
- Opportunities identified to enhance application-level PII tracking
- Planning to expand granular PII protection capabilities

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

- Strengthen existing PII access controls for common reports and dashboards
- Implement a declarative API for defining and tracking PII fields at the model level
- Define sensitivity levels and other metadata for PII fields
- Review existing models and ensure all PII fields are tracked

### Phase 2: Enhanced Tooling & Management

- Strengthen existing PII access controls for comprehensive coverage across all reporting interfaces
- Implement secure data anonymization processes for non-production environments
- Extend PII field definitions to support structured data elements (key-value stores)

### Phase 3: Data Model Refactoring

- Define and implement a process to ensure regular review of PII field definitions
- Evaluate data model optimization to enhance PII isolation, simplify management, and align with requirements

## Consequences

### Positive

1. Clear roadmap for improving PII handling
2. Ability to systematically enhance privacy protections
3. Strengthens privacy protections for clients
4. Builds a strong foundation for future growth and compliance
5. Improved development and testing workflows

### Negative

1. Significant development effort, mitigated by a phased approach designed to minimize disruption
2. May require changes to existing data models and access patterns
3. Additional operational complexity
4. Will need optimization to maintain system performance with additional security measures

## Alternatives Considered

### 1. Status Quo with Enhanced Documentation

**Pros:**

- Minimal changes to existing system
- Lower implementation cost

**Cons:**

- Reduced opportunity for privacy automation and enhancement
- Manual processes would require more staff time
- Growing complexity in maintaining documentation

## Additional Info

### Implementation Notes

The phased approach allows us to:

1. Start with low-risk tracking improvements
2. Gather data to inform protection strategies
3. Incrementally enhance security measures
4. Maintain system stability throughout changes

### Related Documents

- [Epic #7030](https://github.com/open-path/Green-River/issues/7030)
