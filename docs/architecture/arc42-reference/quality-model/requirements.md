# arc42 Example Quality Requirements

149 example requirements (measurable quality scenarios).

- Source: https://quality.arc42.org
- Dataset: [`arc42/quality.arc42.org-site`](https://github.com/arc42/quality.arc42.org-site) @ `3a24a3c640a7bb32fb3d5344dcc7dcda8d6e22f0`
- Retrieved: 2026-08-24
- Refresh by diffing this SHA against `HEAD` and regenerating.


## Scenario structure

arc42 models a quality requirement as a **quality scenario**: a concrete, measurable situation rather than a vague goal ("fast", "secure"). Every example below is written against this structure:

- **Context** — the system and situation the scenario applies to.
- **Trigger (stimulus)** — the event or condition that starts the scenario.
- **Response** — the required system behaviour when the trigger occurs (often folded into the acceptance criteria rather than given its own heading).
- **Acceptance Criteria** — the measurable thresholds that decide pass/fail (numbers, time windows, percentages), plus the measurement source/artifact.

Some entries use a single **Requirement** heading in place of Context/Trigger, and many add a **Monitoring Artifact** or **Measurement & Verification** section naming where the criteria are observed. `tags` are the dimensions the requirement exercises; `related` lists the quality characteristics it demonstrates.

The examples below illustrate the structure — they are templates to adapt, not a checklist to satisfy.

## Examples

### Access control is enforced

- Dimensions: `secure`, `suitable`
- Qualities demonstrated: access-control, auditability
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality scenario to describe an access control requirement`.
- URL: https://quality.arc42.org/requirements/access-control-is-enforced

### Context

The system operates in a multi-user environment with varying levels of user roles and permissions. Sensitive features and confidential information require role-based access control (RBAC) and audit trails to maintain data security and privacy.

### Trigger

A user attempts to access a sensitive feature or confidential information within the system.

### Acceptance Criteria

The system must enforce appropriate access controls based on the user's role and permissions.

The access control mechanism must meet the following criteria:
* 100% of access attempts must be authenticated before granting access to any sensitive data
* Multi-factor authentication (MFA) or biometric authentication is implemented for accessing highly sensitive data
* User roles are precisely defined (e.g., "Customer Service Representative," "Financial Analyst," "Administrator")
* Access permissions are assigned based on the principle of least privilege
* Sensitive data is classified into at least three levels (e.g., public, internal, confidential)
* Access controls are configured according to data classification, with stricter controls for highly sensitive data
* 100% of access attempts (successful and failed) to sensitive data are logged in a tamper-proof audit trail
* Audit logs include user identity, timestamp, accessed data, and outcome (granted or denied)
* Authorized personnel can revoke access permissions immediately, with changes taking effect within 60 seconds
* User sessions automatically timeout after a maximum of 30 minutes of inactivity
* Access denials display a relevant and user-friendly error message within 2 seconds
* 100% of access control violations are logged and reported to authorized personnel within 5 minutes
* The system maintains 99.99% uptime for the access control service
* Access control policy updates are applied system-wide within 5 minutes of being implemented

### Access Control via SSO

- Dimensions: `usable`, `suitable`, `secure`
- Qualities demonstrated: access-control, auditability
- URL: https://quality.arc42.org/requirements/access-control-via-sso

### Context

Employees authenticate through the corporate SSO system and must receive correct application roles immediately after login.

### Trigger

An employee initiates SSO login.

### Acceptance Criteria

- SSO login completes at p95 ≤ 3 s with ≥ 99.5% success rate across the top 5 user roles, excluding declared IdP outage windows (authentication telemetry, rolling 30-day window).
- In release-candidate tests with ≥ 20 representative identities, 100% receive correct roles and rights immediately after login (SSO integration test report, every release candidate).
- If the IdP is unavailable or the assertion is invalid, access is denied in 100% of tested attempts and an audit-log entry is written within 30 s (failure-injection report, quarterly).

### Access find function in three seconds

- Dimensions: `usable`
- Qualities demonstrated: usability, user-experience, ease-of-use, convenience, interaction-capability
- URL: https://quality.arc42.org/requirements/access-find-function-quickly

### Context

The system is a software application with a graphical user interface, accessible via mobile or desktop platforms. The application includes various functions, with the "find" function being a critical feature for locating specific types of data within the system.

### Trigger

A user accesses the find function from the application's main interface.

### Acceptance Criteria

- "Find" function becomes accessible within 3 seconds of interface loading
- At least 99% of users can access the "find" function within the 3-second timeframe
- Performance metric is maintained across different devices and network conditions typical for the application's intended use

### Accessible User Interface

- Dimensions: `usable`
- Qualities demonstrated: usability, inclusivity, compliance, accessibility, interaction-capability
- URL: https://quality.arc42.org/requirements/accessible-user-interface

### Context

Users who rely on keyboard navigation and assistive technologies must be able to complete core product journeys without barriers.

### Trigger

A release candidate is built, or a quarterly accessibility review is due.

### Acceptance Criteria

- 100% of pages in the top 20 user journeys are scanned in CI with zero critical WCAG 2.1 AA violations and ≤ 5 serious violations per release candidate (automated accessibility scan report).
- Quarterly manual audit of the top 10 journeys using keyboard-only plus ≥ 2 mainstream screen readers completes all critical journeys with zero critical blockers (manual audit report).
- Any open critical accessibility violation on a critical journey blocks release within 10 min (release gate log).

### Accurate estimate of insurance contract rate

- Dimensions: `usable`, `suitable`
- Qualities demonstrated: accuracy, preciseness, precision, reliability, functional-correctness, interaction-capability
- URL: https://quality.arc42.org/requirements/accurate-estimate-of-insurance-rate

### Context

The system is an online application for configuring health insurance contracts. The final price of the insurance rate needs to be determined by backoffice employees due to legal and organizational reasons. This constraint cannot currently be relaxed.

### Trigger

A user configures a health insurance contract in the online app.

### Acceptance Criteria

- System calculates price estimate based on currently available information
- Estimate falls within ±15% margin relative to the final price
- At least 95% of estimates meet the ±15% margin requirement
- Regular audits performed on contract samples to verify compliance

### Add new product under 60 minutes

- Dimensions: `suitable`, `efficient`, `reliable`
- Qualities demonstrated: efficiency, usability, extensibility
- URL: https://quality.arc42.org/requirements/add-new-product

### Context

The system is a webshop with an administration panel for editors to manage products. Editors can add new products to the webshop through this administration panel.

### Trigger

Editor uses the administration panel to add a new product to the webshop.

### Acceptance Criteria

- Newly added product becomes visible and available to users within 60 minutes
- At least 95% of newly added products meet the 60-minute publication timeframe

### Adding a new entity type within 5 days and ≤ 3 modules

- Dimensions: `flexible`, `maintainable`
- Qualities demonstrated: evolvability, modularity, maintainability, extensibility
- URL: https://quality.arc42.org/requirements/adding-entity-type-within-5-days

### Context

A legacy business application is undergoing incremental modernisation toward a modular architecture.
The business regularly introduces new entity types (e.g., a new product category, contract type, or regulatory report) that require end-to-end support: persistence, validation, REST API, and UI.
The architecture must make such changes predictable, localised, and fast — without cascading modifications across unrelated modules.

### Trigger

A product team receives a business requirement to add a new entity type to the system, requiring full-stack support (database schema, domain model, service layer, REST endpoint, and basic UI form).

### Acceptance Criteria

- Full-stack implementation of a new entity type touches **at most 3 existing modules** (measured by the number of top-level module directories modified in the version-control diff, excluding the new module itself)
- The **aggregate number of lines changed** outside the new module's own directory is **≤ 50 lines** (excluding auto-generated code such as OpenAPI stubs or ORM migrations)
- A developer with 3–6 months of codebase experience can complete the implementation within **5 working days**, as validated retrospectively across ≥ 3 completed entity additions
- An **automated fitness function running in CI** (e.g., ArchUnit or Dependency-Check) fails the build if any module imports internal packages from more than **7 other modules**
- Adding the new entity type does not cause any existing automated test to fail; existing logic and test assertions require **zero modifications** (Open-Closed Principle)
- Static analysis at merge time confirms the new module's **afferent coupling (Ca) ≤ 5** and **efferent coupling (Ce) ≤ 8**; furthermore, no existing module's **efferent coupling (Ce)** increases by more than **1**
- The new module itself achieves **≥ 80% statement coverage** and **zero critical issues** in static analysis (e.g., SonarQube 'Blocker' or 'Critical' severity)
- The new REST endpoint passes **automated schema linting** (e.g., Spectral), confirming 100% adherence to project-wide naming, pagination, and error-structure standards
- The new entity type is **automatically reflected** in the OpenAPI/Swagger documentation and the System Data Dictionary upon successful build, requiring zero manual documentation updates

### Affordable CRM (customer relationship management)

- Dimensions: `efficient`, `suitable`
- Qualities demonstrated: affordability, cost, budget-constraint, profitability
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality scenario to describe an affordability requirement`.
- URL: https://quality.arc42.org/requirements/affordable-crm

### Context

A mid-sized company is planning to adopt a new Customer Relationship Management (CRM) software system. The company has allocated a limited budget for the software, covering initial purchase, setup, training, and first-year operational costs. The total cost of ownership (TCO) for the first year is a critical factor in ensuring the chosen CRM solution fits within budgetary constraints while meeting operational needs.

### Trigger

Finance department initiates adoption of a new Customer Relationship Management (CRM) software system.

### Acceptance Criteria

- Total first-year TCO does not exceed $24,000 budget
- Cost breakdown requirements:
  - Initial licensing: ≤ $10,000
  - Setup and deployment: ≤ $5,000
  - Training for 50 employees: ≤ $3,000
  - Maintenance and support: ≤ $2,000
  - Operational costs (cloud hosting): ≤ $4,000
- All costs verifiable through official quotes, invoices, or contracts
- Hidden costs and fees identified and included in TCO calculation
- CRM solution meets at least 90% of company's functional requirements
- TCO calculation completed and verified minimum 30 days before final decision

### Any passing build deploys to production within 15 minutes

- Dimensions: `operable`, `suitable`
- Qualities demonstrated: deployability, releasability, testability
- URL: https://quality.arc42.org/requirements/deploy-to-production-within-15-minutes

### Context

A multi-tenant SaaS platform delivers continuous updates to hundreds of enterprise customers.
The development team practices trunk-based development and aims to minimise the gap between code merge and live deployment to accelerate feedback and reduce integration risk.

### Trigger

A developer merges a feature branch into the main branch and all CI pipeline checks pass (unit tests, integration tests, static analysis, security scan).

### Acceptance Criteria

- The end-to-end pipeline — from merge to full production rollout — completes in **≤ 15 minutes** (p95 over 30 consecutive deployments)
- Deployments use a rolling or blue/green strategy; **zero requests return HTTP 5xx** attributable to the deployment process during rollout
- If the post-deployment error rate (5xx responses) exceeds **1% over any 60-second window**, automated rollback triggers **within 90 seconds** of threshold breach
- Rollback completes and the previous version serves 100% of traffic within **5 minutes** of rollback initiation
- The deployment pipeline enforces at least: compilation, unit tests (≥ 85% statement coverage), one integration test suite, and a lightweight DAST scan — none of these gates may be manually bypassed on the main branch
- Pipeline failure rate due to flakiness (excluding real defects) remains **below 2%** averaged over any rolling 7-day window

### Appearance of mobile UI

- Dimensions: `usable`
- Qualities demonstrated: appearance, usability, consistency, user-interface-aesthetics, interaction-capability
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality scenario to describe an appearance requirement`.
- URL: https://quality.arc42.org/requirements/appearance-requirements

### Context

The system is a mobile application with a user interface for performing common tasks such as creating an account or making a purchase. The appearance of the UI is critical for user experience and brand consistency, requiring visual consistency, color scheme compliance, text legibility, proper image resolution, responsive design, and acceptable loading times across various devices and screen sizes while adhering to WCAG 2.0 accessibility standards.

### Trigger

A user interacts with the mobile application's user interface to perform a common task, such as creating an account or making a purchase.

### Acceptance Criteria

- Visual Consistency:
  - At least 95% of UI elements adhere to established style guide
  - Adherence visually assessed and documented
- Color Scheme Compliance:
  - Maximum 5% deviation from specified color codes
  - Verified using automated color analysis tools
- Text Legibility:
  - 100% of text elements meet WCAG 2.0 accessibility guidelines
  - Font size, contrast ratios, and line spacing compliant
  - Confirmed via automated accessibility testing tools
- Image Resolution:
  - 100% of images and icons rendered without distortion or pixelation
  - Correct resolution and aspect ratio verified via automated testing
- Responsive Design:
  - UI layout remains visually appealing and functional on at least 95% of tested devices
  - Testing covers multiple devices and screen sizes
  - No critical layout issues observed
- Loading Times:
  - No individual UI element exceeds 3-second loading time
  - Validated via automated performance testing
- Overall Compliance:
  - Application passes all above criteria in at least 3 consecutive testing cycles
  - Failures documented, addressed, and re-tested until compliance achieved

### Assess impact of proposed change

- Dimensions: `suitable`, `reliable`
- Qualities demonstrated: analysability, reliability
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality scenario to describe an analysability requirement`.
- URL: https://quality.arc42.org/requirements/assess-impact-of-proposed-change

### Context

The system is a financial software application with multiple modules. The system's analysability is crucial for efficient change management and maintenance, supported by tools and practices for code documentation, dependency mapping, and change simulation.

### Trigger

A software development team initiates an impact analysis for a proposed change to a specific module of the financial software application.

### Acceptance Criteria

- Change Impact Assessment Time:
  - Team assesses impact of proposed change within 2 hours
  - Time starts from beginning of documentation and source code review
  - Assessment covers all potential areas affected by change
- Code Comment Density:
  - Affected module has minimum 20% code comment density
  - Measured using automated code analysis tools
  - Comments are meaningful and explain code functionality clearly
- Dependency Mapping:
  - System provides visual dependency map showing all dependencies to/from other components
  - Dependency map generation completes within 5 minutes
  - Map shows 100% of actual dependencies accurately
- Overall Compliance:
  - All three criteria must be met
  - Compliance verified through at least 3 different change scenarios
  - Failures documented and addressed
  - System maintains this analysability level for at least 90% of all modules

### Attractive Appearance of Website

- Dimensions: `usable`
- Qualities demonstrated: attractiveness, usability, appearance, user-interface-aesthetics, user-experience
- Note: **Measurement instruments referenced above:**

- **[Likert scale](https://en.wikipedia.org/wiki/Likert_scale)** — a symmetric agree/disagree rating scale (typically 5 or 7 points), widely used in survey research to quantify subjective attitudes.
- **[VisAWI](https://doi.org/10.1016/j.ijhcs.2010.05.006)** (Moshagen & Thielsch, 2010) — a validated 18-item questionnaire measuring perceived visual aesthetics of websites across four facets: simplicity, diversity, colorfulness, and craftsmanship.
- **[AttrakDiff](https://attrakdiff.de/)** (Hassenzahl et al., 2003) — a semantic differential questionnaire measuring pragmatic quality (usability), hedonic quality (stimulation and identity), and overall attractiveness of interactive products.
- **[SUS](https://doi.org/10.1201/9781498710411-35)** (Brooke, 1996) — a 10-item questionnaire producing a single score (0–100) for perceived usability. Scores above 68 are considered above average.
- URL: https://quality.arc42.org/requirements/attractive-quality-knowledge-base

### Context

The quality.arc42.org knowledge base serves software architects and developers who browse
~220 quality attributes, ~140 requirements, and an interactive force-directed graph.
Users typically arrive via search engines and decide within seconds whether the site
feels trustworthy and worth exploring. Visual appeal directly affects engagement
and return visits.

### Trigger

A new or returning user loads any page of quality.arc42.org on a desktop or mobile browser.

### Acceptance Criteria

- At least 70% of surveyed users (n >= 50) rate overall visual appeal >= 4 on a
  5-point [Likert scale](https://en.wikipedia.org/wiki/Likert_scale),
  measured via the [VisAWI questionnaire](https://doi.org/10.1016/j.ijhcs.2010.05.006)
  (Visual Aesthetics of Websites Inventory) administered annually.
  Assumption: 70% threshold chosen conservatively for a non-commercial knowledge site.

- [AttrakDiff](https://attrakdiff.de/) hedonic quality score (HQ-I subscale) reaches
  at least 0.5 on the -3 to +3 scale across a panel of >= 30 representative users,
  evaluated per major redesign via online self-report.

- Visual consistency: no more than 5% of sampled pages (random sample of >= 30 pages
  per audit) deviate from the site's color scheme, typography, or spacing conventions,
  verified by automated visual regression testing per release.

- Cumulative Layout Shift ([CLS](https://web.dev/articles/cls)) remains <= 0.1 on
  at least 95% of page loads over a rolling 30-day window, measured via real-user monitoring
  or [PageSpeed Insights](https://pagespeed.web.dev/).


- [System Usability Scale](https://doi.org/10.1201/9781498710411-35) (SUS) overall
  score >= 68 (industry average) across >= 20 users, evaluated annually.
  

### Monitoring Artifact

Annual UX survey dashboard combining VisAWI scores, AttrakDiff profiles, SUS scores,
CLS telemetry from PageSpeed Insights, and bounce rate trends from web analytics.

### Authenticity of a digital document

- Dimensions: `secure`, `suitable`
- Qualities demonstrated: authenticity, integrity
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality scenario to describe an authenticity requirement`.
- URL: https://quality.arc42.org/requirements/authenticity-of-digital-document

### Context

The system operates in an environment where document integrity and trustworthiness are critical. It provides functionality for users to verify the authenticity of digital documents using a robust digital signature mechanism, while maintaining a secure and tamper-proof audit trail for all document-related activities.

### Trigger

A user attempts to verify the authenticity of a digital document.

### Acceptance Criteria

- Digital signature mechanism correctly verifies 100% of unmodified documents
- Document modifications or tampering detected with 100% accuracy
- Audit trail records all document-related activities (creation, modifications, approvals)
- Each audit trail entry includes accurate timestamps and user identifiers
- Audit trail is tamper-proof with unauthorized modification attempts detected and logged
- Digital signature verification completes within 5 seconds for documents up to 10MB
- Audit trail entries created and logged within 1 second of document activity
- System provides clear, user-friendly interface for initiating and understanding verification results
- Audit trail searchable with complete document history retrievable within 30 seconds
- Authenticity verification service maintains 99.99% uptime

### Automated Personal Data Lifecycle Protection

- Dimensions: `secure`, `suitable`
- Qualities demonstrated: data-protection, privacy, compliance, security, auditability
- URL: https://quality.arc42.org/requirements/personal-data-lifecycle-protection

### Context
A multinational Financial Services platform processes "Personally Identifiable Information" (PII) and "Sensitive Personal Data" across multiple jurisdictions (EU/GDPR, California/CCPA). The system must ensure data remains protected even in the event of partial system compromise or administrative errors.

### Trigger
Personal data is ingested, stored, accessed for processing, or requested for deletion by a data subject.

### Acceptance Criteria

*   **Encryption at Rest & Transit**: 100% of PII fields (defined in the Data Dictionary) are encrypted at rest using **AES-256-GCM** with per-customer keys (Envelope Encryption). 100% of data in transit uses **TLS 1.3** with Perfect Forward Secrecy.
*   **Anonymization for Non-Production**: 100% of data exported to staging or analytics environments is automatically anonymized via **k-anonymity (k≥5)** or differential privacy, ensuring no individual can be re-identified with >0.01% probability.
*   **Data Subject Rights (SRR)**: The system provides an automated "Self-Service Privacy Portal" where users can trigger a "Right to be Forgotten." 100% of the user's PII is purged from all active databases and search indexes within **24 hours**, and from all immutable backups within **30 days**.
*   **Access Accountability**: Every access to sensitive data fields (e.g., Social Security Numbers, Health Records) is logged with a tamper-proof audit trail (HMAC-chained). Audit logs must be searchable and reportable within **60 seconds** for any 24-hour window.
*   **Breach Notification Latency**: In the event of unauthorized data access detection, the system automatically generates a "Data Impact Report" identifying 100% of affected records and their jurisdictions within **4 hours** of incident confirmation.
*   **Data Retention Enforcement**: 100% of records exceeding the legal retention period (e.g., 7 years for financial records) are automatically flagged and securely overwritten (not just logically deleted) within **7 days** of expiry.

### Available 7x24 with 99% uptime

- Dimensions: `operable`, `usable`, `reliable`
- Qualities demonstrated: availability, high-availability, reliability, operability, user-error-protection, interaction-capability
- URL: https://quality.arc42.org/requirements/available-7-24-99

### Requirement

The user-facing service scope consisting of login, landing page, and the three most-used business transactions must remain continuously available with a monthly uptime objective of at least 99%.

### Acceptance Criteria

- Availability objective: over each rolling **30-day** window, the defined service scope achieves **>= 99.0%** successful synthetic checks from at least **3** independent monitoring regions at **1 min** intervals; source: uptime dashboard and probe logs; horizon: continuous 24x7 operation.
- Incident detection: any outage of the defined scope lasting **> 5 min** triggers an on-call alert within **<= 2 min** after the fifth failed check; source: monitoring and alerting log; horizon: every production incident.
- Breach behavior: if the remaining monthly error budget drops below **20%**, non-urgent production releases are paused within **<= 30 min** until the service owner records a mitigation decision; source: incident log and release calendar; horizon: each 30-day window.

### Avoid common vulnerabilities

- Dimensions: `reliable`, `secure`
- Qualities demonstrated: vulnerability
- Stakeholder: management, product-owner
- URL: https://quality.arc42.org/requirements/avoid-common-vulnerabilities

### Requirement

The system must avoid common security vulnerabilities in every release and deployment.

### Acceptance Criteria

- Zero instances of missing data encryption in production
- No OS command injection vulnerabilities present
- No SQL injection vulnerabilities present
- No buffer overflow vulnerabilities present
- All critical functions require authentication
- All protected operations require proper authorization
- File upload restricted to safe file types only
- Security decisions never rely on untrusted inputs
- 100% of releases pass security vulnerability scanning for these common vulnerabilities

### Backup patient monitoring sensor takes over

- Dimensions: `safe`
- Qualities demonstrated: safety, efficiency, reliability, patient-safety
- URL: https://quality.arc42.org/requirements/backup-patient-monitoring-sensor

Idea: [Bass et al., 2021](/references/#bass2021software)

### Context

The system monitors patients several health and vitality parameters (e.g. heartbeat frequency and amplitude, blood flow in coronary artery etc).

### Trigger

A sensor in the patient monitoring system fails to report a life-critical value after 100 ms.

### Acceptance Criteria

- Failure is logged
- Warning light is illuminated on the console
- Backup (lower-fidelity) sensor is engaged
- System monitors patient using backup sensor after no more than 300 ms

### Budget constrained library update

- Dimensions: `efficient`, `suitable`
- Qualities demonstrated: affordability, cost, time-to-market
- URL: https://quality.arc42.org/requirements/budget-constraint-library-update

### Context

The system uses a commercial library as a core component. An automated build and test pipeline is available for all developers within their development environment. The commercial library receives regular monthly security updates, and in some cases (e.g., zero day exploits) additional updates are delivered from the vendor.

### Trigger

Product owner requires incorporation of library security updates with limited manual effort.

### Acceptance Criteria

- Library update completes within maximum time budget of 2 developer-hours on average
- Automation costs (build and test) not included as infrastructure already exists

### Capacity to process 1000 sensor inputs per minute

- Dimensions: `efficient`
- Qualities demonstrated: time-behaviour, speed, performance
- URL: https://quality.arc42.org/requirements/capacity-to-process-sensor-inputs

### Requirement

The system must handle high-volume sensor data input.

### Acceptance Criteria

- System records, processes, and stores 1000 sensor inputs per minute
- Minimum throughput of 16.67 sensor inputs per second sustained
- All three operations (record, process, store) completed for each input

### Capture unresolved business semantics without structural commitment

- Dimensions: `flexible`, `maintainable`
- Qualities demonstrated: evolvability, traceability
- URL: https://quality.arc42.org/requirements/capture-unresolved-business-semantics-without-structural-commitment

### Context

A business feature must be implemented while a relevant business distinction or rule is explicitly unresolved. The observable information needed by the feature is understood, but the final interpretation has not yet been agreed.

### Trigger

Implementation and release must proceed before the unresolved business interpretation is finalized.

### Acceptance Criteria

- The system can record **100% of the agreed observable information** for a representative sample of at least 100 cases without assigning the unresolved final interpretation
- At least **2 plausible interpretations** can later be evaluated against the same captured sample without changing those recorded facts
- Applying either candidate interpretation modifies **0 previously captured source facts**
- **0 existing producers** of the captured source facts require modification solely to evaluate or finalize the interpretation
- Finalizing the interpretation requires **no migration that rewrites previously captured cases** and **no breaking change to the capture interface used by existing producers**
- Finalizing the interpretation changes **no more than 3 existing modules or independently deployable components**, excluding tests, documentation, and the interpretation implementation itself
- **100% of derived results** in the sample can be traced to the source facts used to calculate them

### Measurement & Verification

Select a business distinction that is explicitly unresolved while implementation proceeds. Capture at least 100 representative cases before the final interpretation is agreed, then evaluate two plausible candidate interpretations against the unchanged sample. Verify the criteria through automated tests, version-control diff, migration history, interface compatibility checks, and data lineage.

### Clarity in technical documentation

- Dimensions: `usable`, `reliable`
- Qualities demonstrated: clarity, coherence, understandability, legibility
- URL: https://quality.arc42.org/requirements/clarity-in-technical-documentation

### Context

The system is fairly large, and maintained/developed by an internationally distributed and highly heterogeneous, diverse and volatile development team.

### Trigger

Users refer to technical documentation to understand technical details or troubleshoot issues.

### Acceptance Criteria

- Documentation provides coherent and intelligible explanations and instructions
- At least 90% of system-specific terms used in documentation are defined in glossary section accessible within same document or via direct links
- Readability score of documentation, as measured by Flesch-Kincaid Readability Test, is between 60 to 70 (8th to 9th-grade reading level)
- Documentation is easily understandable by average dev-team member

### Compatible with 5 different battery providers

- Dimensions: `flexible`
- Qualities demonstrated: flexibility, adaptability, interoperability, compatibility
- URL: https://quality.arc42.org/requirements/compatible-with-5-battery-providers

### Context

The system's energy is supplied by a rechargeable onboard battery mechanically attached to a circuit board (PCB). 
The current board version fits only batteries from _one specific_ supplier.


### Metric / Acceptance Criteria

The circuit-board revision must support approved battery models from _five preferred suppliers_ without PCB redesign or supplier-specific firmware.

- ≥ 1 approved battery model from each of 5 preferred suppliers works with zero PCB changes, adapters, or firmware forks (hardware compatibility matrix, every board revision).
- 100% of critical functional tests pass per approved model under the reference operating profile and environmental test setup (hardware + system test report, every board revision).

- Battery-life variation across approved models ≤ 10% under the same load profile; any supplier missing a threshold is de-listed for that revision (endurance test report).

### Compliance with UI styleguide

- Dimensions: `usable`
- Qualities demonstrated: usability, user-experience, compliance, interaction-capability
- URL: https://quality.arc42.org/requirements/compliance-with-ui-styleguide

### Context

Operating systems like Windows(tm) or MacOS(tm) have strict human-interaction-guidelines that must be followed.

### Trigger

User interface and interactive components of the system are redesigned and implemented.

### Acceptance Criteria

- Manual audit/inspection by user-interface specialist is performed and/or automated style tests are in place
- No deviation from user interface guidelines are detected
- 100% compliance with OS-specific human-interaction-guidelines

### Compliance with WCAG accessibility guidelines

- Dimensions: `usable`
- Qualities demonstrated: accessibility, user-experience, user-assistance, interaction-capability
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `Please generate a quality attribute scenario for accessibility compliance with WCAG 2.1 with precise metrics`.
- URL: https://quality.arc42.org/requirements/compliance-to-wcag

### Context
The web application must comply with WCAG 2.1 Level AA standards to ensure accessibility for users with disabilities navigating with screen readers in standard web browsers.

### Trigger
A person with visual impairment using a screen reader attempts to navigate and interact with the web application.

### Acceptance Criteria

- **Navigation**: At least 95% of all interactive elements (links, buttons, form fields) are navigable and identifiable using the screen reader
- **Content**: At least 98% of all content (text, images with alt attributes, videos with captions) is accessible and consumable using the screen reader
- **Interactivity**: Users can interact with 95% of functionality (e.g., submitting forms) without encountering accessibility barriers
- **Feedback**: All messages, errors, and notifications are clearly announced to the screen reader with 99% accuracy
- **Load time**: Page load times do not exceed 3 seconds for 90% of page loads despite accessibility enhancements
- **Compliance**: Application meets [WCAG 2.1](https://www.w3.org/TR/WCAG21/) Level AA criteria with:
  - Zero non-compliance issues in automated testing
  - No more than 2 issues per page in manual testing

### Confidentiality by multi-tenancy

- Dimensions: `secure`
- Qualities demonstrated: confidentiality, security, privacy
- URL: https://quality.arc42.org/requirements/confidentiality-by-multitenance

### Requirement

The system must enforce multi-tenant data isolation.

### Acceptance Criteria

- System designed with multi-tenant architecture
- Users of one tenant cannot access data specific to other tenants
- 100% data isolation between tenants enforced at all system levels
- Zero cross-tenant data access incidents in security testing

### Configurable UI theme

- Dimensions: `flexible`, `usable`
- Qualities demonstrated: flexibility, changeability, adaptability, configurability, customizability
- URL: https://quality.arc42.org/requirements/configurable-ui-theme

### Requirement

Users must be able to switch between the supported UI themes at runtime without losing their current page state.

### Acceptance Criteria

- Theme switching: with at least **3** supported themes, the selected theme is applied within **<= 2 s** for **>= 95%** of theme changes on the top **10** user screens; source: UI automation timing report; horizon: each release affecting theming.
- Preference persistence: the selected theme is restored correctly in **100%** of automated regression runs after page reload and new login on the latest major versions of the top **3** supported browsers; source: cross-browser UI test report; horizon: each release affecting theming or session handling.
- Gate behavior: if either threshold is missed, the release is blocked for changes to theming, styling, or user-preference persistence; source: release gate log; horizon: every qualifying release.

### Consistent keyboard shortcuts

- Dimensions: `usable`, `efficient`
- Qualities demonstrated: usability, consistency, user-experience, user-assistance, interaction-capability
- URL: https://quality.arc42.org/requirements/consistent-keyboard-shortcuts

### Context

The system provides keyboard shortcuts to select and execute functions within the graphical user interface, supporting keyboard-only navigation across all parts of the interface.

### Trigger

A user navigates the graphical interface using only a keyboard, without a mouse or trackpad.

### Acceptance Criteria

- User can perform all actions with keyboard alone
- Keyboard shortcuts are consistent throughout the system
- Identical or similar functions (save, copy, paste) have identical shortcuts across the entire system

### Content Moderation Fairness

- Dimensions: `reliable`, `safe`, `suitable`
- Qualities demonstrated: fairness, bias-mitigation, transparency, accountability
- URL: https://quality.arc42.org/requirements/content-moderation-fairness

### Context

An automated content moderation system classifies user posts for policy violations across multiple languages and regions. Prior studies show performance disparities by language, dialect, and demographic proxies. The system must ensure equitable error rates and transparent processes.

### Trigger

Trust & Safety moderation service processes content for platform operations and policy teams.

### Acceptance Criteria

- False positive rate (FPR) and false negative rate (FNR) gaps ≤ 2.0 percentage points between any language/dialect groups on stratified benchmark
- Macro-averaged F1 within ±3 points across languages/regions with published per-group PR curves
- Balanced, representative evaluation datasets include adversarial and dialectal examples, refreshed quarterly
- Documented mitigation applied (group-aware thresholds, calibration, post-processing) with validation that no group's precision or recall worsens by >3 points (regret bound)
- Appeal workflows and human-in-the-loop review provided for low-confidence decisions
- Reviewer overrides captured for continuous improvement
- Production disparities monitored with auto-alert on sustained (>24h) metric breaches
- Safe rollback to prior model enabled
- Monthly fairness reports produced with per-group metrics and mitigation notes
- Audit artifacts retained for 12 months

### Convenient online banking

- Dimensions: `usable`, `suitable`
- Qualities demonstrated: user-experience, convenience, interaction-capability, clarity, ease-of-use
- URL: https://quality.arc42.org/requirements/convenient-online-banking

### Context

A browser-based online banking application lets retail customers manage accounts, add payees, and make payments without branch or phone support. The add-payee-plus-first-payment flow must be fast and low-friction because it is both frequent and error-sensitive.

### Trigger

An authenticated customer adds a new payee and submits the first bill payment to that payee.

### Acceptance Criteria

- Task completion: in a usability test with **>= 20** representative customers, **>= 90%** complete the end-to-end flow without assistance within **<= 2 min** including second-factor confirmation; source: moderated usability test log; horizon: each major release affecting the payment flow.
- Correction rate: across the same test, the percentage of attempts requiring user correction of payee data, amount, or scheduling details before confirmation stays **<= 5%**; source: session recordings and task-observation protocol; horizon: each major release affecting the payment flow.
- Gate behavior: if either threshold is missed, release of the changed payment flow is blocked; source: release gate log; horizon: every qualifying release.

### Core functions can be used on multiple OSs

- Dimensions: `flexible`, `usable`, `operable`
- Qualities demonstrated: flexibility, portability, compatibility, interaction-capability
- URL: https://quality.arc42.org/requirements/core-functions-on-mac-win-linux

### Context

The system offers complicated core business functions and is available on different operating systems, especially macOS, Windows, and major Linux distributions.

### Trigger

A new release of one of the supported operating systems becomes available.

### Acceptance Criteria

- New OS release does not affect ability to work on the platform in comparable execution environments (CPU and memory capacity)
- Core functions can be re-used on macOS, Windows, and Linux applications without source code changes

### Credit Scoring Fairness

- Dimensions: `reliable`, `safe`, `suitable`
- Qualities demonstrated: fairness, bias-mitigation, transparency, accountability
- URL: https://quality.arc42.org/requirements/credit-scoring-fairness

### Context

An ML-based credit scoring model ranks applicants for loan approval. Historical data may embed societal or institutional biases. The system must ensure equitable performance and decisions across protected groups while maintaining predictive validity.

### Trigger

Retail banking credit risk platform (scoring + decisioning) processes loan applications for underwriting teams.

### Acceptance Criteria

- Demographic parity difference (selection-rate gap) limited to ≤ 0.10 across any protected-group comparison
- Disparate impact investigated and remediated if falling below 0.80 (4/5ths rule per EEOC Uniform Guidelines)
- Equal opportunity difference (TPR gap) ≤ 0.05 for "good payer" prediction across protected groups
- Equalized odds (TPR/FPR gaps) reported each release
- Group-wise calibration (Brier or ECE) maintained within ±2% across protected groups
- Mitigation documented (reweighing, adversarial debiasing, post-processing thresholds) with justified trade-offs
- Model cards and data sheets provided with quarterly group-wise performance dashboards
- Continuous disparity monitoring runs in production
- Alerts triggered when fairness metric breaches threshold for >24h with rollback or human review
- Auditable log maintained for model versions, features, thresholds, and mitigation settings for at least 24 months

### Terminology

- **True Positive Rate (TPR)**: Share of actual positives correctly predicted as positive; also called recall/sensitivity
- **Expected Calibration Error (ECE)**: Weighted average gap between predicted probability (by bin) and observed outcome frequency; lower is better

### Measurement & Verification

- Use held-out, stratified evaluation set with sufficient support per group (≥100 positives/negatives) and fixed data-splits
- Compute per-group metrics (selection rate, DI, parity diff, TPR/FPR, calibration curves) and confidence intervals (bootstrap 95% CI) each release
- Validate calibration via reliability diagrams and ECE/Brier
- Verify group-wise parity against thresholds
- Recommended tooling: scikit-learn + Fairlearn or AIF360
- Archive notebooks/reports with data and code hashes
- Monitor same metrics on fresh labeled samples in production
- Alert and trigger rollback/human review on sustained breaches

### CRM System Data Synchronization

- Dimensions: `flexible`, `operable`, `reliable`
- Qualities demonstrated: integrability, interoperability, data-quality, consistency
- URL: https://quality.arc42.org/requirements/crm-data-synchronization

### Context

The customer support system must integrate with existing CRM systems (Salesforce, HubSpot, Microsoft Dynamics) to maintain synchronized customer data and interaction history.

### Trigger

Customer data or interaction history is created, updated, or deleted in either the support system or connected CRM systems.

### Acceptance Criteria

- Implement standardized data mapping layer that transforms between internal data model and CRM-specific schemas without custom code for each CRM
- Support both real-time (webhook/API) and batch synchronization modes with configurable sync intervals (1min to 24hrs)
- Data synchronization completes within 5 minutes for incremental updates and 2 hours for full data refresh across all supported CRMs
- Provide conflict resolution strategies (last-write-wins, field-level merging, manual review queue) configurable per CRM and data type
- Integration handles authentication (OAuth 2.0, API keys) and rate limiting automatically with exponential backoff and retry logic; retries feed a dead‑letter queue (DLQ) after max attempts
- Maintain audit trail of all sync operations with detailed logs: timestamp, data changed, source system, success/failure status, error details
- Reconciliation: produce a bidirectional reconciliation report daily; alert when drift exceeds thresholds (e.g., >0.5% records diverged) and provide a remediation workflow
- RPO/RTO: recovery point objective ≤ 15 minutes for incremental sync; recovery time objective ≤ 30 minutes for resuming normal sync after incident

### Measurement & Verification

1. Replay tests confirm idempotent upserts and deduplication across CRMs
2. Chaos tests (rate‑limit bursts, auth expiry) drain through retries and DLQ without data loss; RPO/RTO targets met
3. Reconciliation job detects and repairs seeded drift within policy; observability dashboards display throughput, lag, and error taxonomy per CRM

### Cultural Sensitivity in Content

- Dimensions: `usable`
- Qualities demonstrated: usability, inclusivity, internationalization, i18n, interaction-capability
- URL: https://quality.arc42.org/requirements/cultural-sensitivity-in-content

### Requirement

All content within the system must be culturally sensitive and inclusive.

### Acceptance Criteria

- 100% of content is vetted for cultural sensitivity by subject matter experts through formal review process
- Less than 0.1% negative feedback related to cultural insensitivity from collected user feedback

### Data Localization for Citizen Records

- Dimensions: `secure`, `suitable`
- Qualities demonstrated: data-localization, data-sovereignty, compliance, privacy
- URL: https://quality.arc42.org/requirements/data-localization-for-citizen-records

### Context

A multi-country digital public-services platform stores citizen identity, tax, and benefits records for residents of several jurisdictions. Each jurisdiction requires that protected resident data be stored, processed, replicated, and recovered only inside its national boundary, and the Data Protection Officer needs continuous evidence that operations and recovery stay in-country.

### Trigger

A citizen record is created, updated, queried for processing, exported, replicated, or restored.

### Acceptance Criteria

- Jurisdiction tagging completeness: **100%** of records subject to localization receive a jurisdiction tag before first durable write, and tagging latency is **<= 1 s at p95** under **2,000 writes/second per jurisdiction**; scope: all create/update APIs and ingestion pipelines for citizen records; source: ingestion traces and schema-validation reports; horizon: rolling 5-minute windows. Assumption: up to 1 second of control-plane delay before first durable write is acceptable in this domain.
- Storage and processing locality: **100%** of primary copies, backups, and runtime workloads for localized records remain in approved locations within the assigned country, with placement violations **= 0 events**; scope: all production datasets, backup sets, services, and scheduled jobs handling localized records; source: storage inventory, backup catalog, workload-placement logs, and compliance scan reports; horizon: daily.
- Cross-border transfer prevention: unauthorized cross-border transfer attempts are blocked within **<= 2 s at p95**, with false-negative rate **= 0%** in quarterly control tests of **>= 500 transfer scenarios**; scope: exports, replication, analytics feeds, and support-access flows involving localized records; source: egress-policy logs, transfer-control test harness, and SIEM events; horizon: quarterly tests and rolling 30-day operations.
- Recovery locality: in quarterly failover exercises, **100%** of recovery actions for a localized country restore data only into approved in-country recovery locations, with unauthorized cross-border replica count **= 0 per exercise**; scope: failover of the primary production location for each localized country; source: disaster-recovery orchestration logs and exercise reports; horizon: each quarterly exercise.
- Failure-path behavior: if approved in-country storage or processing capacity for a country is unavailable for **> 60 s**, **100%** of new writes and exports for that country switch to protective restricted mode within **<= 30 s**, and compliance plus on-call alerting is emitted within **<= 5 min**; scope: all localized countries in production; source: control-plane health checks, policy-engine events, and alert logs; horizon: continuous monitoring. Assumption: temporary write/export restriction is preferable to unlawful cross-border placement.

### Monitoring Artifact

Localization compliance dashboard combining jurisdiction-placement scans, transfer-control test results, failover exercise reports, and searchable audit-evidence SLIs.

### Data Throughput for Visual Test System

- Dimensions: `efficient`, `usable`
- Qualities demonstrated: throughput, efficiency, performance, capacity
- URL: https://quality.arc42.org/requirements/data-throughput-for-visual-test-system

### Context

The system consists of hardware boards that enhance simple webcams with image recognition capabilities. These boards contain proprietary advanced image recognition algorithms embedded in their firmware and are used in applications such as license-plate recognition systems in public parking facilities. A test and verification system is used to validate firmware updates prior to release. The quality requirement pertains to the performance of this firmware test and verification system.

### Trigger

An update of the firmware is available, typically including additional functionality or improved recognition performance.

### Acceptance Criteria

- Test and verification system processes 1000 real-hours of video and image playback in less than 72 hours
- Minimum playback speed of 14 times real-time maintained (1000 hours / 72 hours ≈ 14)
- At least 14x playback speed maintained throughout entire test process (or less if tests performed in parallel)
- Accurate data transmission to device-under-test at accelerated rate
- No loss of video frames or degradation of image quality during accelerated playback
- Updated firmware recognizes images with at least accuracy of previous versions
- Complete processing of all 1000 hours of test data within 72-hour timeframe
- Accurate logging and reporting of test results including any anomalies or performance issues detected

### Detailed audit log

- Dimensions: `secure`, `suitable`
- Qualities demonstrated: accountability
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality scenario to describe an accountability requirement`.
- Note: >This "requirement" describes a solution approach to accountability.
- URL: https://quality.arc42.org/requirements/detailed-audit-log

### Context

The system stores personal data and operates in compliance with privacy and data protection regulations. Detailed audit logs of all user actions are crucial for ensuring accountability, transparency, and compliance, as well as facilitating the identification and investigation of any unauthorized or suspicious activities.

### Trigger

User submits a request to access personal data stored in the system.

### Acceptance Criteria

- System maintains detailed audit log of all user actions (data access, modification, deletion)
- 100% of user actions related to personal data are captured
- Each log entry includes timestamps and user identifiers
- Audit logs are tamper-proof to prevent unauthorized modifications
- Access restricted to authorized personnel only
- Logs retained for minimum of 5 years
- Logs searchable and retrievable within 24 hours of authorized request
- Regular integrity checks performed to ensure no tampering
- Secure backups maintained to prevent data loss
- Full compliance with relevant privacy and data protection regulations

### Detect inconsistent user input

- Dimensions: `usable`, `reliable`
- Qualities demonstrated: usability, consistency, user-experience, user-assistance, interaction-capability
- URL: https://quality.arc42.org/requirements/detect-inconsistent-user-input

### Context

System needs to validate user-entered data. It must be clarified what kind of inconsistencies can be recognized within the domain.

### Trigger

User manually enters data into the system.

### Acceptance Criteria

- System accepts consistent or correct data
- System rejects inconsistent or wrong data
- In case of inconsistent or wrong data, system displays appropriate messages that clearly explain the inconsistency or error
- Error messages are specific to the detected inconsistency type

### Deterministic behavior for medical imaging

- Dimensions: `reliable`, `safe`
- Qualities demonstrated: determinism, explainability, reproducibility
- URL: https://quality.arc42.org/requirements/deterministic-behavior-for-medical-imaging

### Context
An AI-enabled medical imaging system provides automated radiology triage for acute stroke detection. In this high-stakes clinical domain, deterministic behavior is essential for regulatory auditability and explainability, ensuring that a specific patient scan always results in the same diagnostic classification when revisited by auditors or clinicians.

### Trigger
A regulatory auditor initiates a retrospective validation by re-processing a historical dataset of 5,000 medical images through the inference engine.

### Acceptance Criteria
- At least 99.9% of inference responses for a fixed input set must produce identical bit-level classification outputs when re-executed under identical initial state conditions across a batch of 1,000 requests, verified by a test harness comparison tool during each release cycle.
- The variance in inference response time (jitter) must remain under 50ms for the p95 of 5,000 requests when the system is under a steady load of 10 requests per second, as measured by the APM dashboard over a rolling 24-hour window.
- Exactly 0 deviations in classification results must occur when processing the same 500 input samples in 10 different randomized sequence orders within a single processing window, measured by automated audit log analysis during weekly quality checks. `Assumption: Software-level synchronization mitigates non-deterministic hardware-level race conditions.`
- If a non-deterministic output variance is detected between primary and shadow execution paths during production monitoring, the system must tag the result as "unverified" and trigger a high-priority alert to the operations dashboard within 30 seconds of detection, as recorded by the telemetry system.
- The enforcement of deterministic execution logic must not increase peak memory consumption by more than 15% compared to the non-deterministic baseline when processing 50 concurrent scans, verified by resource profiling reports per release.

### Monitoring Artifact
Monthly Regulatory Compliance and Reproducibility Audit Report.

### Display Data Based on Context

- Dimensions: `usable`, `suitable`
- Qualities demonstrated: adaptability, functional-appropriateness
- URL: https://quality.arc42.org/requirements/display-data-based-on-context

### Context

The same workstation of a multi-tenant system within a factory might be used by different employees of different shifts.

### Trigger

User logs in to start their shift.

### Acceptance Criteria

- Expert system displays screens that were open when the user last logged off
- User's previous session state is restored automatically upon login

### Easily change cloud provider

- Dimensions: `flexible`
- Qualities demonstrated: flexibility, portability, maintainability, adaptability
- URL: https://quality.arc42.org/requirements/change-cloud-provider

### Requirement

The production system must be portable enough that it can be moved to another supported cloud provider without major redesign.

### Acceptance Criteria

- Migration effort: in a portability exercise for the current production baseline, migration of deployment, configuration, data access, and observability to a second supported cloud provider is completed within **<= 15 person-days**; source: portability exercise report; horizon: annual review or each major platform change.
- Functional equivalence: after the migration, **100%** of critical smoke tests and **>= 95%** of the top **20** automated integration tests pass on the target provider without application code changes outside provider-adaptation points; source: CI and migration validation report; horizon: each portability exercise.
- Gate behavior: if either threshold is missed, new provider-specific dependencies are not approved without an explicit architectural exception; source: architecture review record; horizon: every major platform change.

### Easy UI

- Dimensions: `usable`
- Qualities demonstrated: ease-of-use, user-experience, usability, interaction-capability
- URL: https://quality.arc42.org/requirements/easy-ui

### Context

Users need to register their smartphone as a two-factor authentication device. The enrollment flow must be self-explanatory.

### Trigger

A first-time user starts smartphone enrollment for 2FA.

### Acceptance Criteria

- ≥ 90% of ≥ 20 representative test users find the enrollment entry point within 3 min without facilitator help (moderated usability test, each major auth-UI change).
- ≥ 85% complete enrollment on the first attempt within 8 min without critical errors (same study).
- Release is blocked within 1 business day if either threshold is missed (release gate log).

### Efficient change of business rules

- Dimensions: `flexible`, `efficient`, `maintainable`
- Qualities demonstrated: flexibility, changeability, adaptability, configurability
- URL: https://quality.arc42.org/requirements/luggage-routing

### Context

Luggage routing at an airport depends on origin, destination, stopovers, and current government travel warnings. When an official warning changes, the affected routing rules must be updated quickly enough that inspections and routing decisions stay compliant.

### Trigger

An official government travel warning relevant to an origin, destination, or stopover location is published or changed.

### Acceptance Criteria

- Rule rollout latency: the updated routing rules are active in production within **<= 4 h** after publication of the warning; source: publication timestamp and deployment/change log; horizon: every warning change.
- Impact correctness: in the regression suite for affected routes, **100%** of impacted luggage-routing cases follow the new warning-based rule after rollout; source: rule-validation test report; horizon: every warning change.
- Failure-path behavior: if the updated rule cannot be rolled out within **4 h**, all newly affected routes switch to the predefined restrictive inspection path within **<= 15 min** and operations are alerted; source: rule-engine events and alert log; horizon: every missed rollout target.

### Efficient generation of test data

- Dimensions: `efficient`, `suitable`
- Qualities demonstrated: efficiency, time-behaviour, capacity
- URL: https://quality.arc42.org/requirements/efficient-generation-of-test-data

### Context

The complex database structure of system xyz contains a few dozens of tables with around 100 columns and several dozens of (foreign-key) relationships/dependencies between these tables. Data from production must only be used when heavily anonymized.

### Trigger

A tester needs a large set of test data for system xyz.

### Acceptance Criteria

- Specific generator creates 1GByte of test data for system xyz
- Test data created in less than 60 minutes
- Generated data respects foreign-key relationships and dependencies
- Production data only used when heavily anonymized

### Efficient save function

- Dimensions: `efficient`
- Qualities demonstrated: efficiency, time-behaviour, capacity
- URL: https://quality.arc42.org/requirements/efficient-save-function

### Requirement

User can add articles to shopping cart with immediate confirmation feedback.

### Acceptance Criteria

- System displays confirmation once article added reliably to cart
- Article counter above shopping cart icon is incremented
- Time between hitting add article button and displayed confirmation is less than 1 second in 99% of tests

### Efficient update of annual accounting report

- Dimensions: `efficient`, `flexible`, `maintainable`
- Qualities demonstrated: efficiency, maintainability, changeability
- URL: https://quality.arc42.org/requirements/annual-tax-update

### Context

The data output format of the annual accounting report is adjusted every year on December 31 to comply with legal and tax changes. The system must be able to generate the new format.

### Trigger

Updated specification of data output format for booking reports becomes available, usually October 31st.

### Acceptance Criteria

- Source code of reporting components is updated
- System creates report according to new specification
- Change can be implemented in less than 80 person hours

### Employee attempts to modify pay rate

- Dimensions: `secure`
- Qualities demonstrated: security, privacy, traceability, integrity
- Source reference: [Bass et al., 2021](/references/#bass2021software)
- URL: https://quality.arc42.org/requirements/employee-attempts-to-modify-pay-rate

### Context
The payroll system handles sensitive employee compensation data and must prevent unauthorized modifications while maintaining audit trails for compliance.

### Trigger
A disgruntled employee at a remote location attempts to improperly modify pay rate data during normal operation.

### Acceptance Criteria
- Unauthorized access attempts are detected and blocked
- All access attempts are logged in an audit trail
- Compromised data is restored from backups within 1 business day

### Encrypted storage

- Dimensions: `secure`
- Qualities demonstrated: confidentiality, security, privacy
- URL: https://quality.arc42.org/requirements/encrypted-storage

### Requirement

Data-at-rest must be encrypted using state-of-the-art encryption algorithms.

### Acceptance Criteria

- All data in databases and backups is encrypted
- Encryption uses proven algorithms from established vendors or open-source projects
- Minimum encryption standard: AES-256 or equivalent current best practice

### Every data modification is logged

- Dimensions: `secure`
- Qualities demonstrated: security, privacy, traceability, recoverability
- URL: https://quality.arc42.org/requirements/every-data-modification-is-logged

### Requirement

Every data modification must be logged in an immutable audit trail.

### Acceptance Criteria

- All data modifications (create, update, delete operations) are logged
- Logs stored in a data store that cannot be erased by system users
- Logs cannot be modified by system users
- 100% of data modification operations captured in audit log

### Expressive error messages

- Dimensions: `usable`
- Qualities demonstrated: usability, user-experience, fault-isolation, graceful-degradation, hazard-warning, user-assistance, interaction-capability
- URL: https://quality.arc42.org/requirements/expressive-error-messages

### Context

When error situations occur, they must be displayed to user in expressive, meaningful messages.

### Trigger

Error or exceptional situation occurs in technical infrastructure (memory overflow, out-of-memory, hardware error, virtual-machine-issue, container-related-issue).

### Acceptance Criteria

- System detects error, reports (as far as possible) to user and shuts down in controlled manner
- Message contains specific explanations and instructions on possible reactions
- Error detection occurs within 15 seconds
- Message to user (if still possible) within 1 second
- Shutdown within 15 seconds

### Facial Recognition Bias Mitigation

- Dimensions: `reliable`, `safe`
- Qualities demonstrated: bias-mitigation, fairness, accountability, transparency
- URL: https://quality.arc42.org/requirements/facial-recognition-bias-mitigation

### Context

A facial recognition system is being developed for secure access control in a multinational corporation with employees from diverse demographic backgrounds. Previous facial recognition systems have shown significant disparities in accuracy across different demographic groups, particularly for individuals with darker skin tones and women. The organization is committed to ensuring equitable performance across all demographic groups to prevent discriminatory outcomes and maintain security integrity.

### Trigger

The facial recognition algorithm processes images captured by security cameras at entry points and compares them against the employee database to grant or deny access.

### Acceptance Criteria

- Maximum false non-match rate (FNMR) difference of 1.5% between any demographic groups defined by intersections of gender, age range, and skin tone
- Overall accuracy rate of at least 98% across all demographic groups
- Documented testing demonstrates accuracy disparities between demographic groups reduced to within specified threshold
- Demographically balanced training dataset with representation proportional to global workforce demographics (±5% margin)
- Continuous monitoring automatically flags when performance disparities between demographic groups exceed 2% in production
- Transparent reporting of performance metrics across demographic groups in monthly system audits
- Fallback authentication mechanism triggered automatically when confidence scores fall below predetermined threshold
- Independent third-party testing for demographic performance disparities before deployment and annually thereafter

### Fast and accurate sensor

- Dimensions: `efficient`, `reliable`
- Qualities demonstrated: efficiency, preciseness, accuracy
- URL: https://quality.arc42.org/requirements/fast-accurate-sensor

### Requirement

The temperature sensor must accurately measure the temperature of floating liquid.

### Acceptance Criteria

- Temperature measurements taken at least 5 times per second (minimum 5Hz sampling rate)
- Measurement precision of +/- 0.2 degrees Celsius

### Fast creation of sales report

- Dimensions: `efficient`
- Qualities demonstrated: efficiency, performance, time-behaviour, speed, responsiveness
- URL: https://quality.arc42.org/requirements/fast-creation-of-sales-report

### Context

The warehouse business generates hundreds of thousands of sales per day, and users request a daily sales report as a PDF from the graphical user interface. Report generation must stay fast enough that users can work interactively instead of queueing manual follow-up work.

### Trigger

An authenticated user requests the daily sales report in PDF format for the previous business day.

### Acceptance Criteria

- Report latency: for a report covering up to **500,000** sales records, the PDF is generated within **<= 10 s at p95**; source: report-generation traces; horizon: rolling 7-day window.
- Generation success: the report-generation success rate is **>= 99.5%** for the same workload profile; source: application metrics and error log; horizon: rolling 30-day window.
- Failure-path behavior: if either threshold is missed in staging or production validation, release of report-generation changes is blocked until the target is restored; source: release gate log; horizon: every qualifying release.

### Fast deployment

- Dimensions: `reliable`, `operable`
- Qualities demonstrated: time-behaviour, operability, deployment-frequency, extensibility, lead-time-for-changes, cycle-time
- URL: https://quality.arc42.org/requirements/fast-deployment

### Requirement
Application deployments to production must be fast to enable frequent releases with minimal downtime.

### Acceptance Criteria
- Deployment of new version to production completes in less than 2 hours
- Application is fully rolled out to all production servers
- Deployment process is initiated by authorized developers

### Fast rollout of changes

- Dimensions: `efficient`, `operable`
- Qualities demonstrated: efficiency, operability, speed, time-to-market, speed-to-market
- URL: https://quality.arc42.org/requirements/fast-rollout-of-changes

### Context

More than 1000 devices running our system are distributed in the field in customer sites on various locations.

### Trigger

Operating system gets a security update which needs to be rolled out to every one of these devices.

### Acceptance Criteria

- OS update or patch is created
- Distribution and installation takes less than 4 weeks on all devices
- 100% of devices receive update within 4-week window

### Fast shutdown time (less than 10 sec)

- Dimensions: `efficient`
- Qualities demonstrated: time-behaviour, speed, shutdown-time
- URL: https://quality.arc42.org/requirements/fast-shutdown-time

### Context

The central employee database contains highly sensitive personal data. If credentials are suspected to be compromised, the system must isolate that database quickly enough to reduce the window for data exfiltration.

### Trigger

An authorized emergency shutdown command for the employee database is issued during a suspected credential-compromise incident.

### Acceptance Criteria

- Isolation latency: the database rejects all new application read and write connections within **<= 10 s** after the shutdown command is issued; source: database connection log and incident timeline; horizon: every shutdown drill and incident.
- Session cutoff: **100%** of active privileged application sessions against the database are terminated or blocked within **<= 20 s** after the shutdown command; source: session-management log and drill report; horizon: every shutdown drill and incident.
- Failure-path behavior: if either threshold is missed, network-level isolation is activated within **<= 60 s** and the incident is escalated automatically; source: network-control log and alert record; horizon: every missed shutdown target.

### Fast startup time (less than 90 sec)

- Dimensions: `efficient`
- Qualities demonstrated: time-behaviour, speed, performance, startup-time, elasticity, scalability
- URL: https://quality.arc42.org/requirements/fast-startup-time

### Requirement

The system must reach a defined ready-for-use state quickly after a cold start from the fully powered-off state.

### Acceptance Criteria

- Startup latency: on supported production hardware or runtime profiles, the system reaches ready state within **<= 90 s at p95** after the start command; source: startup timing report; horizon: each release affecting startup or deployment.
- Ready-state completeness: the startup success rate is **>= 99%** for cold starts, where ready state means that all mandatory services are initialized and the first health check or representative user transaction succeeds; source: startup test report; horizon: each release affecting startup or deployment.
- Gate behavior: if either threshold is missed, release of startup-affecting changes is blocked; source: release gate log; horizon: every qualifying release.

### Financial Data Accuracy for Reporting

- Dimensions: `reliable`, `suitable`
- Qualities demonstrated: data-quality, accuracy, correctness, integrity
- Source reference: This example was created with help from Anthropic-Claude-Sonnet-3.7 with the following prompt:

```
I want to add an example requirement (under _requirements) for data-quality.
It shall follow the pattern "Context/Background", "Source", "Metric/Acceptance Criteria" and contain precise metrics
for acceptance criteria.
```
- URL: https://quality.arc42.org/requirements/financial-data-accuracy

### Context

A financial management system processes transaction data from multiple sources (payment gateways, banking APIs, accounting software) to generate quarterly financial reports for regulatory compliance and executive decision-making. Data quality issues in source systems have previously led to reporting errors that required manual correction and restatement of financial results.

### Trigger

Financial transaction data is collected from various internal and external systems and must be validated before being used in regulatory reporting.

### Acceptance Criteria

- 99.99% accuracy of financial transaction data (maximum error rate of 1 in 10,000 transactions)
- 100% completeness of mandatory fields for all financial records
- Automated validation checks flag at least 98% of data anomalies before data enters reporting pipeline
- All data quality issues logged with severity levels and resolved within timeframes:
  - Critical: 1 hour
  - High: 4 hours
  - Medium: 24 hours
  - Low: 72 hours

### Financial transactions are ACID-compliant and fully reconcilable

- Dimensions: `reliable`, `secure`
- Qualities demonstrated: data-integrity, transactionality, consistency, correctness
- URL: https://quality.arc42.org/requirements/financial-transactions-are-acid-compliant

### Context

A core banking system processes payment transactions, account transfers, and balance updates across multiple services and databases.
Regulatory requirements and customer trust demand that no financial data is ever lost, duplicated, or left in a partial state — even during concurrent load, infrastructure failures, or network partitions.

### Trigger

A payment or account-transfer operation is initiated by a user, an automated process, or an external payment network (e.g., SWIFT, SEPA).

### Acceptance Criteria

- Every financial transaction is **fully ACID-compliant**: either all steps (debit, credit, audit log entry) commit atomically, or all are rolled back within **2 seconds** of failure detection — no partial transaction is ever visible to users or downstream systems
- Under concurrent load of **500 simultaneous transactions per second**, zero data anomalies (phantom reads, dirty reads, lost updates) are detected in automated concurrency tests using ≥ 10,000-iteration stress runs
- Simulated node failure (killing the primary DB node mid-transaction) results in **zero confirmed data loss or duplication**; recovery completes within **30 seconds** of failover
- The end-of-day reconciliation job detects **100% of inconsistencies** between ledger entries and account balances in a synthetic dataset of ≥ 1 million transactions seeded with a known 0.1% error rate
- Every committed transaction is immutably logged with: timestamp (UTC, µs precision), transaction ID, initiating user/system, before-image, after-image, and outcome — the audit log is append-only and hash-chained (tamper-evident)
- The system rejects duplicate submissions (same idempotency key) with **HTTP 409 in ≤ 200 ms**, even under concurrent retry storms of 50 simultaneous identical requests

### First-time onboarding without errors

- Dimensions: `usable`
- Qualities demonstrated: intuitiveness, usability, learnability, understandability
- URL: https://quality.arc42.org/requirements/first-time-onboarding-without-errors

### Context

A consumer-facing application should be understandable and usable by first-time users without prior training.

### Trigger

A user opens the product for the first time and attempts the primary onboarding flow.

### Acceptance Criteria

- In usability tests with at least **30** representative first-time users and no facilitator guidance, at least **80%** complete the primary onboarding flow on the first attempt without critical errors.
- No core feature requires more than **3 interactions** from the home screen to reach its starting point.
- Median completion time for onboarding is **<= 5 minutes** for successful first-time attempts.
- Post-test usability score reaches **SUS >= 75**.
- At least **85%** of participants rate navigation and labeling as clear (top-2-box on a 5-point scale).

### Fleet OTA updates with safe rollback

- Dimensions: `operable`, `maintainable`
- Qualities demonstrated: updateability, maintainability, recoverability, availability, security
- URL: https://quality.arc42.org/requirements/fleet-ota-updates-with-safe-rollback

### Context

A long-lived IoT product fleet is deployed across customer sites and updated remotely over heterogeneous networks.  
Timely and safe delivery of software fixes is required to reduce security exposure and operational support effort.  
This quality is critical for fleet operations and product security stakeholders.

### Trigger

A signed software update is released for deployment to active devices in the production fleet.

### Acceptance Criteria

- Deployment reach: at least **99%** of active online devices receive and activate the released update within **48 hours**; scope: devices that connected at least once during the 48-hour window; source: fleet management telemetry; horizon: each update release.
- Update success rate: successful update completion is **>= 98.5%** across targeted devices without manual intervention; scope: per release wave; source: device update status reports; horizon: each update release.
- Atomic failure handling: for failed updates, automatic rollback restores the previously running version within **<= 2 minutes** in **>= 99.9%** of failure cases; scope: controlled failure-injection tests with at least **500** devices per release; source: integration test rig and device heartbeat logs; horizon: each update release.
- Remote recoverability: incidents caused by update attempts are resolved without physical access for **>= 99.5%** of affected devices within **24 hours**; scope: update-related incidents in production; source: service-desk records and fleet operation logs; horizon: rolling quarter.
- Failure-path rollout control: if post-update critical-fault rate exceeds **0.5%** of updated devices over any **30-minute** window, rollout is automatically paused within **<= 10 minutes** and on-call alerting is issued within **<= 5 minutes**; scope: production rollout waves; source: rollout controller metrics and alerting system; horizon: continuous during rollout.

### Monitoring Artifact

Fleet update compliance dashboard with per-wave reach, rollback, fault-rate, and remote-recovery metrics.

### Fraud detection drift detected within 1 hour

- Dimensions: `reliable`, `operable`
- Qualities demonstrated: drift-detectability, reliability, diagnosability, data-quality
- URL: https://quality.arc42.org/requirements/fraud-detection-drift-detected-within-1-hour

### Context

A payment platform uses a machine-learning model to score card and wallet transactions for fraud risk.
Fraud patterns, merchant behavior, customer behavior, and attack campaigns change over time.
The fraud team needs early evidence when production traffic or model behavior diverges from the validated release baseline.

### Trigger

Production transaction traffic is scored by the fraud detection model.

### Acceptance Criteria

- Feature drift: for the top **30** model features, distribution drift is evaluated every **15 min** against the approved release baseline; source: feature-monitoring job; horizon: continuous production monitoring.
- Score drift: if the prediction-score distribution's Population Stability Index (PSI) against the approved release baseline is **PSI >= 0.20** for **2 consecutive 15-minute windows**, an alert is emitted within **<= 60 min** of the first breached window; source: model-monitoring dashboard and alert log.
- Segment localization: every drift alert ranks merchant category, country, and payment method by their **per-segment PSI** against the release baseline and explicitly names every segment whose **per-segment PSI >= 0.20**; the active model version is always recorded; source: drift-analysis report.
- Delayed-label quality drift: once confirmed fraud labels are available, recall and false-positive-rate are evaluated daily against the release baseline on a rolling 7-day window; a **recall drop of >= 3 percentage points** or a **false-positive-rate rise of >= 0.5 percentage points** creates a fraud-analyst review task within **1 business day**; source: labeled-outcome evaluation job.
- Failure-path behavior: if monitoring data is missing for **> 30 min**, the system emits a high-priority monitoring-gap alert and marks the model-health status as **unknown**; source: monitoring heartbeat and incident log.

### Monitoring Artifact

Fraud model drift dashboard with feature drift, score drift, delayed-label quality drift, affected segments, and alert history.

### Global Explainability

- Dimensions: `suitable`, `safe`, `reliable`
- Qualities demonstrated: explainability
- URL: https://quality.arc42.org/requirements/global-explainability

### Requirement

Each production AI model must provide a global explanation view that lets authorized administrators inspect the overall influence of input features on model decisions.

### Acceptance Criteria

- Report latency: a global explanation report for the current production model is generated within **<= 5 min** on the standard validation dataset of up to **100,000** decisions; source: explainability job log; horizon: each model release.
- Feature coverage: the report includes ranked contribution information for **100%** of model input features, and any protected or policy-restricted feature usage is flagged in **100%** of reports; source: model metadata and explanation report validation; horizon: each model release.
- Gate behavior: if either threshold is missed, promotion of the model to production is blocked; source: model release gate log; horizon: every model release.

### Good code readability score

- Dimensions: `maintainable`
- Qualities demonstrated: readability, legibility, code-readability, code-complexity, maintainability
- Stakeholder: developer
- URL: https://quality.arc42.org/requirements/good-code-readability-score

### Context

We use the [SonarQube](https://www.sonarsource.com/open-source-editions/) to obtain several kinds of metrics on the system.

All source code requires a [SonarQube cognitive complexity](https://www.sonarsource.com/blog/cognitive-complexity-because-testability-understandability/) score of 15 or lower.

(See their [whitepaper](https://www.sonarsource.com/resources/cognitive-complexity/) for details)


### Requirement
New and changed production code must stay within a bounded cognitive-complexity limit.

### Acceptance Criteria

- Every new or changed function/method has cognitive complexity ≤ 15 (static-analysis report, every pull request).
- 100% of new and changed production files are included in the analysis run (CI analysis log, every pull request).
- Merge is blocked within 10 min if either threshold is missed (CI gate log).

### Governance policies are enforced and auditable

- Dimensions: `operable`, `secure`
- Qualities demonstrated: governability, compliance, accountability, auditability, security
- URL: https://quality.arc42.org/requirements/governance-policy-enforcement

### Context

Multiple services process sensitive and regulated data under centrally defined organizational policies (for access control, data handling, retention, and model usage).

### Trigger

A policy is created, changed, or violated.

### Acceptance Criteria

- New/updated policies are distributed to all in-scope enforcement points within **15 minutes**.
- At least **99.5%** of in-scope requests are evaluated against active policies.
- Policy violations are detected and logged within **60 seconds**.
- Corrective action (automatic block/quarantine or incident ticket) starts within **5 minutes** of violation detection.

### Grounded and explainable loan decision

- Dimensions: `safe`, `reliable`, `suitable`
- Qualities demonstrated: groundedness, explainability, traceability, accountability
- URL: https://quality.arc42.org/requirements/grounded-explainable-loan-decision

### Context

An AI-assisted lending system recommends approval, rejection, or manual review for loan applications.
The decision must be understandable to applicants and grounded in verified application data, credit-policy rules, and approved risk-model outputs.

### Trigger

The lending system produces a recommendation for a submitted loan application.

### Acceptance Criteria

- Explanation clarity: the applicant-facing explanation lists the top **3** decision factors in plain language and is no longer than **150 words**; source: explanation-rendering test and content review; horizon: each release.
- Factor grounding: **100%** of explanation factors are grounded in recorded source data used at decision time, such as application fields, credit-bureau attributes, policy rules, or approved model-output artifacts; source: decision trace validator; horizon: each release and monthly audit.
- Adverse-action traceability: **100%** of adverse-action reasons are mapped to approved reason codes and traceable to source data used at decision time; source: adverse-action audit report; horizon: monthly.
- Failure-path behavior: if any explanation factor cannot be grounded in recorded source data, the system must not issue an automated final decision and routes the application to manual review; source: release-gate test suite and production decision logs; horizon: each release and continuous monitoring.
- Audit sample: in monthly audit samples of at least **500** decisions, at least **98%** of explanations are both understandable to reviewers and fully source-supported; unsupported critical adverse-action reasons occur in **0** cases; source: compliance audit sample; horizon: monthly.

### Monitoring Artifact

Monthly lending-decision audit report combining explanation quality review, source-grounding validation, adverse-action reason mapping, and manual-review routing metrics.

### Grounded customer support answer

- Dimensions: `reliable`, `suitable`
- Qualities demonstrated: groundedness, correctness, traceability
- URL: https://quality.arc42.org/requirements/grounded-customer-support-answer

### Context

A customer-support assistant answers questions about billing, cancellation, account settings, and product behavior using the current product documentation and support knowledge base.
Because customers may act on these answers, factual claims must be grounded in approved source material instead of generated from model priors alone.

### Trigger

A customer asks the assistant a support question through chat or the help-center search interface.

### Acceptance Criteria

- Source support: in a weekly groundedness evaluation set of at least **500** representative Q&A pairs, at least **98%** of factual claims in assistant answers are supported by retrieved source passages; source: groundedness evaluation report; horizon: weekly.
- Citation coverage: **100%** of answers containing factual product, billing, cancellation, or account-behavior claims include at least **1** link to an approved source document; source: answer telemetry and citation validator; horizon: rolling 7 days.
- Refusal behavior: if no source passage reaches the configured retrieval-confidence threshold, the assistant states that it does not have enough information instead of producing a factual answer; source: no-context test suite; horizon: each release.
- Critical unsupported claims: unsupported claims about pricing, legal terms, data retention, security controls, or customer obligations occur in **0** sampled answers; source: weekly review sample and escalation log; horizon: weekly.
- Auditability: for **100%** of sampled answers, the system stores the prompt, retrieved source identifiers, generated answer, citations, model version, and retrieval configuration; source: audit-log completeness report; horizon: rolling 30 days.

### Monitoring Artifact

Groundedness evaluation dashboard combining retrieval traces, citation validation, sampled human review results, and unsupported-claim alerts.

### Grounded medical triage draft

- Dimensions: `safe`, `reliable`, `suitable`
- Qualities demonstrated: groundedness, correctness, traceability, safety
- URL: https://quality.arc42.org/requirements/grounded-medical-triage-draft

### Context

A clinical assistant drafts non-final triage notes from patient-record data, current encounter notes, and approved medical guidelines.
Clinicians remain responsible for final decisions, but unsupported patient facts or guideline claims can still create safety risks.

### Trigger

A clinician requests a triage recommendation draft for a patient encounter.

### Acceptance Criteria

- Patient-fact grounding: **100%** of patient-specific facts in the draft are present in the patient record, current encounter notes, or clinician-provided input; source: source-span validation report; horizon: each release and monthly audit.
- Guideline grounding: **100%** of guideline-based statements cite an approved guideline identifier and version; source: guideline citation validator; horizon: each release and monthly audit.
- Uncertainty behavior: if required source data is missing, contradictory, or older than the configured clinical freshness threshold, the draft explicitly lists the uncertainty and does not infer missing facts; source: clinical scenario test suite; horizon: each release.
- High-risk unsupported recommendations: in a monthly clinical review of at least **300** drafts, unsupported high-risk recommendations occur in **0** cases; source: clinical review report; horizon: monthly.
- Export guard: if source-span validation fails for any patient fact or guideline statement, the draft is marked **unverified** and cannot be copied into the final clinical note without clinician override and reason capture; source: audit log and UI telemetry; horizon: continuous monitoring.

### Monitoring Artifact

Clinical groundedness review report with source-span coverage, guideline citation coverage, uncertainty cases, overrides, and unsupported-recommendation findings.

### Handle sudden increase in traffic

- Dimensions: `reliable`
- Qualities demonstrated: resilience, reliability, elasticity, scalability
- URL: https://quality.arc42.org/requirements/handle-sudden-increase-in-traffic

### Context

The web application runs in a cloud-based environment with multiple servers. It must remain serviceable during sudden traffic surges and tolerate single-node failure.

### Trigger

A quarterly resilience drill simulates traffic at 300% of baseline within 5 min, sustained for 15 min.

### Acceptance Criteria

- Successful response rate ≥ 99% and p95 end-user latency ≤ 4 s during the surge (load-test + APM report, quarterly).
- Loss of one serving node during the surge causes zero accepted-request loss; traffic redistributes to healthy nodes within 60 s (load-balancer metrics, quarterly).
- If either threshold is missed, rollout of the affected scaling/traffic-management change is blocked within 1 business day (release gate log).

### Hiring Algorithm Bias Mitigation

- Dimensions: `reliable`, `suitable`
- Qualities demonstrated: bias-mitigation, fairness, transparency, accountability, explainability
- URL: https://quality.arc42.org/requirements/hiring-algorithm-bias-mitigation

### Context

A large organization is implementing an AI-powered resume screening and candidate ranking system to streamline its hiring process. Historical hiring data may contain implicit biases that have led to underrepresentation of certain demographic groups. The system must be designed to identify and mitigate these biases to ensure fair consideration of all qualified candidates regardless of gender, ethnicity, age, or other protected characteristics.

### Trigger

The hiring algorithm processes resumes and application materials submitted through the company's applicant tracking system, comparing them against job requirements and historical hiring patterns to rank candidates for human review.

### Acceptance Criteria

- Statistical parity within ±5% across demographic groups (selection rates for protected groups)
- Protected characteristics (name, gender, age, address, proxies) removed or masked during initial screening phase
- Equal true positive rates (±3%) across all demographic groups when predicting candidate success
- Bias detection component continuously monitors for emergent biases and alerts when disparate impact exceeds 80% threshold (4/5ths rule)
- Transparent explanations for candidate rankings focus solely on job-relevant qualifications (see [explainability](/qualities/explainability))
- Audit log maintained for all algorithmic decisions with sufficient detail for retrospective bias analysis
- At least 90% of algorithm-recommended candidates who proceed to interview evaluated as qualified by human recruiters
- Diverse validation dataset represents broader labor market demographics for each job category
- "Human-in-the-loop" design requires human review before any final decisions made

### Inclusive User Testing

- Dimensions: `usable`
- Qualities demonstrated: usability, inclusivity, interaction-capability
- URL: https://quality.arc42.org/requirements/inclusive-user-testing

### Requirement

Conduct user testing with diverse groups to ensure the software meets various needs.

### Acceptance Criteria

- Include participants from at least 5 different demographic groups in user testing sessions
- Achieve an average usability score of 85/100 across all demographic groups

### Independent enhancement of subsystem

- Dimensions: `efficient`, `flexible`, `maintainable`
- Qualities demonstrated: efficiency, maintainability, changeability, adaptability, agility
- URL: https://quality.arc42.org/requirements/independent-enhancement-of-subsystem

### Context

Extensions or changes to a subsystem should be possible independently of all other subsystems.

### Trigger

Development team changes code or configuration within a subsystem or component.

### Acceptance Criteria

- No other subsystem needs to be changed
- For all other subsystems, the following remains identical:
  - Source code
  - Compile, build and test processes
  - Deployment, installation and configuration

### Independent replacement of subsystem

- Dimensions: `flexible`, `operable`, `efficient`
- Qualities demonstrated: adaptability, agility, changeability, efficiency, maintainability
- URL: https://quality.arc42.org/requirements/independent-replacement-of-subsystem

### Context

The system will use an external payment provider. If a different payment provider is chosen, the system needs to be able to quickly adapt to the new payment provider.

### Trigger

Development team needs to integrate a new payment provider.

### Acceptance Criteria

- Integration can be done without changing any other subsystem or component
- For all other subsystems, the following remains identical:
  - Source code
  - Compile, build and test processes
  - Deployment, installation and configuration

### Interoperable with Java 12

- Dimensions: `operable`
- Qualities demonstrated: compatibility, interoperability, backward-compatibility
- Stakeholder: management, product-owner, user
- URL: https://quality.arc42.org/requirements/interoperable-with-java-12

### Context

The system has been implemented on the Java(tm) virtual machine.

### Requirement

The application must run on supported Java runtime baselines (12, 17, 21) from a single build artifact.

### Acceptance Criteria

- 100% of smoke tests pass on reference runtimes for Java 12, 17, and 21 (CI compatibility matrix, every release).
- Zero source-code forks or runtime-specific packaging branches required (build-config review, every release).
- If any baseline fails, that runtime is removed from the supported-platform list and its distribution is blocked within 1 business day (release gate log).

### Interruptable backend process

- Dimensions: `usable`
- Qualities demonstrated: usability, user-experience, time-behaviour, interaction-capability
- URL: https://quality.arc42.org/requirements/interruptable-backend-process

### Context

Report generation is performed in several parallel threads or processes, eventually on different OS-processes, virtual machines or containers. Cancelling or aborting needs to handle distributed execution.

### Trigger

User has (accidentally) started report generation, but now wants to interrupt and clicks `abort` or `cancel` button or selects cancel-function via keyboard.

### Acceptance Criteria

- System interrupts report generation
- Current generation state saved (in case user wants to continue later)
- Control returns to user interface
- User gets back full keyboard or mouse control within at most 10 seconds
- All backend generation tasks or processes have acknowledged abort/cancel signal

### Keep data on error

- Dimensions: `reliable`, `usable`
- Qualities demonstrated: reliability, robustness, ease-of-use, user-experience, interaction-capability
- URL: https://quality.arc42.org/requirements/keep-data-on-error

### Context

A user wants to open a new bank account and is required to identify herself using an external system.

### Trigger

External identification system returns an error that identification could not be completed.

### Acceptance Criteria

- System keeps any data entered by the user when external identification fails
- 100% of user-entered data is preserved when identification error occurs
- User can resume account opening process after identification is resolved without re-entering data

### Local Explainability

- Dimensions: `suitable`, `safe`, `reliable`
- Qualities demonstrated: explainability
- URL: https://quality.arc42.org/requirements/local-explainability

### Context

Using AI to generate decisions involves finding patterns in large sets of data. Individual results are subject to statistical noise and may be erroneous. Specifically for systems in high risk scenarios, giving users an explanation is necessary to allow additional oversight and appeal processes. User has submitted a request and the system used Artificial Intelligence (AI) to decide if the request should be approved or not.

### Trigger

User was subject of an AI-generated decision by the system and is informed of the decision.

### Acceptance Criteria

- The explanation shows the top 3 decision factors that drove the outcome, each with its direction of influence and a normalized contribution score.
- The explanation is rendered within 2 seconds and is shown in the same response or screen as the decision, without additional user action.
- The explanation uses plain language, and is no longer than 150 words.
- If no valid explanation can be generated, the system must not issue a final automated decision and must route the case for human review.

### Localizable to several languages

- Dimensions: `flexible`
- Qualities demonstrated: flexibility, maintainability, modifiability, adaptability, accessibility, localizability, internationalization, i18n
- URL: https://quality.arc42.org/requirements/localizable-to-n-languages

### Requirement

The graphical user interface must be localization-ready so that additional languages and writing directions can be introduced without redesign of the application.

### Acceptance Criteria

- Externalized text coverage: **100%** of user-visible UI text on the top **20** screens is stored in translatable resource files instead of source code literals; source: localization static scan; horizon: each release affecting UI.
- Locale enablement effort: a new locale, including one locale with a different writing direction or non-Latin script, can be enabled within **<= 2 person-days** without application code changes outside localization, styling, or configuration layers; source: localization exercise report; horizon: annual review or each major UI release.
- Gate behavior: if either threshold is missed, release of UI changes is blocked until localization readiness is restored; source: release gate log; horizon: every qualifying release.

### Low change-failure rate

- Dimensions: `reliable`
- Qualities demonstrated: change-failure-rate, reliability
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality scenario to describe a change-failure-rate requirement`.
- URL: https://quality.arc42.org/requirements/low-change-failure-rate

### Requirement

Software development team deploys new versions to production with low failure rate.

### Acceptance Criteria

All metrics measured over three-month period:

- At least 98% of successful deployments where all changes rolled out without causing production incidents
- Severe incidents directly caused by deployments (e.g., application crashes, data loss) do not exceed 1 per month on average
- Minor incidents (e.g., non-critical bugs, minor performance issues) directly caused by deployments do not exceed 2 per month on average
- Rollback rate due to deployment issues does not exceed 2% of all deployments
- Average time to resolve deployment-related incidents does not exceed 4 hours for severe incidents and 2 hours for minor incidents
- Customer complaints related to degraded service or deployment issues do not exceed 1 per month on average

### Low effort deployment

- Dimensions: `operable`
- Qualities demonstrated: compatibility, interoperability, portability
- URL: https://quality.arc42.org/requirements/low-effort-deployment

Idea: [Bass et al., 2021](/references/#bass2021software)

### Context

The product consumes an external authentication/authorization service from a component marketplace. Adopting new service releases must stay within predictable time and effort bounds.

### Trigger

The product owner decides to incorporate a new marketplace release of the auth/authz service.

### Acceptance Criteria

- Elapsed time from adoption decision to production deployment ≤ 40 h (release tracker, each service-version upgrade).
- Total human effort ≤ 120 person-hours across dev, test, ops, and release management (work-log summary, each service-version upgrade).
- Zero Sev-1/Sev-2 deployment-induced incidents and zero contractual availability breaches during the first 7 days after rollout (incident log + SLA dashboard).

### Low impact diagnosis

- Dimensions: `efficient`
- Qualities demonstrated: efficiency, time-behaviour, resource-efficiency
- URL: https://quality.arc42.org/requirements/low-impact-diagnosis

### Context

Diagnostics subsystem must have minimal impact on system performance.

### Trigger

Diagnostics subsystem is running during normal system operation.

### Acceptance Criteria

- Diagnostics subsystem has only minor impact on execution time of system functions and transactions
- Performance degradation due to diagnostics is measurable but minimal
- System functions execute with negligible overhead when diagnostics enabled

### Low-overhead query execution measurement

- Dimensions: `efficient`
- Qualities demonstrated: efficiency, time-behaviour, memory-usage, resource-efficiency, resource-utilization
- URL: https://quality.arc42.org/requirements/query-execution-management

### Context

The system runs CPU- and memory-intensive database queries. A diagnostic component can measure execution times when `query-diagnosis` is enabled.

### Trigger

Query diagnosis is enabled in production or a staging environment.

### Acceptance Criteria

- p95 runtime overhead ≤ 1% for queries with baseline ≥ 200 ms, and ≤ 2 ms absolute for faster queries, across the top-50 benchmark suite (benchmark report, each diagnostic-component release).
- Peak resident-memory increase ≤ 1 MB vs. baseline under the same benchmark (profiler report, each diagnostic-component release).
- If either threshold is missed, diagnosis stays disabled by default and the component release is blocked within 1 business day (release gate log).

### Maintainable checking strategies

- Dimensions: `efficient`
- Qualities demonstrated: efficiency, maintainability
- URL: https://quality.arc42.org/requirements/maintainable-checking-strategy

### Context

[HTMLSanityChecker](https://github.com/aim42/htmlSanityCheck) (short: HtmlSC) is an open-source checker for HTML files. It can check multiple types of problems, but sometimes users need specific additional checks (like grammar, use of certain vocabulary, use of certain stylesheets etc). Such changes are usually **not** integrated in the main branch, but will remain in user-specific forks.

### Trigger

A user needs a specific kind of check currently not available in HtmlSC.

### Acceptance Criteria

- New checking algorithm is implemented and integrated in (a fork of) HtmlSC
- Integration of new check into HtmlSC takes less than 15 minutes for a developer knowledgeable in HtmlSC
- Purely structural checks (like checking availability of referenced external URLs) are implemented in less than 1 person-day of effort
- Effort and duration for implementing complex checks (e.g., those needing AI algorithms) cannot be constrained in advance

### Medical triage model confidence is calibrated

- Dimensions: `safe`, `reliable`
- Qualities demonstrated: calibration, safety, accuracy, reliability
- URL: https://quality.arc42.org/requirements/calibrated-medical-triage-confidence

### Context

A medical triage model assigns urgency categories and confidence values for incoming patient cases.
Clinicians use the confidence value to decide whether to accept the recommendation directly, review it more carefully, or escalate immediately.

### Trigger

The triage model produces a recommendation and confidence score for a patient case.

### Acceptance Criteria

- Confidence reliability: among cases assigned **>= 90%** confidence, observed correctness is at least **87%** in monthly clinical review samples; source: labeled outcome review; horizon: monthly.
- Critical-condition calibration: for high-risk categories, underconfidence and overconfidence gaps must each remain within **<= 5 percentage points** against confirmed clinical outcomes; source: safety validation report; horizon: each release.
- Abstention threshold: if model confidence is below the configured threshold for a critical condition, the system must route the case to clinician review instead of presenting a high-confidence recommendation; source: clinical scenario test suite; horizon: each release.
- Site-level calibration: calibration metrics are reported separately for each clinical site with at least **200** labeled cases per quarter; source: site calibration dashboard; horizon: quarterly.
- Failure-path behavior: if calibration monitoring data is unavailable for **> 7 days**, triage recommendations are marked "confidence unverified" until monitoring is restored.

### Minimize jitter in real-time data streaming

- Dimensions: `reliable`
- Qualities demonstrated: jitter, predictability, latency
- URL: https://quality.arc42.org/requirements/minimize-jitter

### Context

Reduce and control [jitter](/qualities/jitter) in the real-time streaming of data. System operates under standard network conditions during operational phase.

### Trigger

Continuous transmission of real-time data from sensors over network.

### Acceptance Criteria

- Variance in delay between data packets (jitter) does not exceed 5 milliseconds for 95% of transmitted packets
- When jitter exceeds 5ms threshold, system employs buffering mechanisms to smooth data flow, ensuring effective jitter experienced by end-user remains below 7 milliseconds
- System detects and logs instances of high jitter (above 5 milliseconds) in real-time
- Alerts triggered for technical team when high jitter instances exceed 5% of total packets in any 10-minute window
- During peak load times, allowable jitter can increase to maximum of 10 milliseconds, but such instances do not exceed 2% of total packets transmitted in 24-hour period

### Modular System for Data Analysis

- Dimensions: `efficient`, `flexible`, `maintainable`
- Qualities demonstrated: composability, modularity, extensibility, stability
- URL: https://quality.arc42.org/requirements/modular-system-for-data-analysis

### Requirement

The data-analysis platform must allow a new analysis module, such as an NLP step for unstructured social-media data, to be added through defined extension points without broad changes to existing import, visualization, or export modules.

### Acceptance Criteria

- Integration effort and blast radius: in a module-integration exercise, a new analysis module that uses the standard module interfaces is connected end-to-end within **<= 4 h** of engineering effort, while requiring code changes in **<= 2** existing modules outside the extension itself; source: exercise report and pull-request diff review; horizon: each major release.
- Compatibility and stability: after integration, **>= 95%** of the top **20** representative analysis flows using the new module complete successfully, and analysis flows that do not use the new module show **<= 2%** increase in error rate and **<= 5%** increase in p95 runtime; source: automated integration suite and benchmark report; horizon: each module-integration exercise.
- User activation and gate: a trained analyst enables the new module in a standard workflow within **<= 30 min** using product documentation only; if any threshold above is missed, release of the changed extension mechanism is blocked within **<= 1 business day**; source: usability exercise log and release gate record; horizon: each module-integration exercise.

### Monolith loose coupling: change blast radius

- Dimensions: `maintainable`, `suitable`, `efficient`
- Qualities demonstrated: loose-coupling, modularity, modifiability, maintainability, cohesion
- URL: https://quality.arc42.org/requirements/monolith-loose-coupling-change-blast-radius

### Context

A conventional client/server business application with a modular monolith backend (UI, application, domain, persistence modules).

### Trigger

A new business rule is added in one functional area (for example pricing or invoicing).

### Acceptance Criteria

- Per change, implementation touches no more than **2 modules** outside the owning functional module.
- Architecture tests in CI report **0** violations of declared layer/module dependency rules (for example no direct UI -> persistence dependencies, and no cyclic dependencies across modules).
- Over a rolling 90-day window, at least **90%** of classes in changed modules keep class coupling (CBO) **<= 10** after the change.
- Over a rolling 90-day window, at least **90%** of functional changes are implemented without code changes in unrelated modules.
- Over a rolling 90-day window, at least **80%** of such changes are delivered (code, tests, and release) by one developer within **<= 3 working days**.

### Multilinguality Support

- Dimensions: `usable`
- Qualities demonstrated: usability, inclusivity, accessibility, interaction-capability, internationalization, localizability
- URL: https://quality.arc42.org/requirements/multilinguality-support

### Requirement

Core user journeys must be fully translated and linguistically reviewed for every supported locale before release.

### Acceptance Criteria

- The top 20 user journeys (UI, onboarding, error messages, help) are available in ≥ 10 locales with ≥ 98% translated strings and zero placeholder/fallback-language texts (i18n completeness report, every release).
- Native-language review of the top 20 journeys per changed locale finds ≤ 2 major translation defects (linguistic QA report, every release).
- If a locale misses either threshold, it is de-listed from the supported set for that release within 1 business day (release gate log).

### Near instant search results

- Dimensions: `usable`, `efficient`
- Qualities demonstrated: efficiency, performance, time-behaviour, speed, interaction-capability
- Note: Please note: This requirement is tagged both efficient and usable
- URL: https://quality.arc42.org/requirements/near-instant-search-results

### Context
The travel portal forwards flight search queries to multiple airlines and booking agencies, requiring fast response times to maintain user engagement.

### Trigger
A user searches for available flights by entering departure and arrival dates and locations via the graphical user interface.

### Acceptance Criteria
- First search result displayed within 500 milliseconds
- Additional results loaded progressively without blocking UI

### New Features Introduce No Bugs

- Dimensions: `reliable`
- Qualities demonstrated: predictability, reliability, changeability
- Stakeholder: management, product-owner, developer
- URL: https://quality.arc42.org/requirements/new-features-introduct-no-bugs

### Requirement

Each newly released feature must have a bounded escaped-defect rate in the days immediately after release.

### Acceptance Criteria

- Escaped defect count: each new feature introduces **<= 1** customer-visible defect within the first **10 days** after release; source: defect tracker with release linkage; horizon: every feature release.
- Severity guard: each new feature introduces **0** high-severity production defects within the first **10 days** after release; source: incident log and release report; horizon: every feature release.
- Gate behavior: if either threshold is missed, the next feature release requires explicit corrective-action approval before promotion; source: release governance record; horizon: every missed feature-quality target.

### New user completes core tasks without prior training

- Dimensions: `usable`
- Qualities demonstrated: learnability, usability, user-error-protection
- URL: https://quality.arc42.org/requirements/new-user-completes-core-tasks-without-training

### Context

An enterprise ERP system is rolled out to employees across finance, procurement, and HR departments.
Users have domain expertise (e.g., accountants understand invoices) but receive no system-specific training before their first session.
The organisation cannot afford extended training programmes; the software must be self-explanatory to domain-knowledgeable users.

### Trigger

A new user with relevant domain knowledge (e.g., certified accountant, experienced buyer) logs into the ERP for the first time, with no prior demo, tutorial, or instructor-led training.

### Acceptance Criteria

- In a moderated usability test with **≥ 12 first-time users**, **≥ 80% complete all 5 predefined core tasks** (create purchase order, approve invoice, submit expense claim, generate monthly cost-centre report, update supplier record) **within 30 minutes total**, using only in-application guidance
- The **task success rate** (fully correct completion without facilitator intervention) is **≥ 75% per individual task** across test participants
- **No core task requires more than 7 sequential screen interactions** (clicks, form fields, confirmations) to complete on the happy path
- When a user makes an input error, the system surfaces a **contextual, actionable error message within 1 second**; no error message references internal system codes or technical jargon
- After the test session, **≥ 70% of participants** rate the system with a **System Usability Scale (SUS) score of ≥ 68** (the industry-accepted "above average" threshold)
- The in-application help system answers the **top-20 most common first-day questions** (as determined by support-ticket analysis of comparable ERP deployments) without requiring external documentation or internet access

### New users learn to find articles on their own

- Dimensions: `usable`
- Qualities demonstrated: usability, user-experience
- URL: https://quality.arc42.org/requirements/learnability-find-article

### Context

Navigation and search page must be built in a way that users who use other IT-systems learn the usage of the given system without having to read a manual or need to ask someone.

### Trigger

User who has never used the system before (but uses other IT systems in general) has to find a specific article.

### Acceptance Criteria

- System's search page displays article as search result when asked for it
- 95% of users find search page and then the article in less than two minutes
- No manual reading or assistance required for first-time users

### On-prem installation ready in 30 minutes

- Dimensions: `operable`, `flexible`
- Qualities demonstrated: installability, deployability, operability, maintainability
- URL: https://quality.arc42.org/requirements/on-prem-installation-ready-in-30-min

### Context

An enterprise product is deployed on customer-managed infrastructure.

### Trigger

A fresh installation is performed on a supported operating system and platform baseline.

### Acceptance Criteria

- A first-time installation completes within **<= 30 minutes** from start to operational verification.
- Installation requires **0** manual dependency resolution steps outside the documented installer workflow.
- In a test matrix of supported target environments, first-time installation succeeds in at least **95%** of runs.
- At completion, an automated verification check confirms all mandatory components are running and reachable.
- If installation fails, the system provides actionable diagnostics and rollback/cleanup, leaving no partially active runtime components.

### Only authenticated users can access data

- Dimensions: `secure`
- Qualities demonstrated: access-control, confidentiality, security, privacy
- URL: https://quality.arc42.org/requirements/only-authenticated-users-can-access

### Requirement

Access to protected data and business functions requires successful authentication and an authorization decision for the requested action and resource.

### Acceptance Criteria

- Unauthenticated denial: in automated security tests covering **100%** of protected API routes and primary UI entry points, **100%** of requests without a valid session are denied or redirected to login within **<= 1 s**; source: security regression test report; horizon: every pull request.
- Unauthorized access denial: in release-candidate tests with **>= 20** representative cross-role and cross-tenant access attempts, **100%** of out-of-scope reads, writes, and admin actions are denied and written to the audit log within **<= 30 s**; source: authorization test report and audit-log review; horizon: every release candidate.
- Gate behavior: if either threshold is missed, release of the affected authentication or authorization change is blocked within **<= 10 min** after the test report is available; source: CI/CD gate log; horizon: every pull request and release candidate.

### Order queue

- Dimensions: `reliable`
- Qualities demonstrated: fault-tolerance, recoverability
- URL: https://quality.arc42.org/requirements/order-queue

### Context

The database is down, so orders received from the shop cannot be processed immediately.

### Trigger

User sends an order to the shop while database is unavailable.

### Acceptance Criteria

- System detects database is down and queues the order
- Orders queued for up to 1 day
- Queued orders are processed as soon as database is back up
- If database downtime is less than 1 day, 100% of orders received are queued (number of orders received equals number of orders queued)

### Order transaction consistency: no partial outcomes

- Dimensions: `reliable`
- Qualities demonstrated: transactionality, atomicity, consistency, data-integrity
- URL: https://quality.arc42.org/requirements/order-transaction-consistency

### Context

An order-processing system must handle reservation, payment, and order recording as one business transaction.

### Trigger

A customer submits an order.

### Acceptance Criteria

- For each submitted order, inventory reservation, payment capture, and order creation either all complete successfully or the order is completed in an explicit failed/canceled state with no remaining side effects.
- If any transaction step fails, all intermediate effects are undone within **≤ 2 seconds** — either via atomic rollback or via compensating transactions that complete within the same window; in either case the system reaches a consistent terminal state (succeeded or explicitly failed/cancelled) within that window.
- No partial order state is visible to users or downstream systems **outside the 2-second recovery window** (for example: charged but not recorded, or recorded without reserved inventory).
- In failure-injection tests (service crash, timeout, network interruption) across at least **1,000** order attempts, inconsistent end states occur in **0** cases.
- Daily reconciliation between orders, payments, and reservations reports **0** unexplained mismatches.

### Parallel Data Modification

- Dimensions: `usable`, `efficient`, `secure`
- Qualities demonstrated: performance
- URL: https://quality.arc42.org/requirements/parallel-data-modification

### Context

In some multi-tenant systems several tenants may modify the same data at the same time. A possible solution is Optimistic Locking.

### Trigger

User A modifies data shortly after user B has read the same data record.

### Acceptance Criteria

- System displays conflict message when concurrent modification detected
- User B shown user A's modified data record
- User B can react to and resolve changes made by user A

### Patient Data Quality in Healthcare System

- Dimensions: `reliable`, `safe`
- Qualities demonstrated: data-quality, accuracy, completeness, timeliness, integrity
- Source reference: This example was created with help from Anthropic-Claude-Sonnet-3.7 with the following prompt:

```
I want to add an example requirement (under _requirements) for data-quality.
It shall follow the pattern "Context/Background", "Source", "Metric/Acceptance Criteria" and contain precise metrics
for acceptance criteria.
```
- URL: https://quality.arc42.org/requirements/patient-data-quality

### Context

A healthcare information system manages patient data across multiple departments (emergency, radiology, pharmacy, laboratory) in a large hospital network. The system must ensure high-quality patient data to support clinical decision-making, avoid medication errors, and ensure proper continuity of care. Poor data quality could lead to incorrect diagnoses, inappropriate treatments, or adverse patient outcomes.

### Trigger

Patient data is entered, updated, and accessed by various healthcare professionals throughout the patient care journey. Data may be manually entered or automatically imported from medical devices and external systems.

### Acceptance Criteria

The healthcare information system must ensure:

* Patient identification data (name, DOB, medical record number) must have a duplicate detection rate of 99.9% or higher
* Critical clinical data fields (allergies, current medications, diagnoses) must be 100% complete for all active patients
* Laboratory results must be available in the system within 5 minutes of test completion with 99.9% reliability
* Data validation rules must prevent 100% of the following common data entry errors 
  * impossible values (like body temperature, blood pressure) 
  * incorrect formats
  * missing mandatory fields
* All changes to patient data must maintain a complete audit trail with 100% traceability
* Data synchronization between different modules and systems must occur with a maximum latency of 30 seconds
* System must perform automated data quality checks every 4 hours and generate alerts for any records falling below quality thresholds
* Data quality metrics must be monitored and reported daily, with a dashboard showing:
  * Completeness percentage by data category
  * Error rates by department and user role
  * Timeliness of data updates
  * Number of data quality incidents by severity

### Portable Business Data Checker

- Dimensions: `flexible`, `operable`
- Qualities demonstrated: portability, adaptability, flexibility
- URL: https://quality.arc42.org/requirements/portable-business-data-checker

### Requirement

The business-data checker must remain portable across the supported relational database engines so that vendor version changes do not require major redesign or long support gaps.

### Acceptance Criteria

- Version support readiness: for each supported engine family, the latest generally available major version of MySQL, PostgreSQL, Oracle Database, and Db2 passes **100%** of connector smoke tests and **>= 95%** of the top **20** integrity-check scenarios within **<= 10 business days** after vendor release; source: compatibility matrix and CI test report; horizon: each relevant major database release.
- Adaptation effort: enabling support for one new major database version requires **<= 2 person-days** of development and regression-test effort for the existing checker scope; source: engineering work log and release ticket; horizon: each relevant major database release.
- Gate behavior: if either threshold is missed, that database version is marked unsupported in product documentation and blocked from production rollout within **<= 1 business day** after the failed validation; source: release note and support-status log; horizon: each compatibility validation.

### Precise calculation of gamma coefficient

- Dimensions: `reliable`
- Qualities demonstrated: reliability, preciseness, accuracy, correctness
- URL: https://quality.arc42.org/requirements/high-precision-calculation

### Context

The Gamma coefficient drives machine energy-efficiency decisions. Standard math libraries do not support it, so the system computes it from proprietary algorithms.

### Trigger

A release candidate is built.

### Acceptance Criteria

- Absolute error vs. the reference implementation is ≤ 0.0001 for ≥ 99.9% of ≥ 500 validation-corpus inputs and never exceeds 0.0005 (numerical regression suite, every release).
- 100 repeated runs per deterministic input set produce identical 4-decimal-place results on the reference platform (deterministic test report, every release).
- Release is blocked within 10 min if either threshold is missed (CI gate log).

### Precision of vehicle's orientation

- Dimensions: `reliable`
- Qualities demonstrated: accuracy, preciseness, precision, reliability, functional-correctness
- URL: https://quality.arc42.org/requirements/precise-vehicle-orientation-gps

### Trigger

The orientation of the vehicle is measured twice for the same orientation.

### Acceptance Criteria

- Orientation is displayed in GPS software
- Orientation precision is better than ± 3°
- Repeated measurements for same orientation show consistency within precision bounds

### Production anomalies detectable within 2 minutes

- Dimensions: `operable`
- Qualities demonstrated: observability, analysability, debuggability, mean-time-to-recovery
- URL: https://quality.arc42.org/requirements/production-anomalies-detectable-within-2-minutes

### Context

An e-commerce platform runs as a distributed system with multiple services.
Operations engineers must detect and assess production anomalies quickly — without accessing source code or redeploying instrumentation.

### Trigger

A production anomaly occurs (e.g., elevated error rate, latency spike, resource exhaustion, or unexpected traffic pattern).

### Acceptance Criteria

- The anomaly is visible on operational dashboards **within 2 minutes** of onset
- All services emit structured logs (JSON) with at minimum: timestamp, severity, service name, trace ID, and error category
- All inter-service calls are captured as distributed traces with end-to-end latency breakdown per hop
- Key runtime metrics (request rate, error rate, p95 latency, CPU, memory) are collected **at ≤ 30-second** granularity
- Dashboards allow drill-down from system-wide overview to individual service metrics without custom queries
- Alerting rules trigger automated notifications **within 90 seconds** of threshold breach

### Protect Data by Establishing Security Protocols

- Dimensions: `secure`, `safe`, `reliable`
- Qualities demonstrated: safety, cyber-security, security, information-security, patient-safety
- URL: https://quality.arc42.org/requirements/protect-data-by-security-procols

### Context

A medical system stores, transmits, and administers patient data. Regulatory and ethical obligations require enforceable security controls.

### Trigger

A release candidate is prepared, or a scheduled security review is due.

### Acceptance Criteria

- Zero unresolved critical and ≤ 5 unresolved high vulnerabilities older than 30 days on patient-data systems (authenticated vulnerability scan, weekly + every release).
- Penetration test at least once per 12 months and after each major architecture change; critical findings remediated within 14 days; releases with open critical findings are blocked (pen-test report and remediation tracker).
- 100% of privileged access to patient records is logged (identity, timestamp, action, target); audit queries for any 24 h window complete within 60 s (audit-log validation report, every release).

### Provable Insulin Dosage Safety

- Dimensions: `reliable`, `safe`
- Qualities demonstrated: provability, safety, reliability, certifiability
- URL: https://quality.arc42.org/requirements/provable-insulin-dosage-safety

### Context
An automated insulin delivery (AID) system adjusts insulin delivery based on continuous glucose monitor (CGM) sensor data. In this safety-critical medical context, "provability" is the highest level of assurance that the control algorithm will never command a dosage that could lead to severe hypoglycemia (dangerously low blood sugar), regardless of sensor noise or software state transitions. Relying on testing alone is insufficient for such life-critical logic; mathematical proof of safety properties is required for certification and patient safety.

### Trigger
The control algorithm calculates a new insulin infusion rate based on the latest sensor readings and patient history.

### Acceptance Criteria
- **100%** of the core control-law implementation is formally verified against a mathematical model of the safety constraints (e.g., using TLA+, Coq, or bounded model checking).
- **Formal Proof**: The system must provide machine-checkable proof that no combination of inputs within the defined physiological range can result in a "Max Basal" command exceeding the patient-specific safety limit defined by the physician.
- **State Invariants**: All safety-critical state variables (e.g., `active_insulin`, `current_glucose_trend`) are proven to remain within valid bounds across all defined state transitions.
- **Verification Artifacts**: Proof scripts or model-checking logs are generated for every version of the control module, showing zero counter-examples to the safety properties.

### Provable railway interlocking routing logic

- Dimensions: `reliable`, `safe`
- Qualities demonstrated: provability, verifiability, correctness, certifiability
- URL: https://quality.arc42.org/requirements/provable-railway-interlocking-routing-logic

### Context
A computer-based interlocking (CBI) system is responsible for controlling signals and points to ensure safe train movements in a high-density rail network. In this domain, testing alone is not sufficient assurance for the safety-critical routing logic, because the set of possible route combinations and state transitions is too large to justify safety by sampling alone. This requirement focuses on the **automated verification pipeline** that ensures implementation code strictly adheres to the proven safety specification before any release.

### Trigger
A release candidate of the safety-critical routing logic is submitted for safety verification.

### Acceptance Criteria
- **100%** of safety-critical route-setting rules are represented in a machine-checkable specification linked to the release-candidate implementation baseline; source: specification coverage report; evaluation horizon: every release candidate.
- **100%** of generated proof obligations for the defined collision-prevention and point-consistency invariants are discharged, with **0** open counterexamples; source: formal verification report; evaluation horizon: every release candidate.
- If any proof obligation fails or any counterexample is found, release promotion is blocked within **5 min** and the failing invariant identifier and affected rule identifier are recorded in the verification log within **1 min**; source: release-gate log and verification report; evaluation horizon: every release candidate.

> See also: [provable-railway-interlocking-safety](/requirements/provable-railway-interlocking-safety) for the domain-specific safety invariants and EN 50128 compliance details.

### Monitoring Artifact
- Release-candidate formal verification report
- Release-gate decision log
- [EN 50128: Formal Methods for Railway Safety](https://www.railengineer.co.uk/formal-methods-for-railway-safety/)

### Provable Railway Interlocking Safety

- Dimensions: `reliable`, `safe`
- Qualities demonstrated: provability, safety, reliability, certifiability
- URL: https://quality.arc42.org/requirements/provable-railway-interlocking-safety

### Context
A computer-based interlocking (CBI) system must guarantee that conflicting routes are never cleared simultaneously, preventing train collisions. In compliance with safety standards such as **EN 50128 (SIL 4)**, the system's safety-critical logic must be "correct by construction" and its correctness mathematically provable. This requirement focuses on the **formal safety invariants** and mathematical proofs that demonstrate collision-free operation across all possible system states.

### Trigger
The formal safety model of the interlocking logic is submitted for mathematical verification or certification review.

### Acceptance Criteria
- **Formal Safety Invariants**: The system provides machine-checkable proofs that for all possible system states, the "No Collision" invariant holds (i.e., no two routes that share a common track segment can be in the "Clear" state simultaneously).
- **Proof Coverage**: **100%** of the interlocking logic (safety-critical part) is developed using a formal method (e.g., the **B-method** or **Event-B**). All generated proof obligations (POs) must be discharged.
- **Automation Threshold**: At least **90%** of these proofs must be automated (using tools like Atelier B), and **100%** of any manually proven obligations must be independently reviewed and verified by a separate safety team.
- **Standard Compliance**: Verification results must be sufficient to support a **SIL 4 (EN 50128)** safety case for the specific site deployment.

> See also: [provable-railway-interlocking-routing-logic](/requirements/provable-railway-interlocking-routing-logic) for the automated verification pipeline and release-gate integration.

### Reliable Resources
- [EN 50128: Formal Methods for Railway Safety](https://www.railengineer.co.uk/formal-methods-for-railway-safety/)
- [The B-Method in Railway Industry (ClearSy)](https://link.springer.com/chapter/10.1007/978-3-032-12484-5_4)
- [Case Study: METEOR Paris Metro Line 14 (Formal Methods Europe)](https://fmeurope.org/success-stories/meteor/)

### Public API intrusion attempts blocked and alerted

- Dimensions: `secure`
- Qualities demonstrated: intrusion-prevention, intrusion-detection, security, availability
- URL: https://quality.arc42.org/requirements/public-api-intrusion-attempts-blocked

### Context

A public-facing API handles authentication and business operations for internet users and partner systems.  
The platform must prevent common attack traffic without degrading normal access for legitimate clients.  
This quality is critical for security operations and service continuity.

### Trigger

An inbound request reaches an internet-exposed authentication or API endpoint.

### Acceptance Criteria

- Brute-force protection: after **5 failed authentication attempts per account within 10 minutes**, further authentication attempts for that account are blocked for **15 minutes**; scope: all public auth endpoints; source: API gateway and identity logs; horizon: rolling 10-minute windows.
- Injection prevention effectiveness: in per-release security tests with at least **2,000 crafted requests** covering SQL injection, XSS, and path traversal, the blocked malicious-request rate is **>= 99.5%** and false-positive rate on benign traffic is **<= 0.1%**; source: security test harness and staging gateway logs; horizon: each release.
- Runtime blocking latency: malicious requests are blocked within **<= 500 ms at p95** under a representative load of **1,000 requests/second** on top 20 public endpoints; source: gateway telemetry and security event stream; horizon: 5-minute rolling windows.
- Failure-path behavior: if intrusion-classification services are unavailable for **> 30 seconds**, high-risk endpoints (authentication and account administration) switch to protective deny mode for **100%** of requests until recovery, and on-call alerting is emitted within **<= 60 seconds**; source: health checks and alert manager logs; horizon: continuous monitoring.
- Auditability of blocked events: **100%** of blocked requests are logged with timestamp (UTC), endpoint, attack category, request identifier, and pseudonymized source identifier, and are searchable within **<= 30 seconds**; source: SIEM ingestion metrics; horizon: rolling 30 days.

### Monitoring Artifact

Security operations dashboard combining gateway metrics, intrusion-test reports, and SIEM event-ingestion SLIs.

### Quick unit tests

- Dimensions: `operable`
- Qualities demonstrated: testability
- URL: https://quality.arc42.org/requirements/quick-unit-tests

### Requirement
All automated unit tests for a subsystem must execute quickly to enable rapid feedback during development.

### Acceptance Criteria
- All unit tests for a subsystem complete in less than 180 seconds
- Test execution time is measured on standard CI/CD infrastructure

### Quickly locate bugs

- Dimensions: `efficient`
- Qualities demonstrated: efficiency, maintainability
- URL: https://quality.arc42.org/requirements/quickly-locate-bugs

### Trigger

Developers, testers or build system execute automatic test cases (unit or integration tests) and a test fails.

### Acceptance Criteria

- Developer can locate cause of error in less than 10 minutes on average based on error and/or log messages
- Error messages provide sufficient information for quick diagnosis
- Log messages include context needed to identify failure root cause

### Recognize Assistive Technologies

- Dimensions: `usable`
- Qualities demonstrated: usability, inclusivity, accessibility, interaction-capability
- URL: https://quality.arc42.org/requirements/recognize-assistive-technology

### Context

Users with visual or motor impairments interact through screen readers, keyboard navigation, and custom accessibility preferences. The interface must expose correct semantics.

### Trigger

A release candidate is built, or a quarterly accessibility review is due.

### Acceptance Criteria

- ≥ 95% of interactive elements on the top 20 screens expose correct accessible name, role, and state; zero critical workflow controls lack announcements (accessibility test report, every release).
- Keyboard-only task success ≥ 90% and median completion time ≤ 120% of mouse baseline for the top 10 user tasks (comparative usability study, quarterly).
- Text contrast ≥ 4.5 : 1 (normal) and ≥ 3 : 1 (large) on the top 20 journeys; persisted accessibility preferences restored in 100% of returning-user sessions (automated contrast audit + session-restoration test, every release).

### Reduce energy consumption with every new version

- Dimensions: `efficient`
- Qualities demonstrated: sustainability, carbon-emission-efficiency, energy-efficiency
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality scenario to describe a carbon-efficiency requirement`.
- URL: https://quality.arc42.org/requirements/reduce-energy-consumption-with-new-version

### Context

Large-scale application in data center powered by non-renewable energy sources, serving high number of concurrent users with high demand for data processing and computational resources.

### Trigger

Software system is in operation serving concurrent users.

### Acceptance Criteria

- System prioritizes energy efficiency and carbon reduction in operations
- Energy consumption optimized, reducing overall energy usage by 25% compared to previous year's consumption
- Renewable energy sources incorporated for data center operations
- At least 50% of renewable energy usage achieved within two years
- Gradual shift towards more sustainable energy practices implemented

### Reinterpret a domain concept from historical facts

- Dimensions: `flexible`, `maintainable`
- Qualities demonstrated: evolvability, traceability, auditability
- URL: https://quality.arc42.org/requirements/reinterpret-domain-concept-from-historical-facts

### Context

A production system contains historical business information from which a domain state or classification is derived. The business later introduces a revised interpretation of that concept while the underlying historical facts remain unchanged.

### Trigger

The revised interpretation must be applied retrospectively so that previous and revised results can be compared for historical cases.

### Acceptance Criteria

- The revised interpretation can be evaluated for **100% of a representative sample of at least 100 historical cases** using information captured before the revised interpretation existed
- **0 historical source facts are modified, deleted, or rewritten** to produce the revised interpretation
- **0 existing producers of those historical facts require modification** solely to support the retrospective interpretation
- The previous and revised interpretations can be evaluated **side by side for the same sampled historical cases**
- **100% of revised results** in the sample can be traced to the source facts used to derive them
- Where an explicit business policy determines the interpretation, **100% of sampled results** identify the policy version used
- Introducing the revised interpretation changes **no more than 3 existing modules or independently deployable components**, excluding tests, documentation, and the new interpretation itself
- Existing consumers that continue to use the previous interpretation require **0 modifications**

### Measurement & Verification

Select a domain concept whose business meaning changed after production history already existed. Run the previous and revised interpretations against a representative sample of at least 100 historical cases and verify the criteria through automated tests, version-control diff, migration history, and data lineage.

### Reliable Backup and Restore

- Dimensions: `safe`, `reliable`
- Qualities demonstrated: patient-safety, safety, reliability, availability
- URL: https://quality.arc42.org/requirements/reliable-backup-and-restore

### Context

An Electronic Health Records (EHR) system needs to ensure accurate and timely documentation of patient information. Data loss must be avoided.

### Trigger

Data loss incident occurs or backup process is executed.

### Acceptance Criteria

- Data recovery achievable within 4 hours of any data loss incident
- Backups performed daily without any data corruption
- 100% data integrity maintained in all backup operations

### Reliable ERH System

- Dimensions: `safe`
- Qualities demonstrated: patient-safety, safety, reliability, efficiency, availability
- URL: https://quality.arc42.org/requirements/reliable-erh-system

### Context

An Electronic Health Records (EHR) system needs to ensure accurate and timely documentation of patient information.

### Trigger

Healthcare provider performs clinical interaction requiring patient record documentation.

### Acceptance Criteria

- System achieves 99.9% uptime
- Patient records updated within 5 minutes of any clinical interaction

### Replication and Quorum Reads/Writes

- Dimensions: `reliable`, `safe`
- Qualities demonstrated: failure-transparency, availability, resilience, fault-tolerance
- URL: https://quality.arc42.org/requirements/replication-and-quorum-failure-transparency

### Context

An online transactional application (e.g., order processing and account ledger) uses a replicated primary datastore for user‑facing reads and writes. The service is deployed across multiple availability zones and must tolerate single‑node failures and brief network partitions without violating durability or the declared consistency guarantees. Session‑bound clients require read‑your‑writes for critical flows (checkout, balance update), while background analytics can tolerate slightly stale reads.

### Trigger

Single-node failure occurs, leader re-election is triggered, or network partition affects datastore cluster during normal operation.

### Acceptance Criteria

- Use 3‑node (or higher) replicated clusters; configure majority quorum for writes and reads (e.g., N=3, W=2, R=2), or Raft/Paxos‑based consensus with committed log replication
- Under single‑node failure and during leader re‑election, external write availability ≥ 99.9% and median write latency ≤ 1.5× baseline
- Client‑perceived error rate (5xx/timeouts at the edge) during single‑node failures and leader changes ≤ 0.5% over any 10‑minute window; p95 write latency ≤ 2× baseline
- No acknowledged write is lost; reads are monotonic per key after write acknowledgment (define read‑your‑writes for session‑bound clients where required)
- Stale‑read exposure window during failover ≤ 5s; document the window and client cache invalidation strategy
- Support idempotent write semantics for at‑least‑once retries; include deduplication tokens to prevent duplicate side‑effects
- Validate via fault injection (node kill, network partition, disk pause) and demonstrate the SLOs above; include dashboards showing leader changes, commit index, quorum success rate

### Acceptable vs. Unacceptable Transparency Loss

- Acceptable: bounded and documented latency increase (≤ 2× p95) and stale‑read window (≤ 5s) during controlled failover; zero lost acknowledged writes; edge error rate ≤ 0.5% for ≤ 10 minutes
- Unacceptable: any lost acknowledged write; violation of monotonic reads/read‑your‑writes guarantees; sustained (>10 minutes) edge error rate > 0.5%; stale‑read window exceeding the documented bound

### Respond to 15000 requests per workday

- Dimensions: `efficient`
- Qualities demonstrated: capacity, resource-efficiency
- URL: https://quality.arc42.org/requirements/respond-to-15000-requests-per-workday

### Requirement

The system must handle the required request volume during normal business operations.

### Acceptance Criteria

- System responds to 15000 requests per workday (8 hours)
- Average capacity of 1875 requests per hour maintained
- Request processing capacity sustained throughout 8-hour workday

### Response time for image rendering

- Dimensions: `efficient`
- Qualities demonstrated: response-time, efficiency, performance, time-behaviour, speed, responsiveness
- URL: https://quality.arc42.org/requirements/response-time-for-image-rendering

### Context

Image manipulation software offers variety of image filters for users (shadows, greyscaling, resizing, background-removal and others). To achieve required response time, reducing resolution of image for preview is an option.

### Trigger

User selects graphical filter and clicks or selects `apply filter` function.

### Acceptance Criteria

- System displays changed image next to original
- Changed image displayed in less than 1 second
- Preview generation time remains under 1 second regardless of filter type

### Restore Filter after Log In

- Dimensions: `usable`, `suitable`
- Qualities demonstrated: functional-appropriateness
- URL: https://quality.arc42.org/requirements/restore-filter-after-log-in

### Context

In a multi-tenant web based system within a factory, each user may need to have their work environment with their settings restored after successful log in.

### Trigger

User logs in to start their shift and accesses a website with a table with data.

### Acceptance Criteria

- Website displays table filtered by filter configuration from user's last session
- Filter settings automatically restored upon login
- User's work environment preferences persisted between sessions

### Restored to fully functional state 12h after complete failure

- Dimensions: `operable`, `usable`, `reliable`
- Qualities demonstrated: availability, high-availability, reliability, operability, mean-time-to-recovery, interaction-capability
- URL: https://quality.arc42.org/requirements/mttr-12h

### Requirement
The system must be restored to full functionality quickly after a complete failure to minimize business impact.

### Acceptance Criteria
- System restored to fully functional state within 12 hours of complete failure
- Recovery time includes restoration of any corrupted data
- Applies to complete system failure or failure of major subsystems

### Restricted Memory

- Dimensions: `efficient`
- Qualities demonstrated: efficiency, resource-efficiency, memory-usage
- URL: https://quality.arc42.org/requirements/restricted-memory

### Requirement

The system must operate within strict memory constraints.

### Acceptance Criteria

- Total RAM consumption does not exceed 512 MB
- Memory limit enforced at all times during system operation
- No memory consumption spikes above 512 MB threshold

### Retail demand forecast drift detected before replenishment

- Dimensions: `reliable`, `operable`
- Qualities demonstrated: drift-detectability, reliability, data-quality, timeliness
- URL: https://quality.arc42.org/requirements/retail-demand-forecast-drift-before-replenishment

### Context

A retail planning system forecasts demand for product groups across stores and regions.
The forecasts drive replenishment decisions, stock allocation, and promotion planning.
Demand can drift because of seasonality, price changes, promotions, competitor behavior, supply constraints, or local events.

### Trigger

New sales, inventory, pricing, promotion, and regional demand data becomes available for the latest planning cycle.

### Acceptance Criteria

- Forecast-error drift: WAPE is evaluated weekly by product group and region; if WAPE degrades by more than **10 percentage points** compared with the rolling 8-week baseline for **2 consecutive weeks**, a planning-review alert is created before the next replenishment run.
- Input drift: price, promotion flag, stockout rate, and regional sales-volume distributions are compared with the rolling 8-week baseline every planning cycle using Population Stability Index (PSI); a breach is recorded when **PSI >= 0.25** for any feature-region pair and is surfaced in the demand-planning dashboard within the same cycle; source: feature-monitoring job.
- Business-impact prioritization: drift alerts identify affected product groups whose forecasted revenue or inventory value is in the top **20%** of the assortment; source: drift report and merchandising hierarchy.
- Data freshness: forecast drift evaluation uses sales and inventory data no older than **24 h** at the time of the replenishment run; stale input data blocks automatic replenishment recommendations for affected regions.
- Review traceability: every drift alert records baseline window, current evaluation window, forecast model version, affected product group, region, and metric values; source: planning audit log.

### Measurement & Verification

MAPE (Mean Absolute Percentage Error) averages the absolute percentage error for individual forecast points. It is intuitive, but can become unstable or undefined when actual demand is zero or very small.

WAPE (Weighted Absolute Percentage Error) measures total absolute forecast error relative to total observed demand:

`WAPE = sum(abs(actual - forecast)) / sum(actual)`

For retail demand planning, WAPE is often preferable because high-volume items contribute proportionally more to the metric and low-volume or zero-demand noise has less impact on the aggregate error.

Reference definitions: [Amazon Forecast accuracy metrics](https://docs.aws.amazon.com/forecast/latest/dg/metrics.html). For methodological background on forecast-accuracy measures, see Hyndman and Koehler, [Another look at measures of forecast accuracy](https://www.robjhyndman.com/papers/forecast-accuracy.pdf).

### Monitoring Artifact

Demand forecast drift dashboard with WAPE trend, input-drift indicators, affected regions/product groups, stale-data blocks, and planner review status.

### Rollout of a new feature

- Dimensions: `operable`, `suitable`
- Qualities demonstrated: agility, changeability, maintainability
- URL: https://quality.arc42.org/requirements/rollout-new-feature

### Context

Software may be provided via install kit (requiring OS-specific installers) or as web-based system (retrieving logic over network). This requirement does not dictate solution but specifies what must be fulfilled.

### Trigger

Product team provides a new feature.

### Acceptance Criteria

- System updates itself so new feature can be used
- No action required from user to access new feature
- New feature just becomes available automatically
- Zero manual installation steps for end users

### Safety requirements traceable to executable evidence

- Dimensions: `reliable`, `maintainable`
- Qualities demonstrated: verifiability, testability, certifiability, traceability
- URL: https://quality.arc42.org/requirements/safety-requirements-traceable-to-evidence

### Context

An autonomous vehicle software platform implements safety-critical perception, planning, and control functions.  
Regulatory and certification activities require repeatable proof that safety requirements are verified with objective evidence.  
This quality is critical for safety engineering and compliance stakeholders.

### Trigger

A release candidate is submitted for safety verification and approval.

### Acceptance Criteria

- Coverage of safety requirements: **100%** of safety-classified requirements in the approved baseline are linked to at least one automated verification artifact with unique identifiers; scope: all safety requirements in the release baseline; source: requirements repository and traceability export; horizon: each release candidate.
- Traceability completeness: end-to-end trace links requirement -> design element -> implementation unit -> verification result are complete for **>= 98%** of safety requirements; scope: release candidate baseline; source: generated traceability matrix; horizon: each release candidate.
- Verification execution reliability: automated safety verification artifacts execute successfully for **>= 99%** of planned runs, with unresolved critical test-infrastructure failures at **0**; scope: full safety verification set; source: CI pipeline logs; horizon: last 10 pipeline runs for the release candidate.
- Verification turnaround: full safety verification suite completes within **<= 4 hours at p90** on the reference CI environment; scope: full suite execution; source: CI timing telemetry; horizon: rolling 30 days.
- Failure-path release gating: when any safety requirement lacks passing evidence, release promotion is automatically blocked within **<= 5 minutes** of verification completion and safety leads are notified within **<= 15 minutes**; scope: all release candidates; source: release-gate logs and incident notifications; horizon: each release candidate.

### Monitoring Artifact

Release verification packet containing traceability matrix, CI execution report, and release-gate decision log.

### Save at least 20% of carbon emissions with every new version

- Dimensions: `efficient`
- Qualities demonstrated: efficiency, carbon-emission-efficiency, energy-efficiency
- Source reference: This scenario has been created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality scenario to describe a carbon-efficiency requirement`.
- URL: https://quality.arc42.org/requirements/carbon-efficiency-save

### Context

Data center powered by non-renewable energy sources processes high volume of data and performs resource-intensive computations.

### Trigger

System processes data and executes computations during normal operations.

### Acceptance Criteria

- System minimizes carbon footprint by optimizing energy usage and resource allocation
- Energy consumption reduced by at least 20% compared to previous versions
- Optimization targets both computational efficiency and resource allocation strategies

### Scale up in 2 Minutes

- Dimensions: `efficient`, `reliable`
- Qualities demonstrated: elasticity, scalability, performance
- URL: https://quality.arc42.org/requirements/scale-up-in-2-minutes

### Requirement

The cloud-based web application must scale out automatically fast enough to absorb a sharp traffic increase without manual intervention and without disproportionate cost growth.

### Acceptance Criteria

- Scale-out completion: when sustained incoming traffic rises to **150%** of the established baseline for **5 min**, the platform adds enough healthy serving capacity within **<= 2 min** after threshold breach; source: load-test report plus autoscaling and health-check events; horizon: each quarterly elasticity test.
- Post-scale stability: during the first **10 min** after scale-out, request latency stays at **p95 <= 3 s** and average CPU utilization of serving instances stays at **<= 70%** under a traffic level of **200%** of baseline; source: APM dashboard and infrastructure metrics; horizon: each quarterly elasticity test.
- Cost bound and gate: under the same **200%** traffic test, hourly compute cost rises by **<= 150%** over the baseline hour; if any threshold is missed, rollout of the changed autoscaling configuration is blocked within **<= 1 business day**; source: cost report and release gate log; horizon: each quarterly elasticity test.

### Search and graph text filter available on Q42

- Dimensions: `usable`, `suitable`
- Qualities demonstrated: functionality, functional-appropriateness, interaction-capability, discoverability
- URL: https://quality.arc42.org/requirements/search-and-graph-text-filter-available-on-q42

### Context
quality.arc42.org is a public software-architecture reference website with an interactive visual graph that software architects use to explore quality characteristics, related requirements, standards, and solution approaches. For these users, the characteristic `Functionality` matters because the site must provide working search and graph filtering so relevant content can be found quickly. Assumption: no external benchmark exists for this niche reference site, so the thresholds below are conservative release thresholds verified by the team.

### Trigger
A software architect searches for `Functionality` or uses the graph text filter to locate related content.

### Acceptance Criteria
- In a JavaScript-enabled browser, the site search returns the `Functionality` page within the first **5 results** for at least **95%** of **20 reference queries**, with p95 result rendering time of at most **2.0 s** per query; source: scripted UI regression suite; evaluation horizon: every release candidate.
- In a JavaScript-enabled browser, the graph text filter updates the visible result set for at least **95%** of **15 reference filter terms** within **1.5 s** per term on the full production-content dataset; source: graph interaction test harness; evaluation horizon: every release candidate.
- In a non-JavaScript browser, reduced functionality is acceptable: at least **95%** of **20 reference journeys** reach the `Functionality` page through static navigation within **4 interactions**, **0** graph text filter controls are presented as usable, and any failed threshold blocks the release within **5 min** of the no-JS regression suite finishing; source: no-JS test report and release-gate log; evaluation horizon: every release candidate.

### Monitoring Artifact
Release-candidate UI regression dashboard with JavaScript-enabled and no-JavaScript fallback reports.

### Server fails, system continues to operate without downtime

- Dimensions: `reliable`
- Qualities demonstrated: reliability, availability, high-availability, fault-tolerance, stability
- URL: https://quality.arc42.org/requirements/server-fails-operation-without-downtime

### Requirement

The system must maintain continuous operation despite server failures in a server farm.

### Acceptance Criteria

- System continues to operate with no downtime when a server fails during normal operation
- Operator is informed of server failure
- Zero downtime during server farm node failures
- Automatic failover to redundant servers

>Source: [Len Bass et al., 2021, p. 76](/references/#bass2021software)

### Service Circuit Breakers and Graceful Degradation

- Dimensions: `reliable`, `safe`
- Qualities demonstrated: failure-transparency, availability, resilience, fault-tolerance
- URL: https://quality.arc42.org/requirements/circuit-breaker-failure-transparency

### Context

The system depends on multiple upstream services (payments, profiles, notifications). Transient upstream failures must not cascade or break core user flows.

### Trigger

Upstream service experiences transient failures or degraded performance during normal system operation.

### Acceptance Criteria

- Implement circuit breakers with automatic open/half‑open/close states and exponential backoff
  - Sliding window: 10–60s time window or 20–200 requests minimum sample size (use both where supported)
  - Failure‑rate threshold: 20–50% (default 50%); require min 20 requests before evaluation
  - Cool‑down (open state): 10–60s; half‑open probes: 1–5 concurrent trial requests; close after 5–10 consecutive successes
  - Timeouts per dependency: 200–1500ms typical; retries: 0–2 with jittered exponential backoff (cap 2–5s)
- Dependency classification and strategies:
  - Critical dependencies (payments, auth): prefer graceful degradation with cached/queued fallbacks; stricter thresholds (e.g., 20–30% failure trip), shorter timeouts, fewer retries
  - Non‑critical (recommendations, analytics): fail‑silent with placeholders or skip; looser thresholds (e.g., 40–50%), longer cool‑downs
  - Each dependency must declare timeout, retry policy, trip threshold, and fallback behavior in config
- Recovery testing:
  - Exercise half‑open → closed transitions in tests by restoring upstream health; require ≥5 consecutive probe successes to close; ensure queued work drains without user‑visible errors
  - Verify state resets do not cause thundering herds (limit probe concurrency; retain backoff until closed)
- When a breaker opens, the user experience degrades gracefully (e.g., hide recommendations, queue notifications) while core operations succeed; display a neutral placeholder, never a stack trace
- All client calls are idempotent (PUT/DELETE with idempotency keys; POST with dedup keys) to allow safe retries
- Latency and errors during failure injection:
  - Median end‑user latency increases by ≤20%; p95 ≤ 2× baseline, [p99](https://en.wikipedia.org/wiki/Percentile) ≤ 3× baseline
  - Edge error rate (5xx/timeouts) ≤ 0.5% over any rolling 10‑minute window
- Observability (must track and dashboard):
  - Per‑dependency p50/p95/p99 latency; success/error rates by error type (timeout, connect error, 5xx, 4xx policy)
  - Breaker state transitions, time in state, open/close counts, half‑open probe success rate
  - Retry counts, backoff/cancel rates, queue depth, and client/thread‑pool saturation
- Validate via chaos exercises at least quarterly (inject 5xx, timeouts, and 2× latency), demonstrating compliance with thresholds and successful recovery to closed state

### Service loose coupling: change blast radius

- Dimensions: `maintainable`, `suitable`, `efficient`
- Qualities demonstrated: loose-coupling, modularity, evolvability, deployability, independence
- URL: https://quality.arc42.org/requirements/service-loose-coupling-change-blast-radius

### Context

A microservice system with independently owned services (for example order, payment, inventory, notification).

### Trigger

A team changes one service (internal model, API, or event schema) to implement a new feature.

### Acceptance Criteria

- Over a rolling 90-day window, architecture/compliance checks report **0** direct dependencies on another service's internal implementation artifacts (for example internal packages, private libraries, or shared source).
- Cross-service direct database access is **0**; communication is only via explicit API/event contracts.
- Over a rolling 90-day window, at least **85%** of production changes affect **one service only**, and **0%** affect more than **2 services**.
- For contract changes introduced in a rolling 90-day window, required code changes are limited to at most **2 downstream consumers** at the **95th percentile**.
- In production, at the **95th percentile** over a rolling 90-day window, a single service can be deployed or rolled back in **<= 15 minutes** without coordinated redeployment of other services.

### Severe errors are detected and the system shuts down into safe state

- Dimensions: `operable`, `safe`, `reliable`
- Qualities demonstrated: dependability, safety, operability, fail-safe, reliability
- URL: https://quality.arc42.org/requirements/shutdown-to-safe-state

### Context

The system controls physical processes where undetected severe faults can cause hazardous conditions or data corruption.

### Trigger

A documented severe fault condition occurs during operation.

### Acceptance Criteria

- In fault-injection tests covering 100% of documented severe fault classes, shutdown starts within 1 s for ≥ 99% of injected faults (safety test report, every release).
- System reaches the documented safe state within 5 s of shutdown start, accepts zero new commands/transactions, and post-test integrity checks find zero data-corruption incidents (integration + safety test report, every release).
- Release is blocked within 10 min if either threshold is missed (release gate log).

### Shared library adoption by product teams

- Dimensions: `flexible`, `maintainable`
- Qualities demonstrated: reusability, maintainability, modifiability, adaptability
- URL: https://quality.arc42.org/requirements/shared-library-adoption-by-product-teams

### Context

Multiple product teams build user-facing features and should reuse a shared component library instead of duplicating common implementations.

### Trigger

A team starts a new feature stream or a new product integration.

### Acceptance Criteria

- Over a rolling quarter, at least **80%** of UI components used in shipped features come from the shared library.
- A new team can integrate the library and deliver its first production use within **<= 2 hours**, using only the provided documentation and examples.
- For all reusable components, usage guidance (API contract, examples, and version compatibility notes) is available and current at release time.
- Over a rolling quarter, duplicated local re-implementations of components already available in the shared library account for **<= 10%** of shipped components.
- Breaking changes in shared components include a documented migration path and a deprecation period of at least **1** regular release cycle.

### System can run >12h without re-booting the operating system

- Dimensions: `operable`, `reliable`
- Qualities demonstrated: mean-time-between-failures, stability, reliability, availability, high-availability
- URL: https://quality.arc42.org/requirements/long-running-without-reboot

### Requirement

The system must run continuously without requiring operating system reboots.

### Acceptance Criteria

- System operates continuously for more than 12 hours without OS reboot
- No OS reboot required during extended operation periods
- System stability maintained during continuous operation

### System runs offline

- Dimensions: `reliable`, `operable`
- Qualities demonstrated: reliability, autonomy
- URL: https://quality.arc42.org/requirements/system-runs-offline

### Context

Conductor in a train uses device to validate tickets without any network connection being available. During validation only 5% false-negatives are allowed.

### Trigger

Conductor validates ticket using device while offline.

### Acceptance Criteria

- Ticket is validated using certificate information stored on the device
- Validation accuracy does not drop below 95% when device is offline
- Maximum false-negative rate: 5%

### Tamper-Evident Digital Contract Signatures

- Dimensions: `secure`, `reliable`
- Qualities demonstrated: non-repudiation, security, auditability, data-integrity, authenticity, traceability
- URL: https://quality.arc42.org/requirements/tamper-evident-digital-signatures

### Context
An enterprise Contract Management System (CMS) handles legally binding agreements between multiple parties. To prevent legal disputes, the system must provide irrefutable proof of who signed what and when, ensuring that even system administrators cannot forge or alter signatures after the fact.

### Trigger
A user (Signer) completes the signing workflow for a digital contract.

### Acceptance Criteria

- Every signature is cryptographically bound to the document content such that **any modification — however small — causes verification to fail**; this is confirmed by automated tests that alter a single byte and assert rejection
- Each signature is bound to an **independent, trusted timestamp** (sourced outside the CMS) accurate to **≤ 1 second**; the timestamp remains verifiable even if the CMS is unavailable
- For every signed contract, the system produces a **portable evidence package** that an external auditor or court can verify with standard, publicly available tooling at **p95 <= 5 seconds** for documents up to **10 MB** and evidence packages up to **50 MB** on a reference verifier environment (at least **4 vCPU, 8 GB RAM**), without accessing CMS databases or internal services
- The signing event is only completed after **multi-factor authentication**; the audit trail permanently links each signature to the authentication session, originating IP address, and device identifier — these fields are immutable after signing
- Signatures and their evidence packages remain **independently verifiable for >= 10 years** after signing, even if the issuing certificate authority is decommissioned or unreachable; the evidence package contains all required verification material (certificate chain, trusted timestamp token, and revocation evidence such as OCSP/CRL artifacts or equivalent)
- Cryptographic proofs and audit records are retained for **≥ 10 years**; automated integrity checks run at least **quarterly on a statistically representative sample** (≥ 5% of stored contracts, randomly selected) and alert within 24 hours if corruption is detected

> one reviewer remarked: The MFA requirement is intentionally strict for high-assurance signing contexts. In environments with different legal or privacy constraints, an equivalent policy-defined signer-assurance mechanism may be used.

### Test Coverage for Critical Business Logic

- Dimensions: `maintainable`
- Qualities demonstrated: test-coverage, testability, maintainability
- URL: https://quality.arc42.org/requirements/test-coverage-for-critical-business-logic

### Context

A business application contains critical pricing, billing, and eligibility logic where unnoticed regressions would cause financial or contractual errors. The engineering lead needs lightweight but reliable evidence that this logic is exercised sufficiently by automated tests before changes are merged.

### Trigger

A change affecting a critical business-logic module is proposed for merge to the main branch.

### Acceptance Criteria

- Branch coverage: automated tests achieve **>= 85% branch coverage** for all modules classified as critical business logic; 
- Requirement coverage: **>= 95%** of high-risk business rules for the changed scope are linked to at least one automated test case; 
- Failure-path behavior: if either coverage threshold is missed, the merge is blocked within **<= 2 min** after the coverage report is produced;

### Test with path coverage in 30min

- Dimensions: `suitable`
- Qualities demonstrated: testability, risk-identification, cycle-time
- URL: https://quality.arc42.org/requirements/test-with-path-coverage-30min

Idea: [Bass et al., 2021](/references/#bass2021software)

### Trigger

Developer completes a code unit.

### Acceptance Criteria

- Developer performs test sequence whose results are captured
- Test sequence achieves path coverage of 85%
- Testing completed within at most 30 minutes

### Transaction Processing Operates Without Fault Under Normal Load

- Dimensions: `reliable`
- Qualities demonstrated: faultlessness, reliability, dependability, correctness
- URL: https://quality.arc42.org/requirements/transaction-processing-faultlessness

### Context

The platform processes financial transactions across multiple channels (mobile, web, point-of-sale, partner API) at volumes exceeding 500 000 per day. Each transaction must complete its full lifecycle — validation, authorization, settlement, ledger posting — without incorrect results, silent corruption, or inconsistent state. A single wrong balance triggers regulatory reporting and erodes customer trust.

### Trigger

A customer or partner system submits a valid transaction during normal operating conditions (steady-state load ≤ 120% of provisioned capacity, all declared dependencies healthy).

### Acceptance Criteria

- ≥ 99.97% of transactions complete without manual correction, compensating entry, or system-fault retry over any rolling 30-day window; measured by reconciliation of the transaction log against the authoritative ledger.
- End-of-day reconciliation produces zero unexplained discrepancies on ≥ 99.5% of business days over any 90-day period (batch reconciliation report).
- Production-escaping defects (critical + high severity) do not exceed 0.3 per 1 000 function points per quarter (defect tracker).
- Idempotency violations — reprocessing a request yields a different outcome — stay below 1 in 1 000 000 transactions (≤ 0.0001%); verified by weekly automated replay against a shadow ledger.
- Static analysis reports zero "critical" and fewer than 5 "high" unresolved findings per release candidate build.

### Measurement & Verification

- Automated end-of-day reconciliation job; discrepancies feed a dashboard and pager alert.
- Weekly replay suite resubmitting ≥ 10 000 transactions against the shadow ledger, asserting identical outcomes.

### Unavailable for max 2 minutes

- Dimensions: `reliable`, `usable`
- Qualities demonstrated: availability, reliability
- URL: https://quality.arc42.org/requirements/unavailability-max-2-minutes

### Context

If an expert system becomes unavailable, the employer has to pay the employees even though they cannot work. This is especially a problem in countries with high labour costs.

### Trigger

User intends to perform any operation within the expert system.

### Acceptance Criteria

- User never blocked longer than 2 minutes at any time due to system unavailability
- Maximum system downtime per incident: 2 minutes
- Applies to all system operations and features

### Understandable acceptance test cases

- Dimensions: `usable`, `suitable`
- Qualities demonstrated: understandability, learnability, testability, maintainability
- URL: https://quality.arc42.org/requirements/understandable-acceptance-tests

### Requirement

Acceptance test cases written in the domain-specific test language must be understandable and independently extendable by testers without software-development background.

### Acceptance Criteria

- Onboarding comprehension: in an onboarding exercise with **>= 5 new testers**, **>= 80%** correctly explain the intent and main structure of a representative acceptance test within **<= 60 min**; scope: current DSL, test template, and documentation set; source: moderated onboarding exercise log; horizon: each major DSL or template release.
- Independent authoring: in the same evaluation, **>= 80%** of participants create or modify one acceptance test for a new business rule within **<= 45 min** without developer assistance; scope: representative business scenarios from the current release; source: exercise review report; horizon: each major DSL or template release.
- Gate behavior: if either threshold is missed, release of DSL, template, or documentation changes is blocked within **<= 1 business day** after the evaluation report is available; scope: all major changes to the acceptance-test authoring experience; source: release gate log; horizon: every major DSL or template release.

### Monitoring Artifact

Acceptance-test authoring evaluation report and release gate.

### Understandable generated code

- Dimensions: `maintainable`
- Qualities demonstrated: understandability, maintainability, readability, code-readability, legibility
- URL: https://quality.arc42.org/requirements/understandable-generated-code

### Requirement

Code generated from XML-based test specifications into Java, Kotlin, or Groovy must be understandable and safely modifiable by developers or testers without studying the generator internals.

### Acceptance Criteria

- Static readability gate: generated files changed by a generator update contain **0 blocker or critical readability issues**; scope: all changed generated files in each pull request; source: static-analysis report; horizon: every pull request.
- Modification task success: in a release-candidate review with **>= 10 representative generated test files**, **>= 90%** of assigned change tasks are completed correctly within **<= 30 min per file** by the intended audience; scope: adding one assertion, test-data variant, or setup adjustment without generator changes; source: moderated review log; horizon: each release.
- Gate behavior: if either threshold is missed, release of the generator change is blocked within **<= 10 min** after the report is available; scope: all generator changes affecting emitted test code; source: CI gate logs; horizon: every pull request or release candidate.

### Monitoring Artifact

Generator quality gate and release-readiness report for generated test code.

### Up to date API

- Dimensions: `reliable`, `suitable`
- Qualities demonstrated: reliability, accuracy, correctness
- URL: https://quality.arc42.org/requirements/up-to-date-api

### Context

The configuration API aggregates data from multiple sources. Consumers depend on receiving current values; stale configuration leads to incorrect behavior.

### Trigger

A source-of-truth configuration change is published.

### Acceptance Criteria

- ≥ 95% of API responses return the updated value within 30 s of the source change (change-event timestamp vs. response-version telemetry, continuous production sampling).
- Zero stale responses after 60 s from the source change (synthetic freshness probe, continuous).
- If stale-response rate exceeds 5% at 30 s, or any stale response persists beyond 60 s for > 5 min, alert fires within 2 min and cache-invalidation playbook starts (monitoring + incident log).

### Usable Despite Color Blindness

- Dimensions: `usable`
- Qualities demonstrated: usability, user-experience, compliance, accessibility, inclusivity, interaction-capability
- URL: https://quality.arc42.org/requirements/usable-despite-color-blindness

### Requirement

All parts of the system must be usable by people with all types of color blindness.

### Acceptance Criteria

- System fully usable by users with Deuteranomaly (red-green weakness)
- System fully usable by users with Protanomaly (red weakness)
- System fully usable by users with Protanopia (red blindness)
- System fully usable by users with Deuteranopia (green blindness)
- System fully usable by users with Tritanomaly (blue-yellow weakness)
- System fully usable by users with Tritanopia (blue blindness)
- System fully usable by users with complete color blindness (achromatopsia)
- No functionality relies solely on color differentiation

### Usable on Factory Floor

- Dimensions: `usable`, `suitable`
- Qualities demonstrated: anticipated-workplace-environment, usability, interaction-capability
- URL: https://quality.arc42.org/requirements/usable-on-factory-floor

### Requirement

The interactive system must remain operable for trained production workers under representative factory-floor conditions, including required protective gloves, high ambient noise, and poor or uneven lighting.

### Acceptance Criteria

- Critical-task completion: in a qualification test with **>= 12 trained operators**, **>= 95%** complete the top **5** operational tasks without assistance within **<= 75 s per task**; scope: representative factory-floor environment with required gloves, ambient noise **>= 80 dB(A)**, and illuminance between **100 and 500 lux**; source: moderated usability test log; horizon: each release affecting UI, input devices, or workflow.
- Input accuracy: under the same test conditions, the interaction error rate is **<= 2%** across all attempts for the top **5** operational tasks; scope: tap, key, and selection actions required to complete the tested tasks; source: session recordings and task-observation protocol; horizon: each release affecting UI or input devices.
- Gate behavior: if either threshold is missed, rollout to factory-floor use is blocked within **<= 1 business day** after the validation report is available; scope: all releases affecting UI, display behavior, or input handling; source: release gate log; horizon: every qualifying release.

### Usable With Gloves

- Dimensions: `usable`, `suitable`
- Qualities demonstrated: anticipated-workplace-environment, usability, interaction-capability
- URL: https://quality.arc42.org/requirements/usable-with-gloves

### Requirement

All interactive functions required during normal operation must remain usable while operators wear the protective gloves required at the workplace.

### Acceptance Criteria

- In a usability test with **>= 8** representative users wearing the required glove type, **>= 90%** complete the top **5** operational tasks without assistance and within **<= 60 s per task**.
- Across the same test, the interaction error rate stays **<= 3%** for taps, selections, and confirmations on those tasks.
- If either threshold is missed, the release is not approved for glove-required workplaces.

### User Interface can be used in Current Browsers

- Dimensions: `flexible`, `usable`, `operable`
- Qualities demonstrated: flexibility, portability, compatibility, interoperability, interaction-capability
- URL: https://quality.arc42.org/requirements/user-interface-works-with-current-browsers

### Context
The system provides a responsive HTML5 user interface accessible via public internet.

### Trigger
A user accesses any application page using a desktop or mobile browser.

### Acceptance Criteria
- Browser compatibility: **100%** pass rate for critical user journeys in the **two latest stable versions** of Chrome, Firefox, Edge, and Safari; source: Automated end-to-end test suite.
- Visual consistency: **0** critical layout regressions (overlapping elements or broken navigation) across supported browsers; source: Visual regression testing reports.
- Failure-path behavior: **100%** of users on unsupported browsers (older than 3 years) receive a compatibility warning within **2 seconds** of page load; source: Client-side monitoring logs.

### Monitoring Artifact
Cross-browser compatibility dashboard

### User tries to achieve primary function

- Dimensions: `usable`
- Qualities demonstrated: functional-appropriateness, functional-completeness, user-experience, appropriateness-recognizability, interaction-capability
- URL: https://quality.arc42.org/requirements/user-tries-primary-function

### Context

Software is operational, running on its standard platform in typical use-case setting. User is trying to accomplish a primary task in the application.

### Trigger

User attempts to use a feature of the software for its intended purpose.

### Acceptance Criteria

- Software provides functionality that allows user to achieve desired outcome without unnecessary steps or interactions
- 95% of users are able to complete the desired task using the feature on their first attempt
- Average time taken to accomplish the task does not exceed 2 minutes
- Users do not have to undertake more than the minimal logical number of steps for that task
- Post-interaction, at least 90% of users rate their experience with the feature as "Intuitive" or "Very Easy" on feedback scale

### Vehicle's position validity influences accuracy

- Dimensions: `reliable`, `usable`
- Qualities demonstrated: preciseness, precision, reliability, functional-correctness
- URL: https://quality.arc42.org/requirements/accurate-vehicle-position-gps

### Context

The system is a vehicle navigation system that displays the vehicle's position on a map. GPS data might be retrieved at an insufficient rate for smooth position updates. To compensate for this, the system uses extrapolation to determine in-between positions, which is crucial for providing a smooth and accurate representation of the vehicle's movement on the map.

### Trigger

The vehicle's position on the map is being updated when the current position is determined by extrapolation rather than direct GPS data.

### Acceptance Criteria

- Extrapolated position recalculated with frequency greater than 10Hz
- System consistently maintains position update rate higher than 10 times per second
- Update rate maintained under various driving conditions (different speeds, urban vs. rural environments)
- Transition between extrapolated positions and new GPS data is smooth with no visible jumps on the map

### Withstand DDoS Attack

- Dimensions: `reliable`
- Qualities demonstrated: resilience, reliability, availability, high-availability, recoverability, intrusion-detection, resistance
- Source reference: This requirement was created with help from [ChatGPT](https://chat.openai.com) by using the prompt `create a quality attribute scenario to describe a resilience requirement for a web application`.
- URL: https://quality.arc42.org/requirements/withstand-ddos-attack

### Context

Web application is hosted on cloud-based infrastructure with multiple server instances distributed across different regions.

### Trigger

Distributed denial of service (DDoS) attack targeting the web application.

### Acceptance Criteria

- Web application maintains at least 99.9% uptime during DDoS attack, measured over 24-hour period
- Application maintains maximum response time of 500 milliseconds for 95% of legitimate user requests during attack
- Application handles sustained traffic load of 10 times its typical peak traffic during attack without service degradation
- Application effectively identifies and blocks malicious traffic sources with false positive rate of no more than 1%
- In event of server or infrastructure failures caused by attack, application automatically failovers to healthy resources within 2 minutes
- Throughout attack, application ensures data integrity and prevents data corruption with zero data loss or inconsistencies
- Application logs and reports DDoS attack incidents including attack vectors, traffic patterns, and response actions for further analysis

### Zero-knowledge data storage

- Dimensions: `secure`
- Qualities demonstrated: confidentiality, security, privacy
- URL: https://quality.arc42.org/requirements/zero-knowledge-data-storage

### Requirement

The file-storage service must be zero-knowledge for user file content: the operator stores encrypted content, but neither the service nor administrative staff can decrypt that content without user-controlled keys. This claim applies to file content, not necessarily to operational metadata such as file size or upload time.

### Acceptance Criteria

- Key-custody boundary: in each production release review, **0** service-side identities in the application, operations, support, or database-admin scope can export or retrieve plaintext customer content keys; source: IAM/KMS policy audit and privileged-access test report; horizon: every production release.
- Operator non-decryptability: in a quarterly audit drill with full operator access to storage, backups, logs, and databases but without user-supplied keys, **100%** of a random sample of **>= 20** customer files remain undecryptable; source: audit drill report; horizon: quarterly.
- Recovery boundary and gate: in simulated lost-key tests, operator-assisted recovery succeeds for **0 of 10** encrypted sample files; if any threshold above is missed, the product must not be described as zero-knowledge and the affected release is blocked within **<= 1 business day**; source: recovery test report, product copy review, and release gate log; horizon: each release candidate.

### Zone failure: no service interruption

- Dimensions: `reliable`, `operable`
- Qualities demonstrated: redundancy, availability, fault-tolerance, resilience
- URL: https://quality.arc42.org/requirements/zone-failure-no-service-interruption

### Context

A business-critical online service must remain available during infrastructure failures.

### Trigger

One complete availability zone (or equivalent independent failure domain) becomes unavailable.

### Acceptance Criteria

- The production deployment provides **N+1** capacity for stateless service workloads across at least **2** independent failure domains.
- Loss of one failure domain causes **0** user-visible outage for core functions.
- After failover stabilization, sustained throughput remains at least **95%** of pre-failure baseline.
- At the **95th percentile**, end-user response time degradation stays within **<= 20%** of pre-failure baseline.
- Automatic failover and recovery actions are completed within **<= 60 seconds** in quarterly resilience drills.
