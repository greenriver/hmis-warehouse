# HMIS HUD CSV data model

Based on:
HMIS CSV FORMAT Specifications FY2024
VERSION 1.4

## Key Relationships

* One Organization can have many Projects
* One Project can have many Enrollments
* One Client can have many Enrollments
* Each Enrollment is tied to exactly one Project and one Client
* Each Enrollment can have multiple associated services, assessments, and other records

## ERD

Note "CoC" is not a defined table; is included in the diagram as an "implied" entity

```mermaid
erDiagram
    CoC ||..o{ Organization : "operates in"
    CoC ||..o{ ProjectCoC : "contains"
    Export ||--o{ Organization : contains
    Organization ||--o{ Project : operates
    Project ||--o{ ProjectCoC : "has locations in"
    Project ||--o{ Funder : "funded by"
    Project ||--o{ Inventory : "has"
    Project ||--o{ Affiliation : "may be affiliated with"
    Project ||--o{ HMISParticipation : "has"
    Project ||--o{ CEParticipation : "has"

    Client ||--o{ Enrollment : "has"
    Enrollment ||--|| Project : "enrolled in"
    Enrollment }|..|| CoC : "served in"
    Enrollment ||--o{ Exit : "may have"
    Enrollment ||--o{ IncomeBenefits : "has"
    Enrollment ||--o{ HealthAndDV : "has"
    Enrollment ||--o{ EmploymentEducation : "has"
    Enrollment ||--o{ Disabilities : "has"
    Enrollment ||--o{ Services : "receives"
    Enrollment ||--o{ CurrentLivingSituation : "has"
    Enrollment ||--o{ Assessment : "has"
    Assessment ||--o{ AssessmentQuestions : "contains"
    Assessment ||--o{ AssessmentResults : "produces"
    Enrollment ||--o{ Event : "has"
    Enrollment ||--o{ YouthEducationStatus : "has"



    Export {
        string ExportID PK
        string SourceType
        string SourceID
        datetime ExportDate
        string HashStatus
    }

    Organization {
        string OrganizationID PK
        string CoCCode FK
        string OrganizationName
        boolean VictimServiceProvider
    }

    Project {
        string ProjectID PK
        string OrganizationID FK
        string ProjectName
        date OperatingStartDate
        int ProjectType
    }

    ProjectCoC {
        string ProjectCoCID PK
        string ProjectID FK
        string CoCCode FK
        string Geocode
        string Address
        string Geography
    }

    Client {
        string PersonalID PK
        string FirstName
        string LastName
        string SSN
        date DOB
        string VeteranStatus
    }

    Enrollment {
        string EnrollmentID PK
        string PersonalID FK
        string ProjectID FK
        string EnrollmentCoC FK
        date EntryDate
        string RelationshipToHoH
        string DisablingCondition
    }
```
