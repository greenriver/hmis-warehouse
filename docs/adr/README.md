# Architectural Decision Records (ADRs)

## Overview

This directory contains Architectural Decision Records (ADRs) for the Open Path Project.

## What is an ADR?

ADRs are lightweight documents that capture important architectural decisions made during a project, along with their context and consequences. Each ADR should describe:

- Title and status (proposed, accepted, deprecated, etc.)
- Context (what's the situation necessitating a decision?)
- Decision (what is the change we're proposing?)
- Consequences (what becomes easier/harder because of this?)

These sections can be brief. The ADR should not become a technical specification with implementation details

## Why we use ADRs

- To provide a record of architectural decisions and their rationale
- To help onboard new team members by explaining the context behind our architecture
- To track the evolution of our system over time
- To encourage thoughtful consideration of architectural changes

## ADR Process

### When to write an ADR

Create a new ADR when you:

- Make a significant architectural decision that affects multiple components
- Choose technologies that will have long-term impact
- Change or reverse previous architectural decisions
- Need to resolve architectural conflicts or competing approaches

### ADR Lifecycle

1. **Discovery**: Team member identifies need for architectural decision
2. **Draft**: Team member creates initial ADR document in a pull request
3. **Review**: Team discusses and provides feedback
4. **Decision**: Team reaches consensus or designated authority makes final call
5. **Publication**: ADR is merged and numbered
6. **Maintenance**: ADRs may be marked as superseded or deprecated over time

### File Name Convention

- ADR files should be named using the format: `NNNN-title-with-dashes.md`
- NNNN is a sequentially increasing four-digit number with leading zeros (0001, 0002, etc.)
- Example: `0001-choose-database.md`

## Historical Context

Our ADR process began in 2024. Not all historical decisions may be documented as ADRs, but we maintain ADRs for all significant architectural decisions going forward.

## Repository Structure

```
docs/
  adr/
    README.md             <- This file
    0001-first-decision.md
    0002-second-decision.md
    template.md           <- Template for new ADRs
```

## Contributing

1. Copy `template.md` to create your new ADR
2. Fill in the template
3. Create a pull request
4. Seek review from team
5. Update based on feedback
6. Merge once approved
