/*
LSA FY2021 Sample Code

Name: 11 LSAReport DQ and ReportDate 
Date: 16 SEP 2021

	11.1 Get Relevant Enrollments for Data Quality Checks
*/

delete from dq_Enrollment
insert into dq_Enrollment (EnrollmentID, PersonalID, HouseholdID, RelationshipToHoH
	, LSAProjectType, EntryDate, MoveInDate, ExitDate, Status1, Status3, SSNValid, Step)
select distinct n.EnrollmentID, n.PersonalID, n.HouseholdID, n.RelationshipToHoH
	, case when p.ProjectType <> 1 then p.ProjectType
		when p.TrackingMethod = 0 then 0 
		else p.ProjectType end, n.EntryDate, hhinfo.MoveInDate, ExitDate
	, case when x.ExitDate < cd1.CohortStart then null
		when c.DOBDataQuality not in (1,2)
				or c.DOBDataQuality is null 
				or c.DOB is null 
				or c.DOB = '1/1/1900'
				or c.DOB > n.EntryDate
				or (c.DOB = n.EntryDate and n.RelationshipToHoH = 1)
				or dateadd(yy, 105, c.DOB) <= n.EntryDate 
				or dateadd(yy, 105, c.DOB) <= cd1.CohortStart 
			then 99
		when dateadd(yy, 18, c.DOB) <= n.EntryDate 
			or dateadd(yy, 18, c.DOB) <= cd1.CohortStart then 1
		else 0 end
	, case when c.DOBDataQuality not in (1,2)
				or c.DOBDataQuality is null 
				or c.DOB is null 
				or c.DOB = '1/1/1900'
				or c.DOB > n.EntryDate
				or (c.DOB = n.EntryDate and n.RelationshipToHoH = 1)
				or dateadd(yy, 105, c.DOB) <= n.EntryDate 
				or dateadd(yy, 105, c.DOB) <= cd3.CohortStart 
			then 99
		when dateadd(yy, 18, c.DOB) <= n.EntryDate 
			or dateadd(yy, 18, c.DOB) <= cd3.CohortStart  then 1
		else 0 end
, case when c.SSNDataQuality in (8,9) then null
		when SUBSTRING(c.SSN,1,3) in ('000','666')
				or LEN(c.SSN) <> 9
				or SUBSTRING(c.SSN,4,2) = '00'
				or SUBSTRING(c.SSN,6,4) ='0000'
				or c.SSN is null
				or c.SSN = ''
				or c.SSN like '%[^0-9]%'
				--5/14/2020 changed below from ">= '9'"  to "= '9'")
				or left(c.SSN,1) = '9'
				or c.SSN in ('123456789','111111111','222222222','333333333','444444444'
						,'555555555','777777777','888888888')
			then 0 else 1 end 
		, '11.1'
from hmis_Enrollment n
inner join lsa_Report rpt on n.EntryDate <= rpt.ReportEnd
inner join hmis_EnrollmentCoC coc on coc.HouseholdID = n.HouseholdID 
	and coc.CoCCode = rpt.ReportCoC and coc.InformationDate <= rpt.ReportEnd
	and coc.DateDeleted is null
inner join tlsa_CohortDates cd1 on cd1.Cohort = 1
inner join tlsa_CohortDates cd3 on cd3.Cohort = 20
inner join lsa_Project p on p.ProjectID = n.ProjectID 
	and p.ProjectType in (1,2,3,8,13)
inner join hmis_Client c on c.PersonalID = n.PersonalID
left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
	and x.DateDeleted is null 
	and x.ExitDate <= cd3.CohortEnd
left outer join (select distinct hh.EnrollmentID, hh.MoveInDate
	from hmis_Enrollment hh
	inner join lsa_Report rpt on hh.EntryDate <= rpt.ReportEnd
	inner join hmis_Project p on p.ProjectID = hh.ProjectID
	inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hh.EnrollmentID
		and coc.CoCCode = rpt.ReportCoC
		and coc.InformationDate <= rpt.ReportEnd
		and coc.DateDeleted is null 
	where p.ProjectType in (3,13) 
		and hh.RelationshipToHoH = 1
		and hh.MoveInDate <= rpt.ReportEnd 
		and p.ContinuumProject = 1
		and hh.DateDeleted is null
		) hhinfo on hhinfo.EnrollmentID = n.EnrollmentID
where n.EntryDate <= cd1.CohortEnd
	and (x.ExitDate is null or x.ExitDate >= cd3.CohortStart)
	and n.DateDeleted is null 

/*
	11.2 Set LSAReport Data Quality Values 

	NOTE:  In practice, there is no need to check for non-NULL values in Status3 as there 
			are no non-NULL values in dq_Enrollment.
*/
update rpt 
	set	UnduplicatedClient1 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			where n.Status1 is not null)
	,	UnduplicatedClient3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n)
	,	UnduplicatedAdult1 = (select count(distinct n.PersonalID)
			from dq_Enrollment n 
			where n.Status1 = 1)
	,	UnduplicatedAdult3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n 
			where n.Status3 = 1)
	,	AdultHoHEntry1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n 
			where n.Status1 = 1 or (n.Status1 is not null and n.RelationshipToHoH = 1))
	,	AdultHoHEntry3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n 
			where n.Status3 = 1 or n.RelationshipToHoH = 1)
	,	ClientEntry1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			where n.Status1 is not null)
	,	ClientEntry3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n)
	,	ClientExit1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n 
			inner join lsa_Report rpt on n.ExitDate between rpt.ReportStart and rpt.ReportEnd)
	,	ClientExit3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n 
			where n.ExitDate is not null)
	,	Household1 = (select count(distinct n.HouseholdID)
			from dq_Enrollment n
			where n.Status1 is not null)
	,	Household3 = (select count(distinct n.HouseholdID)
			from dq_Enrollment n)
	,	HoHPermToPH1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.DateDeleted is null 
			where n.Status1 is not null and n.RelationshipToHoH = 1
				and n.LSAProjectType in (3,13)
				and x.Destination in (3,31,19,20,21,26,28,10,11,22,23,33,34))
	,	HoHPermToPH3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.DateDeleted is null 
			where n.RelationshipToHoH = 1
				and n.LSAProjectType in (3,13)
				and x.Destination in (3,31,19,20,21,26,28,10,11,22,23,33,34))
	,   NoCoC = (select count (distinct n.HouseholdID)
			from hmis_Enrollment n 
			left outer join hmis_EnrollmentCoC coc on 
				coc.EnrollmentID = n.EnrollmentID
				and coc.InformationDate <= rpt.ReportEnd
				and coc.DateDeleted is null 
			inner join hmis_Project p on p.ProjectID = n.ProjectID
				and p.ContinuumProject = 1 and p.ProjectType in (1,2,3,8,13)
			inner join hmis_ProjectCoC pcoc on pcoc.CoCCode = rpt.ReportCoC
				and pcoc.DateDeleted is null 
			left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.DateDeleted is null
			where n.EntryDate <= rpt.ReportEnd 
				and (x.ExitDate is null or x.ExitDate >= (select CohortStart from tlsa_CohortDates where Cohort = 20))
				and n.RelationshipToHoH = 1 
				and coc.CoCCode is null
				and n.DateDeleted is null)
	,	SSNNotProvided = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			where n.SSNValid is null)
	,	SSNMissingOrInvalid = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			where n.SSNValid = 0)
	,	ClientSSNNotUnique = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			inner join hmis_Client oc on oc.SSN = c.SSN 
				and oc.PersonalID <> c.PersonalID
			inner join dq_Enrollment dqn on dqn.PersonalID = oc.PersonalID 
			where n.SSNValid = 1)
	,	DistinctSSNValueNotUnique = (select count(distinct d.SSN)
			from (select distinct c.SSN
				from hmis_Client c 
				inner join dq_Enrollment n on n.PersonalID = c.PersonalID
					and n.SSNValid = 1
				group by c.SSN
				having count(distinct n.PersonalID) > 1) d)
	,	DOB1 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			where n.Status1 = 99)
	,	DOB3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			where n.Status3 = 99)
	,	Gender1 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
				and (c.GenderNone in (8,9,99)  
					or isnull(c.Female, 0) + isnull(c.Male, 0) + isnull(c.Transgender, 0) + isnull(c.NoSingleGender,0) + isnull(c.Questioning, 0) = 0
					or c.Female not in (0,1)
					or c.Male not in (0,1)
					or c.Transgender not in (0,1)
					or c.NoSingleGender not in (0,1)
					or c.Questioning not in (0,1))
			where n.Status1 is not null)
	,	Gender3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
				and (c.GenderNone in (8,9,99)  
					or isnull(c.Female, 0) + isnull(c.Male, 0) + isnull(c.Transgender, 0) + isnull(c.NoSingleGender,0) + isnull(c.Questioning, 0) = 0
					or c.Female not in (0,1)
					or c.Male not in (0,1)
					or c.Transgender not in (0,1)
					or c.NoSingleGender not in (0,1)
					or c.Questioning not in (0,1)))
	,	Race1 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			where n.Status1 is not null 
				and c.RaceNone in (8,9,99)
					or isnull(c.AmIndAKNative,0) + isnull(c.Asian,0) + isnull(c.BlackAfAmerican,0) + isnull(c.NativeHIPacific,0) + isnull(c.White,0) = 0
					or c.AmIndAKNative not in (0,1)
					or c.Asian not in (0,1)
					or c.BlackAfAmerican not in (0,1)
					or c.NativeHIPacific not in (0,1)
					or c.White not in (0,1))
	,	Race3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			where c.RaceNone in (8,9,99)
					or isnull(c.AmIndAKNative,0) + isnull(c.Asian,0) + isnull(c.BlackAfAmerican,0) + isnull(c.NativeHIPacific,0) + isnull(c.White,0) = 0
					or c.AmIndAKNative not in (0,1)
					or c.Asian not in (0,1)
					or c.BlackAfAmerican not in (0,1)
					or c.NativeHIPacific not in (0,1)
					or c.White not in (0,1))
	,	Ethnicity1 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			where n.Status1 is not null and (c.Ethnicity not in (0,1) or c.Ethnicity is null))
	,	Ethnicity3 = (select count(distinct n.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			where (c.Ethnicity not in (0,1) or c.Ethnicity is null))
	,	VetStatus1 = (select count(distinct c.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			where n.Status1 = 1 
				and (c.VeteranStatus not in (0,1) or c.VeteranStatus is null))
	,	VetStatus3 = (select count(distinct c.PersonalID)
			from dq_Enrollment n
			inner join hmis_Client c on c.PersonalID = n.PersonalID
			where n.Status3 = 1 
				and (c.VeteranStatus not in (0,1) or c.VeteranStatus is null))
	,	RelationshipToHoH1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			where n.Status1 is not null 
				and (n.RelationshipToHoH not in (1,2,3,4,5) or n.RelationshipToHoH is null))
	,	RelationshipToHoH3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			where  (n.RelationshipToHoH not in (1,2,3,4,5) or n.RelationshipToHoH is null))
	,	DisablingCond1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where n.Status1 is not null 
				and (hn.DisablingCondition not in (0,1) or hn.DisablingCondition is null))
	,	DisablingCond3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (hn.DisablingCondition not in (0,1) or hn.DisablingCondition is null))
	,	LivingSituation1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.Status1 = 1 or (n.RelationshipToHoH = 1 and n.Status1 is not null))
				and (hn.LivingSituation in (8,9,99) or hn.LivingSituation is null))
	,	LivingSituation3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Status3 = 1)
				and (hn.LivingSituation in (8,9,99) or hn.LivingSituation is null))
	,	LengthOfStay1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.Status1 = 1 or (n.RelationshipToHoH = 1 and n.Status1 is not null))
				and (hn.LengthOfStay in (8,9,99) or hn.LengthOfStay is null))
	,	LengthOfStay3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Status3 = 1)
				and (hn.LengthOfStay in (8,9,99) or hn.LengthOfStay is null))
	,	HomelessDate1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.Status1 = 1 or (n.RelationshipToHoH = 1 and n.Status1 is not null))
				-- DateToStreetESSH may not be after hn.EntryDate...
				and (hn.DateToStreetESSH > hn.EntryDate
				-- ...and may not be null if...
				or (hn.DateToStreetESSH is null 
				-- ...ProjectType is ES/SH...
				and (n.LSAProjectType in (1,8)
						-- ... or when LivingSituation is ES/SH/street/interim housing
						or hn.LivingSituation in (1,16,18,27) 
						-- ... or when LOS is < 7 days and PreviousStreetESSH = 1
						or ((hn.PreviousStreetESSH = 1 or hn.PreviousStreetESSH is NULL) and hn.LengthOfStay in (10,11))
						-- ... or when LivingSituation is institutional, LOS is < 90 days
							-- and PreviousStreetESSH = 1 
						or ((hn.PreviousStreetESSH = 1 or hn.PreviousStreetESSH is NULL) and hn.LengthOfStay in (2,3)
							and hn.LivingSituation in (4,5,6,7,15,25))
					))))
	,	HomelessDate3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Status3 = 1)
				-- DateToStreetESSH may not be after hn.EntryDate...
				and (hn.DateToStreetESSH > hn.EntryDate
				-- ...and may not be null if...
				or (hn.DateToStreetESSH is null 
				-- ...ProjectType is ES/SH...
				and (n.LSAProjectType in (1,8)
						-- ... or when LivingSituation is ES/SH/street/interim housing
						or hn.LivingSituation in (1,16,18,27) 
						-- ... or when LOS is < 7 days and PreviousStreetESSH = 1
						or ((hn.PreviousStreetESSH = 1 or hn.PreviousStreetESSH is NULL) and hn.LengthOfStay in (10,11))
						-- ... or when LivingSituation is institutional, LOS is < 90 days
							-- and PreviousStreetESSH = 1 
						or ((hn.PreviousStreetESSH = 1 or hn.PreviousStreetESSH is NULL) and hn.LengthOfStay in (2,3)
							and hn.LivingSituation in (4,5,6,7,15,25))
					))))
	,	TimesHomeless1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.Status1 = 1 or (n.RelationshipToHoH = 1 and n.Status1 is not null))
				--TimesHomelessPastThreeYears is required and must be a valid value if...
				and (hn.TimesHomelessPastThreeYears not between 1 and 4  
					or hn.TimesHomelessPastThreeYears is null)
				-- ...ProjectType is ES/SH...
				and (n.LSAProjectType in (1,8)
						-- ... or when LivingSituation is ES/SH/street/interim housing
						or hn.LivingSituation in (1,16,18,27) 
						-- ... or when LOS is < 7 days and PreviousStreetESSH = 1
						or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
						-- ... or when LivingSituation is institutional, LOS is < 90 days
							-- and PreviousStreetESSH = 1 
						or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
							and hn.LivingSituation in (4,5,6,7,15,25))
					))
	,	TimesHomeless3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Status3 = 1)
				--TimesHomelessPastThreeYears is required and must be a valid value if...
				and (hn.TimesHomelessPastThreeYears not between 1 and 4  
					or hn.TimesHomelessPastThreeYears is null)
				-- ...ProjectType is ES/SH...
				and (n.LSAProjectType in (1,8)
						-- ... or when LivingSituation is ES/SH/street/interim housing
						or hn.LivingSituation in (1,16,18,27) 
						-- ... or when LOS is < 7 days and PreviousStreetESSH = 1
						or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
						-- ... or when LivingSituation is institutional, LOS is < 90 days
							-- and PreviousStreetESSH = 1 
						or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
							and hn.LivingSituation in (4,5,6,7,15,25))
					))
	,	MonthsHomeless1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.Status1 = 1 or (n.RelationshipToHoH = 1 and n.Status1 is not null))
				--MonthsHomelessPastThreeYears is required and must be a valid value if...
				and (hn.MonthsHomelessPastThreeYears not between 101 and 113 
				or hn.MonthsHomelessPastThreeYears is null)
				-- ...ProjectType is ES/SH...
				and (n.LSAProjectType in (1,8)
						-- ... or when LivingSituation is ES/SH/street/interim housing
						or hn.LivingSituation in (1,16,18,27) 
						-- ... or when LOS is < 7 days and PreviousStreetESSH = 1
						or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
						-- ... or when LivingSituation is institutional, LOS is < 90 days
							-- and PreviousStreetESSH = 1 
						or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
							and hn.LivingSituation in (4,5,6,7,15,25))	
					))
	,	MonthsHomeless3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
			where (n.RelationshipToHoH = 1 or n.Status3 = 1)
				--MonthsHomelessPastThreeYears is required and must be a valid value if...
				and (hn.MonthsHomelessPastThreeYears not between 101 and 113 
				or hn.MonthsHomelessPastThreeYears is null)
				-- ...ProjectType is ES/SH...
				and (n.LSAProjectType in (1,8)
						-- ... or when LivingSituation is ES/SH/street/interim housing
						or hn.LivingSituation in (1,16,18,27) 
						-- ... or when LOS is < 7 days and PreviousStreetESSH = 1
						or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
						-- ... or when LivingSituation is institutional, LOS is < 90 days
							-- and PreviousStreetESSH = 1 
						or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
							and hn.LivingSituation in (4,5,6,7,15,25))	
					))
	,	DV1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			left outer join hmis_HealthAndDV dv on dv.EnrollmentID = n.EnrollmentID
				and dv.DataCollectionStage = 1
				and dv.DateDeleted is null 
			where (n.Status1 = 1 or (n.RelationshipToHoH = 1 and n.Status1 is not null))
				and (dv.DomesticViolenceVictim not in (0,1)
						or dv.DomesticViolenceVictim is null
						or (dv.DomesticViolenceVictim = 1 and 
							(dv.CurrentlyFleeing not in (0,1) 
								or dv.CurrentlyFleeing is null))))
	,	DV3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			left outer join hmis_HealthAndDV dv on dv.EnrollmentID = n.EnrollmentID
				and dv.DataCollectionStage = 1
				and dv.DateDeleted is null 
			where (n.RelationshipToHoH = 1 or n.Status3 = 1)
				and (dv.DomesticViolenceVictim not in (0,1)
						or dv.DomesticViolenceVictim is null
						or (dv.DomesticViolenceVictim = 1 and 
							(dv.CurrentlyFleeing not in (0,1) 
								or dv.CurrentlyFleeing is null))))
	,	Destination1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.DateDeleted is null 
			where n.Status1 is not null and n.ExitDate is not null 
				and (x.Destination in (8,9,17,30,99) or x.Destination is null))
	,	Destination3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.DateDeleted is null 
			where n.ExitDate is not null 
				and (x.Destination in (8,9,17,30,99) or x.Destination is null))
	,	NotOneHoH1 = (select count(distinct n.HouseholdID)
			from dq_Enrollment n
			left outer join (select hn.HouseholdID, count(distinct hn.EnrollmentID) as hoh
				from hmis_Enrollment hn
				where hn.RelationshipToHoH = 1 and hn.DateDeleted is null 
				group by hn.HouseholdID
				) hoh on hoh.HouseholdID = n.HouseholdID
			where n.Status1 is not null and (hoh.hoh <> 1 or hoh.HouseholdID is null))
	,	NotOneHoH3 = (select count(distinct n.HouseholdID)
			from dq_Enrollment n
			left outer join (select hn.HouseholdID, count(distinct hn.EnrollmentID) as hoh
				from hmis_Enrollment hn
				where hn.RelationshipToHoH = 1 and hn.DateDeleted is null
				group by hn.HouseholdID
			) hoh on hoh.HouseholdID = n.HouseholdID
			where hoh.hoh <> 1 or hoh.HouseholdID is null)
	,	MoveInDate1 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and n.ExitDate is not null and x.DateDeleted is null 
			where n.Status1 is not null and n.RelationshipToHoH = 1
				and n.LSAProjectType in (3,13)
				and ((n.MoveInDate < n.EntryDate or n.MoveInDate > n.ExitDate)
					or (x.Destination in (3,31,19,20,21,26,28,10,11,22,23,33,34) 
						and n.MoveInDate is null)))
	,	MoveInDate3 = (select count(distinct n.EnrollmentID)
			from dq_Enrollment n
			inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
			left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and n.ExitDate is not null and x.DateDeleted is null 
			where n.RelationshipToHoH = 1
				and n.LSAProjectType in (3,13)
				and ((n.MoveInDate < n.EntryDate or n.MoveInDate > n.ExitDate)
					or (x.Destination in (3,31,19,20,21,26,28,10,11,22,23,33,34) 
						and n.MoveInDate is null)))
from lsa_Report rpt

/*
	11.3 Set ReportDate for LSAReport
*/
update lsa_Report set ReportDate = getdate()