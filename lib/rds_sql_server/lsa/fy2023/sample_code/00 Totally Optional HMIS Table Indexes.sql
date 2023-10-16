/*

LSA FY2023 Sample Code
Name:  00 Totally Optional HMIS Table Indexes.sql

*/
	create nonclustered index ix_hmis_Enrollment_TimesHomelessPastThreeYears_MonthsHomelessPastThreeYears on hmis_Enrollment (TimesHomelessPastThreeYears, MonthsHomelessPastThreeYears) include (EnrollmentID)

	create nonclustered index ix_hmis_Enrollment_DateDeleted_EntryDate on hmis_Enrollment (DateDeleted, EntryDate) include (EnrollmentID, HouseholdID, ProjectID, RelationshipToHoH)

	create nonclustered index ix_hmis_Enrollment_HouseholdID_DateDeleted_EntryDate_RelationshipToHoH on hmis_Enrollment (HouseholdID, DateDeleted, EntryDate, RelationshipToHoH) include (EnrollmentID, PersonalID, DisablingCondition)

	create nonclustered index ix_hmis_Enrollment_EntryDate on hmis_Enrollment (EntryDate) include (EnrollmentID, ProjectID, HouseholdID, RelationshipToHoH, DateDeleted)

	create nonclustered index ix_hmis_Enrollment_HouseholdID_DateDeleted_RelationshipToHoH on hmis_Enrollment (HouseholdID, DateDeleted, RelationshipToHoH) include (EnrollmentID, PersonalID, EntryDate, DisablingCondition)

	create nonclustered index ix_hmis_Enrollment_MoveInDate on hmis_Enrollment (MoveInDate) include (EnrollmentID)

	create nonclustered index ix_hmis_Enrollment_LivingSituation on hmis_Enrollment (LivingSituation) include (EnrollmentID)

	create nonclustered index ix_hmis_Enrollment_LengthOfStay on hmis_Enrollment (LengthOfStay) include (EnrollmentID)

	create nonclustered index ix_hmis_Enrollment_HouseholdID_RelationshipToHoH_DateDeleted on hmis_Enrollment (HouseholdID, RelationshipToHoH, DateDeleted) include (EnrollmentID)

	create nonclustered index ix_hmis_Enrollment_ProjectID_RelationshipToHoH_DateDeleted on hmis_Enrollment (ProjectID, RelationshipToHoH, DateDeleted) include (EnrollmentID, PersonalID, EntryDate, HouseholdID, MoveInDate)

	create nonclustered index ix_hmis_Enrollment_RelationshipToHoH_DateDeleted on hmis_Enrollment (RelationshipToHoH, DateDeleted) include (EnrollmentID, PersonalID, ProjectID, EntryDate, HouseholdID, MoveInDate)

	create nonclustered index ix_hmis_Enrollment_MonthsHomelessPastThreeYears on hmis_Enrollment (MonthsHomelessPastThreeYears) include (EnrollmentID, LivingSituation, PreviousStreetESSH)

	create nonclustered index ix_hmis_Exit_DateDeleted on hmis_Exit (DateDeleted) include (EnrollmentID, ExitDate)

	create nonclustered index ix_hmis_Exit_ExitDate_Destination on hmis_Exit (ExitDate, Destination) include (EnrollmentID)

	create nonclustered index ix_hmis_Services_EnrollmentID_RecordType_DateDeleted on hmis_Services (EnrollmentID, RecordType, DateDeleted) include (DateProvided)

	create nonclustered index ix_hmis_Services_RecordType_DateDeleted_DateProvided on hmis_Services (RecordType, DateDeleted, DateProvided) include (EnrollmentID)

	create nonclustered index ix_hmis_Disabilities_DisabilityType_DisabilityResponse_IndefiniteAndImpairs_InformationDate on hmis_Disabilities (DisabilityType, DisabilityResponse, IndefiniteAndImpairs,InformationDate) include (EnrollmentID)

	create nonclustered index ix_hmis_Disabilities_DisabilityType_DisabilityResponse_IndefiniteAndImpairs on hmis_Disabilities (DisabilityType, DisabilityResponse, IndefiniteAndImpairs) INCLUDE (EnrollmentID, InformationDate)

	create nonclustered index ix_hmis_Enrollment_ProjectID_RelationshipToHoH_DateDeleted_EntryDate on hmis_Enrollment (ProjectID, RelationshipToHoH, DateDeleted,EntryDate) include (HouseholdID, EnrollmentCoC)

	create nonclustered index ix_hmis_Enrollment_ProjectID_RelationshipToHoH_DateDeleted on hmis_Enrollment (ProjectID, RelationshipToHoH, DateDeleted) include (PersonalID, EntryDate, HouseholdID, EnrollmentCoC, MoveInDate)