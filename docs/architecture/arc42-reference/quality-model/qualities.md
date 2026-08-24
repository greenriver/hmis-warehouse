# arc42 Quality Characteristics

191 quality characteristics and 37 aliases (redirect entries).

- Source: https://quality.arc42.org
- Dataset: [`arc42/quality.arc42.org-site`](https://github.com/arc42/quality.arc42.org-site) @ `3a24a3c640a7bb32fb3d5344dcc7dcda8d6e22f0`
- Retrieved: 2026-08-24
- Refresh by diffing this SHA against `HEAD` and regenerating.


Dimension tags (arc42 top-level quality categories): `reliable`, `usable`, `suitable`, `safe`, `flexible`, `secure`, `efficient`, `maintainable`, `operable`. Each characteristic carries one or more. `related` lists sibling characteristics; `standards` lists the standards (see `standards.md`) that address it; `aka` lists in-entry synonyms.

## Characteristics

### Access Control

... who is authorized to access to the product (both functionality and data), under what circumstances that access is granted, and to which parts of the product access is allowed.

- Dimensions: `secure`
- Related: security, accountability, authenticity, confidentiality, privacy, intrusion-detection, intrusion-prevention
- Standards: pcidss, iec62443, gdpr, sox, ieee2857, owaspasvs, soc2
- Source: https://quality.arc42.org/qualities/access-control

### Accessibility

Capability of a product or system to be usable by people with the widest range of characteristics and capabilities to achieve a specified goal in a specified context of use.

- Dimensions: `usable`
- Related: usability, inclusivity, interaction-capability, ease-of-use
- Standards: iso26514, iso25024, ieee2857, wcag22, en301549, iso25019
- Source: https://quality.arc42.org/qualities/accessibility

### Accountability

Capability of a product to enable actions of an entity to be traced uniquely to the entity

- Dimensions: `secure`
- Related: authenticity, security, non-repudiation, auditability, access-control, traceability
- Standards: iso38500, iso25010, iso27001, pcidss, iso42001, aiuc1, cra, gdpr, iso42030, sox, ieee2857, iso24028, etsien304223, soc2, nistairmf, ieee7000
- Source: https://quality.arc42.org/qualities/accountability

### Accuracy

The degree of conformity of a measured or calculated value to the true value, typically based on a global reference system.

- Dimensions: `reliable`, `usable`
- Related: correctness, preciseness, precision, data-quality
- Standards: iso25024, sox, iso24028, iso8000
- Source: https://quality.arc42.org/qualities/accuracy

### Adaptability

Capability of a product to be effectively and efficiently adapted for or transferred to different hardware, software or other operational or usage environments * Adaptations include those carried out by specialized support staff, and those carried out by business or operational staff, or end users. *If the product is to be adapted by the end user, adaptability corresponds to suitability for individualization

- Dimensions: `flexible`, `usable`
- Related: changeability, configurability, maintainability, flexibility, usability, scalability, elasticity
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/adaptability

### Affordability

"the state of being cheap enough for people to be able to buy."

- Dimensions: `suitable`, `usable`, `efficient`
- Aliases (aka): Budget Constraint
- Related: cost, profitability, resource-utilization
- Standards: —
- Source: https://quality.arc42.org/qualities/affordability

### Agility

A system can **rapidly** be changed (as opposed to flexibility, which means that a system can _easily_ be changed.)

- Dimensions: `flexible`
- Related: flexibility, changeability, adaptability, modifiability, modularity
- Standards: —
- Source: https://quality.arc42.org/qualities/agility

### Analysability

Capability of a product to be effectively and efficiently assessed regarding the impact of an intended change to one or more of its parts, to diagnose it for deficiencies or causes of failures, or to identify parts to be modified. Implementation can include providing mechanisms for the product to analyse its own faults and provide reports prior to a failure or other event. from [ISO-25010:2023](/references/#iso-25010-2023)

- Dimensions: `reliable`, `maintainable`
- Aliases (aka): Inspectability, Evaluability
- Related: flexibility, maintainability, modifiability, testability, debuggability
- Standards: iso25010, misra-c, iso42030
- Source: https://quality.arc42.org/qualities/analysability

### Anticipated Workplace Environment

This describes the workplace in which the users are to work and use the product. It should describe any features of the workplace that could have an effect on the design of the product, and the social and cultural aspects of the workplace.

- Dimensions: `usable`
- Related: functional-appropriateness, expected-physical-environment
- Standards: —
- Source: https://quality.arc42.org/qualities/anticipated-workplace-environment

### Appearance

Your client may have made particular demands for the product, such as corporate branding, colours to be used, and so on.

- Dimensions: `usable`
- Related: ease-of-use, learnability, self-descriptiveness, user-interface-aesthetics, attractiveness
- Standards: —
- Source: https://quality.arc42.org/qualities/appearance

### Appropriateness recognizability

Capability of a product to be recognized by users as appropriate for their needs.

- Dimensions: `usable`, `operable`
- Related: usability, attractiveness, operability, user-error-protection, user-engagement, ease-of-use, understandability
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/appropriateness-recognizability

### Atomicity

Atomicity ensures that a transaction is an all-or-nothing unit of work: either all operations are applied, or none are. This prevents partially applied changes and hazardous intermediate states.

- Dimensions: `reliable`
- Related: transactionality, consistency, durability, data-integrity, robustness
- Standards: —
- Source: https://quality.arc42.org/qualities/atomicity

### Attractiveness

Attractiveness summarizes properties that make software appealing to users and stakeholders. Attractive software typically exhibits: * User-friendly and intuitive design: The software is easy to navigate and use, minimizing learning curves and maximizing efficiency. * Robust functionality and regular updates: The software offers powerful features and is continuously improved to meet evolving user needs. * Optimized performance with minimal errors: The software runs smoothly, with quick load times and few errors, enhancing user productivity. * Compatibility with various systems: The software works well across different platforms and hardware configurations.

- Dimensions: `usable`
- Related: usability, clarity, user-interface-aesthetics, user-experience, user-assistance, appearance
- Standards: —
- Source: https://quality.arc42.org/qualities/attractiveness

### Auditability

... what the product has to do (usually retain records) to permit the required audit checks.

- Dimensions: `operable`
- Related: transparency, traceability, operability, observability, devops-metrics, accountability, certifiability
- Standards: iso38500, iso26262, misra-c, hl7, iso15408, cra, iec62443, do178c, iso42010, gdpr, iso42030, sox, ieee2857, etsien304223, owaspasvs, soc2, ieee7000, dicom, ihe
- Source: https://quality.arc42.org/qualities/auditability

### Authenticity

Capability of a product to prove that the identity of a subject or resource is the one claimed.

- Dimensions: `secure`
- Related: integrity, security, non-repudiation, accountability, access-control
- Standards: iso25010, iso27001, pcidss, iso15408, cra, gdpr, sox, ieee2857, owaspasvs
- Source: https://quality.arc42.org/qualities/authenticity

### Autonomy

An autonomous decentralized system is a decentralized system composed of modules or components that are designed to operate independently but are capable of interacting with each other to meet the overall goal of the system.

- Dimensions: `operable`, `suitable`
- Aliases (aka): Autonomicity
- Related: independence, self-containedness, controllability, composability, flexibility, configurability, adaptability, recoverability, fault-tolerance, resilience
- Standards: —
- Source: https://quality.arc42.org/qualities/autonomy

### Availability

Capability of a product to be accessible and operational when required for use.

- Dimensions: `reliable`, `usable`
- Aliases (aka): High Availability
- Related: high-availability, robustness, reliability, usability, fault-tolerance, recoverability, dependability, faultlessness, recovery-time, resilience, graceful-degradation
- Standards: iso25010, iso27001, iso26262, pcidss, hl7, iso15408, cra, iec62443, iso25024, iso12207, sox, iso24028, etsien304223, soc2, dicom, ihe
- Source: https://quality.arc42.org/qualities/availability

### Backward compatibility

Backward compatibility is a property of an operating system, product, or technology that allows for interoperability with an older legacy system, or with input designed for such a system, especially in telecommunications and computing.

- Dimensions: `usable`, `operable`, `reliable`
- Related: portability, flexibility, compatibility, interoperability, updateability
- Standards: —
- Source: https://quality.arc42.org/qualities/backward-compatibility

### Bias Mitigation

Bias mitigation refers to the systematic identification and reduction of unfair prejudice in algorithmic systems, particularly those using artificial intelligence and machine learning. It involves techniques and practices designed to prevent, detect, and address algorithmic biases that could lead to discriminatory outcomes against individuals or groups based on protected characteristics.

- Dimensions: `reliable`, `safe`, `suitable`
- Related: fairness, explainability, transparency, accountability, safety, data-quality
- Standards: isoiec22989, ieee7000
- Source: https://quality.arc42.org/qualities/bias-mitigation

### Calibration

Calibration is the degree to which the stated certainty of a system's outputs corresponds to the empirical frequency with which those outputs are correct, over a representative population of inputs and within defined population, time, and refusal conditions.

- Dimensions: `reliable`, `suitable`
- Related: groundedness, accuracy, precision, correctness, model-transparency, explainability, fairness, reliability
- Standards: nistairmf, iso24028
- Source: https://quality.arc42.org/qualities/calibration

### Capacity

System meets requirements for the maximum limits of system parameter. (modified from)) [ISO-25010:2023](/references/#iso-25010-2023)

- Dimensions: `efficient`, `reliable`
- Related: efficiency, resource-efficiency, scalability, performance, resource-utilization
- Standards: iso25010, iso14756
- Source: https://quality.arc42.org/qualities/capacity

### Carbon Emission Efficiency

... refers to the economic benefits generated by production activities that produce carbon emissions at the same time. The less carbon emissions generated per unit of economic output, the more carbon emission efficient it is.

- Dimensions: `efficient`
- Aliases (aka): Carbon Efficiency
- Related: sustainability, energy-efficiency
- Standards: —
- Source: https://quality.arc42.org/qualities/carbon-emission-efficiency

### Certifiability

The degree to which a system can be certified to meet specific regulatory, safety, or quality standards through demonstration of compliance evidence.

- Dimensions: `suitable`, `reliable`, `safe`
- Related: compliance, testability, auditability, traceability, verifiability, safety, analysability
- Standards: iso26262, do178c, iec62304, iec61508, ihe
- Source: https://quality.arc42.org/qualities/certifiability

### Change failure rate

**Change failure rate**: the percentage of code changes that require hot fixes or other remediation after production. This does not measure failures caught by testing and fixed before code is deployed. quoted from [Atlassian](https://www.atlassian.com/devops/frameworks/devops-metrics)

- Dimensions: `operable`
- Related: controllability, operability, testability, analysability, deployability, devops-metrics, reliability
- Standards: —
- Source: https://quality.arc42.org/qualities/change-failure-rate

### Changeability

One common theme popping up in projects is that change is the only constant. Code changes, architecture changes, technology changes, requirements change and people change. But often, change comes at a high cost. Things were just not prepared for change because doing so would have imposed the costs earlier on. But really the same costs? To reduce costs in the long run, wouldn’t it be beneficial to spend some effort in changeability upfront? Of course, but it is difficult to find the sweet spot between spending enough and too much effort to properly implement changeability. ... For aspects shall be distinguished: 1. Robustness: the system is insensitive to a change in the surrounding environment. 2. Flexibility: the system can easily be changed. 3. Agility: the system can rapidly be changed. 4. Adaptability: the system adapts itself to changing operating conditions.

- Dimensions: `flexible`, `maintainable`
- Aliases (aka): Mutability
- Related: flexibility, adaptability, modifiability, configurability, modularity, evolvability, maintainability
- Standards: —
- Source: https://quality.arc42.org/qualities/changeability

### Clarity

The quality of being coherent and intelligible. Oxford Dictionary

- Dimensions: `usable`, `reliable`
- Related: coherence, transparency, understandability, legibility, communicability
- Standards: iso26514, iso42010, iso42030, iso12207
- Source: https://quality.arc42.org/qualities/clarity

### Co-existence

Capability of a product to perform its required functions efficiently while sharing a common environment and resources with other products, without detrimental impact on any other product.

- Dimensions: `flexible`
- Related: compatibility, interoperability, portability
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/co-existence

### Code Complexity

A quantitative measure [whether there is not more than an adequate] number of linearly independent paths through a program’s source code. It was developed by Thomas J. McCabe, Sr. in 1976.

- Dimensions: `efficient`, `usable`
- Related: understandability, legibility, clarity, conciseness, consistency, readability, maintainability
- Standards: —
- Source: https://quality.arc42.org/qualities/code-complexity

### Code Readability

Readability, to me, means that the code is easy to follow, logically. * Standards of indentation and formatting are followed, so that the code and its structure are clearly visible. * Variables are named meaningfully, so that they communicate intent. * Comments, which are present only where needed, are concise and adhere to standard formats. * Guard clauses are used instead of nested if statements. * Facilities of the language are used skillfully, leveraging iteration and recursion rather than copy and paste coding. * Functions are short and to the point, and do one thing. * Indirection is minimized as much as possible, while still maintaining flexibility.

- Dimensions: `usable`, `efficient`
- Related: understandability, legibility, clarity, conciseness, consistency, readability
- Standards: —
- Source: https://quality.arc42.org/qualities/code-readability

### Coherence

Logically or aesthetically ordered or integrated

- Dimensions: `usable`, `efficient`
- Related: consistency
- Standards: iso42010, iso42030, iso12207
- Source: https://quality.arc42.org/qualities/coherence

### Cohesion

In computer programming, cohesion refers to the degree to which the elements inside a module belong together. Cohesion is an ordinal type of measurement and is usually described as “high cohesion” or “low cohesion”. Modules with high cohesion tend to be preferable, because high cohesion is associated with several desirable traits of software including robustness, reliability, reusability, and understandability.

- Dimensions: `efficient`, `suitable`, `maintainable`
- Related: coherence, modularity
- Standards: —
- Source: https://quality.arc42.org/qualities/cohesion

### Communicability

Communicability in software systems refers to the clarity and effectiveness with which the system conveys its functions and usability to the user. This includes the design of the user interface, the presentation of information, and the system's ability to guide and assist users in accomplishing their tasks. modified by G.Starke, originated from [Prates+2000](https://dl.acm.org/doi/fullHtml/10.1145/328595.328608)

- Dimensions: `usable`
- Related: usability, learnability, understandability, user-error-protection, ease-of-use
- Standards: iso42010, iso42030
- Source: https://quality.arc42.org/qualities/communicability

### Compatibility

Capability of a product to exchange information with other products, and/or to perform its required functions while sharing the same common environments and resources.

- Dimensions: `usable`, `operable`, `reliable`
- Related: portability, flexibility, backward-compatibility
- Standards: iso25010, hl7, iso42030, iso12207, dicom, ihe
- Source: https://quality.arc42.org/qualities/compatibility

### Completeness

The degree to which all required data is present and no essential information is missing.

- Dimensions: `reliable`, `suitable`
- Related: data-quality, accuracy, consistency, integrity, correctness
- Standards: iso25024, iso8000, iso25012
- Source: https://quality.arc42.org/qualities/completeness

### Compliance

How well does the system or product obeys the rules of a given standard.

- Dimensions: `secure`, `safe`, `usable`, `reliable`, `efficient`, `suitable`
- Aliases (aka): Standard Compliance
- Related: security, safety, usability, reliability, efficiency, testability, auditability, traceability, accountability, certifiability
- Standards: iso38500, iso27001, iso26262, pcidss, hl7, iso15408, cra, iso25024, do178c, sox, ieee2857, wcag22, en301549, iso24028, iso25019, iso29119
- Source: https://quality.arc42.org/qualities/compliance

### Composability

Composability is a system design principle that deals with the inter-relationships of components. A highly composable system provides components that can be selected and assembled in various combinations to satisfy specific user requirements.

- Dimensions: `flexible`
- Related: modularity, autonomy, reusability, interoperability, loose-coupling
- Standards: —
- Source: https://quality.arc42.org/qualities/composability

### Conciseness

Giving a lot of information clearly and in a few words; brief but comprehensive. Oxford Dictionary

- Dimensions: `usable`, `efficient`
- Related: understandability, clarity, coherence
- Standards: iso26514, iso42010
- Source: https://quality.arc42.org/qualities/conciseness

### Confidentiality

Capability of a product to ensure that data are accessible only to those authorized to have access.

- Dimensions: `secure`
- Related: integrity, accountability, privacy, access-control, authenticity
- Standards: iso25010, iso27001, pcidss, hl7, iso15408, cra, iec62443, iso25024, gdpr, sox, ieee2857, etsien304223, owaspasvs, soc2, dicom, ihe
- Source: https://quality.arc42.org/qualities/confidentiality

### Configurability

Configurability refers to the ability of a system, software application, or hardware device to be easily customized and adapted to suit various requirements, preferences, and environments. A configurable system allows users or administrators to modify its settings, features, or behavior without the need for extensive code changes or hardware modifications. Configurability empowers users to tailor the system to their specific needs, making it more versatile and adaptable.

- Dimensions: `flexible`, `usable`
- Aliases (aka): Tailorability
- Related: flexibility, changeability, adaptability, modifiability, versatility, customizability
- Standards: iso26262, ieee2857
- Source: https://quality.arc42.org/qualities/configurability

### Consent Management

Consent management is the capability to obtain, record, update, and enforce user consent decisions for personal data processing.

- Dimensions: `secure`, `usable`
- Related: privacy, data-protection, compliance, transparency, accountability
- Standards: gdpr, ieee2857, iso29100
- Source: https://quality.arc42.org/qualities/consent-management

### Consistency

Free from variation or contradiction

- Dimensions: `usable`, `efficient`
- Related: determinism, atomicity, durability, transactionality, understandability, coherence
- Standards: iso26514, iso25024, iso42010, iso42030, iso12207, sox, wcag22, en301549, iso8000
- Source: https://quality.arc42.org/qualities/consistency

### Controllability

The interface will allow the user to perceive that they are in control and will allow appropriate control.

- Dimensions: `usable`, `operable`
- Aliases (aka): Human Controllability, Human Oversight
- Related: usability, autonomy, operability, interaction-capability, governability, intervenability, auditability
- Standards: ieee2857, iso25059, iso42001, nistairmf
- Source: https://quality.arc42.org/qualities/controllability

### Convenience

... things the product shall do to simplify tasks, and to expedite and make the user/customer’s work easier and smoother.

- Dimensions: `usable`
- Related: usability, ease-of-use, user-assistance
- Standards: —
- Source: https://quality.arc42.org/qualities/convenience

### Correctness

Provide accurate results when used by intended users for intended functions. Sub-characteristic of functional suitability.

- Dimensions: `usable`, `reliable`, `suitable`
- Aliases (aka): Functional Correctness
- Related: usability, functionality, functional-suitability, functional-correctness, accuracy, precision, functional-appropriateness
- Standards: iso26514, iso12207, sox, iso8000, iso29119, iso25059
- Source: https://quality.arc42.org/qualities/correctness

### Cost

...the value of money that has been used up to produce something or deliver a service, and hence is not available for use anymore.

- Dimensions: `suitable`, `efficient`
- Related: affordability, profitability
- Standards: —
- Source: https://quality.arc42.org/qualities/cost

### Credibility

Credibility comprises the objective and subjective components of the believability of a source or message.

- Dimensions: `reliable`
- Related: accountability, usability, user-engagement
- Standards: iso25024
- Source: https://quality.arc42.org/qualities/credibility

### Customizability

The ability of software to be changed by the user

- Dimensions: `flexible`, `usable`
- Related: configurability, flexibility, adaptability, changeability, themability
- Standards: —
- Source: https://quality.arc42.org/qualities/customizability

### Cyber Security

The term cyber security refers to all measures that serve to protect critical IT infrastructure, networks and data from digital attacks. The focus of cyber security or IT security is on defending against all digital attacks from internal or external sources that aim to access company systems or data without authorization.

- Dimensions: `secure`
- Related: security, information-security, authenticity, confidentiality
- Standards: —
- Source: https://quality.arc42.org/qualities/cyber-security

### Cycle time

Time a team spends working on an item until it is ready for shipment. In the development world, cycle time is the time from when developers make a commit to the moment it's deployed to production. This key DevOps metric helps project leads and engineering managers better understand what works well in the development pipeline. From the introductory article by [Atlassian](https://www.atlassian.com/devops/frameworks/devops-metrics)

- Dimensions: `operable`, `suitable`, `efficient`
- Related: controllability, testability, deployability, devops-metrics, lead-time-for-changes
- Standards: —
- Source: https://quality.arc42.org/qualities/cycle-time

### Data Integrity

Data integrity refers to the maintenance and assurance of accuracy, consistency, and reliability of data over its entire life cycle. It ensures that data remains unaltered and consistent from creation to deletion, maintaining its original state unless specifically modified through authorized processes.

- Dimensions: `reliable`, `secure`
- Related: integrity, data-quality, accuracy, correctness, consistency, authenticity, non-repudiation, transactionality
- Standards: iso27001, iso25024, pcidss, hl7, nist80053, iso15408, gdpr, sox, ieee2857, owaspasvs, iso8000, dicom, ihe
- Source: https://quality.arc42.org/qualities/data-integrity

### Data Localization

Data localization is the requirement that data about a nation's citizens or residents be collected, processed, and/or stored inside the country.

- Dimensions: `suitable`, `secure`
- Related: data-sovereignty, data-residency, compliance, privacy
- Standards: —
- Source: https://quality.arc42.org/qualities/data-localization

### Data Minimization

Data minimization means collecting and processing only the personal data that is necessary for a specific and legitimate purpose.

- Dimensions: `secure`
- Related: privacy, data-protection, compliance, data-quality
- Standards: gdpr, ieee2857, iso29100
- Source: https://quality.arc42.org/qualities/data-minimization

### Data Protection

Data protection is the process of safeguarding important information from corruption, compromise or loss.

- Dimensions: `secure`
- Related: privacy, security, compliance, data-integrity, data-sovereignty
- Standards: gdpr, ieee2857, iso29100
- Source: https://quality.arc42.org/qualities/data-protection

### Data Quality

Data quality refers to the state of qualitative or quantitative pieces of information. Data is generally considered high quality if it is "fit for [its] intended uses in operations, decision making and planning". Data is deemed of high quality if it correctly represents the real-world construct to which it refers.

- Dimensions: `reliable`, `suitable`, `usable`
- Related: accuracy, correctness, precision, integrity, consistency, data-integrity
- Standards: iso42001, hl7, isoiec22989, sox, iso8000, iso25012, dicom, ihe
- Source: https://quality.arc42.org/qualities/data-quality

### Data Residency

Data residency is the physical or geographical location of an organization's digital information.

- Dimensions: `suitable`
- Related: data-sovereignty, data-localization, compliance, privacy
- Standards: —
- Source: https://quality.arc42.org/qualities/data-residency

### Data Sovereignty

Data sovereignty means that data generated within a country's borders is governed by that nation's laws and regulatory frameworks; this ensures local control over data access, storage, and usage.

- Dimensions: `secure`, `suitable`
- Related: privacy, security, compliance, data-protection, data-residency, data-localization
- Standards: —
- Source: https://quality.arc42.org/qualities/data-sovereignty

### Debuggability

Ability of a system to make defects and undesired behaviors easy to diagnose and localize in development, test, and production environments.

- Dimensions: `operable`, `maintainable`
- Related: analysability, maintainability, operability, observability, testability, transparency
- Standards: —
- Source: https://quality.arc42.org/qualities/debuggability

### Dependability

Ability to perform as and when required.

- Dimensions: `reliable`
- Related: availability, robustness, fault-tolerance, reliability
- Standards: iso26262, cra, iso25019
- Source: https://quality.arc42.org/qualities/dependability

### Deployability

Deployability refers to a property of software indicating that it may be deployed, that is, allocated to an environment for execution—within a predictable and acceptable amount of time and effort. Moreover, if the new deployment is not meeting its specifications, it may be rolled back, again within a predictable and acceptable amount of time and effort.

- Dimensions: `operable`, `suitable`
- Related: releasability, operability, testability, analysability, devops-metrics
- Standards: iso12207
- Source: https://quality.arc42.org/qualities/deployability

### Deployment frequency

**Deployment frequency**: how often new code is deployed into production.

- Dimensions: `operable`, `suitable`
- Related: controllability, operability, testability, analysability, deployability, devops-metrics, releasability
- Standards: —
- Source: https://quality.arc42.org/qualities/deployment-frequency

### Determinism

Determinism means that under the same inputs and initial conditions, a system produces the same externally observable behavior. This is foundational for reproducible testing, debugging, formal reasoning, and fault-tolerant replication.

- Dimensions: `reliable`, `efficient`
- Related: reproducibility, consistency, testability, reliability, time-behaviour, transactionality, explainability
- Standards: —
- Source: https://quality.arc42.org/qualities/determinism

### Devops-Metrics

1. **Lead time for changes**: the length of time between when a code change is committed to the trunk branch and when it is in a deployable state. 1. **Change failure rate**: the percentage of code changes that require hot fixes or other remediation after production. 1. **Deployment frequency**: how often new code is deployed into production 1. **Mean time to recovery**: how long it takes to recover from a partial service interruption or total failure. quoted from [Atlassian](https://www.atlassian.com/devops/frameworks/devops-metrics)

- Dimensions: `operable`
- Aliases (aka): DORA
- Related: controllability, operability, testability, analysability, deployability
- Standards: —
- Source: https://quality.arc42.org/qualities/devops-metrics

### Diagnosability

Diagnosability is the degree to which a system provides clear, accurate, and timely information to identify and localize the cause of a failure from its observed symptoms.

- Dimensions: `operable`, `reliable`
- Related: analysability, debuggability, observability, recoverability, fault-tolerance
- Standards: —
- Source: https://quality.arc42.org/qualities/diagnosability

### Discoverability

The ease with which users can find new or unknown features, content, and functionalities within a product or system without prior knowledge of their existence.

- Dimensions: `usable`
- Related: learnability, usability, intuitiveness
- Standards: —
- Source: https://quality.arc42.org/qualities/discoverability

### Distributability

In software engineering, **distributability** refers to the ease with which a system's components can be distributed across multiple physical or virtual locations, platforms, or computing nodes while maintaining functionality, performance, and reliability. A highly distributable system enables workload distribution, geographic deployment flexibility, and the ability to partition functionality across heterogeneous environments.

- Dimensions: `flexible`, `efficient`
- Related: scalability, deployability, modularity, portability, elasticity, performance
- Standards: —
- Source: https://quality.arc42.org/qualities/distributability

### Drift Detectability

Drift detectability is the degree to which a system can detect, quantify, localize, and report meaningful deviations between current production behavior and an expected baseline, within defined time, confidence, coverage, and false-alarm limits.

- Dimensions: `reliable`, `operable`
- Related: observability, diagnosability, reliability, robustness, data-quality, model-transparency, traceability, fairness, bias-mitigation
- Standards: nistairmf, iso24028, etsien304223
- Source: https://quality.arc42.org/qualities/drift-detectability

### Durability

The ability of a software system to remain useful and meet user needs over a long period, particularly in the face of changing business requirements and technological advancements.

- Dimensions: `reliable`
- Related: atomicity, consistency, transactionality, reliability, availability, robustness, data-integrity
- Standards: —
- Source: https://quality.arc42.org/qualities/durability

### Ease of Use

Ease of use is a basic concept that describes how easily users can use a product. Design teams define specific metrics per project—e.g., “Users must be able to tap Find within 3 seconds of accessing the interface.” —and aim to optimize ease of use while offering maximum functionality and respecting business limitations.

- Dimensions: `operable`, `usable`
- Related: attractiveness, operability, user-error-protection, user-engagement, user-experience, user-interface-aesthetics, user-assistance, usability
- Standards: —
- Source: https://quality.arc42.org/qualities/ease-of-use

### Effectiveness

Effectiveness is the capability of producing a desired result or the ability to produce desired output.

- Dimensions: `efficient`
- Related: efficiency
- Standards: iso25022, iso25019
- Source: https://quality.arc42.org/qualities/effectiveness

### Efficiency

capable of producing desired results with little or no waste (as of time or materials)

- Dimensions: `efficient`
- Related: performance, effectiveness
- Standards: misra-c, iso25022, iso25019
- Source: https://quality.arc42.org/qualities/efficiency

### Elasticity

In distributed system and system resource, elasticity is defined as "the degree to which a system is able to adapt to workload changes by provisioning and de-provisioning resources in an autonomic manner, such that at each point in time the available resources match the current demand as closely as possible"

- Dimensions: `flexible`
- Related: adaptability, scalability, flexibility
- Standards: —
- Source: https://quality.arc42.org/qualities/elasticity

### Energy Efficiency

In the context of software engineering, "energy efficiency" refers to the ability of a software system to optimize its energy consumption while performing its intended tasks effectively. It involves designing and implementing software in a way that minimizes the amount of energy required to run the system, without compromising its functionality, performance, or user experience.

- Dimensions: `efficient`
- Related: carbon-emission-efficiency, sustainability, energy-proportionality
- Standards: —
- Source: https://quality.arc42.org/qualities/energy-efficiency

### Energy Proportionality

Energy proportionality is a measure of the relationship between power consumed in a computer system, and the rate at which useful work is done (its utilization). If the overall power consumption is proportional to the computer's utilization, then the machine is said to be energy proportional.

- Dimensions: `efficient`
- Related: energy-efficiency, resource-utilization, elasticity, scalability, sustainability, carbon-emission-efficiency
- Standards: —
- Source: https://quality.arc42.org/qualities/energy-proportionality

### Evolvability

The ability of a system to adapt to changes in its environment, requirements, and implementation technologies in a cost-effective way.

- Dimensions: `flexible`, `maintainable`
- Related: adaptability, maintainability, extensibility, scalability, modularity, traceability, auditability
- Standards: —
- Source: https://quality.arc42.org/qualities/evolvability

### Expected physical environment

... specifies the physical environment in which the product will operate.

- Dimensions: `suitable`, `operable`
- Related: anticipated-workplace-environment
- Standards: —
- Source: https://quality.arc42.org/qualities/expected-physical-environment

### Explainability

A system S is explainable with respect to an aspect X of S relative to an addressee A in context C if and only if there is an entity E (the explainer) who, by giving a corpus of information I (the explanation of X), enables A to understand X of S in C.

- Dimensions: `safe`, `suitable`
- Related: accountability, analysability, clarity, determinism, groundedness
- Standards: iso42001, isoiec22989, iso24028, nistairmf, ieee7000
- Source: https://quality.arc42.org/qualities/explainability

### Extensibility

Ability to add new features or functions to a system.

- Dimensions: `flexible`, `maintainable`
- Related: adaptability, modifiability, changeability, flexibility
- Standards: hl7, dicom, ihe
- Source: https://quality.arc42.org/qualities/extensibility

### Fail safe

Capability of a product to automatically place itself in a safe operating mode, or to revert to a safe condition in the event of a failure

- Dimensions: `safe`, `reliable`
- Related: safety, robustness
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/fail-safe

### Failure Transparency

Failure transparency hides faults and recovery from users and applications so that a distributed system continues to operate correctly despite component failures.

- Dimensions: `reliable`, `safe`
- Related: availability, fault-tolerance, resilience, reliability
- Standards: —
- Source: https://quality.arc42.org/qualities/failure-transparency

### Fairness

In machine learning, fairness refers to the absence of any prejudice or favoritism toward an individual or group based on their inherent or acquired characteristics; many formal criteria (e.g., demographic parity, equalized odds, equal opportunity) are used to assess it.

- Dimensions: `reliable`, `safe`, `suitable`
- Related: bias-mitigation, explainability, transparency, accountability
- Standards: iso42001, isoiec22989, iso24028, nistairmf, ieee7000
- Source: https://quality.arc42.org/qualities/fairness

### Fault isolation

Fault detection, isolation, and recovery (FDIR) is a subfield of control engineering which concerns itself with monitoring a system, identifying when a fault has occurred, and pinpointing the type of fault and its location. Two approaches can be distinguished: A direct pattern recognition of sensor readings that indicate a fault and an analysis of the discrepancy between the sensor readings and expected values, derived from some model. In the latter case, it is typical that a fault is said to be detected if the discrepancy or residual goes above a certain threshold. It is then the task of fault isolation to categorize the type of fault and its location in the machinery.

- Dimensions: `safe`, `reliable`
- Related: safety, fail-safe, fault-tolerance, faultlessness, risk-identification, hazard-warning
- Standards: iso26262, do178c
- Source: https://quality.arc42.org/qualities/fault-isolation

### Fault tolerance

Capability of a product to operate as intended despite the presence of hardware or software faults.

- Dimensions: `reliable`, `usable`
- Related: robustness, reliability, usability, availability, recoverability, faultlessness, graceful-degradation, autonomy
- Standards: iso25010, iso26262, iec61508
- Source: https://quality.arc42.org/qualities/fault-tolerance

### Faultlessness

Capability of a product to perform specified functions without fault under normal operation.

- Dimensions: `reliable`, `usable`, `secure`
- Related: dependability, reliability, availability
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/faultlessness

### Features

A **feature** is a unique characteristic that a product has or should have.

- Dimensions: `usable`
- Related: functionality, functional-completeness, usability, functional-suitability
- Standards: —
- Source: https://quality.arc42.org/qualities/features

### Flexibility

Capability of a product to: - serve a different or expanded set of requirements - work with different infrastructures or environments

- Dimensions: `flexible`
- Related: maintainability, modularity, adaptability, configurability, changeability, agility, autonomy
- Standards: iso25010, misra-c, hl7, iso42030, iso12207, ieee2857, wcag22, en301549, dicom, ihe
- Source: https://quality.arc42.org/qualities/flexibility

### Functional Adaptability

Degree to which an AI system can accurately acquire information from data, or the result of previous actions, and use that information in future predictions.

- Dimensions: `suitable`
- Related: functionality, functional-suitability, suitability
- Standards: iso25059
- Source: https://quality.arc42.org/qualities/functional-adaptability

### Functional Appropriateness

Provide functions that avoid behaviours or interactions that are irrelevant to accomplishing a specific task under specified conditions and do not provide functions that are not.

- Dimensions: `usable`, `reliable`, `suitable`
- Related: usability, functionality, functional-suitability, suitability
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/functional-appropriateness

### Functional completeness

Provide a set of functions that covers **all** the specified tasks and intended users’ objectives.

- Dimensions: `usable`, `reliable`, `suitable`
- Related: usability, functionality, functional-suitability, correctness
- Standards: iso25010, iso42010, iso42030, iso12207, sox
- Source: https://quality.arc42.org/qualities/functional-completeness

### Functional suitability

Provide functions that meet stated and implied needs of intended users when it is used under specified conditions.

- Dimensions: `usable`, `reliable`, `suitable`
- Related: usability, functionality, functional-completeness, suitability
- Standards: iso25010, iso25019
- Source: https://quality.arc42.org/qualities/functional-suitability

### Functionality

Functionality is the ability of the system to do the work for which it was intended.

- Dimensions: `usable`, `reliable`, `suitable`
- Related: usability, functional-suitability, functional-correctness, functional-completeness
- Standards: —
- Source: https://quality.arc42.org/qualities/functionality

### Governability

Governance of IT is the system by which the current and future use of IT is directed and controlled.

- Dimensions: `operable`, `secure`
- Related: compliance, accountability, auditability, controllability, operability, traceability, security
- Standards: iso38500, iso42001, iso42030, iso27001, nist80053
- Source: https://quality.arc42.org/qualities/governability

### Graceful degradation

The ability of maintaining functionality when portions of a system break down. A system that is designed to fail safe, or fail-secure, or fail gracefully, whether it functions at a reduced level or fails completely, does so in a way that protects people, property, or data from injury, damage, intrusion, or disclosure. A program might fail-safe by executing a graceful exit (as opposed to an uncontrolled crash) in order to prevent data corruption after experiencing an error.

- Dimensions: `reliable`, `usable`
- Related: robustness, reliability, usability, availability, recoverability, faultlessness, fault-tolerance
- Standards: —
- Source: https://quality.arc42.org/qualities/graceful-degradation

### Groundedness

Groundedness is the degree to which an AI-generated output, especially its factual claims, is supported by specified grounding sources such as retrieved documents, databases, tool results, or other authoritative context, and avoids unsupported fabrication or speculation.

- Dimensions: `reliable`, `suitable`
- Related: correctness, verifiability, traceability, reliability, explainability, model-transparency, data-quality
- Standards: nistairmf, iso24028
- Source: https://quality.arc42.org/qualities/groundedness

### Hazard warning

A hazard is a potential source of harm. Substances, events, or circumstances can constitute hazards when their nature would allow them, even just theoretically, to cause damage to health, life, property, or any other interest of value.

- Dimensions: `safe`, `reliable`
- Related: safety, robustness
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/hazard-warning

### Immunity

... what the product has to do to protect itself from infection by unauthorized or undesirable software programs, such as viruses, worms, malware, spyware and any other undesirable interference.

- Dimensions: `secure`, `reliable`
- Related: vulnerability, intrusion-detection, intrusion-prevention
- Standards: —
- Source: https://quality.arc42.org/qualities/immunity

### Inclusivity

Capability of a product to be utilised by people of various backgrounds

- Dimensions: `usable`
- Related: usability, functionality, attractiveness, user-error-protection, ease-of-use
- Standards: iso25010, wcag22, en301549
- Source: https://quality.arc42.org/qualities/inclusivity

### Independence

Functional independence is achieved by developing functions that perform only one kind of task and do not excessively interact with other modules. Independence is important because it makes implementation more accessible and faster. The independent modules are easier to maintain, test, and reduce error propagation and can be reused in other programs as well. Thus, functional independence is a good design feature which ensures software quality.

- Dimensions: `flexible`
- Related: maintainability, modularity, adaptability, configurability, changeability, agility, flexibility, autonomy
- Standards: —
- Source: https://quality.arc42.org/qualities/independence

### Injection Resistance

Injection resistance is the degree to which a system prevents untrusted input from being interpreted as executable instructions, control data, or persistent context that can alter behavior, decisions, privileges, outputs, or stored state.

- Dimensions: `secure`
- Related: security, resistance, integrity, intrusion-prevention, robustness
- Standards: owaspasvs, etsien304223
- Source: https://quality.arc42.org/qualities/injection-resistance

### Installability

Capability of a product to be effectively and efficiently installed successfully and/or uninstalled in a specified environment

- Dimensions: `operable`, `flexible`
- Related: maintainability, analysability, operability, deployability
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/installability

### Integrability

Integrability is the ease with which a software component or system can be integrated with other components or systems.

- Dimensions: `flexible`, `operable`
- Related: interoperability, modularity, composability, compatibility, integrity
- Standards: —
- Source: https://quality.arc42.org/qualities/integrability

### Integrity

Capability of a product to ensure that the state of its system and data are protected from unauthorized modification or deletion either by malicious action or computer error

- Dimensions: `secure`
- Related: confidentiality, security
- Standards: iso25010, iso27001, iso26262, misra-c, nist80053, pcidss, hl7, iso15408, cra, iec62443, iso25024, do178c, ieee2857, etsien304223, dicom, ihe
- Source: https://quality.arc42.org/qualities/integrity

### Interaction capability

capability of a product to be interacted with by specified users to exchange information between a user and a system via the user interface to complete the intended task Note 1: Interaction capability in the product quality model and its subcharacteristics focus on a set of attributes that enable interaction by users (or operators) to complete specific tasks in a variety of contexts of use. On the other hand, usability as defined in the quality-in-use model (ISO/IEC 25019) comprehensively focuses on outcomes of use to determine whether tasks are achieved by users with effectiveness, efficiency and satisfaction in a specific context of use. Note 2 to entry: Interaction capability is a prerequisite for usability..

- Dimensions: `usable`, `operable`
- Related: usability, functionality, inclusivity, attractiveness, operability, user-error-protection, user-engagement, ease-of-use
- Standards: iso25010, wcag22, en301549
- Source: https://quality.arc42.org/qualities/interaction-capability

### Interchangeability

Interchangeability is the ability to substitute one component, part, or element with another of the same type without requiring modifications to the system or loss of functionality.

- Dimensions: `flexible`, `operable`
- Related: replaceability, modularity, compatibility, portability, standard-compliance, configurability, composability, flexibility
- Standards: —
- Source: https://quality.arc42.org/qualities/interchangeability

### Internationalization

Developing information so that it is suitable for an international audience

- Dimensions: `flexible`, `usable`
- Aliases (aka): i18n
- Related: localizability, adaptability, modifiability, maintainability, i18n
- Standards: —
- Source: https://quality.arc42.org/qualities/internationalization

### Interoperability

Work (together) with other products or systems.

- Dimensions: `usable`, `operable`
- Related: co-existence, compatibility
- Standards: iso25010, hl7, cra, iso25024, iso42030, iso12207, ieee2857, wcag22, en301549, iso29100, dicom, ihe
- Source: https://quality.arc42.org/qualities/interoperability

### Intervenability

Intervene as an operator in an AI system’s functioning in a timely manner to prevent harm or hazard.

- Dimensions: `secure`
- Related: security
- Standards: iso25059
- Source: https://quality.arc42.org/qualities/intervenability

### Intrusion Detection

Intrusion detection is the process of monitoring the events occurring in a computer system or network and analyzing them for signs of possible incidents, which are violations or imminent threats of violation of computer security policies, acceptable use policies, or standard security practices.

- Dimensions: `secure`
- Related: intrusion-prevention
- Standards: owaspasvs
- Source: https://quality.arc42.org/qualities/intrusion-detection

### Intrusion Prevention

Intrusion prevention is the process of performing intrusion detection and attempting to stop detected possible incidents.

- Dimensions: `secure`
- Related: intrusion-detection
- Standards: owaspasvs
- Source: https://quality.arc42.org/qualities/intrusion-prevention

### Intuitiveness

The degree to which a system's interface, behavior, and information organization align with users' existing mental models and expectations, enabling immediate understanding and effective use without prior learning or training.

- Dimensions: `usable`
- Related: usability, learnability, user-experience, clarity, simplicity, self-descriptiveness, understandability
- Standards: —
- Source: https://quality.arc42.org/qualities/intuitiveness

### Jitter

In electronics and telecommunications, jitter is the deviation from true periodicity of a presumably periodic signal, often in relation to a reference clock signal.

- Dimensions: `efficient`, `reliable`
- Related: performance, latency, predictability
- Standards: —
- Source: https://quality.arc42.org/qualities/jitter

### Latency

Latency in general is a _time delay_ between the cause and the effect of some change in a system.

- Dimensions: `efficient`, `usable`, `operable`
- Related: performance, time-behaviour
- Standards: iso14756
- Source: https://quality.arc42.org/qualities/latency

### Lead time for changes

**Lead time for changes**: the length of time between when a code change is committed to the trunk branch and when it is in a deployable state. Not to be confused with [cycle time](/qualities/cycle-time), lead time for changes is the length of time between when a code change is committed to the trunk branch and when it is in a deployable state. quoted from [Atlassian](https://www.atlassian.com/devops/frameworks/devops-metrics)

- Dimensions: `operable`
- Related: controllability, operability, testability, deployability
- Standards: —
- Source: https://quality.arc42.org/qualities/lead-time-for-changes

### Learnability

Capability of a product to have specified users learn to use specified product functions within a specified amount of time.

- Dimensions: `usable`, `operable`
- Related: usability, user-error-protection, user-engagement, conciseness, understandability
- Standards: iso25010, ieee2857
- Source: https://quality.arc42.org/qualities/learnability

### Legal Requirements

Legal Requirement means any federal, state, local, municipal, foreign or other law, statute, constitution, principle of common law, resolution, ordinance, code, edict, decree, rule, regulation, ruling or requirement issued, enacted, adopted, promulgated, implemented or otherwise put into effect by or under the authority of any Governmental Body.

- Dimensions: `usable`, `operable`
- Related: accountability, adaptability, operational-constraint, correctness, compliance, auditability, privacy
- Standards: —
- Source: https://quality.arc42.org/qualities/legal-requirements

### Legibility

The fact of being easy to read, or the degree to which something is easy to read. The degree to which writing or text can be read easily because the letters are clear, the text is printed well, etc.

- Dimensions: `usable`
- Related: usability, understandability
- Standards: —
- Source: https://quality.arc42.org/qualities/legibility

### Localizability

In computing, internationalization and localization (American) or internationalisation and localisation (British English), often abbreviated i18n and L10n, are means of adapting computer software to different languages, regional peculiarities and technical requirements of a target locale.

- Dimensions: `flexible`, `usable`
- Related: adaptability, modifiability, maintainability, internationalization, i18n
- Standards: —
- Source: https://quality.arc42.org/qualities/localizability

### Longevity

This specifies the expected increases in size that the product must be able to handle. As a business grows (or is expected to grow), our software products must increase their capacities to cope with the new volumes.

- Dimensions: `reliable`, `flexible`, `maintainable`
- Related: reliability, adaptability, modifiability
- Standards: —
- Source: https://quality.arc42.org/qualities/longevity

### Loose Coupling

In computing and systems design, a loosely coupled system is one - in which components are weakly associated (have breakable relationships) with each other, and thus changes in one component least affect existence or performance of another component. - in which each of its components has, or makes use of, little or no knowledge of the definitions of other separate components. Subareas include the coupling of classes, interfaces, data, and services. Loose coupling is the opposite of tight coupling.

- Dimensions: `efficient`, `suitable`, `maintainable`
- Related: coherence, modularity, cohesion
- Standards: —
- Source: https://quality.arc42.org/qualities/loose-coupling

### Maintainability

Maintainability is concerned with modifications after the software baseline is established. - The goal of a maintenance activity is to correct defects, adapt to changing environments, or im- prove a system’s future maintainability or other quality attributes. - The description of a particular maintenance activity is in the eye of the beholder: A particular change (or type of change) can be labeled differently, depending on the maintainer’s intention. We measure maintainability as the amount of work required to modify, test, and maintain our software base in response to changes in environmental elements. This measure may depend on who is perform- ing the maintenance task and that individual’s level of skill or knowledge. from [Kazman et al., p.5](/references/#kazman-maintainability)

- Dimensions: `maintainable`
- Aliases (aka): Supportability
- Related: flexibility, adaptability, changeability, configurability, modularity
- Standards: iso25010, iso26262, misra-c, nist80053, iso5055, iec62304, iec61508, hl7, cra, isoiec22989, do178c, iso42010, iso42030, iso12207, iso29119, ieee2857, iso24028, etsien304223, dicom, ihe
- Source: https://quality.arc42.org/qualities/maintainability

### Mean time between failures

**Mean time between failures (MTBF)** is the predicted elapsed time between inherent failures of a mechanical or electronic system during normal system operation.

- Dimensions: `operable`
- Related: controllability, operability, testability, analysability, devops-metrics, mean-time-to-recovery
- Standards: —
- Source: https://quality.arc42.org/qualities/mean-time-between-failures

### Mean time to recovery

**Mean time to recovery (MTTR)** measures how long it takes to recover from a partial service interruption or total failure. quoted from [Atlassian](https://www.atlassian.com/devops/frameworks/devops-metrics)

- Dimensions: `operable`, `suitable`
- Related: controllability, operability, testability, analysability, deployability, devops-metrics
- Standards: —
- Source: https://quality.arc42.org/qualities/mean-time-to-recovery

### Memory usage

A special case of [resource utilization](/qualities/resource-utilization) and [resource-efficiency]

- Dimensions: `efficient`
- Related: efficiency, capacity, time-behaviour, resource-utilization
- Standards: —
- Source: https://quality.arc42.org/qualities/memory-usage

### Model Transparency

Model transparency is the degree to which relevant stakeholders can obtain accurate, current, and usable information about an AI or machine-learning model's identity, intended use, capabilities, limitations, architecture, provenance, training and evaluation data characteristics, evaluation results, version, license, and known risks.

- Dimensions: `reliable`, `suitable`
- Related: transparency, explainability, traceability, accountability, data-quality
- Standards: isoiec12792, isoiec22989, iso24028, nistairmf, iso42001
- Source: https://quality.arc42.org/qualities/model-transparency

### Modifiability

Capability of a system to be effectively and efficiently modified without introducing defects or degrading existing product quality from [ISO-25010:2023](/references/#iso-25010-2023)

- Dimensions: `maintainable`, `flexible`
- Related: flexibility, adaptability, changeability, configurability, themability
- Standards: iso25010, iso42010
- Source: https://quality.arc42.org/qualities/modifiability

### Modularity

Capability of a product to limit changes to one component from affecting other components. Modularity implies that the product will be composed of discrete modules or components with cohesive content and minimal coupling to other modules or components. from [ISO-25010:2023](/references/#iso-25010-2023)

- Dimensions: `maintainable`
- Related: flexibility, adaptability, changeability, configurability, maintainability, modifiability, composability
- Standards: iso25010, cra, do178c, iso42030, iso12207, ieee2857
- Source: https://quality.arc42.org/qualities/modularity

### Non-repudiation

Capability of a product to prove that actions or events have taken place, so that the events or actions cannot be repudiated later.

- Dimensions: `secure`
- Related: integrity, authenticity, security, accountability
- Standards: iso25010, iso27001, pcidss, owaspasvs, soc2
- Source: https://quality.arc42.org/qualities/non-repudiation

### Observability

Observability is a measure of how well internal states of a system can be inferred from knowledge of its external outputs.

- Dimensions: `operable`
- Related: analysability, testability, drift-detectability
- Standards: iso26262, cra, sox, ieee2857
- Source: https://quality.arc42.org/qualities/observability

### Operability

Capability of a product to have facilities and attributes that make it easy to operate and control. Operability is related to controllability, user error robustness and conformity with user expectations.

- Dimensions: `usable`, `operable`
- Related: usability, user-error-protection, controllability, robustness
- Standards: iso25010, nist80053, wcag22, en301549
- Source: https://quality.arc42.org/qualities/operability

### Operational and Environment Requirements

Requirements for Interfacing with Adjacent Systems, Productization Requirements, Release Requirements, Backwards Compatibility Requirements

- Dimensions: `operable`
- Related: expected-physical-environment, operational-constraint
- Standards: —
- Source: https://quality.arc42.org/qualities/operational-environment-requirements

### Operational constraint

Capability of a product to constrain its operation to within safe parameters or states when encountering operational hazard. Operational hazard is a hazardous situation, that is circumstance in which people, property or the environment are exposed to unacceptable risk during operation.

- Dimensions: `safe`, `reliable`
- Related: availability, robustness, flexibility, safety
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/operational-constraint

### Patient Safety

"The absence of preventable harm to a patient and reduction of risk of unnecessary harm associated with health care to an acceptable minimum." </div><br>

- Dimensions: `safe`, `reliable`, `secure`
- Related: safety, robustness, data-quality, completeness, accuracy, integrity
- Standards: —
- Source: https://quality.arc42.org/qualities/patient-safety

### Performance

Perform its functions within specified time and throughput parameters and be efficient in the use of resources under specified conditions

- Dimensions: `efficient`
- Aliases (aka): Performance Efficiency
- Related: efficiency, resource-efficiency, speed, timeliness, currentness
- Standards: iso14756, iso42030, iso12207, sox, dicom
- Source: https://quality.arc42.org/qualities/performance

### Personalization

"... the way in which the product can be altered or configured to take into account the user’s personal preferences or choice of language. The personalization requirements should cover issues such as the following: * Languages, spelling preferences, and language idioms * Currencies, including the symbols and decimal conventions * Personal configuration options

- Dimensions: `flexible`
- Related: customizability
- Standards: —
- Source: https://quality.arc42.org/qualities/personalization

### Portability

A computer program is said to be portable if there is low effort required to make it run on different environments, operating systems, infrastructures or platforms. Inspired by [Wikipedia](https://en.wikipedia.org/wiki/Software_portability)

- Dimensions: `flexible`, `operable`
- Related: compatibility, flexibility, installability, interoperability, maintainability, configurability, replaceability
- Standards: iso26262, misra-c, hl7, iso25024, dicom, ihe
- Source: https://quality.arc42.org/qualities/portability

### Precision

Refers to how closely individual measurements agree with each other.

- Dimensions: `reliable`, `usable`
- Aliases (aka): Preciseness
- Related: correctness, accuracy, preciseness
- Standards: iso25024
- Source: https://quality.arc42.org/qualities/precision

### Predictability

Predictability is the degree to which a correct prediction or forecast of a system's state can be made, either qualitatively or quantitatively.

- Dimensions: `reliable`
- Related: reliability, correctness
- Standards: misra-c
- Source: https://quality.arc42.org/qualities/predictability

### Privacy

Broadly speaking, privacy is the right to be let alone, or freedom from interference or intrusion. Information privacy is the right to have some control over how your personal information is collected and used.

- Dimensions: `secure`
- Related: security, confidentiality
- Standards: nist80053, aiuc1, isoiec22989, gdpr, ieee2857, iso24028, soc2, nistairmf, nistpf
- Source: https://quality.arc42.org/qualities/privacy

### Profitability

In economics, profit is the difference between revenue that an economic entity has received from its outputs and total costs of its inputs.

- Dimensions: `efficient`
- Related: time-to-market, cost, affordability
- Standards: —
- Source: https://quality.arc42.org/qualities/profitability

### Provability

The ability to demonstrate through rigorous, often mathematical, means that a piece of software meets specified quality requirements.

- Dimensions: `reliable`, `safe`
- Related: explainability, verifiability, correctness
- Standards: —
- Source: https://quality.arc42.org/qualities/provability

### Readability

The fact of being easy to read, or the degree to which something is easy to read.

- Dimensions: `usable`
- Related: usability, understandability, legibility, code-readability
- Standards: —
- Source: https://quality.arc42.org/qualities/readability

### Recoverability

capability of a product in the event of an interruption or a failure to recover the data directly affected and re-establish the desired state of the system.

- Dimensions: `reliable`, `usable`
- Aliases (aka): Recovery Time
- Related: robustness, reliability, usability, availability, faultlessness, fault-tolerance, autonomy
- Standards: iso25010, cra, iso25024, sox, etsien304223
- Source: https://quality.arc42.org/qualities/recoverability

### Redundancy

The term can be interpreted in two different directions:

- Dimensions: `reliable`, `operable`
- Related: fault-tolerance, availability, reliability, robustness, resilience, recoverability
- Standards: —
- Source: https://quality.arc42.org/qualities/redundancy

### Releasability

...the intended release cycle for the product and the form that the release shall take.

- Dimensions: `operable`, `efficient`
- Related: operability, deployability, deployment-frequency
- Standards: —
- Source: https://quality.arc42.org/qualities/releasability

### Reliability

Capability of a product to perform specified functions under specified conditions for a specified period of time without interruptions and failures.

- Dimensions: `reliable`
- Related: determinism, availability, robustness, fault-tolerance, dependability, resilience
- Standards: iso25010, iso27001, iso26262, misra-c, nist80053, iso5055, iso14756, aiuc1, iec62304, iec61508, hl7, iso15408, cra, isoiec22989, iso25024, do178c, iso42030, iso12207, iso29119, sox, nistairmf, iso24028, dicom, ihe
- Source: https://quality.arc42.org/qualities/reliability

### Replaceability

Capability of a product to replace another specified product for the same purpose in the same environment

- Dimensions: `operable`, `flexible`
- Related: installability, analysability, operability, deployability, interchangeability
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/replaceability

### Reproducibility

Reproducibility, closely related to replicability and repeatability, is a major principle [where] any results should be documented by making all data and code available in such a way that the computations can be executed again with identical results

- Dimensions: `usable`
- Aliases (aka): Repeatability
- Related: determinism, consistency, understandability
- Standards: do178c, iso29119
- Source: https://quality.arc42.org/qualities/reproducibility

### Resilience

Resilience is the ability to "provide and maintain an acceptable level of service in the face of faults and challenges to normal operation."

- Dimensions: `reliable`, `secure`
- Related: availability, autonomy
- Standards: cra, isoiec22989, iso42030, etsien304223, nistairmf
- Source: https://quality.arc42.org/qualities/resilience

### Resistance

Capability of a product to sustain operations while under attack from a malicious actor. A malicious attack can include a denial of service attack, a ransomware attack, or other malicious actions. The following approaches can be applied to improve resistance: * to continuously protect itself from well-known attacks by removing potential flaws or weaknesses of the product with the use of integrated special security product to protect against DoS attacks, ransomware, and so on, which is a reasonable method;<br> * to minimize vulnerability of a product by secure software coding and/or to incorporate security enhancement functions or mechanisms;<br> * to maintain product updated during life time for security reason.

- Dimensions: `secure`
- Related: integrity, security, injection-resistance, dependability, fault-tolerance, recoverability
- Standards: iso25010, owaspasvs
- Source: https://quality.arc42.org/qualities/resistance

### Resource efficiency

Resource efficiency is the maximising of the supply of money, materials, staff, and other assets that can be drawn on by a person or organization in order to function effectively, with minimum wasted (natural) resource expenses.

- Dimensions: `efficient`
- Related: efficiency, resource-utilization, performance
- Standards: —
- Source: https://quality.arc42.org/qualities/resource-efficiency

### Resource utilization

Use no more than the specified amount of resources to perform its function under specified conditions.

- Dimensions: `efficient`
- Related: efficiency, resource-efficiency, speed, performance, time-behaviour, memory-usage
- Standards: iso25010, iso14756
- Source: https://quality.arc42.org/qualities/resource-utilization

### Response Time

The time period between a terminal operator’s completion of an inquiry and the receipt of a response. Response time includes the time taken to transmit the inquiry, process it by the computer, and transmit the response back to the terminal. Response time is frequently used as a measure of the performance of an interactive system.

- Dimensions: `efficient`
- Related: performance, speed, time-behaviour
- Standards: —
- Source: https://quality.arc42.org/qualities/response-time

### Responsiveness

Responsiveness as a concept of computer science refers to the specific ability of a system or functional unit to complete assigned tasks within a given time.

- Dimensions: `usable`, `efficient`
- Related: response-time, usability, user-experience
- Standards: —
- Source: https://quality.arc42.org/qualities/responsiveness

### Reusability

Capability of a product to be used as assets in more than one system, or in building other assets. from [ISO-25010:2023](/references/#iso-25010-2023)

- Dimensions: `flexible`, `maintainable`
- Related: flexibility, adaptability, changeability, configurability, maintainability, modifiability
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/reusability

### Risk identification

Capability of a product to identify a course of events or operations that can expose life, property or environment to unacceptable risk

- Dimensions: `safe`, `reliable`
- Related: safety, analysability
- Standards: iso25010, cra
- Source: https://quality.arc42.org/qualities/risk-identification

### Robustness

Degree to which an AI system can maintain its level of functional correctness under any circumstances.

- Dimensions: `reliable`
- Related: resilience, dependability, reliability
- Standards: iso26262, misra-c, isoiec22989, iec62443, do178c, wcag22, en301549, iso24028, etsien304223, iso25059
- Source: https://quality.arc42.org/qualities/robustness

### Safe integration

Capability of a product to maintain safety during and after integration with one or more components.

- Dimensions: `safe`, `reliable`
- Related: safety, robustness
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/safe-integration

### Safety

Freedom from unacceptable risks.

- Dimensions: `safe`, `reliable`, `secure`
- Related: availability, robustness, certifiability
- Standards: iso25010, iso26262, misra-c, aiuc1, iec62304, iec61508, isoiec22989, do178c, iso24028, iso25019, nistairmf
- Source: https://quality.arc42.org/qualities/safety

### Scalability

Scalability is the property of a system to handle a growing amount of work by adding resources to the system. In computing, scalability is a characteristic of computers, networks, algorithms, networking protocols, programs and applications.

- Dimensions: `flexible`
- Related: adaptability, elasticity, performance
- Standards: iso25010, iso42030, iso12207, sox, ieee2857, hl7, dicom
- Source: https://quality.arc42.org/qualities/scalability

### Securability

Ability of a system to provide different levels of secure access

- Dimensions: `secure`
- Related: security
- Standards: cra
- Source: https://quality.arc42.org/qualities/securability

### Security

Protect system against malicious attacks, so that the system continues to function correctly. Security requires at least integrity, availability and non-repudiation.

- Dimensions: `secure`, `reliable`
- Aliases (aka): Information Security
- Related: integrity, availability, non-repudiation, confidentiality, accountability, authenticity, resistance, injection-resistance
- Standards: iso25010, iso27001, iso26262, misra-c, nist80053, iso5055, pcidss, iso42001, aiuc1, iec62304, hl7, iso15408, cra, isoiec22989, iec62443, do178c, gdpr, iso29100, iso42030, iso12207, sox, ieee2857, iso24028, etsien304223, owaspasvs, nistairmf, dicom, ihe
- Source: https://quality.arc42.org/qualities/security

### Self-containedness

A system is a self-contained system (SCS) if it has the following characteristics:

- Dimensions: `flexible`
- Related: flexibility, adaptability, changeability, configurability, maintainability, modifiability, modularity, autonomy
- Standards: —
- Source: https://quality.arc42.org/qualities/self-containedness

### Self-descriptiveness

Capability of a product to present appropriate information, where needed by the user, to make its capabilities and use immediately obvious to the user without excessive interactions with a product or other resources.

- Dimensions: `usable`
- Related: usability, user-assistance, user-experience, learnability, conciseness
- Standards: iso25010, iso42010
- Source: https://quality.arc42.org/qualities/self-descriptiveness

### Shutdown Time

Coloquially, the duration required for a system, application, service or hardware to get from fully operational and ready state to a halt- or off-state.

- Dimensions: `efficient`
- Related: startup-time, time-behaviour
- Standards: —
- Source: https://quality.arc42.org/qualities/shutdown-time

### Simplicity

For software, “simple” means easy to read, understand, and correctly modify. Complexity is stupid. Simplicity is smart.

- Dimensions: `efficient`, `usable`
- Related: efficiency, modularity
- Standards: —
- Source: https://quality.arc42.org/qualities/simplicity

### Speed

Rate of motion or velocity.

- Dimensions: `efficient`
- Related: efficiency, performance, time-behaviour
- Standards: —
- Source: https://quality.arc42.org/qualities/speed

### Stability

Software stability means the resistance to the amplification of changes in software.

- Dimensions: `reliable`
- Related: reliability, adaptability, changeability
- Standards: —
- Source: https://quality.arc42.org/qualities/stability

### Startup Time

Coloquially, the duration required for a system, application, or service to become fully operational and ready to use (by either human users or external systems) from the moment it is initiated.

- Dimensions: `efficient`
- Related: efficiency, performance, time-behaviour
- Standards: —
- Source: https://quality.arc42.org/qualities/startup-time

### Suitability

Provide functions that meet stated and implied needs of intended users when it is used under specified conditions.

- Dimensions: `usable`, `reliable`, `suitable`
- Related: usability, functionality, functional-completeness
- Standards: iso25019
- Source: https://quality.arc42.org/qualities/suitability

### Sustainability

State in which the ecosystem and its functions are maintained for the present and future generation(s).

- Dimensions: `efficient`, `reliable`
- Related: energy-efficiency, carbon-emission-efficiency
- Standards: iso38500, iso42030, iso25059
- Source: https://quality.arc42.org/qualities/sustainability

### Test Coverage

The term test coverage used in the context of programming / software engineering, refers to measuring how much a software program has been exercised by tests. Coverage is a means of determining the rigour with which the question underlying the test has been answered. There are many kinds of test coverage: - requirements coverage, - code coverage, - feature coverage, - scenario coverage, - screen item coverage, - model coverage.

- Dimensions: `suitable`, `maintainable`
- Related: maintainability, flexibility, modifiability, analysability, testability
- Standards: —
- Source: https://quality.arc42.org/qualities/test-coverage

### Testability

Capability of a product to enable an objective and feasible test to be designed and performed to determine whether a requirement is met.

- Dimensions: `suitable`, `maintainable`
- Aliases (aka): Unit Testability
- Related: determinism, maintainability, flexibility, modifiability, analysability
- Standards: iso25010, iso26262, misra-c, iec61508, iso15408, do178c, iso24028, iso29119, ihe
- Source: https://quality.arc42.org/qualities/testability

### Themability

Themability allows for stylistic changes to a design system, often through design tokens or stylesheet variables. It enables a single codebase to support multiple brands or variations, where components share the same structure but can have different visual styles. from [Brad Frost: The Many Faces of Themeable Design Systems](/references/#brad-frost-theming)

- Dimensions: `flexible`, `maintainable`
- Related: modifiability, configurability, customizability, personalization, user-interface-aesthetics, accessibility
- Standards: —
- Source: https://quality.arc42.org/qualities/themability

### Throughput

Network throughput (or just throughput, when in context) refers to the rate of message delivery over a communication channel, such as Ethernet or packet radio, in a communication network. Throughput is usually measured in bits per second (bit/s or bps), and sometimes in data packets per second (p/s or pps) or data packets per time slot.

- Dimensions: `efficient`
- Related: performance, efficiency, speed
- Standards: iso14756
- Source: https://quality.arc42.org/qualities/throughput

### Time behaviour

Response and processing times and throughput rates of a product or system, when performing its functions, meet requirements.

- Dimensions: `efficient`
- Related: determinism, efficiency, resource-efficiency, speed, performance
- Standards: iso25010, iso14756
- Source: https://quality.arc42.org/qualities/time-behaviour

### Time to Market

**Time to market (TTM)** is the length of time it takes from a product being conceived until it is available for sale.

- Dimensions: `efficient`
- Aliases (aka): Speed to Market
- Related: flexibility, efficiency, deployment-frequency, extensibility, lead-time-for-changes, cycle-time
- Standards: iso42030
- Source: https://quality.arc42.org/qualities/time-to-market

### Timeliness

The degree to which data is up-to-date and available when needed for decision-making or processing.

- Dimensions: `reliable`, `suitable`
- Aliases (aka): Currentness
- Related: data-quality, accuracy, completeness, consistency, credibility
- Standards: iso25024
- Source: https://quality.arc42.org/qualities/timeliness

### Traceability

**Traceability** is the ability to recover all of the artifacts that led to an element having a problem. That includes all the code and dependencies that are included in that element. It also includes the test cases that were run on that element and the tools that were used to produce the element. Errors in tools used in the deployment pipeline can cause problems in production.

- Dimensions: `reliable`, `operable`
- Related: devops-metrics, operability, testability, certifiability, accountability
- Standards: iso26262, iec62304, hl7, iso15408, cra, isoiec22989, iso25024, do178c, iso42010, gdpr, iso42030, iso12207, sox, etsien304223, iso8000, ieee7000, dicom, ihe
- Source: https://quality.arc42.org/qualities/traceability

### Transactionality

A transaction is a sequence of operations performed as a single, logical unit of work. For a transaction to be considered complete, all operations within it must succeed. If any single operation fails, the entire transaction fails, and the system is rolled back to the state it was in before the transaction began. Source: [Jim Gray, "The Transaction Concept: Virtues and Limitations", 1981](https://www.microsoft.com/en-us/research/publication/the-transaction-concept-virtues-and-limitations/)

- Dimensions: `reliable`
- Related: determinism, atomicity, consistency, durability, data-integrity, robustness
- Standards: —
- Source: https://quality.arc42.org/qualities/transactionality

### Transparency

Communicate appropriate information about the AI system to relevant stakeholders. Appropriate information for AI system transparency can include aspects such as features, components, procedures, measures, design goals, design choices and assumptions.

- Dimensions: `reliable`
- Related: clarity, understandability, usability, model-transparency, interaction-capability
- Standards: iso38500, iso42001, cra, isoiec22989, isoiec12792, iso42010, gdpr, iso42030, sox, ieee2857, iso24028, etsien304223, nistairmf, ieee7000, iso25059
- Source: https://quality.arc42.org/qualities/transparency

### Understandability

Understandability is the concept that a system should be presented so that (somebody) can easily comprehend it. The more understandable a system is, the easier it will be for engineers to change it in a predictable and safe manner.

- Dimensions: `usable`, `operable`
- Aliases (aka): Comprehensibility
- Related: usability, self-descriptiveness, user-assistance, user-experience, learnability, conciseness
- Standards: misra-c, iso26514, iso25024, iso42010, iso42030, wcag22, en301549
- Source: https://quality.arc42.org/qualities/understandability

### Updateability

Updateability refers to the capability of a software system to efficiently receive, install, and integrate updates, patches, security fixes, and minor enhancements while maintaining system integrity and minimizing service disruption.

- Dimensions: `operable`, `maintainable`
- Related: maintainability, upgradeability, installability, modifiability, flexibility, portability, configurability, securability
- Standards: cra, iso25010, iec62304, iec61508
- Source: https://quality.arc42.org/qualities/updateability

### Upgradeability

Upgrading is the process of replacing a product with a newer version of the same product. In computing and consumer electronics an upgrade is generally a replacement of hardware, software or firmware with a newer or better version, in order to bring the system up to date or to improve its characteristics.

- Dimensions: `operable`, `maintainable`
- Related: flexibility, operability, predictability, releasability, installability
- Standards: cra
- Source: https://quality.arc42.org/qualities/upgradeability

### Usability

Capability of a product to be used by specified users to exchange information between a user and an interactive system via the user interface to complete the intended task.

- Dimensions: `usable`, `operable`
- Related: functionality, attractiveness, operability, user-error-protection, user-engagement, ease-of-use, inclusivity
- Standards: iec62304, isoiec22989, iso26514, iso12207, wcag22, en301549, iso25019
- Source: https://quality.arc42.org/qualities/usability

### User assistance

Capability of a product to be used by people with the widest range of characteristics and capabilities to achieve specified goals in a specified context of use.

- Dimensions: `usable`
- Related: usability, user-error-protection, user-engagement
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/user-assistance

### User engagement

Capability of a product to present functions and information in an inviting and motivating manner, supporting continued interaction. This refers to properties of the product that increase the pleasure and satisfaction of the user, such as harmonious colour, intuitive user interface or friendly voice guidance.

- Dimensions: `usable`
- Related: usability
- Standards: iso25010
- Source: https://quality.arc42.org/qualities/user-engagement

### User error protection

Capability of a product to protect users against making operation errors

- Dimensions: `usable`, `operable`
- Related: usability, operability, robustness
- Standards: iso25010, wcag22, en301549
- Source: https://quality.arc42.org/qualities/user-error-protection

### User experience

The user experience (UX) is how a user interacts with and experiences a product, system or service. It includes a person's perceptions of utility, ease of use, and efficiency. Improving user experience is important to most companies, designers, and creators when creating and refining products because negative user experience can diminish the use of the product and, therefore, any desired positive impacts; conversely, User experience includes all the aspects of the interaction between the end-user with the company, its services, and its products.

- Dimensions: `usable`
- Related: usability, user-interface-aesthetics, user-error-protection, accessibility
- Standards: iso25019
- Source: https://quality.arc42.org/qualities/user-experience

### User interface aesthetics

Capability of a user interface to enable pleasing and satisfying interaction for the user

- Dimensions: `usable`
- Related: usability
- Standards: —
- Source: https://quality.arc42.org/qualities/user-interface-aesthetics

### Verifiability

System Verification is a set of actions used to check the correctness of any element, such as a system element, a system, a document, a service, a task, a requirement, etc. These types of actions are planned and carried out throughout the life cycle of the system. from [SWEBOKwiki](https://sebokwiki.org/wiki/System_Verification)

- Dimensions: `reliable`, `maintainable`
- Related: testability, analysability, certifiability
- Standards: do178c, iso42010, iso29119, ihe
- Source: https://quality.arc42.org/qualities/verifiability

### Versatility

able to change easily or to be used for different purposes

- Dimensions: `flexible`, `suitable`
- Related: flexibility, adaptability
- Standards: —
- Source: https://quality.arc42.org/qualities/versatility

### Vulnerability

A software vulnerability is a defect in software that could allow an attacker to gain control of a system. These defects can be because of the way the software is designed, or because of a flaw in the way that it’s coded.

- Dimensions: `secure`, `reliable`
- Related: reliability, availability, fault-tolerance, immunity
- Standards: owaspasvs
- Source: https://quality.arc42.org/qualities/vulnerability

## Aliases

These names redirect to a canonical characteristic above.

| Alias | Redirects to |
|---|---|
| Autonomicity | `autonomy` (https://quality.arc42.org/qualities/autonomy) |
| Budget Constraint | `affordability` (https://quality.arc42.org/qualities/affordability) |
| Carbon Efficiency | `carbon-emission-efficiency` (https://quality.arc42.org/qualities/carbon-emission-efficiency) |
| Comprehensibility | `understandability` (https://quality.arc42.org/qualities/understandability) |
| Currentness | `timeliness` (https://quality.arc42.org/qualities/timeliness) |
| DORA | `devops-metrics` (https://quality.arc42.org/qualities/devops-metrics) |
| Efficacy | `effectiveness` (https://quality.arc42.org/qualities/effectiveness) |
| Environmental Sustainability | `sustainability` (https://quality.arc42.org/qualities/sustainability) |
| Eventual Consistency | `consistency` (https://quality.arc42.org/qualities/consistency) |
| Exactness | `accuracy` (https://quality.arc42.org/qualities/accuracy) |
| Functional Correctness | `correctness` (https://quality.arc42.org/qualities/correctness) |
| High Availability | `availability` (https://quality.arc42.org/qualities/availability) |
| Human Controllability | `controllability` (https://quality.arc42.org/qualities/controllability) |
| Human Oversight | `controllability` (https://quality.arc42.org/qualities/controllability) |
| i18n | `internationalization` (https://quality.arc42.org/qualities/internationalization) |
| Information Security | `security` (https://quality.arc42.org/qualities/security) |
| Inspectability | `analysability` (https://quality.arc42.org/qualities/analysability) |
| Legacy Support | `backward-compatibility` (https://quality.arc42.org/qualities/backward-compatibility) |
| Mutability | `changeability` (https://quality.arc42.org/qualities/changeability) |
| Performance Efficiency | `performance` (https://quality.arc42.org/qualities/performance) |
| Policy Enforcement | `governability` (https://quality.arc42.org/qualities/governability) |
| Preciseness | `precision` (https://quality.arc42.org/qualities/precision) |
| Recovery Time | `recoverability` (https://quality.arc42.org/qualities/recoverability) |
| Repeatability | `reproducibility` (https://quality.arc42.org/qualities/reproducibility) |
| Self-Configuring | `autonomy` (https://quality.arc42.org/qualities/autonomy) |
| Self-Healing | `autonomy` (https://quality.arc42.org/qualities/autonomy) |
| Self-Optimizing | `autonomy` (https://quality.arc42.org/qualities/autonomy) |
| Self-Protecting | `autonomy` (https://quality.arc42.org/qualities/autonomy) |
| Speed to Market | `time-to-market` (https://quality.arc42.org/qualities/time-to-market) |
| Standard Compliance | `compliance` (https://quality.arc42.org/qualities/compliance) |
| Supportability | `maintainability` (https://quality.arc42.org/qualities/maintainability) |
| Tailorability | `configurability` (https://quality.arc42.org/qualities/configurability) |
| Truthfulness | `correctness` (https://quality.arc42.org/qualities/correctness) |
| Unit Testability | `testability` (https://quality.arc42.org/qualities/testability) |
| Uptime | `availability` (https://quality.arc42.org/qualities/availability) |
| User Controllability | `controllability` (https://quality.arc42.org/qualities/controllability) |
| Value for Money | `affordability` (https://quality.arc42.org/qualities/affordability) |
