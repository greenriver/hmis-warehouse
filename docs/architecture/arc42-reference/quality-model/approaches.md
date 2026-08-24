# arc42 Solution Approaches

55 solution approaches (tactics & patterns), 51 aliases.

- Source: https://quality.arc42.org
- Dataset: [`arc42/quality.arc42.org-site`](https://github.com/arc42/quality.arc42.org-site) @ `3a24a3c640a7bb32fb3d5344dcc7dcda8d6e22f0`
- Retrieved: 2026-08-24
- Refresh by diffing this SHA against `HEAD` and regenerating.


An approach is an architectural tactic or pattern that improves one or more quality characteristics, usually at the cost of others. Read this as a "we want X, what do we do about it" lookup: find the quality in the index, then read the approach entries it points to.

## Index by quality enabled

| Quality wanted | Approaches that enable it |
|---|---|
| **access-control** | Fine-Grained Authorization (RBAC/ABAC), Least Privilege, Secret Management, Strong Authentication (MFA / OIDC) |
| **accessibility** | Progressive Disclosure, Responsive Design |
| **accountability** | Strong Authentication (MFA / OIDC) |
| **adaptability** | Defer Binding, Externalized Business Rules, Responsive Design |
| **analysability** | Increase Cohesion, Preserve Facts, Derive Interpretations |
| **atomicity** | Transactional Outbox |
| **auditability** | Event Sourcing, Externalized Business Rules, Fine-Grained Authorization (RBAC/ABAC), Preserve Facts, Derive Interpretations, Secret Management |
| **authenticity** | Strong Authentication (MFA / OIDC) |
| **autonomy** | Backends for Frontends, Event-Driven Architecture, Microservice Architecture, Reconciliation Loops, Self-Contained Systems |
| **availability** | API Gateway, Backpressure Propagation, Blue-Green Deployment, Bulkheads, Canary Deployment, Circuit Breaker, Content Delivery Network (CDN), Data Replication, Database Sharding, Feature Degradation, Quarantine, Rate Limiting, Saga Pattern, Standby/Failover, Timeout, Watchdog Supervision |
| **backward-compatibility** | Consumer-Driven Contracts, Tolerant Reader |
| **capacity** | Database Sharding |
| **changeability** | Externalized Business Rules, Feature Toggles |
| **compliance** | Encryption at Rest + in Transit, Fine-Grained Authorization (RBAC/ABAC), Input Sanitization / Output Encoding, Least Privilege, Secret Management, Strong Authentication (MFA / OIDC) |
| **confidentiality** | Encryption at Rest + in Transit, Fine-Grained Authorization (RBAC/ABAC), Least Privilege, Secret Management, Threat Modeling |
| **configurability** | Defer Binding, Plugin Architecture |
| **consistency** | Transactional Outbox |
| **controllability** | Fail-Safe Defaults, Safety Interlocks |
| **correctness** | B-Method, N-Version Redundancy and Voting |
| **data-integrity** | Encryption at Rest + in Transit, Input Sanitization / Output Encoding, Saga Pattern, Transactional Outbox |
| **data-protection** | Encryption at Rest + in Transit |
| **debuggability** | Event Sourcing |
| **deployability** | Blue-Green Deployment, Canary Deployment, Feature Toggles, Microservice Architecture, Self-Contained Systems |
| **distributability** | Database Sharding |
| **drift-detectability** | Reconciliation Loops |
| **durability** | Data Replication |
| **effectiveness** | A/B Testing |
| **energy-efficiency** | Computational Overhead Reduction, Limit Event Response, Manage Event Arrival |
| **evolvability** | Backends for Frontends, Consumer-Driven Contracts, Defer Binding, Event Sourcing, Event-Driven Architecture, Hexagonal Architecture, Microservice Architecture, Open Host Service, Preserve Facts, Derive Interpretations, Reduce Coupling, Self-Contained Systems, Tolerant Reader |
| **explainability** | Externalized Business Rules |
| **extensibility** | CQRS, Event-Driven Architecture, Plugin Architecture, Sidecar |
| **fail-safe** | Fail-Safe Defaults, Safety Interlocks |
| **fault-isolation** | Microservice Architecture, Quarantine, Timeout |
| **fault-tolerance** | Bulkheads, Circuit Breaker, Fail-Safe Defaults, N-Version Redundancy and Voting, Standby/Failover, Timeout, Watchdog Supervision |
| **flexibility** | Feature Toggles |
| **functional-appropriateness** | A/B Testing |
| **graceful-degradation** | Bulkheads, Feature Degradation |
| **hazard-warning** | Safety Interlocks |
| **integrability** | Event-Driven Architecture, Open Host Service |
| **integrity** | Fine-Grained Authorization (RBAC/ABAC), Input Sanitization / Output Encoding, Least Privilege, N-Version Redundancy and Voting, Safety Interlocks, Threat Modeling |
| **interoperability** | API Gateway, Consumer-Driven Contracts, Open Host Service, Sidecar, Tolerant Reader |
| **intrusion-prevention** | Rate Limiting, Threat Modeling |
| **latency** | Backpressure Propagation, Computational Overhead Reduction, Content Delivery Network (CDN), Manage Event Arrival |
| **lead-time-for-changes** | Asynchronous Messaging |
| **learnability** | Progressive Disclosure |
| **legacy-support** | Sidecar |
| **loose-coupling** | Asynchronous Messaging, Backends for Frontends, Event-Driven Architecture, Hexagonal Architecture, Open Host Service, Saga Pattern, Self-Contained Systems |
| **mean-time-to-recovery** | Watchdog Supervision |
| **modifiability** | Feature Toggles, Increase Cohesion, Plugin Architecture, Reduce Coupling |
| **modularity** | API Gateway, Hexagonal Architecture, Increase Cohesion, Reduce Coupling |
| **non-repudiation** | Strong Authentication (MFA / OIDC) |
| **observability** | API Gateway, Sidecar |
| **operability** | Reconciliation Loops, Secret Management |
| **performance** | CQRS, Caching |
| **policy-enforcement** | Fine-Grained Authorization (RBAC/ABAC) |
| **portability** | Defer Binding |
| **predictability** | Fail-Safe Defaults |
| **privacy** | Encryption at Rest + in Transit |
| **provability** | B-Method |
| **recoverability** | Blue-Green Deployment, Canary Deployment, Event Sourcing, Feature Degradation, Quarantine, Reconciliation Loops, Saga Pattern, Standby/Failover, Watchdog Supervision |
| **releasability** | Blue-Green Deployment, Canary Deployment |
| **reliability** | B-Method, Backpressure Propagation, Transactional Outbox |
| **replaceability** | Self-Contained Systems |
| **resilience** | Bulkheads, Circuit Breaker, Feature Degradation, Rate Limiting |
| **resource-efficiency** | Computational Overhead Reduction, Limit Event Response, Manage Event Arrival |
| **response-time** | Backends for Frontends, Content Delivery Network (CDN), Timeout |
| **responsiveness** | Asynchronous Messaging, CQRS, Caching |
| **reusability** | Plugin Architecture |
| **risk-identification** | Threat Modeling |
| **robustness** | Fail-Safe Defaults, Input Sanitization / Output Encoding, Tolerant Reader |
| **safety** | B-Method, Fail-Safe Defaults, Safety Interlocks, Watchdog Supervision |
| **scalability** | API Gateway, Asynchronous Messaging, CQRS, Caching, Content Delivery Network (CDN), Data Replication, Database Sharding, Microservice Architecture |
| **securability** | Threat Modeling |
| **security** | API Gateway, Fine-Grained Authorization (RBAC/ABAC), Input Sanitization / Output Encoding, Least Privilege, Rate Limiting, Secret Management, Strong Authentication (MFA / OIDC) |
| **self-healing** | Watchdog Supervision |
| **stability** | Backpressure Propagation, Bulkheads, Circuit Breaker, Limit Event Response, Manage Event Arrival, Quarantine, Rate Limiting |
| **testability** | Consumer-Driven Contracts, Feature Toggles, Hexagonal Architecture, Increase Cohesion, Reduce Coupling |
| **throughput** | Asynchronous Messaging, CQRS, Computational Overhead Reduction, Content Delivery Network (CDN), Database Sharding |
| **time-behaviour** | Limit Event Response |
| **time-to-market** | Externalized Business Rules |
| **traceability** | Event Sourcing, Preserve Facts, Derive Interpretations |
| **transactionality** | Saga Pattern |
| **usability** | Progressive Disclosure, Responsive Design |
| **user-engagement** | A/B Testing |
| **user-error-protection** | Safety Interlocks |
| **user-experience** | A/B Testing, Progressive Disclosure |
| **verifiability** | B-Method |

## Approaches

### A/B Testing

*Also known as: Split Testing, Online Controlled Experiment*

**Intent:** Split live traffic between variants with randomized assignment, then ship the version that measurably improves the target metric.

**Mechanism:** Randomly assign incoming users to a control (A) and one or more treatments (B), each seeing a different variant. Log a predefined success metric per user, run until the sample reaches statistical power, then compare variants with a significance test and promote the winner.

**Applicability:** Use when you have enough traffic to reach significance quickly, a clear quantitative success metric, and reliable per-user logging. Skip when traffic is too low for a timely verdict, the change has no measurable outcome, or ethics or safety forbid withholding it from a group.

- Dimensions: `suitable`, `usable`
- Enables:
    - **functional-appropriateness** — Each variant is judged on whether it actually helps users accomplish the target task, so only changes that demonstrably improve task outcomes ship.
    - **effectiveness** — Controlled comparison quantifies whether users complete their goals more accurately and completely under a variant before it reaches everyone.
    - **user-experience** — Design and flow changes are decided by observed user behaviour on live traffic, grounding UX choices in evidence rather than opinion.
    - **user-engagement** — Variants compete on real engagement metrics, so the version that measurably increases interaction is the one promoted to all users.
- Trade-offs (costs):
    - **code-complexity** — An experiment needs variant-assignment logic, per-user event tracking, and a statistics pipeline to compute significance — infrastructure the team builds and maintains. Each live test also forks the code into branches that must be cleaned up after the verdict, or stale variants accumulate and obscure the real behaviour.
    - **cycle-time** — A change reaches production but stays unproven until the experiment gathers enough samples for a trustworthy verdict, often days or weeks. Cutting that window short to decide faster invites false positives from peeking — the very error A/B testing exists to prevent.
- Related requirements: first-time-onboarding-without-errors, user-tries-primary-function, new-features-introduct-no-bugs
- Related approaches: canary-deployment
- Source: https://quality.arc42.org/approaches/ab-testing

### API Gateway

**Intent:** Provide a single, managed entry point that enforces cross-cutting concerns — authentication, rate limiting, routing, observability, and protocol translation — so that backend services remain focused on business logic.

**Mechanism:** Route all external (and optionally internal) traffic through a reverse-proxy layer that terminates TLS, validates credentials, enforces quotas, selects the target backend via declarative routing rules, and emits structured telemetry for every request — rejecting or transforming requests before they reach application code.

**Applicability:** Use when multiple backend services share common cross-cutting concerns that would otherwise be duplicated in each service, or when client-facing API contracts must remain stable while internal service boundaries evolve. Avoid when the system has a single backend with no cross-cutting requirements, or when the added hop and operational complexity outweigh the consolidation benefit.

- Dimensions: `secure`, `operable`, `reliable`
- Enables:
    - **security** — Centralizes authentication, authorization, and request validation at a single enforcement point instead of duplicating those controls in every backend service.
    - **interoperability** — Translates between client-facing protocols (REST, GraphQL, WebSocket) and internal protocols, shielding consumers from backend technology choices.
    - **observability** — Produces a uniform stream of access logs, latency histograms, error rates, and distributed-trace headers for every request entering the system.
    - **scalability** — Offloads cross-cutting work from backend services and absorbs traffic spikes via connection pooling, request buffering, and integration with autoscaling.
    - **availability** — Health-check routing steers traffic away from failing backends, and retry-with-jitter masks transient failures on idempotent routes — provided the gateway fleet itself is deployed redundantly; a single fleet is a single point of failure.
    - **modularity** — Decouples client-facing API contracts from internal service boundaries, allowing backend teams to split, merge, or rewrite services without breaking consumers.
- Trade-offs (costs):
    - **latency** — Every request traverses an additional network hop; TLS termination, policy evaluation, and logging add measurable overhead on the critical path.
    - **operability** — The gateway's routing rules, rate-limit policies, certificate rotation, and plugin configuration become a shared operational surface that requires dedicated ownership.
    - **loose-coupling** — If routing rules, request transformations, or response shaping accumulate business logic, the gateway becomes a coupling bottleneck that must change whenever any backend changes.
- Related requirements: access-control-is-enforced, withstand-ddos-attack, handle-sudden-increase-in-traffic, production-anomalies-detectable-within-2-minutes, public-api-intrusion-attempts-blocked
- Source: https://quality.arc42.org/approaches/api-gateway

### Asynchronous Messaging

**Intent:** Move long-running or failure-prone work off the synchronous request path so user-facing interactions stay fast and resilient under variable load.

**Mechanism:** Accept work, persist a message to a durable queue or topic, acknowledge quickly, and process the message asynchronously with dedicated consumers using retry, backoff, and dead-letter handling; because durable brokers commonly provide at-least-once delivery, handlers must be idempotent to tolerate redelivery safely.

**Applicability:** Use for tasks that can complete after the initial response, especially when workload is bursty or integrations are slow or unreliable. Avoid for operations that require immediate, strongly consistent confirmation in the same request.

- Dimensions: `efficient`, `flexible`
- Enables:
    - **responsiveness** — Returns quickly by accepting work without waiting for full processing.
    - **throughput** — Buffers burst traffic and lets workers process jobs at stable rates.
    - **scalability** — Consumers can scale independently from request-handling components.
    - **loose-coupling** — Producers and consumers evolve independently via stable message contracts.
    - **lead-time-for-changes** — Teams can release producer and consumer changes separately with backward-compatible schemas.
- Trade-offs (costs):
    - **eventual-consistency** — Downstream views are updated after processing, not immediately at request time.
    - **determinism** — Maintaining strict event order across distributed consumers often requires partition-key constraints that reduce maximum parallelism.
    - **observability** — Tracing a business transaction across broker hops and retries is harder than synchronous call chains.
    - **code-complexity** — Durable messaging needs idempotency, retries, dead-letter handling, and schema governance.
    - **latency** — Queueing delay can increase end-to-end completion time under load or consumer slowdown.
- Related requirements: handle-sudden-increase-in-traffic, service-loose-coupling-change-blast-radius, response-time-for-image-rendering
- Source: https://quality.arc42.org/approaches/asynchronous-messaging

### B-Method

**Intent:** Ensure software correctness through mathematical proof and stepwise refinement, so critical behavior is justified by evidence stronger than testing alone.

**Mechanism:** Model the critical state and operations in a formal notation, state invariants explicitly, refine the model in controlled steps, and discharge the generated proof obligations before accepting the implementation.

**Applicability:** Best fit for discrete, state-rich, high-assurance systems where failure is costly and the core behavior is stable enough to justify upfront modeling and proof effort. Usually a poor fit for fast-moving UI-heavy product surfaces or low-risk business features.

- Dimensions: `reliable`, `safe`
- Enables:
    - **provability** — Stepwise refinement and mathematical proof produce explicit evidence that stated properties hold.
    - **correctness** — Proof obligations show that each operation and refinement preserves the model's invariants.
    - **safety** — Safety constraints can be encoded as invariants and shown to hold for every modeled state transition.
    - **reliability** — Removing whole classes of logic errors in critical code paths reduces latent defect risk.
    - **verifiability** — Formal models make assumptions, states, and transitions precise enough for automated and manual checking.
- Trade-offs (costs):
    - **cost** — Formalizing specifications and discharging proofs takes far more upfront effort than ordinary coding, and it demands scarce expertise in formal logic and set theory that can bottleneck hiring and team scaling — even where the rigor reduces later rework.
    - **modifiability** — Changing a core requirement can ripple through machines, invariants, refinements, and their proofs; a safety-critical change may force re-proving large portions of the refinement chain, slowing iteration and reducing agility.
    - **time-to-market** — First usable output arrives later because the assurance argument is built before the implementation is considered complete, pushing delivery out compared with iterative or test-driven approaches.
    - **understandability** — Most stakeholders can follow the intent, but few read the formal notation or proof artifacts directly; success also hinges on proof, animation, and model-analysis tools and a team that interprets their output correctly.
- Related requirements: provable-railway-interlocking-routing-logic, provable-railway-interlocking-safety, provable-insulin-dosage-safety
- Source: https://quality.arc42.org/approaches/b-method

### Backends for Frontends

*Also known as: BFF*

**Intent:** Give each frontend its own purpose-built backend, so every experience shapes and evolves its API without negotiating with other clients.

**Mechanism:** One thin edge service per frontend — web, mobile, partner — aggregates downstream APIs and tailors the payload to that single experience. The team building the frontend owns its BFF and changes the contract on the frontend's release cadence; downstream services stay general-purpose.

**Applicability:** Use when several distinct frontends pull differently shaped data from the same services and a general-purpose API has become the negotiation bottleneck between client teams. Skip with a single frontend, or when light response shaping in an API gateway covers the differences.

- Dimensions: `flexible`, `efficient`
- Enables:
    - **evolvability** — Each frontend changes its API contract at its own pace; no cross-client negotiation over one general-purpose API.
    - **autonomy** — The frontend team owns the backend it consumes — shaping, building, and releasing it without waiting on a central API team.
    - **loose-coupling** — Clients couple to one tailored contract instead of to the granularity and churn of many downstream services.
    - **response-time** — Server-side aggregation replaces several client round trips with one call — felt most over high-latency mobile networks.
- Trade-offs (costs):
    - **simplicity** — Every experience adds another deployable with its own pipeline, monitoring, and on-call duty, plus one more hop in every request path. The service count grows with the number of frontends, not with business capability.
    - **consistency** — Aggregation and presentation rules reimplemented per BFF drift apart: web and mobile quietly diverge in totals, filtering, or wording until users comparing both surfaces notice.
    - **maintainability** — A downstream API change must be repeated in every BFF that consumes it. Logic shared across BFFs is either duplicated — Newman's own caveat — or extracted into libraries the client teams must version and govern.
- Related requirements: independent-enhancement-of-subsystem, service-loose-coupling-change-blast-radius
- Related approaches: api-gateway, microservice-architecture
- Source: https://quality.arc42.org/approaches/backends-for-frontends

### Backpressure Propagation

*Also known as: Flow Control*

**Intent:** Signal overload upstream, stage by stage, so producers slow down at the source before queues grow past collapse.

**Mechanism:** Bound every buffer between stages. When a buffer fills, the stage signals its upstream neighbor — by demand requests, slowed acknowledgements, or explicit rejection — and the neighbor forwards the pressure until it reaches a component that can pace, degrade, or shed work.

**Applicability:** Use in pipelines and streaming systems where producers can outpace consumers and every stage is under your control or speaks a pressure-aware protocol. Skip when sources cannot slow down — then shed load explicitly at the edge instead of propagating a signal nobody can honor.

- Dimensions: `reliable`
- Enables:
    - **stability** — Bounded buffers keep load inside the operating range: overload slows intake instead of pushing the system into runaway queue growth.
    - **availability** — The pipeline keeps serving at its capacity limit during overload instead of collapsing under runaway queues.
    - **latency** — Short, bounded queues bound waiting time, so processing delay stays predictable under load instead of growing with queue depth.
    - **reliability** — No work is silently lost to overflowing buffers: excess is refused explicitly at the edge, where the caller can react.
- Trade-offs (costs):
    - **loose-coupling** — Consumer state now steers producers at runtime through an explicit control channel. Every intermediary must forward the signal, so stages that messaging deliberately decoupled become operationally coupled again during overload.
    - **code-complexity** — Each stage needs bounded buffers, a demand or signaling protocol, and a policy for being slowed — buffer, degrade, or reject. Pull-based streaming code is harder to write, test, and debug than fire-and-forget publishing.
    - **throughput** — Producers run at the slowest stage's pace, and offered load above capacity is delayed or refused at the source. A mis-tuned buffer or an overly eager signal throttles the pipeline below its real capacity.
- Related requirements: handle-sudden-increase-in-traffic
- Related approaches: asynchronous-messaging, rate-limiting, limit-event-response
- Source: https://quality.arc42.org/approaches/backpressure-propagation

### Blue-Green Deployment

**Intent:** Release a new version with zero downtime by running it on an idle, identical environment, then switching all traffic to it at once.

**Mechanism:** Keep two identical application environments in production, blue and green. One serves live traffic while the other stays idle. Deploy and validate the new version on the idle one, then repoint the router or load balancer to it. The previous environment stays running as the rollback target.

**Applicability:** Use for stateless or compatibility-tolerant services behind a router where downtime windows are costly and fast rollback matters. Skip when environment duplication is unaffordable, or when stateful schema and data migrations cannot be made compatible across both versions — then a rolling or canary release fits better.

- Dimensions: `operable`, `reliable`
- Enables:
    - **availability** — Switching all traffic at the router gives zero-downtime releases — users see no maintenance window.
    - **deployability** — The new version deploys to an idle environment and is validated there before any user traffic arrives.
    - **releasability** — Release decouples from deploy: the version goes live the instant traffic is flipped, on the team's schedule.
    - **recoverability** — Traffic rollback is instant — flip back to the still-running previous environment, with no rebuild or redeploy.
- Trade-offs (costs):
    - **cost** — Running two production-grade environments doubles infrastructure spend for compute, and for stateful tiers also storage and licences, while the idle side sits unused between releases. Trimming the standby to save money erodes the zero-downtime and instant-rollback guarantees the tactic exists to provide.
    - **code-complexity** — Blue and green usually share one database, so every schema change must stay backward- and forward-compatible across both versions at once. The application carries expand/contract migration code and version-tolerant read and write paths, and that compatibility logic persists long after the release completes.
- Related requirements: available-7-24-99, low-change-failure-rate, unavailability-max-2-minutes
- Related approaches: canary-deployment
- Source: https://quality.arc42.org/approaches/blue-green-deployment

### Bulkheads

**Intent:** Isolate resource pools so that a failure, slowdown, or overload in one part of the system cannot exhaust shared resources and cascade into unrelated parts.

**Mechanism:** Partition shared resources — thread pools, connection pools, memory regions, or entire service instances — into isolated compartments, each with its own capacity limits; when one compartment saturates or fails, the others continue operating within their own budgets.

**Applicability:** Use when a system has multiple callers, dependencies, or workload classes competing for shared resources, and a failure in one must not degrade the others. Avoid when workloads are uniform and the overhead of maintaining separate pools outweighs the isolation benefit.

- Dimensions: `reliable`
- Enables:
    - **fault-tolerance** — A failure in one compartment cannot propagate to others, so the system keeps functioning despite partial outages.
    - **availability** — Unaffected resource pools continue serving requests while the degraded pool is isolated or recovering.
    - **resilience** — Blast radius is bounded by design — resource exhaustion in one path does not cascade system-wide.
    - **stability** — Load spikes or failures in one consumer cannot destabilize unrelated workloads sharing the same infrastructure.
    - **graceful-degradation** — When a pool is saturated, only its callers see errors; the rest of the system degrades gracefully rather than collapsing entirely.
- Trade-offs (costs):
    - **resource-utilization** — Dedicated pools reserve capacity per compartment, leaving some resources idle even when other pools are under pressure.
    - **capacity** — Total peak throughput is lower than with a single shared pool because spare capacity in one partition cannot absorb bursts in another.
    - **code-complexity** — Partition boundaries, pool sizing, and per-compartment configuration add operational and architectural overhead.
    - **observability** — Monitoring per-pool utilization, rejection rates, and queue depths across many compartments increases telemetry volume.
- Related requirements: server-fails-operation-without-downtime, zone-failure-no-service-interruption
- Source: https://quality.arc42.org/approaches/bulkheads

### Caching

**Intent:** Store frequently accessed data closer to the consumer to reduce latency and load on backend systems.

**Mechanism:** Interpose a fast-access storage layer between the consumer and the source, check it first for a match (hit), and only fetch from the source (miss) when necessary, optionally updating the cache according to read/write strategies.

**Applicability:** Use when data is read significantly more often than it is written, when slight staleness is acceptable, and when backend latency or load is a concern. Avoid when data must always be real-time consistent or when the working set exceeds available cache memory.

- Dimensions: `efficient`, `reliable`
- Enables:
    - **performance** — Reduces repeated expensive operations and lowers response time.
    - **scalability** — Offloads backend services to handle higher concurrent demand.
    - **responsiveness** — Returns frequent queries faster from near-memory storage.
- Trade-offs (costs):
    - **consistency** — Cached values can become stale between updates and invalidation.
    - **code-complexity** — Cache invalidation and eviction policies add implementation overhead.
    - **memory-usage** — Large or unbounded caches can consume significant memory.
    - **observability** — Monitoring cache hit rates, eviction frequency, and data staleness adds operational overhead.
- Related requirements: response-time-for-image-rendering
- Related approaches: content-delivery-network
- Source: https://quality.arc42.org/approaches/caching

### Canary Deployment

*Also known as: Scale Rollouts*

**Intent:** Release a new version to a small slice of production traffic first, then widen exposure step by step only while live metrics stay healthy.

**Mechanism:** Deploy the new version alongside the stable one and route a small percentage of traffic to it. Compare the canary's error, latency, and saturation metrics against the stable baseline. If they hold, raise the share in stages to 100%; if they regress, route all traffic back.

**Applicability:** Use when you have enough production traffic to read canary metrics quickly, metrics labeled by version so canary and baseline separate cleanly, and a router that can split traffic by percentage. Skip when traffic is too low for a timely signal, when releases must be all-or-nothing, or when canary and stable cannot share state safely.

- Dimensions: `operable`, `reliable`
- Enables:
    - **releasability** — Traffic shifts in graded steps gated on live metrics, so exposure stays controlled and decoupled from deploy.
    - **deployability** — The new version runs in production beside the stable one, validated against real user traffic before full rollout.
    - **recoverability** — Aborting a bad release routes the small canary share back to stable in seconds, with no rebuild or redeploy.
    - **availability** — Request-path failures from a faulty release stay confined to the canary slice; the majority of users remain on the proven version.
- Trade-offs (costs):
    - **code-complexity** — Canary needs traffic-splitting at the router, automated comparison of canary-versus-baseline metrics, and — because canary and stable share one datastore — expand/contract schema migrations that stay compatible across both versions at once. The step sizes, thresholds, and bake windows are configuration the team owns and tunes long after the release.
    - **cycle-time** — Each release shifts traffic in steps with a bake-and-observe window at every stage, so a change takes minutes to hours to reach all users instead of an instant flip. Shortening the windows to release faster trades away the early-warning signal canary exists to provide.
- Related requirements: low-change-failure-rate, available-7-24-99, production-anomalies-detectable-within-2-minutes
- Source: https://quality.arc42.org/approaches/canary-deployment

### Circuit Breaker

**Intent:** Prevent a failure in one part of the system from cascading to others by failing fast when a remote service is struggling.

**Mechanism:** Wrap remote calls in a stateful guard that monitors success/failure rates; it trips to an 'Open' state to reject calls immediately when failures exceed a threshold, and probes for recovery via a 'Half-Open' state after a timeout.

**Applicability:** Use when making remote calls (API, DB, etc.) that can fail or become slow and where a fail-fast response is better than waiting. Avoid for local in-process calls where overhead exceeds benefit or when operations must be retried immediately without delay.

- Dimensions: `reliable`, `operable`
- Enables:
    - **resilience** — Improves uptime by containing dependency failures and preventing cascading effects.
    - **stability** — Prevents cascading errors across service boundaries by isolating unhealthy dependencies.
    - **fault-tolerance** — Degrades in a controlled way under partial failure by serving safe fallbacks.
    - **availability** — Protects overall system availability by failing fast rather than hanging on slow dependencies.
- Trade-offs (costs):
    - **maintainability** — Adds threshold and fallback logic that must be configured and maintained.
    - **latency** — Introduces a small overhead for state checks and timeout handling on every request.
- Related requirements: available-7-24-99, server-fails-operation-without-downtime
- Related approaches: bulkheads
- Source: https://quality.arc42.org/approaches/circuit-breaker

### Computational Overhead Reduction

**Intent:** Cut the processing done per event so each one finishes faster and costs fewer cycles.

**Mechanism:** Find the work repeated or wasted on the hot path — redundant recomputation, unnecessary intermediaries, general-purpose code in a tight loop — and remove it: memoize results, inline or drop abstraction layers, and pick algorithms and data structures suited to the actual workload.

**Applicability:** Use when a profiler shows a few operations dominate CPU time or energy on a high-frequency path. Skip when the overhead is negligible, when the code is not yet correct, or when tuning would obscure logic that changes often — tune the proven hot spot, not everything.

- Dimensions: `efficient`
- Enables:
    - **latency** — Removing redundant work from the hot path shortens the time each event spends in processing.
    - **throughput** — Fewer cycles per event let the same resource pool clear more events per second.
    - **resource-efficiency** — Each event consumes less CPU and memory bandwidth, so the system does more with the hardware it has.
    - **energy-efficiency** — Less computation per event draws less power, lowering the energy spent per unit of work.
- Trade-offs (costs):
    - **maintainability** — Memoization and its invalidation, inlined abstraction layers, and hand-tuned loops add code the team must understand and preserve. A routine refactor can silently reintroduce the overhead or break a cache's invalidation, so each change near the hot path costs more review.
    - **accuracy** — When overhead is cut by approximation — lower-precision arithmetic, a coarser model, or reusing a memoized result after its inputs changed — outputs drift from the exact value, so a consumer that needs full fidelity gets a degraded answer.
- Related requirements: response-time-for-image-rendering, reduce-energy-consumption-with-new-version
- Related approaches: caching, limit-event-response
- Source: https://quality.arc42.org/approaches/computational-overhead-reduction

### Consumer-Driven Contracts

*Also known as: Contract Testing*

**Intent:** Each consumer publishes executable expectations of an interface, so provider changes that would break a consumer fail the provider's build.

**Mechanism:** Consumers record what they send and which response elements they read as executable contracts, published to a shared broker; the provider's CI replays every current contract against the real implementation and blocks release on failure.

**Applicability:** Use inside an organization or closed partner ecosystem where consumers are known and publish contracts: internal APIs, microservices, event streams. Skip for public APIs with anonymous consumers — versioning and tolerant readers carry the load there.

- Dimensions: `flexible`, `reliable`, `maintainable`
- Enables:
    - **backward-compatibility** — A provider change that would break any existing consumer fails the provider's build before release, not after deployment.
    - **testability** — Integration compatibility becomes a fast, deterministic CI test instead of a slow end-to-end run on a shared staging environment.
    - **interoperability** — Executable expectations document exactly how each consumer uses the interface, keeping both sides aligned on the wire format.
    - **evolvability** — Contracts reveal which parts of the interface consumers actually use; everything unmentioned can change or disappear safely.
- Trade-offs (costs):
    - **maintainability** — Contract suites are code that every consumer team owns and updates. Contracts left behind by a decommissioned consumer keep blocking provider releases for expectations nobody holds anymore, until someone notices and prunes them.
    - **simplicity** — A contract broker, contract versioning, and cross-team CI wiring join the toolchain — each provider build now depends on artifacts published by consumer teams, coupling pipelines across team boundaries.
- Related requirements: low-change-failure-rate, independent-enhancement-of-subsystem
- Related approaches: tolerant-reader, open-host-service
- Source: https://quality.arc42.org/approaches/consumer-driven-contracts

### Content Delivery Network (CDN)

**Intent:** Reduce latency and offload origin capacity by serving cacheable content from edge nodes close to users.

**Mechanism:** Route requests to a globally distributed edge cache fleet via DNS or anycast to serve content from the nearest healthy node.

**Applicability:** Use for static or semi-static content with many geographically dispersed consumers. Avoid for highly dynamic, per-user, or strongly consistent data where cache invalidation overhead outweighs the latency benefit.

- Dimensions: `efficient`, `operable`
- Enables:
    - **latency** — Serving assets from edge nodes geographically close to users cuts round-trip time across long-haul links.
    - **response-time** — Cached static responses return from the edge without touching the origin, shortening time-to-first-byte.
    - **throughput** — Fan-out of requests across thousands of edge nodes multiplies effective serving capacity far beyond a single origin.
    - **availability** — Edge caches absorb traffic spikes before they reach the origin; during an origin outage, already-cached content keeps serving users — provided serve-stale (stale-if-error) is configured.
    - **scalability** — Traffic surges are absorbed by the CDN's elastic edge fleet without provisioning origin capacity.
- Trade-offs (costs):
    - **currentness** — Cached content can lag the origin until TTLs expire or explicit purges propagate across the edge network.
    - **cost** — Commercial CDN egress and request pricing adds a recurring operational expense that scales with traffic.
    - **debuggability** — Faults and anomalies can originate at any of many edge nodes, cache layers, or routing decisions outside direct control.
- Related requirements: near-instant-search-results, response-time-for-image-rendering, handle-sudden-increase-in-traffic
- Source: https://quality.arc42.org/approaches/content-delivery-network

### CQRS

**Intent:** Separate the read and write sides of a system so each can be modeled, optimized, and scaled for its own workload characteristics.

**Mechanism:** Route commands through a write model that enforces invariants and emits state changes, then project those changes asynchronously into one or more read-optimized views tailored to specific query patterns.

**Applicability:** Use when read and write workloads differ significantly in volume, shape, or scaling needs, or when multiple query patterns require views that do not map naturally to the write schema. Avoid for simple CRUD domains where a single model serves both paths without contention.

- Dimensions: `efficient`, `flexible`
- Enables:
    - **scalability** — Read and write workloads scale independently, allowing each side to match its actual demand profile.
    - **throughput** — Read models use denormalized, query-optimized structures that serve high fan-out without burdening the write path.
    - **performance** — Queries hit purpose-built projections instead of traversing a normalized write model, reducing join depth and index contention.
    - **extensibility** — New read models can be projected from the same event or change stream without modifying command-side logic.
    - **responsiveness** — Asynchronous projection keeps the write path fast by deferring view updates to background consumers.
- Trade-offs (costs):
    - **eventual-consistency** — Read models lag behind the write model by the projection delay, which can range from milliseconds to seconds under load.
    - **code-complexity** — Teams maintain two distinct data models, projection logic, and synchronization plumbing instead of one shared schema.
    - **operability** — Projection pipelines, consumer lag dashboards, and rebuild tooling add operational surface area.
    - **observability** — Monitoring projection lag, data drift, and consumer health is critical for maintaining trust in the read models.
- Related requirements: handle-sudden-increase-in-traffic, crm-data-synchronization
- Related approaches: event-sourcing
- Source: https://quality.arc42.org/approaches/cqrs

### Data Replication

*Also known as: Read Replicas*

**Intent:** Keep copies of data on independent nodes so reads and writes survive node loss and can be served close to the user.

**Mechanism:** A write to one replica propagates to the others, synchronously (the write waits for acknowledgement) or asynchronously (it returns first, replicas catch up). A consistency protocol such as quorum or consensus decides when a read sees a write.

**Applicability:** Use when data must survive node or zone failure, or reads must scale or sit near users. Skip when a single node's durability suffices, or the staleness and write-latency costs of staying in sync outweigh the benefit.

- Dimensions: `reliable`, `efficient`
- Enables:
    - **availability** — Reads and writes continue against a surviving replica when a node fails.
    - **durability** — Copies on independent nodes survive the loss of any single node or disk.
    - **scalability** — Read replicas spread read load across copies, raising read throughput beyond one node.
- Trade-offs (costs):
    - **consistency** — Replicas diverge between updates. Strong consistency coordinates every write across replicas — slower, and unavailable under partition; relaxing to eventual consistency returns fast but can serve stale reads. This is the CAP/PACELC tradeoff.
    - **latency** — Synchronous replication holds each write until enough replicas acknowledge, so write latency tracks the slowest quorum member, and a geographically distant replica adds round-trip time to every committed write.
    - **cost** — Every replica multiplies storage, and cross-region replication adds continuous network transfer; N copies cost roughly N times the storage plus the bandwidth to keep them current.
- Related requirements: replication-and-quorum-failure-transparency, available-7-24-99, zone-failure-no-service-interruption
- Related approaches: n-version-redundancy
- Source: https://quality.arc42.org/approaches/data-replication

### Database Sharding

**Intent:** Scale a database horizontally by partitioning one logical dataset into multiple shards so that storage growth, write load, and targeted query traffic no longer hit the limits of a single database server or cluster.

**Mechanism:** Choose a shard key that matches dominant access patterns, partition the data horizontally by range, hash, or directory mapping, route each request to the owning shard through a router or metadata service, replicate each shard independently for durability, and reshard online when data volume or key distribution changes.

**Applicability:** Use when a single database instance or replica set is no longer sufficient for dataset size, write throughput, or sustained hot-key traffic after schema tuning, indexing, caching, and read replicas have been exhausted. Avoid when the workload depends on frequent cross-shard joins, multi-shard transactions, or global uniqueness constraints that dominate the traffic profile.

- Dimensions: `efficient`, `reliable`
- Enables:
    - **scalability** — Read and write load can be spread across multiple shards instead of concentrating on one database node or cluster.
    - **capacity** — Total data volume can grow beyond the storage, memory, and index limits of a single server.
    - **throughput** — Targeted operations can execute in parallel on different shards, increasing aggregate cluster throughput.
    - **availability** — When each shard is independently replicated, a shard failure can be isolated to only the data or tenants on that shard instead of stopping the whole dataset.
    - **distributability** — Data can be placed across multiple nodes or regions based on key ranges or placement rules.
- Trade-offs (costs):
    - **consistency** — Cross-shard transactions, joins, and global constraints require extra coordination and are often slower or weaker than single-shard operations.
    - **code-complexity** — Applications and routing layers must understand shard keys, fan-out behavior, online migration, and failure handling.
    - **operability** — Resharding, balancing, hotspot detection, and per-shard backup or restore add substantial operational surface area.
    - **latency** — Queries that do not include the shard key can fan out to many shards and become slower than the same query on a single well-indexed database.
- Related requirements: respond-to-15000-requests-per-workday, data-throughput-for-visual-test-system, handle-sudden-increase-in-traffic
- Source: https://quality.arc42.org/approaches/database-sharding

### Defer Binding

*Also known as: Late Binding, Binding Time, Deferred Binding*

**Intent:** Postpone the moment a choice is fixed — which implementation, which value — from source-code time toward build, deployment, startup, or runtime.

**Mechanism:** Replace a hard-coded dependency with a binding point resolved later: read a value from an environment variable or resource file at startup, select an implementation by configuration, route through a broker or service lookup, or dispatch via polymorphism. The later the binding, the less a change costs.

**Applicability:** Defer a binding when the choice varies by environment, customer, or deployment, or must change without a rebuild — endpoints, credentials, feature switches, pluggable strategies. Bind early for choices that never vary or are performance-critical: late binding adds indirection and moves errors from compile time to runtime.

- Dimensions: `flexible`, `maintainable`
- Enables:
    - **configurability** — Values and choices move into configuration read at deploy or startup, so behaviour changes without touching source.
    - **adaptability** — One build adapts to each environment — endpoints, credentials, feature switches — by reading its late-bound settings.
    - **evolvability** — Swapping an implementation behind a binding point — polymorphism, plugin, service lookup — changes behaviour without editing callers.
    - **portability** — Environment-specific values held in variables or resource files let one artifact run unchanged across dev, test, and production.
- Trade-offs (costs):
    - **debuggability** — The concrete choice no longer appears in source. Tracing a fault means reconstructing which value or implementation was actually bound — reading environment, config files, and wiring at the real binding time, not the code.
    - **reliability** — A choice fixed at runtime escapes compile-time checking. A missing variable, a typo'd config key, or an absent plugin surfaces as a startup or runtime failure that a hard-coded value would have caught at build.
- Related requirements: configurable-ui-theme, change-cloud-provider, localizable-to-n-languages
- Related approaches: reduce-coupling
- Source: https://quality.arc42.org/approaches/defer-binding

### Encryption at Rest + in Transit

**Intent:** Protect data confidentiality and integrity by applying cryptographic protection both when data is stored (at rest) and when it moves between components (in transit), ensuring that unauthorized access to storage media or network traffic does not expose plaintext.

**Mechanism:** Encrypt data at rest using storage-level, database-level, or application-level encryption with current, well-vetted algorithms and keys managed through a dedicated key-management system; encrypt data in transit using TLS 1.2+ with strong configurations; implement automated key rotation on a defined schedule and support re-encryption of stored data without downtime where the storage mechanism requires it.

**Applicability:** Use for any data classified as sensitive, personal, financial, or regulated — the default should be to encrypt rather than to justify why encryption is needed. Avoid only for data that is genuinely public and where the performance overhead is prohibitive and measurably impactful (for example, high-throughput video streaming of public content).

- Dimensions: `secure`
- Enables:
    - **confidentiality** — Data is unreadable without the corresponding decryption key, whether stored on disk or intercepted on the network.
    - **data-integrity** — Authenticated encryption (AEAD) modes detect ciphertext tampering at decryption time; full-disk and TDE setups often use unauthenticated modes (AES-XTS) that provide no integrity protection.
    - **data-protection** — Cryptographic protection is a primary technical control for safeguarding personal and sensitive data at every stage of its lifecycle.
    - **privacy** — Encryption limits exposure of personal data to authorized processors, supporting data-protection-by-design requirements.
    - **compliance** — Regulatory frameworks (GDPR, PCI DSS, HIPAA) mandate or strongly recommend encryption as a baseline control for sensitive data.
- Trade-offs (costs):
    - **performance** — On modern CPUs with hardware AES acceleration (AES-NI), raw crypto overhead is often negligible; the real performance cost comes from TLS handshake latency on short-lived connections and from re-encryption operations during key rotation on large datasets.
    - **operability** — Key lifecycle management — generation, distribution, rotation, revocation, and disaster recovery of keys — adds significant operational complexity.
    - **code-complexity** — Application code must handle key references, envelope encryption, and graceful re-encryption during key rotation without downtime.
- Related requirements: encrypted-storage, zero-knowledge-data-storage, personal-data-lifecycle-protection
- Source: https://quality.arc42.org/approaches/encryption-at-rest-and-in-transit

### Event Sourcing

**Intent:** Persist every state change as an immutable event; the log is the system of record, and any state derives from replaying it.

**Mechanism:** Commands rehydrate an aggregate from its past events, validate invariants, and append new events instead of overwriting state. Projections subscribe to the log and maintain read-optimized views; replaying from the start rebuilds any view.

**Applicability:** Use when history is a first-class requirement: audit trails, temporal queries, retroactive corrections, many evolving read models. Skip for simple CRUD domains, teams new to the pattern under deadline pressure, or data with strict erasure duties and no key-shredding plan.

- Dimensions: `flexible`
- Enables:
    - **auditability** — The append-only log is a complete, ordered record of every state change — the audit trail is the system of record, not a copy.
    - **traceability** — Every current value traces back to the exact sequence of domain events that produced it.
    - **evolvability** — New read models derive retroactively from the full history, long after the original events were recorded.
    - **recoverability** — Replaying the log rebuilds corrupted or lost derived state; a fixed handler replays history to repair the damage it caused.
    - **debuggability** — Replaying events up to a chosen point reproduces the exact state in which a defect occurred.
- Trade-offs (costs):
    - **maintainability** — Event schemas last forever: every version ever written must stay replayable, so the team maintains upcasters or versioned handlers for years. A simple field rename becomes a migration of the readers, not of the data.
    - **eventual-consistency** — Queries run against projections that lag the log. A client that writes and immediately reads sees the old value unless the team builds read-your-own-writes mechanics on top.
    - **privacy** — Erasure obligations (GDPR Art. 17) clash with an immutable log. Crypto-shredding — deleting a per-subject encryption key — restores erasability, at the cost of key management and encrypted payloads that plain CRUD storage never needs.
    - **performance** — State is computed, not read: loading an aggregate replays its events. Long-lived aggregates need snapshots, and the log grows without bound unless archiving is designed in from the start.
- Related requirements: every-data-modification-is-logged, detailed-audit-log
- Related approaches: event-driven-architecture
- Source: https://quality.arc42.org/approaches/event-sourcing

### Event-Driven Architecture

**Intent:** Connect components through asynchronous events so producers publish facts without knowing their consumers, and new behavior attaches by subscription instead of modification.

**Mechanism:** Components publish events — immutable records of completed state changes — to a broker. Subscribed consumers react independently with their own logic and may emit further events. The producer's responsibility ends at publication; routing, fan-out, and delivery belong to the broker, so the consumer set changes freely.

**Applicability:** Use when several consumers react to the same business facts, integrations change often, and bounded staleness is acceptable. Skip when the caller needs an immediate, strongly consistent answer in the request path, or when so few components interact that a broker adds more moving parts than it removes.

- Dimensions: `flexible`, `operable`
- Enables:
    - **loose-coupling** — The dependency points one way: consumers depend on the event schema, while producers hold no reference to any consumer.
    - **extensibility** — New capabilities attach as additional subscribers to existing events; the producing service and its current consumers stay untouched.
    - **evolvability** — Event contracts outlive individual services: implementations change or get replaced behind a stable stream without coordinated rewrites.
    - **autonomy** — Each consumer reacts with its own logic and data, and keeps working from already-received events while peers are down.
    - **integrability** — A new system integrates by subscribing to the existing event stream; producers need no adapter code and no release.
- Trade-offs (costs):
    - **eventual-consistency** — Consumers learn about a state change only when its event reaches them, so parts of the system disagree for the propagation interval. Reads issued mid-propagation return stale data — acceptable for a search index, hazardous for a balance check.
    - **understandability** — End-to-end behavior is written down nowhere: it emerges from which consumers subscribe to which events. Answering 'what happens when an order is placed?' takes an inventory of subscriptions across services, and the answer silently changes whenever any team adds one.
    - **debuggability** — One business flow becomes a chain of events across broker hops, retries, and consumers. Reconstructing why something happened — or failed to happen — needs correlation IDs propagated through every event and traces collected from every participant.
- Related requirements: service-loose-coupling-change-blast-radius, add-new-product
- Related approaches: asynchronous-messaging
- Source: https://quality.arc42.org/approaches/event-driven-architecture

### Externalized Business Rules

*Also known as: Rule Engine, Decision Tables*

**Intent:** Move volatile decision logic out of application code into declarative, separately deployed rules, so policy changes ship without touching or redeploying the application.

**Mechanism:** The application sends input facts to a rule engine; the engine evaluates a declarative decision model — decision tables, DMN with FEEL expressions, or policy rules — and returns the outcome plus the rules that fired. The decision model is versioned, tested, and deployed on its own cadence.

**Applicability:** Use for decision logic that changes faster than the codebase — pricing, eligibility, risk scoring, routing, compliance — especially when domain experts own the policy. Skip for stable logic, decisions needing complex data access mid-evaluation, or teams unwilling to govern a second artifact lifecycle.

- Dimensions: `flexible`
- Enables:
    - **changeability** — Pricing, eligibility, and routing rules change by editing the decision model; the application code and its release cycle stay untouched.
    - **adaptability** — Different markets, regions, or tenants run different rule sets against the same application binary.
    - **time-to-market** — A policy update ships on the decision model's own deployment cadence instead of waiting for the next application release train.
    - **explainability** — The engine reports which rules fired for a decision, giving case workers and auditors a concrete explanation per outcome.
    - **auditability** — Versioned decision models record which policy was in force when; each decision links to the exact rule version that produced it.
- Trade-offs (costs):
    - **maintainability** — The rule base becomes a second programming environment with its own versioning, review, and deployment discipline. The promise that business users maintain rules rarely survives production — developers usually end up owning both worlds, plus the engine.
    - **testability** — Rules bypass the application's test suite. Without a dedicated harness that runs every decision table against expected outcomes, a rule edit reaches production with less scrutiny than any code change.
    - **debuggability** — A wrong outcome emerges from the interplay of matching rules, hit policies, and evaluation order. Tracing why a rule fired — or silently lost to a higher-priority one — requires engine-specific tooling.
    - **performance** — Every decision call pays engine-evaluation overhead, plus a network hop when rules run as a separate decision service on the request path.
- Related requirements: annual-tax-update, governance-policy-enforcement
- Source: https://quality.arc42.org/approaches/externalized-business-rules

### Fail-Safe Defaults

**Intent:** Ensure that when a system encounters an unexpected condition — unknown input, missing configuration, corrupted state, or unhandled error — it transitions to a predefined safe state rather than continuing in an undefined or hazardous mode.

**Mechanism:** Define an explicit safe-state configuration for every component and operational mode; treat all unrecognized inputs, permissions, and conditions as denied or invalid by default; on detecting an anomaly that exceeds defined tolerance, transition the system to the safe state and signal operators.

**Applicability:** Use wherever the consequences of continuing in an unknown state are worse than stopping or restricting the system — safety-critical controllers, access-control systems, financial transaction processing, and infrastructure with high blast radius. Avoid when maximum availability matters more than safety and the domain tolerates best-effort behavior under uncertainty.

- Dimensions: `safe`, `reliable`
- Enables:
    - **safety** — The system transitions to a predefined safe state rather than continuing in an unknown or hazardous condition.
    - **fault-tolerance** — Unrecognized or unexpected inputs are rejected by default, preventing faults from propagating into undefined behavior.
    - **fail-safe** — By design, every failure path ends in a known-safe configuration rather than an open or permissive one.
    - **robustness** — The system handles unexpected conditions — missing configuration, corrupted state, unknown inputs — without entering a dangerous mode.
    - **predictability** — Operators and safety engineers can reason about worst-case behavior because all unhandled paths converge on a documented default state.
    - **controllability** — The predefined safe state keeps the system in a condition that operators or automated recovery logic can act on.
- Trade-offs (costs):
    - **availability** — Transitioning to a safe state often means halting or heavily restricting service, reducing availability until the issue is resolved.
    - **graceful-degradation** — A hard safe-state transition shuts down functionality abruptly rather than shedding load gradually; the system is safe but not incrementally useful.
    - **recoverability** — Returning from a safe state may require manual intervention, diagnostic inspection, or a restart sequence, increasing recovery time.
- Related requirements: shutdown-to-safe-state, circuit-breaker-failure-transparency
- Source: https://quality.arc42.org/approaches/fail-safe-defaults

### Feature Degradation

**Intent:** Shed non-essential features when a dependency or resource fails, so the system preserves its core function instead of failing whole.

**Mechanism:** Rank features by criticality, watch per-dependency health signals, and disable or simplify non-essential features when a signal crosses its threshold, re-enabling them once health recovers.

**Applicability:** Use when a system has a clear critical core and optional features that can be dropped under stress, and partial service beats none. Skip when every feature is essential or a degraded result is unsafe.

- Dimensions: `reliable`, `usable`
- Enables:
    - **graceful-degradation** — This is the concrete tactic behind the graceful-degradation quality: shed non-essential features so core function survives a partial failure.
    - **availability** — Keeping the core path serving a reduced feature set avoids a full outage when a dependency or capacity limit is hit.
    - **resilience** — Disabling the features bound to a failing dependency contains the fault instead of letting it spread to the core.
    - **recoverability** — Degraded mode holds the system up while failed dependencies recover, then features re-enable as health returns.
- Trade-offs (costs):
    - **usability** — Users see a thinner experience; without clear signalling they may read missing features as broken, raising support load and eroding trust.
    - **consistency** — Serving cached or default values during degradation lets different users see divergent data until the dependency recovers and caches refill.
    - **code-complexity** — Each degradable feature needs a fallback path, a health signal, and re-enable logic, multiplying the states the team must build and test.
- Related requirements: handle-sudden-increase-in-traffic, zone-failure-no-service-interruption, server-fails-operation-without-downtime
- Source: https://quality.arc42.org/approaches/feature-degradation

### Feature Toggles

**Intent:** Decouple code deployment from feature release by wrapping new behavior behind a runtime-configurable flag.

**Mechanism:** Wrap new or risky code paths in a conditional check against a toggle store (configuration file, database, or feature-flag service), allowing the switch to be flipped per environment, user cohort, or percentage rollout without a redeployment.

**Applicability:** Use when merging incomplete features to the main branch (trunk-based development), conducting canary releases or A/B tests, or providing a fast kill switch for risky changes. Give release, experiment, and ops toggles an explicit expiry date and treat overdue ones as technical debt; only permission toggles are long-lived by design.

- Dimensions: `flexible`, `operable`
- Enables:
    - **deployability** — Allows code deployment independently from feature release timing.
    - **flexibility** — Controls behavior at runtime by cohort, environment, or rollout percentage.
    - **testability** — Supports safe experiments and canary rollout validation in production.
    - **changeability** — Decouples implementation changes from immediate user exposure.
    - **modifiability** — Localizes behavior changes to specific conditional paths without affecting core logic.
- Trade-offs (costs):
    - **maintainability** — Toggles that outlive their purpose create technical debt and dead paths; only permission toggles are long-lived by design.
    - **code-complexity** — Branching logic multiplies execution paths and test effort.
    - **reliability** — Inconsistent flag evaluation can produce incoherent behavior.
    - **observability** — Monitoring which users see which toggle state adds operational logging overhead.
- Related requirements: fast-deployment, fast-rollout-of-changes
- Source: https://quality.arc42.org/approaches/feature-toggles

### Fine-Grained Authorization (RBAC/ABAC)

**Intent:** Authorize each request against explicit policies for actor, action, resource, and context so that only permitted operations are allowed, even inside shared, multi-tenant, or highly regulated systems.

**Mechanism:** Model permissions as action-resource policies, assign stable baseline entitlements via roles where appropriate, refine decisions with attributes such as tenant, ownership, classification, region, time, device state, or workflow status, evaluate at every business operation with deny-by-default semantics, and log the policy, subject, resource, and outcome for audit.

**Applicability:** Use when coarse roles alone are insufficient, especially in multi-tenant products, delegated administration, approval workflows, regulated data access, and systems with record-level or context-dependent permissions. Prefer RBAC alone when the permission model is stable and simple; introduce ABAC when context materially changes access and role explosion would otherwise dominate.

- Dimensions: `secure`
- Enables:
    - **security** — Fine-grained authorization is a core security control that limits what authenticated actors can do, reducing the impact of compromised accounts and insider threats.
    - **access-control** — Decides permission per actor, action, resource, and context instead of relying on coarse endpoint visibility or UI hiding.
    - **confidentiality** — Prevents users and services from reading records outside their tenant, ownership scope, clearance, or purpose of use.
    - **integrity** — Blocks unauthorized state changes such as modifying salaries, approvals, or regulated records without the required entitlements.
    - **compliance** — Regulatory frameworks (GDPR, PCI DSS, HIPAA, SOX) require demonstrable, auditable access restrictions at the data and action level.
    - **policy-enforcement** — Central policy definitions can be evaluated consistently across APIs, services, and data-access paths.
    - **auditability** — Decision logs can record who attempted which action on which resource, under which policy, and with what result.
- Trade-offs (costs):
    - **code-complexity** — Action and resource modeling, policy composition, exception handling, and authorization tests grow quickly as the domain expands.
    - **operability** — Roles, attributes, policy versions, and attribute sources need ownership, rollout discipline, monitoring, and regular review.
    - **latency** — Remote policy evaluation and attribute lookups add per-request overhead unless bounded by careful caching and freshness rules.
    - **usability** — Legitimate work is blocked when roles or attributes are incomplete, stale, or modeled too narrowly.
- Related requirements: access-control-is-enforced, employee-attempts-to-modify-pay-rate, confidentiality-by-multitenance, governance-policy-enforcement
- Source: https://quality.arc42.org/approaches/fine-grained-authorization

### Hexagonal Architecture

*Also known as: Ports and Adapters, Clean Architecture*

**Intent:** Keep domain logic at the center, free of technology; all infrastructure connects through ports the core owns.

**Mechanism:** The domain core defines ports — interfaces for everything that drives it or that it drives. Adapters implement them for concrete technology: UIs and tests call in, databases and brokers are called through. Source-code dependencies point only inward.

**Applicability:** Use when domain logic is rich enough to outlive its frameworks, when infrastructure must stay swappable, or the core must test without I/O. Skip for thin CRUD services and short-lived tools — the indirection and mapping tax exceeds the logic it protects.

- Dimensions: `maintainable`, `flexible`
- Enables:
    - **testability** — The core runs in plain unit tests — no database, broker, or framework; fakes implement the ports.
    - **evolvability** — Frameworks, databases, and delivery mechanisms change at the adapter rim; the domain core outlives them.
    - **loose-coupling** — Core and infrastructure share only the port interfaces the core owns; neither knows the other's internals.
    - **modularity** — Ports draw an explicit, compiler-enforced boundary between domain and technology modules.
- Trade-offs (costs):
    - **simplicity** — Every infrastructure touchpoint costs an interface, an adapter, and often a mapping between domain and persistence models. In CRUD-heavy services this machinery outweighs the logic it protects — three artifacts changing in lockstep for every added field.
    - **understandability** — Indirection hides the concrete path: finding where a request actually hits the database means traversing port, adapter, and wiring code. Newcomers and IDE navigation pay for the inversion on every traced call.
- Related requirements: independent-replacement-of-subsystem, change-cloud-provider, quick-unit-tests
- Related approaches: plugin-architecture
- Source: https://quality.arc42.org/approaches/hexagonal-architecture

### Increase Cohesion

*Also known as: Split Module, Redistribute Responsibilities, Increase Semantic Coherence*

**Intent:** Group each module around a single, related responsibility, so a change to that responsibility stays inside one module.

**Mechanism:** Two tactics raise cohesion. Split a module: when a module carries responsibilities that change for different reasons, break it into smaller modules that each serve one purpose. Redistribute responsibilities: when one responsibility is scattered across modules, gather its pieces into a single module.

**Applicability:** Apply when a module changes for several unrelated reasons, when one concern is smeared across many modules, or when a class has grown too large to hold in your head. Splitting cohesive, stable code that already changes as a unit only adds boundaries.

- Dimensions: `maintainable`, `flexible`
- Enables:
    - **modularity** — Grouping one responsibility per module is what gives a decomposition meaningful, self-contained parts.
    - **analysability** — A module that does one thing is understood by reading it alone — its behaviour isn't scattered across the codebase.
    - **modifiability** — When a responsibility lives in one place, a change to it touches one module instead of several.
    - **testability** — A single-purpose module has fewer reasons to change and a smaller interface to exercise, so tests stay focused.
- Trade-offs (costs):
    - **loose-coupling** — Splitting one module into cohesive pieces multiplies the interfaces between them. Pushed past the point of genuine separation, it trades an internal tangle for a web of inter-module calls — cohesion bought with coupling.
    - **simplicity** — More, smaller modules mean more files, names, and boundaries to hold in mind. A reader chasing one feature now hops across several modules instead of scrolling through one.
- Related requirements: adding-entity-type-within-5-days, monolith-loose-coupling-change-blast-radius, assess-impact-of-proposed-change
- Source: https://quality.arc42.org/approaches/increase-cohesion

### Input Sanitization / Output Encoding

**Intent:** Neutralize untrusted data at every system boundary so that user-controlled input cannot be interpreted as executable code, query logic, or markup in any downstream context.

**Mechanism:** Validate all input against strict schemas (type, length, format, allowed characters) and reject what does not conform; encode all output for its specific rendering context (HTML entity encoding, SQL parameterization, shell escaping, URL encoding) so that data is always treated as data, never as code.

**Applicability:** Use at every trust boundary where untrusted data enters or leaves the system — HTTP request parameters, file uploads, message payloads, database queries, HTML rendering, shell commands, log entries. Particularly critical for web applications, public APIs, and any system that processes user-generated content. No system that accepts external input is exempt.

- Dimensions: `secure`
- Enables:
    - **security** — Neutralizing untrusted data at system boundaries prevents the most common attack classes — injection, cross-site scripting, and command execution.
    - **integrity** — Data stores and downstream systems are protected from corruption caused by malicious payloads embedded in user input.
    - **robustness** — The system handles malformed, unexpected, or adversarial input without crashing, entering undefined states, or leaking internal details.
    - **data-integrity** — Stored data remains clean because malicious content is rejected or neutralized before it reaches the persistence layer.
    - **compliance** — OWASP ASVS and PCI DSS require input validation and output encoding as mandatory controls.
- Trade-offs (costs):
    - **performance** — Validation, parsing, and encoding at every trust boundary add processing overhead per request, especially for large payloads or complex schemas.
    - **usability** — Strict validation can reject legitimate input that does not match expected patterns (for example international names, special characters in free-text fields).
    - **code-complexity** — Every input path and every output context (HTML, SQL, shell, JSON, URL) requires its own encoding strategy, and missing a single path creates a vulnerability.
- Related requirements: protect-data-by-security-procols, public-api-intrusion-attempts-blocked, access-control-is-enforced
- Source: https://quality.arc42.org/approaches/input-sanitization-output-encoding

### Least Privilege

*Also known as: Limit Access*

**Intent:** Grant every actor and process only the minimum permissions required for its specific function, so that a compromise or error in one part of the system cannot escalate into broader unauthorized access.

**Mechanism:** Assign permissions and policies based on the specific actions each actor or process needs to perform; default to deny-all and grant explicit, scoped permissions; enforce at every trust boundary — API gateway, service-to-service call, database connection, filesystem access — and review regularly to revoke permissions that are no longer needed.

**Applicability:** Use as a foundational security principle in any system that handles sensitive data or exposes operations with significant impact. Particularly critical in multi-tenant systems, systems under regulatory oversight, and environments with many service-to-service integrations. The principle applies at every layer: user roles, service accounts, database grants, cloud IAM policies, and container security contexts.

- Dimensions: `secure`
- Enables:
    - **security** — Reducing the permissions available to any actor or process limits the damage an attacker can do after compromising that actor.
    - **confidentiality** — Actors can only read data they are explicitly authorized for, preventing inadvertent or malicious disclosure.
    - **integrity** — Write permissions are scoped narrowly, so a compromised process cannot modify resources outside its designated scope.
    - **access-control** — Every actor operates with the minimum set of permissions required for its function, enforced at runtime.
    - **compliance** — Regulatory frameworks (GDPR, PCI DSS, SOX) require demonstrable access restriction as a baseline control.
- Trade-offs (costs):
    - **usability** — Users encounter permission-denied errors more frequently when permissions are tightly scoped, increasing friction and support requests.
    - **operability** — Managing many fine-grained permissions, policies, and exception paths across environments requires dedicated tooling and regular access reviews.
    - **code-complexity** — Application code must propagate and check scoped credentials at every boundary rather than relying on broad service accounts.
- Related requirements: access-control-is-enforced, employee-attempts-to-modify-pay-rate, governance-policy-enforcement
- Related approaches: fine-grained-authorization
- Source: https://quality.arc42.org/approaches/least-privilege

### Limit Event Response

**Intent:** Process arriving events only up to a set maximum rate, queuing or discarding the excess, so processing stays predictable under overload.

**Mechanism:** Place a rate limiter and a bounded queue in front of the handler. Service events up to the configured rate, hold the surplus in the queue, and shed or back-pressure once the queue is full.

**Applicability:** Use when event arrival is outside your control and bursts can outrun capacity. Skip when every event must be processed and none may be delayed or dropped, where adding capacity fits better than bounding the rate.

- Dimensions: `efficient`, `reliable`
- Enables:
    - **stability** — Processing at a bounded rate keeps the system inside its stable operating range even when arrivals spike past capacity.
    - **time-behaviour** — A fixed maximum response rate makes processing time predictable for the events that are serviced.
    - **resource-efficiency** — Capping work per interval bounds CPU, memory, and I/O regardless of how fast events arrive.
    - **energy-efficiency** — Servicing fewer events per interval under load lowers the energy spent on surplus work.
- Trade-offs (costs):
    - **latency** — Excess events wait in a queue rather than process at once, so under sustained overload queued events see growing delay — the bounded rate trades per-event latency for a predictable, survivable processing rate.
    - **availability** — When the queue fills and overflow is discarded, those callers get no response and the service looks unavailable to them; the drop policy must separate sheddable events from ones that must not be lost.
- Related requirements: handle-sudden-increase-in-traffic, respond-to-15000-requests-per-workday, reduce-energy-consumption-with-new-version
- Source: https://quality.arc42.org/approaches/limit-event-response

### Manage Event Arrival

*Also known as: Service-Level Agreement*

**Intent:** Cap or shape the rate at which events reach a component, so it only accepts work it can serve within its operating range.

**Mechanism:** Agree a maximum arrival rate with each event source — often as a service-level agreement — and pace, batch, or reject events at the boundary so the inflow stays at or below that rate.

**Applicability:** Use when event sources are known and contractable, and an agreed input ceiling keeps the system efficient and stable. Skip when arrival is intrinsically unbounded or anonymous — public internet traffic, DDoS — where edge rate limiting or admission control fits better than a negotiated rate.

- Dimensions: `efficient`, `reliable`
- Enables:
    - **latency** — Capping arrival keeps queues short, so per-event latency stays predictable instead of climbing as load builds.
    - **resource-efficiency** — Accepting fewer events per interval means less work, freeing CPU, memory, and I/O for the load that matters.
    - **energy-efficiency** — Doing less work when the inflow is capped directly lowers energy draw, the same lever used for performance.
    - **stability** — Bounding the input rate prevents overload, keeping the system inside the operating range where its behavior stays stable.
- Trade-offs (costs):
    - **throughput** — An arrival cap is a hard ceiling. A legitimate burst the system could actually absorb is still refused once it crosses the agreed rate, so spare capacity sits idle unless the rate is renegotiated or made adaptive.
    - **availability** — Sources whose events exceed the cap are rejected or delayed; from their side the service looks unavailable. Size the rate against real load patterns, or the cap sheds valid traffic and pushes back-pressure onto producers.
- Related requirements: respond-to-15000-requests-per-workday, reduce-energy-consumption-with-new-version
- Source: https://quality.arc42.org/approaches/manage-event-arrival

### Microservice Architecture

*Also known as: Microservices*

**Intent:** Structure the system as independently deployable services around business capabilities, each owned by one team and free to scale, fail, and evolve alone.

**Mechanism:** Each service implements one business capability, owns its data store, and talks to peers over the network — synchronous APIs or asynchronous events. A gateway fronts the landscape; services deploy, scale, and fail independently, coordinated by contracts instead of shared code or databases.

**Applicability:** Use when several teams need independent delivery cadence, parts of the system scale very differently, or domains demand different stacks. Skip for single-team products, unclear domain boundaries, or organizations without automated deployment and observability — there the premium exceeds the benefit.

- Dimensions: `flexible`, `operable`
- Enables:
    - **deployability** — Each service ships alone behind stable contracts; a release touches one pipeline, not a coordinated train.
    - **scalability** — Hot services scale out independently — the catalog scales to read traffic without touching checkout.
    - **evolvability** — A service changes its stack, data model, or internals freely while its contract holds.
    - **autonomy** — One team owns each service end to end — build, run, and decide — limiting cross-team coordination.
    - **fault-isolation** — A crashing service takes only its capability down — provided callers guard themselves with timeouts, circuit breakers, and fallbacks.
- Trade-offs (costs):
    - **simplicity** — Every call between capabilities becomes a network call with discovery, retries, and versioned contracts. The moving-parts count — pipelines, brokers, dashboards per service — grows with the service count: the 'microservices premium' that small systems never recoup.
    - **consistency** — Data lives in many stores; transactions across services give way to sagas and eventual consistency. Invariants one database used to enforce now need compensation logic and reconciliation.
    - **latency** — In-process calls become network hops; a request fanning out across five services stacks their latencies and tail effects.
    - **debuggability** — One business flow spans many services, brokers, and retries. Without distributed tracing and correlated logs, reconstructing a failure is archaeology across team boundaries.
- Related requirements: deploy-to-production-within-15-minutes, scale-up-in-2-minutes
- Related approaches: self-contained-systems
- Source: https://quality.arc42.org/approaches/microservice-architecture

### N-Version Redundancy and Voting

*Also known as: Voting, Masking, Triple Modular Redundancy, TMR, N-Modular Redundancy*

**Intent:** Run a computation on several redundant components and vote on their outputs, so a single faulty result is detected or masked.

**Mechanism:** N components compute the same result from the same input. A voter compares outputs and forwards the majority (TMR masks one fault) or flags a mismatch. N-version uses independently built implementations to resist common design faults.

**Applicability:** Use for high-integrity or safety-critical computation where a wrong output is unacceptable and the N-fold cost is justified. Skip for ordinary services where failover or retry handles faults more cheaply.

- Dimensions: `reliable`, `safe`
- Enables:
    - **integrity** — Comparing redundant results detects a corrupted or wrong output before it propagates.
    - **fault-tolerance** — A majority vote masks a single faulty component, so its error never reaches the output.
    - **correctness** — With independently built versions, a design fault in one is outvoted by the others.
- Trade-offs (costs):
    - **cost** — Running N replicas multiplies compute — three-fold for TMR. Achieving genuine fault independence through N-version diversity also multiplies development effort, since each version must be built separately to avoid shared faults.
    - **latency** — The voter cannot decide until enough replicas return, so response time tracks the slowest replica plus the comparison step, not the fastest.
    - **maintainability** — Each independent version is separate code to specify, build, test, and keep in step as requirements change; the voter and its comparison rules add still more to own.
- Related requirements: transaction-processing-faultlessness
- Source: https://quality.arc42.org/approaches/n-version-redundancy

### Open Host Service

*Also known as: Published Language*

**Intent:** Expose one well-defined protocol in a documented shared language, so any number of consumers integrate without bespoke per-consumer translation.

**Mechanism:** The upstream context publishes one service interface expressed in a published language: a documented, versioned shared model such as an OpenAPI or event schema. A translation layer maps the internal domain model to this language, so internal types never appear on the wire.

**Applicability:** Use when one context serves many or unknown downstream consumers and bespoke per-consumer integration stops scaling. Skip with one or two known consumers — a direct contract, with an anti-corruption layer on the consumer side, is cheaper.

- Dimensions: `flexible`, `operable`
- Enables:
    - **interoperability** — Host and consumers exchange information through one documented shared model, so data means the same on both sides of every integration.
    - **integrability** — New consumers integrate against the published protocol and its documentation alone, with no bespoke contract negotiated with the host team.
    - **loose-coupling** — Consumers couple to the published language only; the host's internal domain model stays invisible behind the translation layer.
    - **evolvability** — The host refactors its internal model freely; only the translation layer absorbs the change.
- Trade-offs (costs):
    - **changeability** — The published language ossifies: every revision must be versioned and coordinated across all consumers, known and unknown. The public contract evolves on the slowest consumer's schedule, and renamed or removed concepts linger for years as deprecated baggage.
    - **maintainability** — The team owns two models permanently — the internal one and the published one — plus the translation between them. Every internal refactoring adds mapping work, and drift between the two models surfaces as subtle translation bugs.
    - **simplicity** — A general-purpose language for unknown consumers costs more than a point-to-point integration: schema, documentation, versioning and deprecation policy must exist before the second consumer does. With only one or two known consumers, that machinery is pure overhead.
- Related requirements: service-loose-coupling-change-blast-radius
- Related approaches: api-gateway, event-sourcing
- Source: https://quality.arc42.org/approaches/open-host-service

### Plugin Architecture

*Also known as: Microkernel, Add-in Architecture*

**Intent:** Let third parties or independent teams extend system behavior without modifying or redeploying its core.

**Mechanism:** Define a stable extension point (API, interface, or event bus) in the core; plugins register themselves at startup or runtime, and the host invokes them through the shared contract.

**Applicability:** Use when the capability set varies or is unknown — third-party extensions, per-customer feature combinations, hardware drivers. Skip when the extension set is small and fixed: a stable public API is permanent work that a handful of known variants never repays.

- Dimensions: `flexible`
- Enables:
    - **extensibility** — New capabilities arrive as plugins against a stable extension point; the core stays closed to modification, open to extension.
    - **modifiability** — A behavior change lands in one plugin behind a contract; the blast radius stops at the extension-point boundary.
    - **configurability** — Per-customer or per-environment feature sets become composition: ship the same core, vary the plugin set.
    - **reusability** — A plugin written once runs in every product and version that hosts the same extension point.
- Trade-offs (costs):
    - **security** — A plugin inherits the host's privileges unless sandboxed; one malicious or compromised third-party extension reads what the host reads and writes what it writes. Marketplace ecosystems carry this as a permanent supply-chain risk.
    - **performance** — Every extension-point call pays indirection — registry lookup, dynamic dispatch, sometimes a process or sandbox crossing. One slow synchronous plugin stalls the host's whole pipeline, and the isolation levels strong enough for safety cost the most latency.
    - **maintainability** — The extension API is a public contract: every change must stay compatible with plugins the team neither owns nor sees. Versioning, deprecation windows, and compatibility test suites become permanent core-team work that grows with the ecosystem.
- Related requirements: compatible-with-5-battery-providers, service-loose-coupling-change-blast-radius, fast-rollout-of-changes
- Related approaches: externalized-business-rules
- Source: https://quality.arc42.org/approaches/plugin-architecture

### Preserve Facts, Derive Interpretations

*Also known as: Facts over State, Semantic Deferral, Business Uncertainty Tolerance*

**Intent:** Preserve business facts independently of their current interpretation so later knowledge can derive new meaning without rewriting history.

**Mechanism:** Capture durable domain observations with provenance, derive statuses and decisions through explicit policies or projections, and retain the lineage needed to reproduce or replace those interpretations later.

**Applicability:** Use where business meaning may evolve or where historical reinterpretation matters. Skip when history has little value or privacy and lifecycle costs outweigh the benefit.

- Dimensions: `flexible`, `maintainable`
- Enables:
    - **evolvability** — Preserved facts support later reinterpretation without rewriting history, keeping semantic change localized.
    - **auditability** — Derived states remain explainable because their source facts and policy versions stay available.
    - **traceability** — Each interpretation can retain lineage to the observations and policies from which it was derived.
    - **analysability** — Explicit facts, provenance, and policy versions make the impact of changing an interpretation easier to assess before modifying the system.
- Trade-offs (costs):
    - **maintainability** — Fact schemas, provenance, policy versions, and projections add concepts that teams must evolve consistently over time.
    - **performance** — Recomputing or replaying interpretations can add read latency or require materialized projections and indexes for operational workloads.
    - **privacy** — Detailed historical facts increase retained personal data and can require explicit retention, erasure, redaction, or crypto-shredding mechanisms.
- Related requirements: reinterpret-domain-concept-from-historical-facts, capture-unresolved-business-semantics-without-structural-commitment
- Related approaches: event-sourcing, defer-binding
- Source: https://quality.arc42.org/approaches/preserve-facts-derive-interpretations

### Progressive Disclosure

**Intent:** Present only the information and controls a user needs right now, revealing more complexity on demand.

**Mechanism:** Organize UI and content into layers — a simple primary layer visible by default, and secondary/expert layers exposed through explicit user actions like expanding sections, hovering, or navigating deeper.

**Applicability:** Use when the full feature set or information space is too large to present at once without overwhelming users. Avoid when users are experts who need the full picture immediately, or when hiding options would create dangerous ambiguity (e.g., in safety-critical controls).

- Dimensions: `usable`
- Enables:
    - **usability** — Reduces cognitive load by showing only primary actions first.
    - **learnability** — Helps new users build confidence before seeing advanced options.
    - **accessibility** — Improves focus by limiting simultaneous controls and information.
    - **user-experience** — Makes complex interfaces feel simpler and less overwhelming.
- Trade-offs (costs):
    - **completeness** — Important details can feel hidden if disclosure levels are too deep.
    - **functionality** — Advanced capabilities may be harder to discover and use quickly.
    - **observability** — Monitoring how users interact with hidden layers requires granular telemetry.
- Related requirements: first-time-onboarding-without-errors, learnability-find-article, user-tries-primary-function
- Source: https://quality.arc42.org/approaches/progressive-disclosure

### Quarantine

*Also known as: Removal from Service*

**Intent:** Detach an unstable or suspect component from live service so its degraded behaviour stops affecting the system while it is diagnosed and repaired.

**Mechanism:** A health signal — rising error rate, latency, resource leak, or flapping — marks an instance suspect. The orchestrator drains its in-flight work, removes it from the serving pool, and holds it out for diagnosis, restart, or repair, then reintroduces it once healthy.

**Applicability:** Use for pooled, replaceable instances behind a load balancer or scheduler, where one can be spared without dropping the service. Skip for a singleton with no replica to cover it, or when the instance holds in-flight state that cannot be drained or migrated first.

- Dimensions: `reliable`, `operable`
- Enables:
    - **availability** — Pulling a degraded instance from the serving pool stops it returning errors or slow responses, so the healthy remainder keeps the service up.
    - **fault-isolation** — Detaching the unstable component contains its faults — a leak, corruption, or flapping — so they cannot spread to healthy request paths.
    - **recoverability** — Quarantine buys a safe window to diagnose, restart, or scrub the component and reintroduce it once healthy.
    - **stability** — Removing a resource-leaking or thrashing instance keeps its degradation from destabilising the rest of the pool.
- Trade-offs (costs):
    - **capacity** — Removing an instance shrinks the serving pool. If quarantine fires under load with no spare to absorb the shortfall, the remaining instances take on its traffic and can saturate — the correlated failure the tactic was meant to prevent.
    - **maintainability** — Health thresholds, drain-and-detach automation, diagnosis hooks, and safe reintroduction are machinery the team builds and tunes. Thresholds set too sensitively pull healthy instances needlessly, so the pool flaps in and out and capacity churns.
- Related requirements: server-fails-operation-without-downtime, production-anomalies-detectable-within-2-minutes
- Related approaches: circuit-breaker, standby-failover
- Source: https://quality.arc42.org/approaches/quarantine

### Rate Limiting

*Also known as: Throttling*

**Intent:** Protect scarce resources by capping request admission per client, identity, tenant, or route over time, so brute-force attempts, abusive automation, and sudden traffic spikes cannot exhaust shared capacity or overwhelm sensitive endpoints.

**Mechanism:** Enforce request budgets as close to ingress as possible using deterministic algorithms such as token bucket or sliding window, keyed by IP address, account, API key, tenant, route, or operation cost as appropriate; apply layered quotas for global traffic, high-risk endpoints, and expensive handlers; reject excess requests immediately with explicit backpressure such as `429 Too Many Requests`, optional `Retry-After`, and structured audit events for tuning and incident response.

**Applicability:** Use on any internet-facing endpoint and any internal API where overload from misuse, retries, or fan-out can exhaust shared resources. Most valuable on authentication, password reset, search, export, and write-heavy endpoints. Do not treat it as the only DDoS control when upstream bandwidth can be saturated before the request reaches the application; pair it with upstream filtering, caching, bulkheads, and autoscaling.

- Dimensions: `secure`, `reliable`
- Enables:
    - **security** — Slows brute-force login attempts, credential stuffing, scraping, and abusive automation before those requests consume expensive application work.
    - **intrusion-prevention** — Blocks or delays suspicious request patterns at the edge instead of merely detecting them after the protected handler has already been reached.
    - **availability** — Preserves worker threads, database connections, and identity-provider capacity by rejecting excess requests before scarce resources are exhausted.
    - **resilience** — Converts overload into explicit, bounded rejection so the system can continue providing an acceptable level of service to legitimate traffic under hostile or accidental surges.
    - **stability** — Bounds queue growth and latency amplification by enforcing admission control rather than letting demand grow unbounded inside the service.
- Trade-offs (costs):
    - **usability** — Legitimate users can be throttled during bursts or when many users share one source address unless keys and budgets are chosen carefully.
    - **operability** — Per-route tuning, tenant exceptions, incident overrides, and telemetry review require continuous operational ownership.
    - **latency** — Distributed counters, shared quota stores, or cross-node synchronization add request-path overhead, especially on globally distributed ingress.
    - **code-complexity** — Correctly combining per-IP, per-account, per-tenant, and global limits across multiple replicas is harder than applying a single static threshold.
- Related requirements: public-api-intrusion-attempts-blocked, withstand-ddos-attack, handle-sudden-increase-in-traffic
- Related approaches: manage-event-arrival
- Source: https://quality.arc42.org/approaches/rate-limiting

### Reconciliation Loops

*Also known as: Controller Pattern, Reconciler Pattern*

**Intent:** Continuously drive observed system state toward declared intent, so failures and drift trigger automatic correction instead of manual repair.

**Mechanism:** Store desired state durably; a level-triggered controller observes current state, computes the delta, and applies idempotent actions. It records status and repeats with backoff until current state matches intent, regardless of missed events, restarts, or partial progress.

**Applicability:** Use for long-lived resources whose desired state can be declared and observed, especially infrastructure, fleets, policies, and service topology. Skip one-off commands, irreversible side effects without compensating actions, and domains where a human must approve every state transition.

- Dimensions: `operable`, `reliable`
- Enables:
    - **autonomy** — The controller restores declared intent without an operator by detecting drift and applying corrective actions until observed state converges.
    - **recoverability** — After a managed resource fails or disappears, repeated reconciliation recreates or repairs it from the durable desired-state description.
    - **drift-detectability** — Every comparison exposes the delta between declared and observed state, making configuration and runtime drift explicit.
    - **operability** — Operators change one declarative specification while the controller handles ordering, retries, and repeated correction across managed resources.
- Trade-offs (costs):
    - **eventual-consistency** — Desired and observed state differ while actions run or observations lag. Callers must tolerate the convergence window; a controller that needs five minutes to repair drift cannot satisfy a requirement that assumes immediate consistency.
    - **code-complexity** — Each controller needs idempotent actions, ownership rules, retry and backoff, status reporting, and safe handling of partial progress. Interacting controllers multiply the state space and can turn a simple deployment workflow into a distributed system.
    - **resource-utilization** — Polling, repeated reads, and unsuccessful corrections consume API, network, and compute capacity. A tight retry loop during a dependency outage can overload the control plane and slow every controller sharing it.
- Related requirements: scale-up-in-2-minutes, governance-policy-enforcement, fleet-ota-updates-with-safe-rollback
- Related approaches: watchdog-supervision
- Source: https://quality.arc42.org/approaches/reconciliation-loops

### Reduce Coupling

*Also known as: Decoupling, Dependency Reduction*

**Intent:** Weaken the dependencies between modules so a change to one module stops at its boundary instead of rippling across the system.

**Mechanism:** Four complementary tactics lower coupling: encapsulate a module behind an explicit interface, insert an intermediary between modules that must interact, restrict which modules a module may depend on, and abstract several similar dependencies behind one shared contract. Each converts a direct, wide dependency into a narrow, indirect one.

**Applicability:** Apply where modules change independently, must be tested or replaced in isolation, or where change ripple already hurts. Reach for it selectively: decoupling stable, cohesive collaborators that always change together adds indirection while removing no real dependency.

- Dimensions: `maintainable`, `flexible`
- Enables:
    - **modifiability** — A change confined to one module can't ripple through dependents, so modification effort stays local and predictable.
    - **evolvability** — Modules with few external dependencies can be replaced or restructured without renegotiating contracts across the system.
    - **testability** — A module with fewer collaborators needs fewer test doubles and can run in isolation.
    - **modularity** — Narrow, explicit interfaces are what make a decomposition into modules real rather than nominal.
- Trade-offs (costs):
    - **simplicity** — Each interface, broker, or visibility rule is a moving part. Added where no real variability exists, they raise the part count and the indirection a reader must traverse while removing no actual dependency — abstraction for its own sake.
    - **latency** — Routing a call through an intermediary — broker, message bus, mediator — adds a hop or a dispatch step. Decoupling a hot path this way can raise p99 latency measurably.
- Related requirements: monolith-loose-coupling-change-blast-radius, service-loose-coupling-change-blast-radius, independent-enhancement-of-subsystem
- Related approaches: increase-cohesion
- Source: https://quality.arc42.org/approaches/reduce-coupling

### Responsive Design

**Intent:** Ensure a single codebase renders correctly and usably across the full range of screen sizes, input methods, and device capabilities.

**Mechanism:** Use fluid grids, flexible images, and CSS media queries to adapt layout and content presentation to the available viewport, rather than serving separate sites per device class.

**Applicability:** Use for any web application or content site where users access it from more than one class of device. Avoid when the use case is strictly single-device (e.g., a kiosk with fixed hardware) or when a native app provides a significantly better experience than a web-based one.

- Dimensions: `usable`
- Enables:
    - **usability** — Preserves task flow across desktop, tablet, and mobile viewports.
    - **accessibility** — Supports readable layouts and touch-friendly controls on all devices.
    - **adaptability** — Adjusts presentation to differing screen sizes and capabilities.
- Trade-offs (costs):
    - **performance** — Adaptive layouts can still ship heavy assets without careful optimization.
    - **maintainability** — Breakpoints and cross-device testing increase styling complexity.
    - **observability** — Tracking layout-driven errors across thousands of device/browser combinations is difficult.
- Related requirements: user-interface-works-with-current-browsers, usable-on-factory-floor, usable-with-gloves, localizable-to-n-languages, usable-despite-color-blindness
- Source: https://quality.arc42.org/approaches/responsive-design

### Safety Interlocks

**Intent:** Enforce verified preconditions before allowing hazardous operations to execute, ensuring the system never enters a dangerous state through premature, accidental, or unauthorized action.

**Mechanism:** Guard every hazardous operation with a gate that evaluates required preconditions — sensor readings, system state, operator confirmations, or environmental conditions; when any precondition is not met or cannot be evaluated, drive the system to the default the hazard analysis declared safe — typically blocking execution — and provide explicit feedback; log every check, pass, and override for audit.

**Applicability:** Use wherever an operation can cause harm to people, equipment, data, or environment if executed under wrong conditions — industrial control, medical devices, financial transactions with irreversible effect, infrastructure provisioning. Avoid for low-risk operations where the gate overhead reduces throughput without meaningful safety benefit.

- Dimensions: `safe`
- Enables:
    - **safety** — Hazardous operations cannot execute unless all preconditions are satisfied, preventing the system from entering dangerous states.
    - **fail-safe** — If an interlock check fails or cannot be evaluated, the interlock falls to the default the hazard analysis declared safe — it never proceeds as if the check had passed.
    - **controllability** — Operators retain explicit control over hazardous transitions because each gate requires deliberate confirmation that conditions are met.
    - **integrity** — Data and physical state are protected from corruption caused by operations executed under invalid preconditions.
    - **hazard-warning** — Interlock violations produce immediate, unambiguous feedback explaining which precondition is not met and what must change.
    - **user-error-protection** — Interlocks prevent accidental initiation of dangerous operations by requiring that safety-relevant conditions are verified before execution.
- Trade-offs (costs):
    - **availability** — Blocking operations on unmet preconditions can delay or prevent work when conditions are transiently unsatisfied or sensors report false negatives.
    - **usability** — Additional confirmation steps and gate checks slow workflows and frustrate users when the hazard is not immediately obvious to them.
    - **code-complexity** — Each interlock requires precondition logic, sensor integration, bypass governance, and audit logging, adding implementation and maintenance effort.
- Related requirements: shutdown-to-safe-state, safety-requirements-traceable-to-evidence
- Source: https://quality.arc42.org/approaches/safety-interlocks

### Saga Pattern

**Intent:** Reach a consistent business outcome across services where a single distributed ACID transaction is impractical, even when individual steps fail.

**Mechanism:** Partition a distributed flow into local transactions: compensatable steps (undone via compensating actions), a pivot transaction (point of no return), and retriable steps designed so retries eventually succeed. Coordinate execution using choreography (event-driven) or orchestration (central controller), persisting progress durably and making all operations idempotent.

**Applicability:** Apply to business processes spanning multiple microservices with isolated datastores, where synchronous distributed lock-based commits (like two-phase commit) impair availability and scalability. Avoid when the entire operation can run inside a single database transaction, or when business requirements strictly forbid the exposure of intermediate states (lack of isolation).

- Dimensions: `reliable`, `flexible`
- Enables:
    - **transactionality** — Delivers eventual all-or-nothing business outcomes across services where a single distributed ACID transaction is impractical or impossible.
    - **data-integrity** — Compensating actions and out-of-band reconciliation loops counteract orphaned side effects, so cross-service data converges to a consistent state after partial failure.
    - **recoverability** — Every compensatable step has a defined undo path and every post-pivot step is retriable; operators step in only when compensation itself fails permanently.
    - **availability** — Short local transactions replace long-held locks and blocking distributed commits (like 2PC), so services keep serving requests during multi-step flows.
    - **loose-coupling** — Each service commits only its own local transaction and coordinates through asynchronous events or commands, keeping its internal datastore private.
- Trade-offs (costs):
    - **consistency** — Sagas give up isolation: while a saga runs, other transactions observe intermediate states that compensation may later revert, causing anomalies such as dirty reads or lost updates that the application must counter itself.
    - **code-complexity** — Every step needs a hand-written compensating action plus idempotent, retry-safe message handling, and saga progress must be persisted. Compensation code runs rarely yet must work flawlessly during failures — precisely when the system is already degraded.
    - **debuggability** — One business transaction spans several services and message hops over seconds to hours. Reconstructing why a saga stalled or compensated requires correlated logs or distributed traces across every participant.
- Related requirements: order-transaction-consistency
- Source: https://quality.arc42.org/approaches/saga-pattern

### Secret Management

**Intent:** Eliminate secret sprawl by centralizing the storage, distribution, rotation, and revocation of sensitive credentials in a hardened, auditable vault using short-lived, identity-based tokens.

**Mechanism:** Store all secrets in a dedicated vault with encrypted storage and fine-grained access policies; bootstrap service access via trusted platform identities (OIDC, IAM, K8s) to solve the 'secret zero' problem; issue short-lived, scoped credentials at runtime via API or sidecar injection; automate rotation and revoke compromised credentials immediately; avoid persisting secrets in source code, images, or environment variables (which leak via /proc/self/environ and crash dumps).

**Applicability:** Use in any system handling database passwords, API keys, TLS certificates, or encryption keys. Particularly critical in microservice architectures with high credential diversity. Avoid only in truly isolated, single-process systems where the operational risk of a Tier-0 vault dependency outweighs the risk of local, filesystem-protected secrets.

- Dimensions: `secure`, `operable`
- Enables:
    - **security** — Eliminates secret sprawl by centralizing sensitive credentials in a hardened, network-isolated perimeter rather than scattered config.
    - **confidentiality** — Secrets remain encrypted at rest and in transit, appearing in plaintext only within the memory space of the authorized consuming process.
    - **access-control** — Fine-grained policies ensure that each service identity (e.g., K8s ServiceAccount, IAM role) accesses only the specific secrets required for its role.
    - **auditability** — Every lifecycle event — creation, access, rotation, and revocation — is recorded in an immutable trail for forensic and compliance use.
    - **compliance** — Automated rotation and centralized auditing support controls commonly required by PCI DSS, SOC 2 audits, and ISO 27001 Annex A.
    - **operability** — Decouples the secret lifecycle (rotation/updates) from application deployment, reducing manual toil and "expired credential" outages.
- Trade-offs (costs):
    - **availability** — The vault is a Tier-0 dependency; its failure can prevent service startup or renewal of dynamic credentials, potentially causing system-wide cascading outages.
    - **latency** — Authenticating to the vault and fetching secrets at runtime adds overhead to cold starts and introduces latency spikes during periodic credential renewal.
    - **code-complexity** — Developers must solve the "secret zero" bootstrap problem, manage token renewal lifecycles, and implement reliable retry and fallback logic for vault transients.
- Related requirements: access-control-is-enforced, encrypted-storage, governance-policy-enforcement
- Source: https://quality.arc42.org/approaches/secret-management

### Self-Contained Systems

*Also known as: SCS*

**Intent:** Split a system along business domains into autonomous web applications — each owning its UI, logic, and data — that integrate loosely and evolve independently.

**Mechanism:** Each self-contained system is a complete web application for one business domain, with its own database and optional service API. Integration happens preferably in the browser via links and UI composition, otherwise asynchronously; no shared runtime, no shared database, shared business code avoided.

**Applicability:** Use for larger systems with several teams, where domains separate cleanly and independent delivery matters more than a uniform UI. Skip for small systems one team handles, products demanding a deeply integrated single-page experience, or domains whose boundaries are still unknown.

- Dimensions: `flexible`, `maintainable`
- Enables:
    - **autonomy** — Each system owns UI, logic, and data, runs on its own, and keeps serving users while neighboring systems are down.
    - **loose-coupling** — Integration via links, UI composition, and async events — no shared database, no shared runtime, no synchronous call chains.
    - **evolvability** — Each system changes its stack, data model, and release cadence without coordinating with the others.
    - **deployability** — Every system deploys independently; coordinated big-bang releases disappear by construction.
    - **replaceability** — Systems stay small enough that a team can rewrite one entirely without touching the others.
- Trade-offs (costs):
    - **consistency** — Each system keeps its own copy of the data it needs, replicated asynchronously. Cross-system views are eventually consistent — 'one customer, three systems' means three records that drift unless reconciliation is designed in.
    - **user-experience** — One business process now crosses several web applications. Navigation, look-and-feel, and session handling stay coherent only through deliberate effort — shared style assets, composition techniques, and discipline that a single application gets for free.
    - **resource-efficiency** — Every system brings its own full stack — runtime, database, pipeline, monitoring. Infrastructure and operational footprint multiply with the number of systems, regardless of load.
    - **reusability** — SCS favors replication over shared business code: common logic is duplicated per system. Each copy evolves separately, and a fix in one place reaches the others only by repetition.
- Related requirements: independent-enhancement-of-subsystem, service-loose-coupling-change-blast-radius
- Source: https://quality.arc42.org/approaches/self-contained-systems

### Sidecar

*Also known as: Ambassador*

**Intent:** Add or adapt capabilities of an application by deploying a companion process beside it, leaving the application untouched.

**Mechanism:** A sidecar runs in the same scheduling unit as the application — same host or pod — sharing network and storage. It intercepts or supplements the application's traffic to add capabilities such as TLS termination, retries, or telemetry, and deploys and upgrades on its own cadence.

**Applicability:** Use to give a polyglot or legacy fleet uniform cross-cutting behavior, or to extend an application you cannot modify. Skip when a shared library is viable across your stacks, or when per-instance overhead outweighs the gain — single-stack shops often need no sidecar.

- Dimensions: `flexible`, `operable`
- Enables:
    - **extensibility** — New capabilities — TLS, retries, telemetry — arrive as a deployed companion, with zero changes to application code.
    - **legacy-support** — Retrofits current platform capabilities onto processes nobody can or wants to modify.
    - **observability** — A telemetry sidecar gives every service uniform logs, metrics, and traces without touching any codebase.
    - **interoperability** — An adapter or ambassador sidecar translates protocols, letting mismatched components talk without changing either side.
- Trade-offs (costs):
    - **resource-efficiency** — Every workload instance carries an extra process with its own CPU and memory reservation. At fleet scale this overhead is one of the main drivers behind sidecar-less service-mesh designs.
    - **latency** — Each intercepted call crosses the proxy twice — small per hop, but it stacks along multi-service request chains and shows in tail latencies.
    - **simplicity** — Two coupled containers now form one unit: startup order, health checks, and shutdown need coordination, and upgrading the sidecar fleet means restarting every workload that carries it.
- Related requirements: production-anomalies-detectable-within-2-minutes
- Related approaches: plugin-architecture, microservice-architecture
- Source: https://quality.arc42.org/approaches/sidecar

### Standby/Failover

*Also known as: Redundancy, Hot Spare, Warm Spare, Cold Spare, Active Redundancy, Passive Redundancy*

**Intent:** Keep a redundant component ready to take over when the active one fails, so service continues through the failure.

**Mechanism:** Run one or more redundant components behind a failure detector. On failure it promotes a standby to active. Standbys range from hot (fully synchronized) to cold (started on demand), trading cost against recovery time.

**Applicability:** Use when downtime is costly and the component can be replicated. Skip when state cannot be replicated affordably, or the recovery-time budget is loose enough that a plain restart suffices.

- Dimensions: `reliable`, `operable`
- Enables:
    - **availability** — A standby takes over when the active component fails, keeping the service reachable through the outage.
    - **fault-tolerance** — Losing one component does not stop the system, because a redundant peer continues the work.
    - **recoverability** — Automated failover restores service in seconds to minutes, without waiting for the failed component to be repaired.
- Trade-offs (costs):
    - **cost** — Redundant capacity is paid for before any failure occurs. A hot spare that mirrors the active component roughly doubles the resource bill; colder standbys cut that cost but lengthen recovery time.
    - **consistency** — Stateful failover relies on replicating state to the standby. A warm or cold spare can be promoted with stale or missing state, so in-flight work is dropped or replayed on takeover.
    - **maintainability** — Failure detection, promotion logic, and split-brain prevention are machinery the team builds, tunes, and must exercise regularly, or failover quietly rots until the outage that needs it.
- Related requirements: available-7-24-99, server-fails-operation-without-downtime, zone-failure-no-service-interruption, unavailability-max-2-minutes
- Related approaches: data-replication, n-version-redundancy
- Source: https://quality.arc42.org/approaches/standby-failover

### Strong Authentication (MFA / OIDC)

**Intent:** Verify the identity of every actor — human user, service, or device — with sufficient assurance that credential-based attacks (phishing, credential stuffing, brute force) rarely succeed, providing a trustworthy foundation for all downstream access-control decisions.

**Mechanism:** Authenticate actors using at least two independent factors (knowledge, possession, inherence) or a phishing-resistant protocol (FIDO2/WebAuthn, mutual TLS); centralize identity verification through an OIDC-compliant identity provider that issues short-lived, signed tokens; enforce authentication at every trust boundary and re-authenticate for sensitive operations.

**Applicability:** Use for any system that distinguishes between actors and grants differentiated access — which is nearly every system. Multi-factor is mandatory for privileged access (admin, infrastructure, financial). Phishing-resistant methods (FIDO2/WebAuthn) are preferred for high-value targets. Single-factor password authentication is acceptable only for low-risk, non-sensitive contexts. Service-to-service authentication should use mutual TLS or signed JWT tokens, not shared secrets.

- Dimensions: `secure`
- Enables:
    - **security** — Multi-factor and phishing-resistant authentication prevents credential-based attacks — the most common initial access vector in breaches.
    - **authenticity** — The system can verify with high confidence that an actor is who they claim to be, not an impersonator with stolen credentials.
    - **access-control** — Reliable identity verification is the prerequisite for all access-control decisions — [Least Privilege](/approaches/least-privilege) only works if the identity is trustworthy.
    - **accountability** — Actions can be attributed to a verified identity rather than a shared or spoofed account.
    - **non-repudiation** — Strong authentication binds actions to a verified identity, making it difficult for actors to deny having performed them.
    - **compliance** — PCI DSS mandates multi-factor authentication for privileged and remote access; NIST SP 800-63 supplies the assurance levels (AAL1–AAL3) that audits and regulations commonly reference.
- Trade-offs (costs):
    - **usability** — Additional authentication steps (second factor, biometric, redirect to identity provider) add friction to every login and can frustrate users.
    - **availability** — Dependency on an external identity provider (OIDC issuer, SMS gateway, push-notification service) introduces a single point of failure for authentication.
    - **operability** — Operating an identity provider or integrating with external ones requires ongoing maintenance of OIDC configurations, certificate rotation, and MFA device lifecycle management.
- Related requirements: only-authenticated-users-can-access, access-control-is-enforced, access-control-via-sso, governance-policy-enforcement
- Source: https://quality.arc42.org/approaches/strong-authentication

### Threat Modeling

*Also known as: STRIDE, Attack Trees*

**Intent:** Derive the security controls a system needs by systematically enumerating credible attacks against its assets, entry points, and trust boundaries.

**Mechanism:** Model assets, actors, data flows, and trust boundaries; apply STRIDE to relevant elements and interactions, or use attack trees to decompose attacker goals; rank threats; choose a disposition; and retain threats, assumptions, decisions, controls, and verification evidence as versioned artifacts.

**Applicability:** Use when compromise could cause meaningful harm; scale depth to risk. Skip a full workshop for low-risk changes only after recording a no-impact decision. Reassess when assets, actors, privileges, dependencies, exposure, controls, flows, boundaries, or trust assumptions change.

- Dimensions: `secure`
- Enables:
    - **risk-identification** — Systematic enumeration of attack paths exposes event sequences that put assets at unacceptable risk before code exists.
    - **securability** — Mapping trust boundaries shows where the design must support distinct access levels and which controls each boundary needs.
    - **confidentiality** — Data-flow analysis reveals where sensitive data crosses trust boundaries unprotected, so disclosure threats get targeted mitigations.
    - **integrity** — Tampering analysis at each entry point identifies where the design must verify origin and detect modification.
    - **intrusion-prevention** — Ranked attack paths show which entry points warrant blocking controls, so prevention effort concentrates where intrusions are credible.
- Trade-offs (costs):
    - **cost** — Modeling sessions need architects, security expertise, and preparation, and every significant design change adds re-analysis effort. For a low-risk tool, a full workshop costs more than the risk it retires, so scale session depth to the assets at stake.
    - **maintainability** — Threat registers, assumptions, and mitigation traces become versioned artifacts the team owns. Once the architecture moves on and nobody updates them, a stale model misleads reviews and audits more than no model would.
    - **time-to-market** — Analysis precedes implementation, so the first release ships later than with a ship-then-patch strategy. Under deadline pressure teams skip the ranking and mitigation steps — exactly the part that produces the value.
- Related requirements: avoid-common-vulnerabilities, public-api-intrusion-attempts-blocked, protect-data-by-security-procols
- Related approaches: least-privilege, input-sanitization-output-encoding
- Source: https://quality.arc42.org/approaches/threat-modeling

### Timeout

*Also known as: Deadline*

**Intent:** Bound the wait on every remote or long-running call so a stalled component fails fast at a deadline instead of hanging indefinitely.

**Mechanism:** Attach a deadline to each call. Start a timer when the call begins; if the response is still outstanding when the timer expires, abandon the wait, release the held resources, and raise a timeout error the caller handles as a detected fault.

**Applicability:** Use for every call that crosses a process, network, or hardware boundary, and for any operation with a timing constraint. Skip for fast local in-process work where no wait can stall, and pair with retries or a circuit breaker rather than replacing them.

- Dimensions: `reliable`, `safe`
- Enables:
    - **availability** — Bounding the wait frees the caller from an indefinite hang, so it stays responsive when a dependency stalls.
    - **fault-tolerance** — A call that exceeds its deadline is the detection signal that triggers fallback, retry, or failover.
    - **fault-isolation** — Releasing threads and connections held by a stalled call keeps resource exhaustion from spreading to healthy request paths.
    - **response-time** — A deadline caps the caller's worst-case wait, giving a predictable latency ceiling instead of an unbounded tail.
- Trade-offs (costs):
    - **data-integrity** — A caller that times out cannot distinguish 'the request never arrived' from 'it succeeded but the reply was slow.' Retrying a non-idempotent write after a timeout can duplicate the effect or leave state inconsistent unless the operation carries an idempotency key.
    - **maintainability** — Every remote call needs a deadline chosen against the dependency's real p99 and kept in sync as latency budgets shift. Set it too short and healthy-but-slow calls fail spuriously; too long and the wait defeats the tactic — an ongoing tuning burden.
- Related requirements: unavailability-max-2-minutes, server-fails-operation-without-downtime, available-7-24-99
- Related approaches: circuit-breaker
- Source: https://quality.arc42.org/approaches/timeout

### Tolerant Reader

*Also known as: Postel's Law, Robustness Principle*

**Intent:** Read only what you need from a message and ignore the rest, so producer-side schema changes leave consumers working.

**Mechanism:** Consumers bind only the fields they use — a subset DTO with unknown properties ignored, or name/path extraction — apply explicit defaults for absent optional elements, validate the extracted values, and treat an unknown value in a read enum field as an error.

**Applicability:** Use where producers and consumers evolve independently: public APIs, event streams, third-party integrations, long-lived document formats. Skip where the contract is the protection and every deviation must fail loudly — financial postings, safety commands, security-sensitive input.

- Dimensions: `flexible`, `reliable`, `operable`
- Enables:
    - **backward-compatibility** — Consumers built against an older schema keep working when producers add fields, elements, or enum values.
    - **interoperability** — Extracting only the needed elements lets one consumer work with many producers whose payloads differ in detail.
    - **robustness** — Unknown fields, extra elements, or reordered content leave the consumer functioning instead of failing the whole message.
    - **evolvability** — Producers extend schemas without coordinating a lockstep upgrade of every consumer, so contracts evolve at low cost.
- Trade-offs (costs):
    - **correctness** — A renamed or repurposed field no longer raises a parse error — the reader substitutes its default and processes wrong data silently. Contract drift then surfaces downstream, in reports or invoices, instead of at the integration boundary where a strict parser would have stopped it.
    - **maintainability** — Every consumer owns a hand-curated subset model, its defaults, and drift monitoring instead of one generated full-schema binding. The tolerated field set must be documented and contract-tested per consumer, or it decays into guesswork about what producers may still change.
- Related requirements: crm-data-synchronization
- Related approaches: open-host-service, event-driven-architecture
- Source: https://quality.arc42.org/approaches/tolerant-reader

### Transactional Outbox

**Intent:** Publish events reliably by writing them to an outbox table inside the same local transaction as the state change, eliminating the dual-write problem.

**Mechanism:** The business transaction inserts its state change and a serialized event record into an outbox table and commits as one ACID unit. A separate relay — a poller or change-data-capture reader — publishes new outbox rows to the message broker and marks them sent once acknowledged.

**Applicability:** Use when a service updates its database and must publish events about that change — event-driven integration, cache invalidation, saga steps — and lost or ghost events are unacceptable. Skip when consumers can query the database directly, or when the datastore offers no transactions.

- Dimensions: `reliable`
- Enables:
    - **atomicity** — One local ACID transaction covers the state change and the event record, so the intent to publish commits or rolls back with the data.
    - **consistency** — Every committed change produces exactly its event, so downstream read models and replicas converge on the source of truth.
    - **data-integrity** — No ghost events for rolled-back changes, no committed change without its event — source and derived data stay reconcilable.
    - **reliability** — Events wait in the durable outbox across crashes and broker outages; the relay retries until the broker acknowledges.
- Trade-offs (costs):
    - **latency** — Events reach the broker only after the relay reads them: polling interval plus publish time, typically tens of milliseconds to seconds. Workloads needing immediate fan-out feel this delay, and shortening the polling interval trades it directly against database load.
    - **performance** — Every business transaction carries an extra outbox insert, and a polling relay issues continuous queries against the primary database. Under high write volume the outbox table becomes a hot spot that needs regular purging to bound index growth and storage cost.
    - **simplicity** — The relay is a new stateful component with offset tracking, ordering keys, and cleanup jobs. Because delivery is at least once, every consumer must deduplicate by event ID — complexity the pattern pushes onto all subscribers.
- Related requirements: crm-data-synchronization, financial-transactions-are-acid-compliant
- Related approaches: event-sourcing, saga-pattern, asynchronous-messaging
- Source: https://quality.arc42.org/approaches/transactional-outbox

### Watchdog Supervision

*Also known as: Monitor*

**Intent:** Detect unresponsive or hung components through an independent monitor and trigger an automated restart or safe-state transition, bounding recovery time without relying on human intervention.

**Mechanism:** An independent supervisor process periodically checks the health of a monitored component — via heartbeat, liveness probe, or watchdog timer — and if the component fails to respond within the configured timeout, the supervisor initiates a restart, failover, or safe-state transition and raises an alert.

**Applicability:** Use for any long-running process where an undetected hang is worse than a restart — backend services, embedded controllers, infrastructure daemons, container orchestration. Avoid for short-lived batch jobs where the orchestrator already handles completion and retry, or where the restart cost (state loss, connection draining) exceeds the cost of brief unavailability.

- Dimensions: `safe`, `reliable`
- Enables:
    - **availability** — Hung or unresponsive processes are detected and restarted automatically, reducing the window of unavailability.
    - **fault-tolerance** — The system tolerates process-level failures by replacing the failed component rather than allowing the fault to persist.
    - **recoverability** — Automated restart returns the supervised component to a functional state without waiting for human intervention.
    - **self-healing** — The watchdog closes the detect-restart loop autonomously, making the system self-correcting for a class of failures.
    - **mean-time-to-recovery** — Detection and restart happen on a fixed timer, bounding recovery time to a predictable interval.
    - **safety** — In safety-critical systems, a missed heartbeat triggers a transition to a safe state, preventing a hung controller from causing harm.
- Trade-offs (costs):
    - **determinism** — In-flight work is lost on forced restart, and false-positive restarts from transient load or GC pauses add unplanned downtime, making behavior less predictable.
    - **observability** — The watchdog detects that a process is unresponsive but not why — root-cause diagnosis requires separate pre-restart telemetry capture.
    - **code-complexity** — Supervised components must support clean shutdown, state checkpointing, and startup-after-restart semantics, adding implementation effort.
- Related requirements: server-fails-operation-without-downtime, unavailability-max-2-minutes, production-anomalies-detectable-within-2-minutes
- Source: https://quality.arc42.org/approaches/watchdog-supervision
