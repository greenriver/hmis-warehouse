# Coordinated Entry (CE) Match Engine

This directory contains the core logic for the Coordinated Entry (CE) Match Engine. The engine is responsible for evaluating a universe of clients against a set of eligibility and prioritization rules for a given candidate pool. It identifies which clients are eligible for the pool and calculates a priority score for each.

## Directory Structure

The classes within this module are organized into several subdirectories to group related functionality and clarify the architecture.

- **`/` (ActiveRecord Models & Public API)**
  - Contains the main ActiveRecord models (`CandidatePool`, `Candidate`, `CandidateEvent`, `Rule`).
  - Contains the public-facing API classes that orchestrate the matching process (`Engine`, `CandidatePoolBuilder`, `CandidatePoolResolver`, `MatchApplicability`). These are the primary entry points for interacting with the match engine.

- **`internal/` (Internal Components)**
  - Houses the service objects that are used internally by the `Engine`. These classes are considered implementation details and should not be called directly from outside the `Hmis::Ce::Match` module.
  - Examples: `CandidateRepository`, `CandidateEventWriter`, `ClientPoolEvaluator`, `SqlPrefilter`.

- **`expression/` (Expression Handling Subsystem)**
  - A self-contained subsystem for parsing, translating, and evaluating the custom expressions used in eligibility and prioritization rules.
  - This directory contains all the logic for handling `FieldMap`s, translating expressions to SQL (`SqlExpressionTranslator`), and the `CalculatorFactory` for evaluating expressions in Ruby.

## Core Workflow

1.  **Initiation**: The process is typically initiated via the `Engine` class, triggered by a `ProcessChangesJob` job. The engine supports both full and incremental client processing.
2.  **SQL Prefiltering**: The `Engine` first uses the `SqlPrefilter` to translate the pool's eligibility requirements into a SQL `WHERE` clause. This efficiently filters out a large number of non-matching clients at the database level.
3.  **In-Memory Evaluation**: For the remaining clients, the `ClientPoolEvaluator` performs an, in-memory evaluation of priority and eligibility requirements
4.  **Persistence**: The `Engine` performs the following, via the `CandidateRepository`:
    * Creates proxy records for all clients if they do not exist
    * Creates or updates candidate records for the pool for newly matched clients or where priority score has changed.
    * Deletes candidate records for clients that no-longer match the pool's expression
5.  **Event Logging**: The `CandidateEventWriter` records the outcome of the evaluation (`add`, `update`, `remove`) in the `ce_match_candidate_events` table associated with the client's proxy record, creating an audit trail of eligibility changes.
