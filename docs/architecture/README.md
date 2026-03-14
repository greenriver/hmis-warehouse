# Architecture Documentation

This directory contains the architectural documentation for the **entire Open Path Platform system**, including the Rails monolith, the HMIS front-end, the analytics store, and the CAS matching system.

## Table of Contents

1. [**1 Introduction and Goals**](01-introduction.md): Short description of the requirements and goals.
2. [**2 Architecture Constraints**](02-constraints.md): System-wide constraints and limitations.
3. [**3 Context and Scope**](03-context.md): External interfaces and communication partners.
4. [**4 Solution Strategy**](04-solution-strategy.md): Fundamental system-wide decisions and strategies.
5. [**5 Building Block View**](05-building-blocks/05-0-building-blocks.md): Static decomposition into containers and components.
6. [**6 Runtime View**](06-runtime/06-0-runtime-view.md): Behavior and interactions at runtime.
7. [**7 Deployment View**](07-deployment.md): Technical infrastructure and mapping.
8. [**8 Cross-cutting Concepts**](08-concepts/08-0-concepts.md): Cross-cutting concerns and patterns.
9. [**9 Architecture Decisions**](09-decisions.md): References to Architecture Decision Records (ADRs).
10. [**10 Quality Requirements**](10-quality.md): Quality goals and scenarios.
11. [**11 Risks and Technical Debts**](11-risks.md): Identified risks and debts.
12. [**12 Glossary**](12-glossary.md): Important domain and technical terms.

## About this Documentation

This documentation uses a combination of two industry-standard frameworks to ensure clarity, consistency, and depth.

### About the arc42 Template
We use the [arc42](https://arc42.org/) template to provide a consistent structure for the documentation. Each numbered file in this directory corresponds to a section of the arc42 template, guiding the reader from high-level goals and constraints down to technical implementation details and cross-cutting concepts.

### C4 Model
For visual documentation and diagramming, we follow the [C4 model](https://c4model.com/). This allows us to represent the system at different levels of abstraction:
- [**Level 1 (System Context)**](03-context.md): The system as a "black box" in its environment.
- [**Level 2 (Containers)**]: See [5.1 Core Operations](05-building-blocks/05-1-core-operations.md) and [5.2 Data Ingestion & Analytics](05-building-blocks/05-2-data-ingestion-analytics.md).
- [**Level 3 (Components)**]: See [5.3 Authentication & Identity](05-building-blocks/05-3-authentication-identity.md), [5.4 Warehouse Application](05-building-blocks/05-4-warehouse-application.md), and [5.5 CAS Legacy](05-building-blocks/05-5-cas-legacy.md). Internal components of specific containers.

## Other Documentation
- [**Detailed Implementation Documentation**]: Refer to the respective `docs/features` directories in each repository.
- [**Architecture Decisions (ADRs)**]: Refer to the respective `docs/adr` directories in each repository for low-level technical decisions.
