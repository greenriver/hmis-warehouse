<!-- Based off Green River's work on Open Path https://github.com/greenriver/hmis-warehouse/blob/stable/docs/adr/README.md -->
# ADR 0008 [Keycloak, Dex, and OAuth2-Proxy as a Single Authentication Mechanism]

## Status

- Current Status: Draft
- Date of last update: 2026-06-04
- Decision-makers: OP engineering team, DevOps team
- Supersedes: [ADR 0004](0004-identity-management.md)
- Revision note: Default IdP changed from Zitadel to Keycloak; see Alternatives Considered. Original Zitadel decision was never deployed.

## Context

As Open Path continues to expand the number of applications that comprise the software it is becoming a burden to maintain so many disparate mechanisms for accounts management within one platform.  Open Path currently employs three different mechanisms for accounts:
  1. Separate accounts (CAS & Warehouse)
  2. Re-used accounts (HMIS & Warehouse)
  3. Shared accounts via SSO (Analytics & Warehouse).

This ADR outlines an external IdP, IdP Proxy, and OAuth2 proxy that can be placed in front of all Open Path applications, streamlining the authentication workflows bringing consistency to the authentication process across the platform.
It is recognized that some Open Path installations will require an additional external IdP, and the proposed structure should allow that without significant development.

## Decision Criteria

This solution must:
- Provide a single sign-on experience
- Support external IdPs for some installations
- Enable centralized admin access across installations
- Maintain or improve security posture
- Not add significant operational cost

## Decision

1. We will standardize on [OAuth2 authentication with a JWT](https://docs.secureauth.com/ciam/en/using-jwt-profile-for-oauth-2-0-authorization-flows.html) at the application level as it is an industry standard with wide library support
2. We will install [OAuth2-Proxy](https://oauth2-proxy.github.io/oauth2-proxy/) in front of all Open Path applications to ensure protected paths are enforced
3. We will add [Dex](http://dexidp.io) as an IdP proxy upstream of OAuth2-Proxy
4. We will install and host [Keycloak](https://www.keycloak.org) as the default identity provider for production and staging installations.

## Consequences
### Benefits

- **Unified authentication experience** across all Open Path applications
- **Hardens security posture** uses more robust solution
- **Reduced maintenance burden and technical debt** no longer need to support and maintain auth libraries and configuration
- **Centralized admin access** across customer installations through shared admin IdP instance
- **Lower adoption risk** — newer Keycloak versions are already proven on other Green River applications, reducing unknown-technology risk

### Challenges

- **Migration complexity** from existing Devise-based authentication
  - May require significant code changes
  - User credentials will need to be migrated to Keycloak
- **Configuration and operational familiarity** with Keycloak's realm/client model — the team has exposure from other GR apps but has not yet operated it for Open Path
- **Potential user experience impact** during transition

Keycloak provides a full-featured IdP with an Admin REST API if we decide to build user management directly into the application. Keycloak natively supports TOTP (authenticator apps) and WebAuthn (passkeys and security keys) for MFA. SMS and email OTP are not built in and would require a custom authenticator SPI or third-party extension — if those channels are needed, that is additional build work compared to IdPs that include them natively.

Keycloak uses **realms** as its primary isolation boundary. Newer Keycloak versions also add an **Organizations** feature for multi-org management within a single realm. This model is already proven on other Green River applications.

Using Keycloak will require (allow) us to remove much or all of the Devise code. This may cause a significant amount of code churn, but should not be particularly difficult. Moving the security risk from Devise and Devise-related gems to Keycloak should be a security win overall but will impact authentication workflows and may require trainings or additional documentation.

Migrating from in-app authentication to Keycloak can be accomplished via realm/user import, the Admin REST API, or a User Storage SPI to federate the existing database during cutover.

Using JWT to determine the current user will also require effort, but should result in significantly less application code.

We have customers who already use external IdPs through the OmniAuth gem. The login workflow would change minimally, and we may need to work with those customers to reconfigure endpoints in their IdPs, but the flexibility of Dex should make this relatively painless.


## Alternatives Considered

* **Zitadel** — Originally selected (this ADR's prior revision) and offered a full-featured IdP with strong native MFA including SMS and email OTP. Rejected before deployment due to reliability concerns: rapid codebase churn and an aggressive release cycle with no long-term-supported versions, making it unsuitable for the support lifecycle Open Path installations require.
* **Okta** — Okta is the gold-standard of hosted IdP, however it is also extremely expensive with a per-user per-month cost. If price were no object, we would probably go with Okta.
* **Cognito** — Much cheaper than Okta, and hosted, but does not follow standards and would require a significant build.

## Additional Info

Keycloak [documentation](https://www.keycloak.org/documentation)
Dex [documentation](https://dexidp.io/docs/)
OAuth2-Proxy [documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
