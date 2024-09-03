/*
LSA FY2024 Sample Code
Name:	03_02 to 03_06 HMIS Households and Enrollments.sql 

FY2024 Changes

		3.2 - Set ReportEnd = ReportStart if LSAScope = HIC
			- Set Exit and Point-in-Time Cohort dates only if LSAScope <> HIC
		3.3 - Adjust entry/exit dates to align with period of projects' HMIS participation if the dates conflict
			     and limit reported bednights to periods of HMIS participation

	(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)


	3.2 Cohort Dates 
*/

	if (select LSAScope from lsa_Report) = 3
	begin
		update lsa_Report set ReportEnd = ReportStart
	end -- END IF LSAScope = HIC

	truncate table tlsa_CohortDates

	insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, LookbackDate, ReportID)
	select 1, rpt.ReportStart, rpt.ReportEnd, rpt.LookbackDate, rpt.ReportID
	from lsa_Report rpt

	if (select LSAScope from lsa_Report) <> 3
	begin
	
		insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, LookbackDate, ReportID)
		select 0, rpt.ReportStart,
			case when dateadd(mm, -6, rpt.ReportEnd) <= rpt.ReportStart 
				then rpt.ReportEnd
				else dateadd(mm, -6, rpt.ReportEnd) end
			, rpt.LookbackDate
			, rpt.ReportID
		from lsa_Report rpt

		insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, LookbackDate, ReportID)
		select -1, dateadd(yyyy, -1, rpt.ReportStart)
			, dateadd(yyyy, -1, rpt.ReportEnd)
			, rpt.LookbackDate
			, rpt.ReportID
		from lsa_Report rpt

		insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, LookbackDate, ReportID)
		select -2, dateadd(yyyy, -2, rpt.ReportStart)
			, dateadd(yyyy, -2, rpt.ReportEnd)
			, rpt.LookbackDate
			, rpt.ReportID
		from lsa_Report rpt

		insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, LookbackDate, ReportID)
		select distinct case cal.mm 
			when 10 then 10
			when 1 then 11 
			when 4 then 12 
			else 13 end
			, cal.theDate
			, cal.theDate
			, rpt.LookbackDate
			, rpt.ReportID
		from lsa_Report rpt 
		inner join ref_Calendar cal 
			on cal.theDate between rpt.ReportStart and rpt.ReportEnd
		where (cal.mm = 10 and cal.dd = 31 and cal.yyyy = year(rpt.ReportStart))
			or (cal.mm = 1 and cal.dd = 31 and cal.yyyy = year(rpt.ReportEnd))
			or (cal.mm = 4 and cal.dd = 30 and cal.yyyy = year(rpt.ReportEnd))
			or (cal.mm = 7 and cal.dd = 31 and cal.yyyy = year(rpt.ReportEnd))

	end -- END IF LSASCOPE <> HIC
	

/*
	3.3 HMIS HouseholdIDs 
*/
truncate table tlsa_HHID
-- Note:  Code here and elsewhere 
			-- Uses LSAProjectType = 13 when ProjectType = 13 and RRHSubType = 2 (RRH: Housing with or without services)	
--				and LSAProjectType = 15 when ProjectType = 13 and RRHSubType = 1 (RRH: Services Only)
			-- When RRH MoveInDate = ExitDate, uses an effective ExitDate of MoveIn + 1 day so that subsequent
--				sections can use the same logic for RRH and PSH.

insert into tlsa_HHID (
	  HouseholdID, HoHID, EnrollmentID
	, ProjectID, LSAProjectType
	, EntryDate
	, MoveInDate
	, ExitDate
	, LastBedNight
	, Step)
select distinct hoh.HouseholdID, hoh.PersonalID, hoh.EnrollmentID
	, hoh.ProjectID, p.LSAProjectType
	, case when hoh.EntryDate < bn.FirstBednight then bn.FirstBednight
		when hoh.EntryDate < part.HMISParticipationStatusStartDate then part.HMISParticipationStatusStartDate
		else hoh.EntryDate end
	, case when hoh.MoveInDate > rpt.ReportEnd 
			or p.LSAProjectType not in (3,13,15) 
			or hoh.MoveInDate < hoh.EntryDate 
			or hoh.MoveInDate > p.OperatingEndDate 
			or hoh.MoveInDate >= part.HMISParticipationStatusEndDate
		    then null
		when hoh.MoveInDate < part.HMISParticipationStatusStartDate then part.HMISParticipationStatusStartDate
		when p.LSAProjectType = 3 and (hoh.MoveInDate < hx.ExitDate or hx.ExitDate is null)  
			then hoh.MoveInDate
		when p.LSAProjectType in (13,15) and (hoh.MoveInDate <= hx.ExitDate or hx.ExitDate is null) 
		    then hoh.MoveInDate
		else null end
	, case when p.LSAProjectType = 1 
				and dateadd(dd, 1, bn.LastBednight) >= p.OperatingEndDate then p.OperatingEndDate
	    when p.LSAProjectType = 1 and hx.ExitDate > dateadd(dd, 1, bn.LastBednight)
			then dateadd(dd, 1, bn.LastBednight)
		when p.LSAProjectType = 1 and hx.ExitDate is null 
			and dateadd(dd, 90, bn.LastBednight) <= rpt.ReportEnd then dateadd(dd, 1, bn.LastBednight) 
		when part.HMISParticipationStatusEndDate < hx.ExitDate and part.HMISParticipationStatusEndDate < rpt.ReportEnd then part.HMISParticipationStatusEndDate
		when p.OperatingEndDate <= rpt.ReportEnd and hx.ExitDate is null then p.OperatingEndDate
		when p.LSAProjectType in (13,15) and hoh.MoveInDate = hx.ExitDate and hx.ExitDate = rpt.ReportEnd then NULL
		when p.LSAProjectType in (13,15) and hoh.MoveInDate = hx.ExitDate then dateadd(dd, 1, hx.ExitDate)
		else hx.ExitDate end
	, bn.LastBednight
	, '3.3.1'
from hmis_Enrollment hoh
inner join lsa_Report rpt on rpt.ReportEnd >= hoh.EntryDate and rpt.ReportCoC = hoh.EnrollmentCoC
inner join (select hp.ProjectID
			,  case when hp.ProjectType = 13 and hp.RRHSubType = 1 then 15
						else hp.ProjectType end as LSAProjectType, 
					hp.OperatingStartDate, hp.OperatingEndDate
				from hmis_Project hp
				inner join hmis_Organization ho on ho.OrganizationID = hp.OrganizationID
				inner join tlsa_CohortDates cd on cd.Cohort = 1
				where hp.DateDeleted is null
					and hp.ContinuumProject = 1 
					and (hp.ProjectType <> 13 or hp.RRHSubType in (1,2))
					and hp.OperatingStartDate <= cd.CohortEnd
					and (hp.OperatingEndDate is null 
						or (hp.OperatingEndDate > hp.OperatingStartDate and hp.OperatingEndDate >= cd.LookbackDate))
			) p on p.ProjectID = hoh.ProjectID
-- Enrollments must be active (no exit date) or exited during the relevant period 
left outer join hmis_Exit hx on hx.EnrollmentID = hoh.EnrollmentID
	and hx.ExitDate <= rpt.ReportEnd 
	and (hx.ExitDate <= p.OperatingEndDate or p.OperatingEndDate is null)
	and hx.DateDeleted is null
-- Some part of the enrollment must occur during a period of HMIS participation for the project
inner join hmis_HMISParticipation part on part.ProjectID = hoh.ProjectID 
left outer join hmis_Enrollment hohCheck on hohCheck.HouseholdID = hoh.HouseholdID
	and hohCheck.RelationshipToHoH = 1 and hohCheck.EnrollmentID <> hoh.EnrollmentID
	and hohCheck.DateDeleted is null
left outer join (select distinct svc.EnrollmentID, min(svc.DateProvided) as FirstBednight, max(svc.DateProvided) as LastBednight
		from hmis_Services svc
		inner join hmis_Enrollment nbn on nbn.EnrollmentID = svc.EnrollmentID
		left outer join hmis_Exit nbnx on nbnx.EnrollmentID = nbn.EnrollmentID
		inner join hmis_Project p on p.ProjectID = nbn.ProjectID 
			and p.ProjectType = 1 
			and (p.OperatingEndDate is null or p.OperatingEndDate > DateProvided)
		inner join lsa_Report rpt on svc.DateProvided between rpt.LookbackDate and rpt.ReportEnd
		inner join hmis_HMISParticipation part on part.ProjectID = p.ProjectID 
			and part.HMISParticipationType = 1
			and svc.DateProvided >= part.HMISParticipationStatusStartDate 
			and (svc.DateProvided < part.HMISParticipationStatusEndDate or part.HMISParticipationStatusEndDate is null)
		where svc.RecordType = 200 and svc.DateDeleted is null
			and svc.DateProvided >= nbn.EntryDate 
			and (nbnx.ExitDate is null or svc.DateProvided < nbnx.ExitDate)
		group by svc.EnrollmentID
		) bn on bn.EnrollmentID = hoh.EnrollmentID
where hoh.DateDeleted is null
	and hoh.RelationshipToHoH = 1
	and hohCheck.EnrollmentID is null 
	and (hoh.EntryDate < p.OperatingEndDate or p.OperatingEndDate is null)
	and	(hx.ExitDate is null or 
			(hx.ExitDate >= rpt.LookbackDate and hx.ExitDate > hoh.EntryDate) 
		)
	and (p.LSAProjectType in (0,2,3,8,13,15)
   		or (p.LSAProjectType = 1 and bn.LastBednight is not null)
		)
	and part.HMISParticipationID = (select top 1 hp1.HMISParticipationID 
			from hmis_HMISParticipation hp1
			where hp1.ProjectID = hoh.ProjectID 
				and hp1.HMISParticipationType = 1 
				and (hoh.EntryDate <= hp1.HMISParticipationStatusEndDate or hp1.HMISParticipationStatusEndDate is null)
				and (hx.ExitDate > hp1.HMISParticipationStatusStartDate or hx.ExitDate is null)
				and hp1.DateDeleted is null
			order by hp1.HMISParticipationStatusStartDate desc)

		update hhid
		set hhid.ExitDest = case	
				when hhid.ExitDate is null then -1
				when hx.Destination is null or 
					hx.Destination in (17,30,99) or
					(hx.ExitDate <> hhid.ExitDate 
						and (hhid.MoveInDate is NULL or hhid.MoveInDate <> hx.ExitDate)) then 99
				when hx.Destination in (8,9) then 98
				when hx.Destination = 435 and hx.DestinationSubsidyType is null then 99
				when hx.Destination = 435 then hx.DestinationSubsidyType 
				else hx.Destination	end
			, hhid.Step = '3.3.2'
		from tlsa_HHID hhid
		left outer join hmis_Exit hx on hx.EnrollmentID = hhid.EnrollmentID
			and hx.DateDeleted is null 

/*
	3.4  HMIS Client Enrollments 
*/
	truncate table tlsa_Enrollment

	--all project types except ES night-by-night
	insert into tlsa_Enrollment 
		(EnrollmentID, PersonalID, HouseholdID
		, RelationshipToHoH
		, ProjectID, LSAProjectType
		, EntryDate, ExitDate
		, DisabilityStatus
		, Step)
	select distinct hn.EnrollmentID, hn.PersonalID, hn.HouseholdID
		, hn.RelationshipToHoH
		, hhid.ProjectID, hhid.LSAProjectType
		, case when hhid.EntryDate > hn.EntryDate then hhid.EntryDate else hn.EntryDate end
		, case when hx.ExitDate >= hhid.ExitDate then hhid.ExitDate
			when hx.ExitDate is NULL and hhid.ExitDate is not NULL then hhid.ExitDate
			when hhid.LSAProjectType in (13,15) and hhid.MoveInDate = hx.ExitDate and hx.ExitDate = rpt.ReportEnd then NULL
			when hhid.LSAProjectType in (13,15) and hhid.MoveInDate = hx.ExitDate then dateadd(dd, 1, hx.ExitDate)
			else hx.ExitDate end
		, case when hn.DisablingCondition in (0,1) then hn.DisablingCondition 
			else null end
		, '3.4.1'
	from tlsa_HHID hhid
	inner join hmis_Enrollment hn on hn.HouseholdID = hhid.HouseholdID
		and hn.DateDeleted is NULL
	inner join lsa_Report rpt on rpt.ReportEnd >= hn.EntryDate
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID	
		and hx.ExitDate <= rpt.ReportEnd
		and hx.DateDeleted is null
	where hhid.LSAProjectType in (0,2,3,8,13,15) 
		and hn.RelationshipToHoH in (1,2,3,4,5)
		and hn.EntryDate <= isnull(hhid.ExitDate, rpt.ReportEnd)
		and (hx.ExitDate is null or 
				(hx.ExitDate > hhid.EntryDate and hx.ExitDate >= rpt.LookbackDate
					and hx.ExitDate > hn.EntryDate)) 

	-- ES night-by-night
	insert into tlsa_Enrollment 
		(EnrollmentID, PersonalID, HouseholdID
		, RelationshipToHoH
		, ProjectID, LSAProjectType
		, EntryDate, ExitDate
		, LastBednight
		, DisabilityStatus
		, Step)
	select distinct svc.EnrollmentID, nbn.PersonalID, nbn.HouseholdID
		, nbn.RelationshipToHoH
		, hhid.ProjectID, hhid.LSAProjectType
		, min(svc.DateProvided) as EntryDate
		, case when nbnx.ExitDate is null and hhid.ExitDate is null and dateadd(dd, 90, max(svc.DateProvided)) > rpt.ReportEnd then null
			else dateadd(dd, 1, max(svc.DateProvided)) end as ExitDate				
		, max(svc.DateProvided) as LastBednight
		, case when nbn.DisablingCondition in (0,1) then nbn.DisablingCondition else null end
		, '3.4.2'
	from hmis_Services svc
	inner join hmis_Enrollment nbn on nbn.EnrollmentID = svc.EnrollmentID and svc.DateProvided >= nbn.EntryDate
		and nbn.DateDeleted is null
	inner join tlsa_HHID hhid on hhid.HouseholdID = nbn.HouseholdID and svc.DateProvided >= hhid.EntryDate 
		and (hhid.ExitDate is null or svc.DateProvided < hhid.ExitDate)
	left outer join hmis_Exit nbnx on nbnx.EnrollmentID = nbn.EnrollmentID and nbnx.DateDeleted is null
	inner join lsa_Report rpt on svc.DateProvided between rpt.LookbackDate and rpt.ReportEnd
	where hhid.LSAProjectType = 1 
		and svc.RecordType = 200 and svc.DateDeleted is null
		and svc.DateProvided >= nbn.EntryDate 
		and (nbnx.ExitDate is null or svc.DateProvided < nbnx.ExitDate)
		and nbn.RelationshipToHoH in (1,2,3,4,5)
	group by svc.EnrollmentID, nbn.PersonalID, nbn.HouseholdID
		, nbn.RelationshipToHoH
		, hhid.ProjectID, hhid.LSAProjectType
		, case when nbn.DisablingCondition in (0,1) then nbn.DisablingCondition else null end
		, nbnx.ExitDate, hhid.ExitDate, rpt.ReportEnd


	update n 
	set n.MoveInDate = 	case when hhid.MoveInDate < n.EntryDate then n.EntryDate
			when hhid.MoveInDate > n.ExitDate then NULL
			when hhid.MoveInDate = n.ExitDate and 
				(hhid.ExitDate is NULL or hhid.ExitDate > n.ExitDate) then NULL
			else hhid.MoveInDate end 
		, Step = '3.4.3'
	from tlsa_Enrollment n
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID and hhid.LSAProjectType in (3,13,15)

	update n
	set n.DVStatus = dv.DVStat 
		, n.Step = '3.4.4'
	from tlsa_Enrollment n
	left outer join (select dv.EnrollmentID,
		min(case when dv.DomesticViolenceSurvivor = 1 and dv.CurrentlyFleeing = 1 then 1
		when dv.DomesticViolenceSurvivor = 1 and dv.CurrentlyFleeing = 0 then 2
		when dv.DomesticViolenceSurvivor = 1 then 3
		when dv.DomesticViolenceSurvivor = 0 then 10
		else 98 end) as DVStat
		from hmis_HealthAndDV dv
		inner join lsa_Report rpt on rpt.ReportEnd >=  dv.InformationDate
		inner join tlsa_Enrollment n on n.EnrollmentID = dv.EnrollmentID and dv.InformationDate >= n.EntryDate 
			and (n.ExitDate is null or dv.InformationDate <= n.ExitDate)
		group by dv.EnrollmentID) dv on n.EnrollmentID = dv.EnrollmentID

/*
	3.5 Enrollment Ages - Active and Exit
		NOTE:  EntryAge is included in the 3.4 insert statement
*/

	update n
	set n.EntryAge = case when c.DOBDataQuality in (8,9) then 98
				when c.DOB is null 
					or c.DOB = '1/1/1900'
					or c.DOB > n.EntryDate
					or (n.RelationshipToHoH = 1 and c.DOB = n.EntryDate)
					or DATEADD(yy, 105, c.DOB) <= n.EntryDate 
					or c.DOBDataQuality is null
					or c.DOBDataQuality not in (1,2) then 99
				when DATEADD(yy, 65, c.DOB) <= n.EntryDate then 65
				when DATEADD(yy, 55, c.DOB) <= n.EntryDate then 64
				when DATEADD(yy, 45, c.DOB) <= n.EntryDate then 54
				when DATEADD(yy, 35, c.DOB) <= n.EntryDate then 44
				when DATEADD(yy, 25, c.DOB) <= n.EntryDate then 34
				when DATEADD(yy, 22, c.DOB) <= n.EntryDate then 24
				when DATEADD(yy, 18, c.DOB) <= n.EntryDate then 21
				when DATEADD(yy, 6, c.DOB) <= n.EntryDate then 17
				when DATEADD(yy, 3, c.DOB) <= n.EntryDate then 5
				when DATEADD(yy, 1, c.DOB) <= n.EntryDate then 2
				else 0 end 	
		, n.Step = '3.5.1'
	from tlsa_Enrollment n
	inner join hmis_Client c on c.PersonalID = n.PersonalID

	update n
	set n.EntryAge = 99, n.Step = '3.5.2'
	from tlsa_Enrollment n
	inner join tlsa_Enrollment DOBIssue on DOBIssue.PersonalID = n.PersonalID
		and DOBIssue.EntryAge = 99

	update n
	set n.ActiveAge = case when n.ExitDate < rpt.ReportStart
				or n.EntryDate >= rpt.ReportStart 
				or n.EntryAge in (98,99) then n.EntryAge
			when DATEADD(yy, 65, c.DOB) <= rpt.ReportStart then 65
			when DATEADD(yy, 55, c.DOB) <= rpt.ReportStart then 64
			when DATEADD(yy, 45, c.DOB) <= rpt.ReportStart then 54
			when DATEADD(yy, 35, c.DOB) <= rpt.ReportStart then 44
			when DATEADD(yy, 25, c.DOB) <= rpt.ReportStart then 34
			when DATEADD(yy, 22, c.DOB) <= rpt.ReportStart then 24
			when DATEADD(yy, 18, c.DOB) <= rpt.ReportStart then 21
			when DATEADD(yy, 6, c.DOB) <= rpt.ReportStart then 17
			when DATEADD(yy, 3, c.DOB) <= rpt.ReportStart then 5
			when DATEADD(yy, 1, c.DOB) <= rpt.ReportStart then 2
			else 0 end 		
		, n.Step = '3.5.3'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd 
	inner join hmis_Client c on c.PersonalID = n.PersonalID

	update n
	set n.Exit1Age = case when n.EntryDate >= cd.CohortStart
				or (n.ExitDate not between cd.CohortStart and cd.CohortEnd or n.ExitDate is null)
				or n.EntryAge in (98,99) then n.EntryAge
			when DATEADD(yy, 65, c.DOB) <= cd.CohortStart then 65
			when DATEADD(yy, 55, c.DOB) <= cd.CohortStart then 64
			when DATEADD(yy, 45, c.DOB) <= cd.CohortStart then 54
			when DATEADD(yy, 35, c.DOB) <= cd.CohortStart then 44
			when DATEADD(yy, 25, c.DOB) <= cd.CohortStart then 34
			when DATEADD(yy, 22, c.DOB) <= cd.CohortStart then 24
			when DATEADD(yy, 18, c.DOB) <= cd.CohortStart then 21
			when DATEADD(yy, 6, c.DOB) <= cd.CohortStart then 17
			when DATEADD(yy, 3, c.DOB) <= cd.CohortStart then 5
			when DATEADD(yy, 1, c.DOB) <= cd.CohortStart then 2
			else 0 end 				
		, n.Step = '3.5.4'
	from  tlsa_Enrollment n
	inner join tlsa_CohortDates cd on cd.Cohort = -1 
	inner join hmis_Client c on c.PersonalID = n.PersonalID

	update n
	set n.Exit2Age = case when n.EntryDate >= cd.CohortStart
				or (n.ExitDate not between cd.CohortStart and cd.CohortEnd or n.ExitDate is null)
				or n.EntryAge in (98,99) then n.EntryAge 
			when DATEADD(yy, 65, c.DOB) <= cd.CohortStart then 65
			when DATEADD(yy, 55, c.DOB) <= cd.CohortStart then 64
			when DATEADD(yy, 45, c.DOB) <= cd.CohortStart then 54
			when DATEADD(yy, 35, c.DOB) <= cd.CohortStart then 44
			when DATEADD(yy, 25, c.DOB) <= cd.CohortStart then 34
			when DATEADD(yy, 22, c.DOB) <= cd.CohortStart then 24
			when DATEADD(yy, 18, c.DOB) <= cd.CohortStart then 21
			when DATEADD(yy, 6, c.DOB) <= cd.CohortStart then 17
			when DATEADD(yy, 3, c.DOB) <= cd.CohortStart then 5
			when DATEADD(yy, 1, c.DOB) <= cd.CohortStart then 2
			else 0 end 				
		, n.Step = '3.5.5'
	from  tlsa_Enrollment n
	inner join tlsa_CohortDates cd on cd.Cohort = -2 
	inner join hmis_Client c on c.PersonalID = n.PersonalID

	--NOTE:  The logic for HIV/SMI/SUD columns is described in specs section 5.4; this is occurring in the code here 
	--       because it made a massive difference in the speed with which the code in section 5.4 runs.
	update n
	set n.HIV = 1, n.Step = '3.4.5'
	from tlsa_Enrollment n
	inner join hmis_Disabilities d on d.EnrollmentID = n.EnrollmentID and d.DisabilityType = 8 and d.DisabilityResponse = 1
	where n.ActiveAge between 18 and 65 and d.InformationDate <= (select ReportEnd from lsa_Report) 

	update n
	set n.SMI = 1, n.Step = '3.4.6'
	from tlsa_Enrollment n
	inner join hmis_Disabilities d on d.EnrollmentID = n.EnrollmentID and d.DisabilityType = 9 and d.DisabilityResponse = 1
		and d.IndefiniteAndImpairs = 1
	where n.ActiveAge between 18 and 65 and d.InformationDate <= (select ReportEnd from lsa_Report) 

	update n
	set n.SUD = 1, n.Step = '3.4.7'
	from tlsa_Enrollment n
	inner join hmis_Disabilities d on d.EnrollmentID = n.EnrollmentID and d.DisabilityType = 10 and d.DisabilityResponse in (1,2,3)
		and d.IndefiniteAndImpairs = 1
	where n.ActiveAge between 18 and 65 and d.InformationDate <= (select ReportEnd from lsa_Report) 


/*
	3.6 Household Types
*/

-- Note:  Code here and elsewhere uses 'between 18 and 65' instead of 'between 21 and 65' because the output
--        is the same (there are no values of 18, 19, or 20) and it is easier to understand without consulting 
--		  the LSA Dictionary.
	update hhid
	set hhid.EntryHHType = case 
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is null
				and noDOB.EnrollmentID is null then 1
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is not null then 2
			when adult.EnrollmentID is null 
				and child.EnrollmentID is not null
				and noDOB.EnrollmentID is null then 3	
			else 99 end
		, hhid.Step = '3.6.1'
	from tlsa_HHID hhid 
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.EntryAge between 18 and 65
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.EntryAge < 18
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.EntryAge in (98,99)

	update hhid
	set hhid.ActiveHHType = case 
			when hhid.ExitDate < rpt.ReportStart 
				or hhid.EntryDate >= rpt.ReportStart then hhid.EntryHHType
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is null
				and noDOB.EnrollmentID is null then 1
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is not null then 2
			when adult.EnrollmentID is null 
				and child.EnrollmentID is not null
				and noDOB.EnrollmentID is null then 3	
			else 99 end
		, hhid.Step = '3.6.2'
	from tlsa_HHID hhid 
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate 
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.ActiveAge between 18 and 65
		and (adult.ExitDate is null or adult.ExitDate >= rpt.ReportStart)
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.ActiveAge < 18
		and (child.ExitDate is null or child.ExitDate >= rpt.ReportStart)
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.ActiveAge in (98,99)
		and (noDOB.ExitDate is null or noDOB.ExitDate >= rpt.ReportStart)

	update hhid
	set hhid.Exit1HHType = case 
			when hhid.ExitDate < cd.CohortStart 
				or hhid.EntryDate >= cd.CohortStart then hhid.EntryHHType 
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is null
				and noDOB.EnrollmentID is null then 1
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is not null then 2
			when adult.EnrollmentID is null 
				and child.EnrollmentID is not null
				and noDOB.EnrollmentID is null then 3	
			else 99 end
		, hhid.Step = '3.6.3'
	from tlsa_HHID hhid
	inner join tlsa_CohortDates cd on cd.CohortEnd <> hhid.EntryDate and cd.Cohort = -1
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.Exit1Age between 18 and 65 and adult.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.Exit1Age < 18 and child.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.Exit1Age in (98,99) and noDOB.ExitDate between cd.CohortStart and cd.CohortEnd

	update hhid
	set hhid.Exit2HHType = case 
			when hhid.ExitDate < cd.CohortStart 
				or hhid.EntryDate >= cd.CohortStart then hhid.EntryHHType 
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is null
				and noDOB.EnrollmentID is null then 1
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is not null then 2
			when adult.EnrollmentID is null 
				and child.EnrollmentID is not null
				and noDOB.EnrollmentID is null then 3	
			else 99 end
		, hhid.Step = '3.6.4'
	from tlsa_HHID hhid
	inner join tlsa_CohortDates cd on cd.CohortEnd <> hhid.EntryDate and cd.Cohort = -2
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.Exit2Age between 18 and 65 and adult.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.Exit2Age < 18 and child.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.Exit2Age in (98,99) and noDOB.ExitDate between cd.CohortStart and cd.CohortEnd
