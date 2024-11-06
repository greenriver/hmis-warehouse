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

## Enrollment ERD

Note "CoC" and "Household" are not formally defined but are implied or virtual entities
```mermaid
erDiagram
  Project }o--o{ CoC : "via ProjectCCoC"

  CustomService }|--|| Enrollment : "has"
  CustomServiceType ||--|{ CustomService : "has"
  CustomServiceCategory ||--|{ CustomService : "has"

  CustomAssessment }|--|| Enrollment : "has"
  CustomCaseNote }|--|| Enrollment : "has"
  CustomClientName }|--|| Client : "has"
  CustomClientAddress }|--|| Client : "has"
  CustomClientContactPoint }|--|| Client : "has"

  CoC }|..|| Enrollment : "served in"
  Project ||--|| Enrollment : "enrolled in"

  Enrollment }|..|| Household: "in"

  Enrollment ||--o| Exit : "has"
  Enrollment ||--o{ IncomeBenefits : "has"
  Enrollment ||--o{ HealthAndDV : "has"
  Enrollment ||--o{ EmploymentEducation : "has"
  Enrollment ||--o{ Disabilities : "has"
  Enrollment ||--o{ Services : "has"
  Enrollment ||--o{ CurrentLivingSituation : "has"
  Enrollment ||--o{ Assessment : "has"
  Assessment ||--o{ AssessmentQuestions : "has"
  Assessment ||--o{ AssessmentResults : "has"
  Enrollment ||--o{ Event : "has"
  Enrollment ||--o{ YouthEducationStatus : "has"
  Enrollment }o--|| Client : "has"

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
      string HouseholdID FK
      string PersonalID FK
      string ProjectID FK
      string EnrollmentCoC FK
      date EntryDate
      string RelationshipToHoH
      string DisablingCondition
  }

  Exit {
      date ExitDate
  }
```

## Project ERD

```mermaid
erDiagram
  CoC ||..o{ ProjectCoC : "contains"
  Organization ||--o{ Project : operates
  Project ||--o{ ProjectCoC : "operates in"
  Project ||--o{ Funder : "funded by"
  Project ||--o{ Inventory : "has"
  Project ||--o{ Enrollment : "has"
  Project |o--o{ Affiliation : "has"
  Affiliation |o--o{ Project : "has"

  Project ||--o{ HMISParticipation : "has"
  Project ||--o{ CEParticipation : "has"

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
  }
```
