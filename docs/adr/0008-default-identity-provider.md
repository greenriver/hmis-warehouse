<!-- Based off Green River's work on Open Path https://github.com/greenriver/hmis-warehouse/blob/stable/docs/adr/README.md -->
# ADR 0008 [Default Identity Provider]

## Status

- Current Status: Proposed
- Date of last update: 2026-02-28
- Decision-makers: OP engineering team, DevOps team

## Context

After an initial pilot phase on other projects with Zitadel, it has been determined that:
1. The Zitadel roadmap and proposed release cycle is too agressive for our purposes
2. Keycloak is not as difficult to host and upgrade as previously thought
3. Keycloak has a more reasonable deprecation and support cycle

This ADR details the change from Zitadel as the default external IdP to Keycloak for all Open Path applications.
It is recognized that some Open Path installations will require an additional external IdP, Oauth2-proxy and Dex will continue to proxy to additonal IdP as necessary.

## Decision Criteria

This solution must:
- Be maintainable
- Enable centralized admin access across installations
- Maintain or improve security posture
- Not add significant operational cost

## Decision

4. We will install and host a copy of [Keycloak](https://www.keycloak.org) as an identity provider for both development and deployed installations.

## Consequences
### Benefits

- **Unified authentication experience** across all Open Path applications
- **Hardens security posture** uses more robust solution
- **Reduced maintenance burden and technical debt** no longer need to support and maintain auth libraries and configuration
- **Centralized admin access** across customer installations through shared admin IdP instance

### Challenges

- **Migration complexity** from existing Devise-based authentication
  - May require significant code changes
  - User credentials will need to be migrated to Keycloak
  - Keycloak no longer supports bcrypt passwords out of the box and requires a plugin
- **Learning curve** for development team to understand new IdP

Using Keycloak provides a full-featured IdP with a battle tested API and existing implementations we can reference if we decide to build user management directly into the application.  Additionally, Keycloak has been in use for years at Green River; it is a known entity.

## Alternatives Considered

* Okta - Okta is the gold-standard of hosted IdP, however it is also extremely expensive with a per-user per-month cost, if price were no object, we would probably go with Okta.
* Zitadel - Zitadel was piloted on other projects and is a serviceable open source solution.  The release cycle and proposed roadmap was deemed too agressive for our use.
* Cognito - Much cheaper than Okta, and hosted, but does not follow standards and would require a significant build.
