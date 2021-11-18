/*
LSA FY2021 Sample Code

Name:  10 LSACalculated Data Quality.sql
Date:  20 AUG 2021


	10.2 Get Counts of Enrollments Active after Operating End Date by ProjectID
*/

	delete from lsa_Calculated  where ReportRow in (58,59)

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 20, 10, 0, 0, -1
		, case when hx.ExitDate is null then 58
			else 59 end 
		, p.ProjectID, cd.ReportID, '10.2'
	from tlsa_Enrollment n
	left outer join hmis_Exit hx on hx.EnrollmentID = n.EnrollmentID 
		and hx.DateDeleted is null
	inner join hmis_Project p on p.ProjectID = n.ProjectID 
	inner join tlsa_CohortDates cd on cd.Cohort = 20 and p.OperatingEndDate between cd.CohortStart and cd.CohortEnd
	where (hx.ExitDate is null or hx.ExitDate > p.OperatingEndDate)
		and p.ProjectType in (1,2,3,8,13)
	group by case when hx.ExitDate is null then 58
			else 59 end 
		, p.ProjectID, cd.ReportID

/*
	10.3 Get Counts of Night-by-Night Enrollments with Exit Date Discrepancies
*/

	delete from lsa_Calculated where ReportRow in (60,61) 

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct hn.EnrollmentID), 20, 10, 0, 0, -1
		, case when hx.ExitDate is null or hx.ExitDate > cd.CohortEnd then 60
			else 61 end 
		, p.ProjectID, cd.ReportID, '10.3'
	from tlsa_Enrollment n
	inner join tlsa_CohortDates cd on cd.Cohort = 20
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID 
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
		and hx.DateDeleted is NULL
	inner join hmis_Project p on p.ProjectID = hn.ProjectID and p.ProjectType = 1 and p.TrackingMethod = 3 and p.ContinuumProject = 1
	left outer join (select distinct svc.EnrollmentID, max(svc.DateProvided) as LastBednight
		from hmis_Services svc
		inner join hmis_Enrollment nbn on nbn.EnrollmentID = svc.EnrollmentID
		inner join hmis_Project p on p.ProjectID = nbn.ProjectID 
			and p.ProjectType = 1 and p.TrackingMethod = 3 
			and (p.OperatingEndDate is null or p.OperatingEndDate >= DateProvided)
		inner join tlsa_CohortDates cd on cd.Cohort = 20 
			and svc.DateProvided between cd.CohortStart and cd.CohortEnd
		where svc.RecordType = 200 and svc.DateDeleted is null
		group by svc.EnrollmentID
		) bn on bn.EnrollmentID = hhid.EnrollmentID
	where ((hx.ExitDate is null or hx.ExitDate > cd.CohortEnd) and bn.LastBednight <= dateadd(dd, -90, cd.CohortEnd))
		or (hx.ExitDate between cd.CohortStart and cd.CohortEnd and hx.ExitDate <> dateadd(dd, 1, bn.LastBednight))
	group by case when hx.ExitDate is null or hx.ExitDate > cd.CohortEnd then 60
			else 61 end 
		, p.ProjectID, cd.ReportID

/*
	10.4 Get Counts of Households with no Enrollment CoC Record
*/

	delete from lsa_Calculated where ReportRow = 62

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct hn.HouseholdID), 1, 10, 0, 0, -1, 62, p.ProjectID, rpt.ReportID, '10.4'
	from lsa_Report rpt
	inner join hmis_Enrollment hn on hn.EntryDate <= rpt.ReportEnd
	inner join lsa_Project p on p.ProjectID = hn.ProjectID and p.ProjectType not in (9,10)
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
		and hx.DateDeleted is null
	left outer join hmis_Enrollment hoh on hoh.HouseholdID = hn.HouseholdID 
		and hoh.RelationshipToHoH = 1 
		and hoh.DateDeleted is null
	left outer join (select distinct coc.EnrollmentID, coc.InformationDate, coc.CoCCode
					from hmis_EnrollmentCoC coc
					where coc.CoCCode is not null
						and coc.DateDeleted is null) coccode on coccode.EnrollmentID = hoh.EnrollmentID 
						and coccode.InformationDate <= rpt.ReportEnd 
	where hn.DateDeleted is null 
		and coccode.CoCCode is null
		and (hx.ExitDate is null or 
				(hx.ExitDate >= rpt.ReportStart and hx.ExitDate > hn.EntryDate))
	group by p.ProjectID, rpt.ReportID

	/*
		10.5 LSACalculated

		NOTE:  Export of lsa_Calculated data to LSACalculated.csv has to exclude the Step column.

		alter lsa_Calculated drop column Step

		select Value, Cohort, Universe, HHType, Population, SystemPath, ProjectID, ReportRow, ReportID
		from lsa_Calculated
	*/