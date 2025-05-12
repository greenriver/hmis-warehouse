/*

LSA FY2024 Sample Code
Name:  00 Totally Optional HMIS Table Indexes.sql

*/
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_TimesHomelessPastThreeYears_MonthsHomelessPastThreeYears')
	begin
		create nonclustered index ix_hmis_Enrollment_TimesHomelessPastThreeYears_MonthsHomelessPastThreeYears on hmis_Enrollment (TimesHomelessPastThreeYears, MonthsHomelessPastThreeYears) include (EnrollmentID)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_DateDeleted_EntryDate')
	begin
		create nonclustered index ix_hmis_Enrollment_DateDeleted_EntryDate on hmis_Enrollment (DateDeleted, EntryDate) include (EnrollmentID, HouseholdID, ProjectID, RelationshipToHoH)
		end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_HouseholdID_DateDeleted_EntryDate_RelationshipToHoH')
	begin
		create nonclustered index ix_hmis_Enrollment_HouseholdID_DateDeleted_EntryDate_RelationshipToHoH on hmis_Enrollment (HouseholdID, DateDeleted, EntryDate, RelationshipToHoH) include (EnrollmentID, PersonalID, DisablingCondition)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_EntryDate')
	begin
		create nonclustered index ix_hmis_Enrollment_EntryDate on hmis_Enrollment (EntryDate) include (EnrollmentID, ProjectID, HouseholdID, RelationshipToHoH, DateDeleted)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_HouseholdID_DateDeleted_RelationshipToHoH')
	begin
		create nonclustered index ix_hmis_Enrollment_HouseholdID_DateDeleted_RelationshipToHoH on hmis_Enrollment (HouseholdID, DateDeleted, RelationshipToHoH) include (EnrollmentID, PersonalID, EntryDate, DisablingCondition)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_MoveInDate')
	begin
		create nonclustered index ix_hmis_Enrollment_MoveInDate on hmis_Enrollment (MoveInDate) include (EnrollmentID)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_LivingSituation')
	begin
		create nonclustered index ix_hmis_Enrollment_LivingSituation on hmis_Enrollment (LivingSituation) include (EnrollmentID)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_LengthOfStay')
	begin
		create nonclustered index ix_hmis_Enrollment_LengthOfStay on hmis_Enrollment (LengthOfStay) include (EnrollmentID)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_HouseholdID_RelationshipToHoH_DateDeleted')
	begin
		create nonclustered index ix_hmis_Enrollment_HouseholdID_RelationshipToHoH_DateDeleted on hmis_Enrollment (HouseholdID, RelationshipToHoH, DateDeleted) include (EnrollmentID)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_ProjectID_RelationshipToHoH_DateDeleted')
	begin
		create nonclustered index ix_hmis_Enrollment_ProjectID_RelationshipToHoH_DateDeleted on hmis_Enrollment (ProjectID, RelationshipToHoH, DateDeleted) include (EnrollmentID, PersonalID, EntryDate, HouseholdID, MoveInDate)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_RelationshipToHoH_DateDeleted')
	begin
		create nonclustered index ix_hmis_Enrollment_RelationshipToHoH_DateDeleted on hmis_Enrollment (RelationshipToHoH, DateDeleted) include (EnrollmentID, PersonalID, ProjectID, EntryDate, HouseholdID, MoveInDate)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_MonthsHomelessPastThreeYears')
	begin
		create nonclustered index ix_hmis_Enrollment_MonthsHomelessPastThreeYears on hmis_Enrollment (MonthsHomelessPastThreeYears) include (EnrollmentID, LivingSituation, PreviousStreetESSH)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Exit_DateDeleted')
	begin
		create nonclustered index ix_hmis_Exit_DateDeleted on hmis_Exit (DateDeleted) include (EnrollmentID, ExitDate)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Exit_ExitDate_Destination')
	begin
		create nonclustered index ix_hmis_Exit_ExitDate_Destination on hmis_Exit (ExitDate, Destination) include (EnrollmentID)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Services_EnrollmentID_RecordType_DateDeleted')
	begin
		create nonclustered index ix_hmis_Services_EnrollmentID_RecordType_DateDeleted on hmis_Services (EnrollmentID, RecordType, DateDeleted) include (DateProvided)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Services_RecordType_DateDeleted_DateProvided')
	begin
		create nonclustered index ix_hmis_Services_RecordType_DateDeleted_DateProvided on hmis_Services (RecordType, DateDeleted, DateProvided) include (EnrollmentID)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Disabilities_DisabilityType_DisabilityResponse_IndefiniteAndImpairs_InformationDate')
	begin
		create nonclustered index ix_hmis_Disabilities_DisabilityType_DisabilityResponse_IndefiniteAndImpairs_InformationDate on hmis_Disabilities (DisabilityType, DisabilityResponse, IndefiniteAndImpairs,InformationDate) include (EnrollmentID)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Disabilities_DisabilityType_DisabilityResponse_IndefiniteAndImpairs')
	begin
		create nonclustered index ix_hmis_Disabilities_DisabilityType_DisabilityResponse_IndefiniteAndImpairs on hmis_Disabilities (DisabilityType, DisabilityResponse, IndefiniteAndImpairs) INCLUDE (EnrollmentID, InformationDate)
	end
	if not exists (select * from sys.indexes where name = 'ix_hmis_Enrollment_ProjectID_RelationshipToHoH_DateDeleted_EntryDate')
	begin
		create nonclustered index ix_hmis_Enrollment_ProjectID_RelationshipToHoH_DateDeleted_EntryDate on hmis_Enrollment (ProjectID, RelationshipToHoH, DateDeleted,EntryDate) include (HouseholdID, EnrollmentCoC)
	end

	if not exists (select * from sys.indexes where name = 'ix_hmis_HealthAndDV_InformationDate_DateDeleted')
	begin
		create nonclustered index ix_hmis_HealthAndDV_InformationDate_DateDeleted on hmis_HealthAndDV (InformationDate, DateDeleted) include ([EnrollmentID], [DomesticViolenceSurvivor], [CurrentlyFleeing])
	end
