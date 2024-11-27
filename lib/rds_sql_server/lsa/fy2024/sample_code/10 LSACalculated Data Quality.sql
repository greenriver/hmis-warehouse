/*
LSA FY2024 Sample Code
Name:  10 LSACalculated Data Quality.sql

FY2024 Changes

		None

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)/


	10.2 Get Counts of Enrollments Active after Operating End Date by ProjectID
*/

	delete from lsa_Calculated  where ReportRow in (901,902)

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1
		, case when hx.ExitDate is null then 901
			else 902 end 
		, p.ProjectID, cd.ReportID, '10.2'
	from tlsa_Enrollment n
	left outer join hmis_Exit hx on hx.EnrollmentID = n.EnrollmentID 
		and hx.DateDeleted is null
	inner join hmis_Project p on p.ProjectID = n.ProjectID 
	inner join tlsa_CohortDates cd on cd.Cohort = 1 
		and p.OperatingEndDate between cd.CohortStart and cd.CohortEnd
	where (hx.ExitDate is null or hx.ExitDate > p.OperatingEndDate)
	group by case when hx.ExitDate is null then 901
			else 902 end 
		, p.ProjectID, cd.ReportID

/*
	10.3 Get Counts of Night-by-Night Enrollments with Exit Date Discrepancies
*/

	delete from lsa_Calculated where ReportRow in (903,904) 

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct hn.EnrollmentID), 1, 10, 0, 0, -1
		, case when hx.ExitDate is null or hx.ExitDate > cd.CohortEnd then 903
			else 904 end 
		, p.ProjectID, cd.ReportID, '10.3'
	from tlsa_Enrollment n
	inner join tlsa_CohortDates cd on cd.Cohort = 1
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID 
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
		and hx.DateDeleted is NULL
	inner join hmis_Project p on p.ProjectID = hn.ProjectID and p.ProjectType = 1 and p.ContinuumProject = 1
	left outer join (select svc.EnrollmentID, max(svc.DateProvided) as LastBednight
		from hmis_Services svc
		inner join hmis_Enrollment nbn on nbn.EnrollmentID = svc.EnrollmentID
		inner join hmis_Project p on p.ProjectID = nbn.ProjectID 
			and p.ProjectType = 1 
			and (p.OperatingEndDate is null or p.OperatingEndDate >= DateProvided)
		inner join tlsa_CohortDates cd on cd.Cohort = 1
			and svc.DateProvided between cd.CohortStart and cd.CohortEnd
		where svc.RecordType = 200 and svc.DateDeleted is null
		group by svc.EnrollmentID
		) bn on bn.EnrollmentID = hhid.EnrollmentID
	where ((hx.ExitDate is null or hx.ExitDate > cd.CohortEnd) and bn.LastBednight <= dateadd(dd, -90, cd.CohortEnd))
		or (hx.ExitDate between cd.CohortStart and cd.CohortEnd and hx.ExitDate <> dateadd(dd, 1, bn.LastBednight))
	group by case when hx.ExitDate is null or hx.ExitDate > cd.CohortEnd then 903
			else 904 end 
		, p.ProjectID, cd.ReportID

/*
	10.4 Get Counts of Households with no Enrollment CoC Record
*/

	delete from lsa_Calculated where ReportRow = 905

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct hn.HouseholdID), 1, 10, 0, 0, -1, 905, p.ProjectID, rpt.ReportID, '10.4'
	from lsa_Report rpt
	inner join hmis_Enrollment hn on hn.EntryDate <= rpt.ReportEnd
	inner join lsa_Project p on p.ProjectID = hn.ProjectID and p.ProjectType not in (9,10)
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
		and hx.DateDeleted is null
	left outer join hmis_Enrollment hoh on hoh.HouseholdID = hn.HouseholdID 
		and hoh.RelationshipToHoH = 1 
		and hoh.DateDeleted is null
	where hn.DateDeleted is null 
		and hoh.EnrollmentCoC is null
		and (hx.ExitDate is null or 
				(hx.ExitDate >= rpt.ReportStart and hx.ExitDate > hn.EntryDate))
	group by p.ProjectID, rpt.ReportID

/*
	10.5	DQ – Enrollments in non-participating projects
*/
	delete from lsa_Calculated where ReportRow = 906

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 906, n.ProjectID, rpt.ReportID, '10.5'
	from lsa_Report rpt
	inner join hmis_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join hmis_Enrollment hoh on hoh.HouseholdID = n.HouseholdID 
	inner join lsa_Project p on p.ProjectID = n.ProjectID and p.ProjectType not in (9,10)
	left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID and x.DateDeleted is null
		and x.ExitDate <= rpt.ReportEnd 
	left outer join lsa_HMISParticipation part on part.ProjectID = n.ProjectID
		and part.HMISParticipationType = 1
		and part.HMISParticipationStatusStartDate <= n.EntryDate
		and (part.HMISParticipationStatusEndDate is null
			or part.HMISParticipationStatusEndDate >= x.ExitDate
			or (x.ExitDate is null and part.HMISParticipationStatusEndDate > rpt.ReportEnd))
	where hoh.RelationshipToHoH = 1 and hoh.EnrollmentCoC = rpt.ReportCoC and part.ProjectID is null
		and (x.ExitDate is null 
			or (x.ExitDate >= ReportStart and x.ExitDate > n.EntryDate))
		and n.DateDeleted is null and hoh.DateDeleted is null
	group by n.ProjectID, rpt.ReportID
/*
	10.6	DQ – Enrollments without exactly one HoH
*/
	delete from lsa_Calculated where ReportRow = 907

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct hn.EnrollmentID), 1, 10, 0, 0, -1, 907, hn.ProjectID, rpt.ReportID, '10.6'
	from lsa_Report rpt
	inner join hmis_Enrollment hn on hn.EntryDate <= rpt.ReportEnd
	inner join lsa_Project p on p.ProjectID = hn.ProjectID
	inner join hmis_Enrollment coc on coc.HouseholdID = hn.HouseholdID and coc.EnrollmentCoC = rpt.ReportCoC
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
		and hx.DateDeleted is null
	left outer join (select hoh.HouseholdID, count(hoh.PersonalID) as hoh
		from hmis_Enrollment hoh
		where hoh.RelationshipToHoH = 1 and hoh.DateDeleted is null
		group by hoh.HouseholdID) counthoh on counthoh.HouseholdID = hn.HouseholdID
	where (counthoh.HouseholdID is null or counthoh.hoh > 1)
		and p.ProjectType not in (9,10) 
		and hn.DateDeleted is null 
		and (hx.ExitDate is null or 
				(hx.ExitDate >= rpt.ReportStart and hx.ExitDate > hn.EntryDate))
	group by hn.ProjectID, rpt.ReportID
/*
	10.7	DQ – Relationship to HoH
*/
	delete from lsa_Calculated where ReportRow = 908

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct hn.EnrollmentID), 1, 10, 0, 0, -1, 908, hn.ProjectID, rpt.ReportID, '10.7'
	from lsa_Report rpt
	inner join hmis_Enrollment hn on hn.EntryDate <= rpt.ReportEnd
	inner join lsa_Project p on p.ProjectID = hn.ProjectID
	inner join hmis_Enrollment coc on coc.HouseholdID = hn.HouseholdID and coc.EnrollmentCoC = rpt.ReportCoC
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
		and hx.DateDeleted is null
	where (hn.RelationshipToHoH is null or hn.RelationshipToHoH not between 1 and 5)
		and p.ProjectType not in (9,10) 
		and hn.DateDeleted is null 
		and (hx.ExitDate is null or 
				(hx.ExitDate >= rpt.ReportStart and hx.ExitDate > hn.EntryDate))
	group by hn.ProjectID, rpt.ReportID
/*
	10.8	DQ – Household Entry
*/
	delete from lsa_Calculated where ReportRow = 909

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct hh.HouseholdID), 1, 10, 0, 0, -1, 909, hh.ProjectID, rpt.ReportID, '10.8'
	from lsa_Report rpt
	inner join tlsa_HHID hh on hh.EntryDate <= rpt.ReportEnd
	where hh.Active = 1
	group by hh.ProjectID, rpt.ReportID
/*
	10.9	DQ – Client Entry
*/
	delete from lsa_Calculated where ReportRow = 910

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 910, n.ProjectID, rpt.ReportID, '10.9'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	where n.Active = 1
	group by n.ProjectID, rpt.ReportID
/*
	10.10	DQ – Adult/HoH Entry
*/
	delete from lsa_Calculated where ReportRow = 911

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 911, n.ProjectID, rpt.ReportID, '10.10'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	where n.Active = 1 
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
	group by n.ProjectID, rpt.ReportID

/*
	10.11	DQ – Client Exit
*/
	delete from lsa_Calculated where ReportRow = 912

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 912, n.ProjectID, rpt.ReportID, '10.11'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.ExitDate <= rpt.ReportEnd
	where n.Active = 1
	group by n.ProjectID, rpt.ReportID
/*
	10.12	DQ – Disabling Condition
*/
	delete from lsa_Calculated where ReportRow = 913

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 913, n.ProjectID, rpt.ReportID, '10.12'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	where n.Active = 1 and n.DisabilityStatus = 99
	group by n.ProjectID, rpt.ReportID
/*
	10.13	DQ – Living Situation
*/
	delete from lsa_Calculated where ReportRow = 914

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 914, n.ProjectID, rpt.ReportID, '10.13'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID 
	where n.Active = 1 
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
		and (hn.LivingSituation in (8,9,99) or hn.LivingSituation is NULL)
	group by n.ProjectID, rpt.ReportID

/*
	10.14	DQ – Length of Stay
*/
	delete from lsa_Calculated where ReportRow = 915

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 915, n.ProjectID, rpt.ReportID, '10.14'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID 
	where n.Active = 1 
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
		and (hn.LengthOfStay in (8,9,99) or hn.LengthOfStay is NULL)
	group by n.ProjectID, rpt.ReportID
/*
	10.15	DQ – Date ES/SH/Street Homelessness Started
*/
	delete from lsa_Calculated where ReportRow = 916

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 916, n.ProjectID, rpt.ReportID, '10.15'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID 
	where n.Active = 1 
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
		and (hn.DateToStreetESSH > hn.EntryDate
		 or (hn.DateToStreetESSH is null 
				and (n.LSAProjectType in (0,1,8)
					 or hn.LivingSituation in (101,116,118)
					 or hn.PreviousStreetESSH = 1
					)
			)
		)	
	group by n.ProjectID, rpt.ReportID
/*
	10.16	DQ – Times ES/SH/Street Homeless Last 3 Years
*/
	delete from lsa_Calculated where ReportRow = 917

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 917, n.ProjectID, rpt.ReportID, '10.16'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID 
	where n.Active = 1 
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
		and (hn.TimesHomelessPastThreeYears is NULL
			or hn.TimesHomelessPastThreeYears not in (1,2,3,4)) 
		and (n.LSAProjectType in (0,1,8)
				or hn.LivingSituation in (101,116,118)
				or hn.PreviousStreetESSH = 1)
	group by n.ProjectID, rpt.ReportID
/*
	10.17	DQ – Months ES/SH/Street Homeless Last 3 Years
*/
	delete from lsa_Calculated where ReportRow = 918

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 918, n.ProjectID, rpt.ReportID, '10.17'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID 
	where n.Active = 1 
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
		and (hn.MonthsHomelessPastThreeYears is NULL
			or hn.MonthsHomelessPastThreeYears not between 101 and 113) 
		and (n.LSAProjectType in (0,1,8)
			or hn.LivingSituation in (101,116,118)
		or hn.PreviousStreetESSH = 1)	
	group by n.ProjectID, rpt.ReportID
/*
	10.18	DQ – Destination 
*/
	delete from lsa_Calculated where ReportRow = 919

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 1, 10, 0, 0, -1, 919, n.ProjectID, rpt.ReportID, '10.18'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.ExitDate <= rpt.ReportEnd
	inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID and x.DateDeleted is null
	where n.Active = 1
		and (x.Destination is NULL or x.Destination in (8,9,17,30,99)
			or (x.Destination = 435 and x.DestinationSubsidyType is NULL))
	group by n.ProjectID, rpt.ReportID
/*
	10.19	DQ – Date of Birth
*/

	delete from lsa_Calculated where ReportRow = 920

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.PersonalID), 1, 10, 0, 0, -1, 920, n.ProjectID, rpt.ReportID, '10.19'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	where n.Active = 1 and n.ActiveAge in (98,99)
	group by n.ProjectID, rpt.ReportID

	/*
		10.20 LSACalculated

		NOTE:  Export of lsa_Calculated data to LSACalculated.csv has to exclude the Step column.

		alter lsa_Calculated drop column Step

		select Value, Cohort, Universe, HHType, Population, SystemPath, ProjectID, ReportRow, ReportID
		from lsa_Calculated
	*/
