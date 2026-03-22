# 7 Deployment View

[← Previous: 6 Runtime View](06-runtime/06-0-runtime-view.md) | [Table of Contents](README.md) | [Next: 8 Cross-cutting Concepts →](08-concepts/08-0-concepts.md)

This section describes the technical infrastructure used to execute the system and how [building blocks](05-building-blocks/05-0-building-blocks.md) are mapped to that infrastructure. Operational procedures (scaling, upgrades, incident response) are covered in the internal runbook, not here.

## 7.1 Infrastructure Level 1

*TBD. This section should contain a deployment diagram showing the production topology and a building-block-to-infrastructure mapping table.*

### Key Infrastructure

| Element | Technology | Purpose |
| --- | --- | --- |
| **Container Orchestration** | AWS EKS (Kubernetes) | Runs all application workloads as containerized pods. |
| **Continuous Deployment** | ArgoCD | GitOps-based deployment pipeline; syncs desired state from Git to the cluster. |
| **Database** | Amazon RDS (PostgreSQL) | Managed database for Warehouse, CAS, and Analytics stores. |
| **Object Storage** | Amazon S3 | HUD CSV ingestion boundary, public form hosting, report exports. |
| **Identity Provider** | Keycloak (self-hosted on EKS) | User directory and OIDC provider for the authentication layer. |

### Building Block Mapping

*TBD. Document which building blocks run as which Kubernetes deployments/services, including replica counts and resource profiles.*

| Building Block | K8s Deployment | Notes |
| --- | --- | --- |
| HMIS Frontend | *TBD* | React SPA served via nginx container |
| Warehouse Application | *TBD* | Rails app + Delayed Job workers |
| CAS | *TBD* | Separate Rails deployment |
| Authentication Layer | *TBD* | OAuth2-Proxy, Dex, Keycloak pods |
| Analytics Stack | *TBD* | Airflow, DBT, Superset |

### Environments

*TBD. Document the environments (production, staging, development) and any meaningful differences between them.*

## 7.2 Infrastructure Level 2

*TBD. Zoom into selected infrastructure elements as needed — e.g., the EKS cluster topology, networking/ingress configuration, or database replication setup.*
