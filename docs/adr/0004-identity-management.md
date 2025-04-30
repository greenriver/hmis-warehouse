<!-- Based off Green River's work on Open Path https://github.com/greenriver/hmis-warehouse/blob/stable/docs/adr/README.md -->
# ADR 0004 [Zitadel, Dex, and Oauth2-Proxy as a Single Authentication Mechanism]

## Status

- Current Status: Proposed
- Date of last update: 2025-04-29
- Decision-makers: OP engineering team, DevOps team

## Context

As Open Path continues to expand the number of applications that comprise the software it is becoming a burden to maintain so many disparate mechanisms for accounts management within one platform.  Open Path currently employs three different mechanisms for accounts:
  1. Separate accounts (CAS & Warehouse)
  2. Re-used accounts (HMIS & Warehouse)
  3. Shared accounts via SSO (Analytics & Warehouse).

This ADR outlines an external IdP, IdP Proxy, and Oauth2 proxy that can be placed in front of all Open Path applications, streamlining the authentication workflows bringing consistency to the authentication process across the platform.
It is recognized that some Open Path installations will require an additional external IdP, and the proposed structure should allow that without significant development.
## Decision Criteria

This solution must:
- Provide a single sign-on experience
- Support external IdPs for some installations
- Enable centralized admin access across installations
- Maintain or improve security posture
- Not add significant operational cost
## Decision

1. We will standardize on [Oauth2 authentication with a JWT](https://docs.secureauth.com/ciam/en/using-jwt-profile-for-oauth-2-0-authorization-flows.html) at the application level
2. We will install [Oauth2-Proxy](https://oauth2-proxy.github.io/oauth2-proxy/) in front of all Open Path applications to ensure protected paths are enforced
3. We will add [Dex](http://dexidp.io) as an IdP proxy upstream of Oauth2-Proxy
4. We will install and host a copy of [Zitadel](https://zitadel.com) as an identity provider for both development and deployed installations.

## Consequences
### Benefits

- **Unified authentication experience** across all Open Path applications
- **Hardens security posture** uses more robust solution
- **Reduced maintenance burden and technical debt** no longer need to support and maintain auth libraries and configuration
- **Centralized admin access** across customer installations through shared admin IdP instance

### Challenges

- **Risk of unknown technology** our team does not have experience with Zitadel
- **Migration complexity** from existing Devise-based authentication
  - May require significant code changes
  - User credentials will need to be migrated to Zitadel
- **Learning curve** for development team to understand new authentication flow
- **Potential user experience impact** during transition

Using Zitadel provides a full-featured IdP with a straight-forward API if we decide to build user management directly into the application.  [Zitadel provides many mechanisms of MFA as documented here](https://zitadel.com/docs/concepts/features/selfservice#mfa--fido-passkeys) and specifically includes Authenticator app, email, and SMS OTP options as well as passkeys and security device support.

Zitadel is untested at Green River though, it isn't unknown.   The architecture [appears to support everything we need](https://zitadel.com/docs/concepts/structure/instance) including hosting multiple "instances" within a single installation, and multiple organizations and projects within an instance.  This should allow us to grant someone access to manage their own set of users within the context of their organization.

Using Zitadel will require (allow?) us to remove much (or all) of the devise code.  This may cause a significant amount of code churn, but should not be particularly difficult.  Moving the security risk from devise and devise-related gems to Zitadel should be a security win overall but will impact authentication workflows and may require trainings or additional documentation.

Migrating from in-app authentication to [Zitatdel may be script-able](https://zitadel.com/docs/guides/migrate/introduction) but this is currently untested at Green River.  Best case scenario, we could migrate all data seamlessly en masse and logins would simply shift.  Worst-case scenario, we would need to write post-login workflows to explain and facilitate the change-over on a per-account basis.

Using JWT to determine the current user will also require effort, but should result in significantly less application code.  Of note, we would need to re-write the masquerade/become/impersonate feature.

We have customers who already use external IdPs through the OmniAuth gem.  The login workflow would change minimally, and we may need to work with those customers to reconfigure endpoints in their IdPs, but the flexibility of Dex should make this relatively painless.


## Alternatives Considered

* Okta - Okta is the gold-standard of hosted IdP, however it is also extremely expensive with a per-user per-month cost, if price were no object, we would probably go with Okta.
* Keycloak - Keycloak is currently in use on other Green River projects, it has been deemed sufficient, but the version currently in-use doesn't support our needs and the newer versions are untested at Green River.  Additionally, it was suggested that it is "heavier" than Zitadel.
* Cognito - Much cheaper than Okta, and hosted, but does not follow standards and would require a significant build.

## Additional Info

Zidtadel [documentation](https://zitadel.com/docs/guides/overview)
Dex [documentation](https://dexidp.io/docs/)
Oauth2-Proxy [documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
