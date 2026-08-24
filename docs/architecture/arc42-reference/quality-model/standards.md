# arc42 Standards

46 standards across 13 categories.

- Source: https://quality.arc42.org
- Dataset: [`arc42/quality.arc42.org-site`](https://github.com/arc42/quality.arc42.org-site) @ `3a24a3c640a7bb32fb3d5344dcc7dcda8d6e22f0`
- Retrieved: 2026-08-24
- Refresh by diffing this SHA against `HEAD` and regenerating.


## Categories

| Category | Standards |
|---|---|
| `accessibility` | EN 301 549, ISO/IEC/IEEE 26514, WCAG 2.2 |
| `ai` | AIUC-1, ETSI EN 304 223, IEEE 7000, ISO/IEC 12792, ISO/IEC 22989, ISO/IEC 25059, ISO/IEC 42001, ISO/IEC TR 24028, NIST AI RMF |
| `coding` | ISO/IEC 5055, MISRA-C |
| `data` | ISO 8000, ISO/IEC 25012, ISO/IEC 25022, ISO/IEC 25024 |
| `documentation` | ISO/IEC/IEEE 12207, ISO/IEC/IEEE 26514, ISO/IEC/IEEE 29119, ISO/IEC/IEEE 42010, ISO/IEC/IEEE 42030 |
| `general` | IEEE 2857, ISO/IEC 14756, ISO/IEC 25010, ISO/IEC 25019, ISO/IEC 25059, ISO/IEC 29100, ISO/IEC 5055, ISO/IEC/IEEE 12207, ISO/IEC/IEEE 29119, ISO/IEC/IEEE 42010, ISO/IEC/IEEE 42030 |
| `governance` | IEEE 7000, ISO/IEC 38500 |
| `privacy` | GDPR, IEEE 2857, ISO/IEC 29100, NIST PF, NIST SP 800-53 |
| `safety` | DO-178C, IEC 61508, IEC 62304, ISO 26262, MISRA-C |
| `sector` | DICOM, DO-178C, HL7 / FHIR, IEC 62304, IEC 62443, IHE, ISO 26262, MISRA-C, PCI DSS, SOX |
| `security` | CRA, ETSI EN 304 223, GDPR, IEC 62443, ISO 15408, ISO/IEC 27001, ISO/IEC TR 24028, NIST AI RMF, NIST PF, NIST SP 800-53, OWASP ASVS, PCI DSS, SOC 2 |
| `trustworthiness` | ISO/IEC TR 24028, NIST AI RMF |
| `usability` | EN 301 549, ISO/IEC 25010, ISO/IEC 25022, ISO/IEC/IEEE 26514, WCAG 2.2 |

## Standards

### AIUC-1 — AIUC-1 – AI Agent Standard

Commercial framework for enterprise AI agent adoption, addressing data and privacy, security, safety, reliability, accountability, and societal risk.

- ID: `aiuc1`
- Categories: `ai`
- Source: https://quality.arc42.org/standards/aiuc-1

### DICOM — DICOM — Digital Imaging and Communications in Medicine

International standard for storing, transmitting, and managing medical imaging data across modalities, PACS, and viewers for cross-vendor interoperability.

- ID: `dicom`
- Categories: `sector`
- Source: https://quality.arc42.org/standards/dicom

### DO-178C — DO-178C - Software Considerations in Airborne Systems and Equipment Certification

The de facto standard for developing and certifying airborne software, defining objective-based assurance levels (DAL A-E) tied to system safety impact.

- ID: `do178c`
- Categories: `safety`, `sector`
- Source: https://quality.arc42.org/standards/do-178c

### EN 301 549 — EN 301 549 - Accessibility requirements for ICT products and services

European standard defining accessibility requirements for ICT products and services across the EU: web, software, hardware, telecoms, and documents.

- ID: `en301549`
- Categories: `accessibility`, `usability`
- Source: https://quality.arc42.org/standards/en-301-549

### ETSI EN 304 223 — ETSI EN 304 223 - AI Cybersecurity Baseline Requirements

European standard setting baseline cybersecurity requirements for AI models and systems across their lifecycle, complementing the EU AI Act.

- ID: `etsien304223`
- Categories: `security`, `ai`
- Source: https://quality.arc42.org/standards/etsi-en-304-223

### CRA — EU Cyber Resilience Act (CRA) — Regulation 2024/2847

EU regulation mandating cybersecurity requirements for products with digital elements across their lifecycle: secure-by-design, vulnerability handling, updates.

- ID: `cra`
- Categories: `security`
- Source: https://quality.arc42.org/standards/cra

### GDPR — GDPR - General Data Protection Regulation

EU regulation governing the processing of personal data: individual rights, accountability, and privacy by design for anyone handling EU residents' data.

- ID: `gdpr`
- Categories: `privacy`, `security`
- Source: https://quality.arc42.org/standards/gdpr

### HL7 / FHIR — HL7 — Health Level Seven International (V2, CDA, FHIR)

Family of healthcare interoperability standards (V2, CDA, FHIR) for exchanging, integrating, and retrieving health information across organizations.

- ID: `hl7`
- Categories: `sector`
- Source: https://quality.arc42.org/standards/hl7

### IEC 61508 — IEC 61508 - Functional safety of E/E/PE safety-related systems

Foundational cross-industry standard for functional safety of E/E/PE systems, built on a risk-based lifecycle and Safety Integrity Levels (SIL 1 to 4).

- ID: `iec61508`
- Categories: `safety`
- Source: https://quality.arc42.org/standards/iec-61508

### IEC 62304 — IEC 62304 - Medical device software

International standard defining software life cycle processes for medical device software, including standalone Software as a Medical Device (SaMD).

- ID: `iec62304`
- Categories: `safety`, `sector`
- Source: https://quality.arc42.org/standards/iec-62304

### IEC 62443 — IEC 62443 - Security for Industrial Automation and Control Systems

Series of standards for cybersecurity of industrial automation and control systems, spanning product development, system integration, and operation.

- ID: `iec62443`
- Categories: `security`, `sector`
- Source: https://quality.arc42.org/standards/iec-62443

### IEEE 2857 — IEEE 2857 - Privacy Engineering Guidelines

IEEE guidelines for engineering privacy into software and systems across the development lifecycle, translating privacy-by-design into technical practice.

- ID: `ieee2857`
- Categories: `privacy`, `general`
- Source: https://quality.arc42.org/standards/ieee-2857

### IEEE 7000 — IEEE 7000-2021 — Ethical Concerns in System Design

IEEE process for embedding ethical values into system design via value-based engineering: value elicitation, ethical risk assessment, and traceability.

- ID: `ieee7000`
- Categories: `governance`, `ai`
- Source: https://quality.arc42.org/standards/ieee-7000

### IHE — IHE — Integrating the Healthcare Enterprise

Healthcare initiative defining integration profiles that combine HL7 and DICOM to solve interoperability problems, verified through Connectathon testing.

- ID: `ihe`
- Categories: `sector`
- Source: https://quality.arc42.org/standards/ihe

### ISO 26262 — ISO 26262 - Road vehicles — Functional safety

Automotive functional-safety standard for electrical and electronic systems, defining a risk-based safety lifecycle and ASIL A to D risk classification.

- ID: `iso26262`
- Categories: `safety`, `sector`
- Source: https://quality.arc42.org/standards/iso-26262

### ISO 8000 — ISO 8000 — Data Quality

International standard series for data quality and master data: defining, measuring, verifying, and exchanging quality data across sectors and systems.

- ID: `iso8000`
- Categories: `data`
- Source: https://quality.arc42.org/standards/iso-8000

### ISO/IEC 12792 — ISO/IEC 12792 - AI transparency taxonomy

Taxonomy of information elements helping AI stakeholders identify and address the transparency needs of AI systems across model, data, and governance.

- ID: `isoiec12792`
- Categories: `ai`
- Source: https://quality.arc42.org/standards/iso-iec-12792

### ISO/IEC 14756 — ISO/IEC 14756 - Measurement and Rating of Performance of Computer-Based Software Systems

Methods for measuring and rating user-oriented performance of computer-based software systems from the user's perspective: response times and throughput.

- ID: `iso14756`
- Categories: `general`
- Source: https://quality.arc42.org/standards/iso-iec-14756

### ISO 15408 — ISO/IEC 15408 - Common Criteria for IT Security

The Common Criteria framework for evaluating IT product security via protection profiles, security targets, and Evaluation Assurance Levels EAL1 to EAL7.

- ID: `iso15408`
- Categories: `security`
- Source: https://quality.arc42.org/standards/iso-15408

### ISO/IEC 22989 — ISO/IEC 22989 - AI concepts and terminology

Foundational vocabulary for artificial intelligence: core concepts and terms for AI systems, data, lifecycle stages, roles, and AI properties.

- ID: `isoiec22989`
- Categories: `ai`
- Source: https://quality.arc42.org/standards/iso-iec-22989

### ISO/IEC 25010 — ISO/IEC 25010 - Systems and Software Quality

The SQuaRE product quality model defining nine characteristics, from functional suitability and performance to security, maintainability, and safety.

- ID: `iso25010`
- Categories: `general`, `usability`
- Source: https://quality.arc42.org/standards/iso-25010

### ISO/IEC 25012 — ISO/IEC 25012 - Data Quality Model

SQuaRE-family data quality model defining 15 data quality characteristics across inherent and system-dependent perspectives for information systems.

- ID: `iso25012`
- Categories: `data`
- Source: https://quality.arc42.org/standards/iso-iec-25012

### ISO/IEC 25019 — ISO/IEC 25019 - Quality-in-use model

The SQuaRE quality-in-use model describing the outcome of system use through three characteristics: beneficialness, freedom from risk, and acceptability.

- ID: `iso25019`
- Categories: `general`
- Source: https://quality.arc42.org/standards/iso-25019

### ISO/IEC 25022 — ISO/IEC 25022 - Measurement of quality in use

SQuaRE measures for quality in use: effectiveness, efficiency, satisfaction, freedom from risk, and context coverage in a specified context of use.

- ID: `iso25022`
- Categories: `data`, `usability`
- Source: https://quality.arc42.org/standards/iso-25022

### ISO/IEC 25024 — ISO/IEC 25024 - Measurement of Data Quality

SQuaRE measures for evaluating data quality characteristics such as accuracy, completeness, consistency, and timeliness across the data lifecycle.

- ID: `iso25024`
- Categories: `data`
- Source: https://quality.arc42.org/standards/iso-25024

### ISO/IEC 25059 — ISO/IEC 25059 - Systems and Software Quality — Quality models for AI systems

Extended SQuaRE product quality model for AI systems defining seven modified or added sub-characteristics to the following characteristics of ISO 25010: functional suitability, performance efficiency, interaction capability, Reliability and security.

- ID: `iso25059`
- Categories: `general`, `ai`
- Source: https://quality.arc42.org/standards/iso-25059

### ISO/IEC 27001 — ISO/IEC 27001 - Information security management

International standard specifying requirements for an information security management system (ISMS): risk-based establishment, operation, and improvement.

- ID: `iso27001`
- Categories: `security`
- Source: https://quality.arc42.org/standards/iso-27001

### ISO/IEC 29100 — ISO/IEC 29100 - Privacy Framework

Privacy framework establishing common terminology, actors, and safeguards for processing personally identifiable information across its lifecycle.

- ID: `iso29100`
- Categories: `privacy`, `general`
- Source: https://quality.arc42.org/standards/iso-iec-29100

### ISO/IEC 38500 — ISO/IEC 38500 - Governance of IT for the Organization

International standard giving governing bodies principles for the effective, efficient, and acceptable use of IT via an Evaluate-Direct-Monitor model.

- ID: `iso38500`
- Categories: `governance`
- Source: https://quality.arc42.org/standards/iso-38500

### ISO/IEC 42001 — ISO/IEC 42001 - Artificial Intelligence Management System

International standard framing an AI management system (AIMS) to develop and use AI responsibly, with transparency, fairness, and accountability.

- ID: `iso42001`
- Categories: `ai`
- Source: https://quality.arc42.org/standards/iso-42001

### ISO/IEC 5055 — ISO/IEC 5055 - Automated Source Code Quality Measures

International standard defining four automated source-code quality measures for reliability, security, performance efficiency, and maintainability.

- ID: `iso5055`
- Categories: `general`, `coding`
- Source: https://quality.arc42.org/standards/iso-5055

### ISO/IEC TR 24028 — ISO/IEC TR 24028 - Overview of trustworthiness in artificial intelligence

Technical Report surveying trustworthiness in AI systems, cataloguing properties like reliability, robustness, safety, and fairness, plus AI threats.

- ID: `iso24028`
- Categories: `ai`, `trustworthiness`, `security`
- Source: https://quality.arc42.org/standards/iso-24028

### ISO/IEC/IEEE 12207 — ISO/IEC/IEEE 12207 - Software Life Cycle Processes

ISO/IEC/IEEE framework defining software life cycle processes across acquisition, development, operation, maintenance, and disposal of software systems.

- ID: `iso12207`
- Categories: `general`, `documentation`
- Source: https://quality.arc42.org/standards/iso12207

### ISO/IEC/IEEE 26514 — ISO/IEC/IEEE 26514 - Design and Development of Information for Users

Requirements for designing and developing user information across the software lifecycle: planning, information architecture, writing, and presentation.

- ID: `iso26514`
- Categories: `documentation`, `usability`, `accessibility`
- Source: https://quality.arc42.org/standards/iso-26514

### ISO/IEC/IEEE 29119 — ISO/IEC/IEEE 29119 - Software Testing

International software testing standard series defining test processes, documentation, and techniques from small projects to regulated environments.

- ID: `iso29119`
- Categories: `general`, `documentation`
- Alias: ['Testing', 'Software Testing']
- Source: https://quality.arc42.org/standards/iso-iec-ieee-29119

### ISO/IEC/IEEE 42010 — ISO/IEC/IEEE 42010 - Architecture Description

Framework for creating, evaluating, and comparing architecture descriptions using stakeholders, concerns, viewpoints, views, and documented decisions.

- ID: `iso42010`
- Categories: `documentation`, `general`
- Source: https://quality.arc42.org/standards/iso-42010

### ISO/IEC/IEEE 42030 — ISO/IEC/IEEE 42030 - Architecture Evaluation

Framework for systematically evaluating software, systems, and enterprise architectures: evaluation processes, methods, criteria, and quality models.

- ID: `iso42030`
- Categories: `documentation`, `general`
- Source: https://quality.arc42.org/standards/iso-iec-ieee-42030

### MISRA-C — MISRA C - Guidelines for the use of the C language in critical systems

Guidelines defining a safer subset of the C language for safety- and security-critical embedded systems, reducing undefined behavior for higher assurance.

- ID: `misra-c`
- Categories: `safety`, `sector`, `coding`
- Source: https://quality.arc42.org/standards/misra-c

### NIST AI RMF — NIST AI RMF — Artificial Intelligence Risk Management Framework

NIST voluntary framework for managing AI risks across the system lifecycle, organized around seven trustworthiness characteristics and four functions.

- ID: `nistairmf`
- Categories: `ai`, `security`, `trustworthiness`
- Source: https://quality.arc42.org/standards/nist-ai-rmf

### NIST PF — NIST Privacy Framework — Managing Privacy Risk

NIST voluntary tool for managing privacy risk in personal data processing through enterprise risk management, organized around five core functions.

- ID: `nistpf`
- Categories: `privacy`, `security`
- Source: https://quality.arc42.org/standards/nist-privacy-framework

### NIST SP 800-53 — NIST SP 800-53 — Security and Privacy Controls

US catalog of security and privacy controls for information systems, providing a risk-based baseline for compliance and continuous monitoring.

- ID: `nist80053`
- Categories: `security`, `privacy`
- Source: https://quality.arc42.org/standards/nist-800-53

### OWASP ASVS — OWASP Application Security Verification Standard (ASVS)

Open OWASP framework of requirement-level security controls for designing, building, and testing web applications and APIs, with three assurance levels.

- ID: `owaspasvs`
- Categories: `security`
- Source: https://quality.arc42.org/standards/owasp-asvs

### PCI DSS — PCI Data Security Standard (PCI DSS)

Payment card industry standard defining twelve baseline security requirements to protect cardholder data wherever it is stored, processed, or transmitted.

- ID: `pcidss`
- Categories: `security`, `sector`
- Source: https://quality.arc42.org/standards/pci-dss

### SOC 2 — SOC 2 — Service Organization Control 2

AICPA auditing framework producing a CPA attestation report on a service organization's controls across five Trust Services Criteria.

- ID: `soc2`
- Categories: `security`
- Source: https://quality.arc42.org/standards/soc-2

### SOX — SOX - Sarbanes-Oxley Act

US federal law mandating financial reporting accuracy and internal controls (ICFR) for systems that process, store, or report financial data.

- ID: `sox`
- Categories: `sector`
- Source: https://quality.arc42.org/standards/sox

### WCAG 2.2 — WCAG 2.2 - Web Content Accessibility Guidelines

The W3C standard for web accessibility: how to make web content usable by people with disabilities, organized around the four POUR principles.

- ID: `wcag22`
- Categories: `accessibility`, `usability`
- Source: https://quality.arc42.org/standards/wcag-2-2
