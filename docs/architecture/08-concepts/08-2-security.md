# 8.2 Security & Access Control

[← 8.1 HMIS Data Model](08-1-hmis-data-model.md) | [Table of Contents](../README.md) | [Next: 8.3 Driver Module Pattern →](08-3-driver-module-pattern.md)

*TBD. This concept should document the cross-cutting authorization and data visibility model — how permissions, roles, and access policies work across the platform. The authentication layer itself is documented in [5.2.3 Authentication](../05-building-blocks/05-2-3-authentication.md) and [6.1 Login Flow](../06-runtime/06-1-login-flow.md).*

### Planned Scope

- **Permission system** — How granular permissions are defined, assigned, and enforced within the Warehouse and HMIS modules.
- **Role hierarchy** — Built-in roles, custom roles, and how role assignments cascade across organizations and projects.
- **Legacy CAS roles** — How CAS manages its own role/access model independently of the Warehouse.
- **Data visibility rules** — Row-level and field-level restrictions based on user role, data source ownership, and CoC affiliation.
- **Access policies** — Policy objects that gate controller actions and GraphQL resolvers (see `docs/features/warehouse-auth-policies.md`).
- **Audit logging** — How access to sensitive data (PII, SSN) is tracked across systems.
