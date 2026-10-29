# ADR 0009: AI-Powered Help Chatbot Architecture

## Status

- Current Status: Proposed
- Date of last update: 2026-08-17
- Decision-makers: OP Team

## Context

Warehouse staff and HMIS System Administrators lack an in-app way to get quick answers to "how do I do X in this software" and "what does this HUD concept mean" questions. Our own documentation (`docs/`, `docs/architecture/`) is sparse and uneven, so before building a help feature we need both a knowledge base worth querying and a safe way to expose it through an LLM.

### Current State

- No existing AI/LLM integration anywhere in the codebase.
- `docs/features/*` and `docs/architecture/` contain useful but developer-oriented, uneven, and incomplete material — not something an end-user help bot could rely on as-is.
- Existing PII-handling code (`app/models/pii/scrubber/*`, ADR 0002) anonymizes client data at rest for non-production environments; nothing scans free-text input for PII before it leaves the app.
- No existing pattern for anonymized usage/topic analytics (only PaperTrail-style record-change audit trails tied to specific users).

### Constraints

1. The chatbot must only answer questions relevant to the HMIS/HMIS-adjacent domain and how to use the Warehouse software.
2. Answers involving HMIS/HUD concepts must cite official sources (hudexchange.info or similar).
3. Off-topic questions get a fixed redirect message, not an answer.
4. User input must be screened for PII *before* it reaches the AI agent; PII-flagged requests are rejected immediately and never reach the agent.
5. Query topics must be logged in a normalized form, not linked to the user, to drive future documentation/FAQ work.
6. The design must extend to other apps (HMIS-frontend, boston-cas, and eventually Superset) and be able to tailor responses to which app(s) a user has access to.

## Decision

Build the help chatbot as four independently deployed services rather than a single in-app feature, so the LLM-facing agent process can be fully, fail-closed isolated from the Rails application and its data:

1. **Warehouse app** (existing Rails app) — owns the chat widget UI, runs the PII pre-filter (deterministic regex for structured PII like SSN/DOB/phone/email, plus a fuzzy match against the client roster and nicknames table — imperfect by design, paired with a user-facing warning, biased toward over-blocking), mints a short-lived per-conversation token scoping exactly what the agent is allowed to call, and performs all query-topic logging (retrieved document IDs and reject reasons only — never raw text or user identity).
2. **Agent service** (new, isolated) — holds the LLM tool-calling loop and system prompt. It has **no standing credentials to the Rails app at all**: no DB connection, no session/cookie access, no general service account. It can reach exactly three things over the network: the two knowledge MCP servers below, one narrow read-only "app data" endpoint on the Warehouse app (authenticated via the per-conversation scoped token, itself running against a read-only DB role), and the Anthropic API. Fail-closed: without a valid, capability-scoped token, nothing beyond that is reachable, by construction, not by filtering.
3. **Warehouse-KB MCP server** (new, isolated) — Warehouse-specific "how to use this software" content, markdown + YAML frontmatter, populated and validated by CI on every merge to this repo or possibly during deployment.
4. **HUD-Domain-KB MCP server** (new, isolated) — HUD specification/domain content ingested from official PDFs/guides, refreshed on its own cadence, deliberately separate from Warehouse-KB so it can be reused by other apps' agents later without duplication, and so it can carry a vetted `source_url` per document for citation.

Both MCP servers are built in Node/TypeScript against the official MCP SDK; the live serving code stays small (frontmatter parsing, keyword search, protocol handling) regardless of how large the underlying content grows — search-quality upgrades (e.g. embeddings) are an ingestion-pipeline concern, not a serving-layer rewrite. Retrieval is agentic tool-calling (`search_knowledge` + `read_document`) rather than a single-shot RAG pass, mirroring the reference implementation. The model never emits a freeform URL — only markers resolved against a declared, vetted registry (in-app routes for Warehouse-KB, HUD citations for HUD-Domain-KB).

Delivery is phased: (1) Warehouse-KB infrastructure with a small seed of content, (2) the agent service + PII filter + widget, (3) the HUD-Domain-KB pipeline, (4) quality confirmation against both knowledge domains, (5) expanding Warehouse-KB toward 75%+ workflow/report coverage, (6) an admin-only view of the normalized query log for FAQ/gap discovery, and (7) extending to HMIS-frontend and boston-cas.

## Consequences

### Positive

1. A compromised or manipulated agent process cannot reach client data, the database, or any Rails app code beyond one narrow, read-only, explicitly allow-listed endpoint.
2. The HUD-Domain-KB becomes a single, reusable source of vetted domain knowledge for every future app's agent, rather than being copied per repo.
3. Knowledge content lives and is validated alongside the code it documents (Warehouse-KB in this repo, CI-checked on merge), which limits doc/code drift.
4. Users have an appropriately limited view of content leaning on existing code and APIs for access control.

### Negative

1. Four services to build, deploy, and monitor instead of one — meaningfully more operational surface than an in-app-only feature.
2. Cross-service auth (the per-conversation scoped token) and network segmentation must be implemented correctly for the isolation guarantee to hold; this is new infrastructure, not something to bolt on later.
3. PII pre-filtering is deliberately imperfect (new/not-yet-in-roster clients, novel PII shapes) and depends on the accompanying warning note rather than a guarantee.

### Neutral

1. Lexical (not embeddings-based) search is the starting point; the team already expects to outgrow it and has an intentional upgrade path rather than solving it upfront.

## Alternatives Considered

### 1. Agent loop running in-process inside the Warehouse app

**Pros:** One fewer deployable; simpler to build and reuse existing session/auth.
**Cons:** A compromised or buggy tool-calling loop shares a process/container with the full Rails app, DB credentials, and session handling — inconsistent with the fail-closed requirement. Rejected once full isolation was confirmed as a hard requirement.

### 2. Single MCP server hosting both knowledge domains

**Pros:** One fewer service to operate.
**Cons:** Warehouse-specific content and HUD domain content have different owners, update cadences, and validation rules (route-existence checks vs. PDF-source citation checks), and only the HUD content is meant to be shared across future apps. Splitting them avoids coupling those lifecycles and avoids duplicating HUD content into every future app's repo.

### 3. Central service that ingests/pulls each app's knowledge via an exposed endpoint

**Pros:** One aggregation point for cross-app search and logging.
**Cons:** Introduces staleness (ingested copies can lag the source) and requires each app to expose a pull-auth endpoint. Rejected in favor of each app owning a live MCP server rebuilt via its own CI.

### 4. Embeddings/vector search from day one

**Pros:** Scales better to a large knowledge base and supports semantic (not just keyword) matching.
**Cons:** Unnecessary complexity at the expected initial content size; deferred until lexical search demonstrably falls short.
