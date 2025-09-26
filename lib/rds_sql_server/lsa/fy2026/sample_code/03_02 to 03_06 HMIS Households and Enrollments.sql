/*
LSA Sample Code
03_02 to 03_06 HMIS Households and Enrollments.sql 
https://github.com/HMIS/LSASampleCode
Last update: 8/7/2025

Source: LSA Programming Specifications v7 
	3.2.	LSA Reporting Cohorts and Dates (tlsa_CohortDates)
	3.3.	HMIS Household Enrollments (tlsa_HHID)
	3.4.	HMIS Client Enrollments (tlsa_Enrollment)		
	3.5.	Enrollment Ages (tlsa_Enrollment)
	3.6.	Household Types (tlsa_HHID)
	5.4		LSAPerson Demographics (HIV, SMI, and SUD)

*/


/*
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

insert into tlsa_HHID (
	  HouseholdID, HoHID, EnrollmentID
	, ProjectID, LSAProjectType
	, EntryDate
	, MoveInDate
	, ExitDate
	, LastBedNight
	, Step)
select 	
	HouseholdID, HoHID, EnrollmentID, ProjectID, LSAProjectType
	, case 
		-- nbn EntryDate must = FirstBedNight
		when LSAProjectType = 1 then FirstBedNight
		-- no adjustment as long as the entry date occurs while the project is operating & participating in HMIS
		when EntryDate >= pStart then EntryDate
		-- otherwise, adjust to the later of HMIS/OperatingStart
		else pStart end
	, case 
		-- select null if recorded Move-In Date is null, not relevant, or not valid
		when core.MoveInDate is null
			or core.MoveInDate > rpt.ReportEnd 
			or LSAProjectType not in (3,13,15) 
			or core.MoveInDate < EntryDate 
			or core.MoveInDate >= pEnd 
			or core.MoveInDate > ExitDate
			or (core.MoveInDate = ExitDate and LSAProjectType = 3)
			then null
		-- no adjustment as long as the valid MoveInDate occurs while the project is operating & participating in HMIS
		when core.MoveInDate >= pStart then core.MoveInDate
		else pStart end
	, case 
		when LSAProjectType = 1 and LastBednight = rpt.ReportEnd then null
		when LSAProjectType = 1 and ExitDate < rpt.ReportEnd then dateadd(dd, 1, LastBednight)
		when dateadd(dd, 90, LastBednight) <= rpt.ReportEnd then dateadd(dd, 1, LastBednight)
		-- When RRH MoveInDate = ExitDate, uses an effective ExitDate of MoveIn + 1 day so that subsequent
		--	sections can use the same logic for RRH and PSH.
		when LSAProjectType in (13,15) and core.MoveInDate = ExitDate and (pEnd is null or core.MoveInDate < pEnd) and ExitDate = rpt.ReportEnd then NULL
		when LSAProjectType in (13,15) and core.MoveInDate = ExitDate and (pEnd is null or core.MoveInDate < pEnd) and ExitDate < rpt.ReportEnd then dateadd(dd, 1, ExitDate)
		when pEnd is not null and (ExitDate is null or ExitDate >= pEnd) then pEnd   
		when ExitDate > rpt.ReportEnd then null
		else ExitDate end 
	, LastBednight
	, '3.3.1'
from
lsa_Report rpt
inner join 
	(select hoh.HouseholdID, hoh.PersonalID as HoHID, hoh.EnrollmentID
		, hoh.ProjectID, p.LSAProjectType
		, hoh.EntryDate, hoh.MoveInDate, hx.ExitDate, min(bn.BedNightDate) as FirstBedNight, max(bn.BedNightDate) as LastBedNight
		, case when part.HMISStart >= p.OperatingStart then part.HMISStart
			else p.OperatingStart end as pStart 
		, case when part.HMISEnd <= p.OperatingEnd or (part.HMISEnd is not null and p.OperatingEnd is null) then part.HMISEnd
			when part.HMISEnd > p.OperatingEnd or (part.HMISEnd is null and p.OperatingEnd is not null) then p.OperatingEnd 
			else null end as pEnd
		, rpt.LookbackDate, rpt.ReportEnd
	from hmis_Enrollment hoh
	inner join lsa_Report rpt on rpt.ReportEnd >= hoh.EntryDate and rpt.ReportCoC = hoh.EnrollmentCoC
	inner join (
		select hp.ProjectID
			-- Code here and elsewhere 
			-- Uses LSAProjectType = 13 when ProjectType = 13 and RRHSubType = 2 (RRH: Housing with or without services)	
			--	and LSAProjectType = 15 when ProjectType = 13 and RRHSubType = 1 (RRH: Services Only)
			, case when hp.ProjectType = 13 and hp.RRHSubType = 1 then 15 else hp.ProjectType end as LSAProjectType 
			, hp.OperatingStartDate as OperatingStart
			-- Selecting null if Operating End > Cohort End so not necessary to specify over and over again 
			-- "OperatingEndDate is null or OperatingEndDate > ReportEnd"  
			, case when hp.OperatingEndDate <= cd.CohortEnd then hp.OperatingEndDate else null end as OperatingEnd
		from hmis_Project hp
		inner join hmis_Organization ho on ho.OrganizationID = hp.OrganizationID
		inner join tlsa_CohortDates cd on cd.Cohort = 1
		where hp.DateDeleted is null
			and hp.ContinuumProject = 1 
			and ho.VictimServiceProvider = 0
			and hp.ProjectType in (0,1,2,3,8,13)
			and (hp.ProjectType <> 13 or hp.RRHSubType in (1,2))
			and hp.OperatingStartDate <= cd.CohortEnd
			and (hp.OperatingEndDate is null 
				or (hp.OperatingEndDate > hp.OperatingStartDate and hp.OperatingEndDate > cd.LookbackDate))
			) p on p.ProjectID = hoh.ProjectID
	-- Some part of the enrollment must occur during a period of HMIS participation for the project
	inner join (
		select hp.HMISParticipationID, hp.ProjectID, hp.HMISParticipationStatusStartDate as HMISStart 
			-- Selecting null if HMIS End > Cohort End so not necessary to specify over and over again 
			-- "HMISParticipationStatusEndDate is null or HMISParticipationStatusEndDate > ReportEnd"  
			-- Also using HMISStart and HMISEnd aliases for obvious reasons
			, case when hp.HMISParticipationStatusEndDate > (select ReportEnd from lsa_Report) then null else hp.HMISParticipationStatusEndDate end as HMISEnd
		from hmis_HMISParticipation hp
		) part on part.ProjectID = hoh.ProjectID 
	left outer join hmis_Exit hx on hx.EnrollmentID = hoh.EnrollmentID
		and (hx.ExitDate <= p.OperatingEnd or p.OperatingEnd is null)
		and (hx.ExitDate <= part.HMISEnd or part.HMISEnd is null)
		and hx.DateDeleted is null
	left outer join hmis_Enrollment hohCheck on hohCheck.HouseholdID = hoh.HouseholdID
		and hohCheck.RelationshipToHoH = 1 and hohCheck.EnrollmentID <> hoh.EnrollmentID
		and hohCheck.DateDeleted is null
	left outer join (select svc.EnrollmentID, svc.DateProvided as BedNightDate
		from hmis_Services svc
		where svc.RecordType = 200 and svc.DateDeleted is null
		) bn on bn.EnrollmentID = hoh.EnrollmentID and p.LSAProjectType = 1 
			and bn.BedNightDate >= part.HMISStart 
			and bn.BedNightDate >= p.OperatingStart
			and bn.BedNightDate >= rpt.LookbackDate
			and bn.BedNightDate >= hoh.EntryDate
			and bn.BedNightDate <= rpt.ReportEnd  
			and (bn.BedNightDate < hx.ExitDate or hx.ExitDate is null)
			and (bn.BedNightDate < part.HMISEnd or part.HMISEnd is null)
			and (bn.BedNightDate < p.OperatingEnd or p.OperatingEnd is null)
	where hoh.DateDeleted is null
		and hoh.RelationshipToHoH = 1
		and hohCheck.EnrollmentID is null 
		and (hoh.EntryDate < p.OperatingEnd or p.OperatingEnd is null)
		and	(hx.ExitDate is null or 
				(	hx.ExitDate > rpt.LookbackDate 
					and hx.ExitDate > hoh.EntryDate
					and hx.ExitDate > p.OperatingStart 
					and hx.ExitDate > part.HMISStart
				)
			)
		and part.HMISParticipationID = (select top 1 hp1.HMISParticipationID 
				from hmis_HMISParticipation hp1
				where hp1.ProjectID = hoh.ProjectID 
					and hp1.HMISParticipationType = 1 
					and (hp1.HMISParticipationStatusEndDate is null
						or (hp1.HMISParticipationStatusEndDate > (select LookbackDate from lsa_Report) and hp1.HMISParticipationStatusEndDate > hoh.EntryDate)
						)
					and hp1.HMISParticipationStatusStartDate <= (select ReportEnd from lsa_Report)
					and (hx.ExitDate > hp1.HMISParticipationStatusStartDate or hx.ExitDate is null)
					and hp1.DateDeleted is null
				order by hp1.HMISParticipationStatusStartDate desc)
	group by hoh.HouseholdID, hoh.PersonalID, hoh.EnrollmentID
		, hoh.ProjectID, p.LSAProjectType
		, hoh.EntryDate, hoh.MoveInDate, hx.ExitDate
		, part.HMISStart, part.HMISEnd, p.OperatingStart, p.OperatingEnd
		, rpt.LookbackDate, rpt.ReportEnd
		) core on core.EntryDate <= rpt.ReportEnd
where core.LSAProjectType <> 1 or core.LastBedNight is not null

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
				(hx.ExitDate > hhid.EntryDate and hx.ExitDate > rpt.LookbackDate
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
		and svc.DateProvided >= rpt.LookbackDate 
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
	set n.HIV = 1, n.Step = '3.5.6'
	from tlsa_Enrollment n
	inner join hmis_Disabilities d on d.EnrollmentID = n.EnrollmentID and d.DisabilityType = 8 and d.DisabilityResponse = 1
	where n.ActiveAge between 18 and 65 and d.InformationDate <= (select ReportEnd from lsa_Report) 

	update n
	set n.SMI = 1, n.Step = '3.5.7'
	from tlsa_Enrollment n
	inner join hmis_Disabilities d on d.EnrollmentID = n.EnrollmentID and d.DisabilityType = 9 and d.DisabilityResponse = 1
		and d.IndefiniteAndImpairs = 1
	where n.ActiveAge between 18 and 65 and d.InformationDate <= (select ReportEnd from lsa_Report) 

	update n
	set n.SUD = 1, n.Step = '3.5.8'
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
set hhid.EntryHHType = case when hh.hh = 100 then 1
		when hh.hh in (110, 111) then 2
		when hh.hh = 10 then 3
		else 99 end
	, hhid.Step = '3.6.1'
from tlsa_HHID hhid 
inner join (select HouseholdID
	, sum(distinct case when n.EntryAge between 18 and 65 then 100 
		when n.EntryAge < 18 then 10 
		else 1 end) as hh
		from tlsa_Enrollment n
		group by HouseholdID) hh on hh.HouseholdID = hhid.HouseholdID


update hhid
set hhid.ActiveHHType = case when hhid.ExitDate < cd.CohortStart 
		or hhid.EntryDate >= cd.CohortStart then hhid.EntryHHType 
		when hh.hh = 100 then 1
		when hh.hh in (110, 111) then 2
		when hh.hh = 10 then 3
		else 99 end
	, hhid.Step = '3.6.2'
from tlsa_HHID hhid 
inner join tlsa_CohortDates cd on cd.Cohort = 1
left outer join (select HouseholdID
	, sum(distinct case when n.ActiveAge between 18 and 65 then 100 
		when n.ActiveAge < 18 then 10 
		else 1 end) as hh
		from tlsa_Enrollment n
		inner join tlsa_CohortDates cd on cd.Cohort = 1
		where n.ExitDate is null or n.ExitDate >= cd.CohortStart
		group by HouseholdID) hh on hh.HouseholdID = hhid.HouseholdID

update hhid
set hhid.Exit1HHType = case when hhid.ExitDate < cd.CohortStart 
		or hhid.EntryDate >= cd.CohortStart then hhid.EntryHHType 
		when hh.hh = 100 then 1
		when hh.hh in (110, 111) then 2
		when hh.hh = 10 then 3
		else 99 end
	, hhid.Step = '3.6.3'
from tlsa_HHID hhid 
inner join tlsa_CohortDates cd on cd.Cohort = -1
left outer join (select HouseholdID
	, sum(distinct case when n.Exit1Age between 18 and 65 then 100 
		when n.Exit1Age < 18 then 10 
		else 1 end) as hh
		from tlsa_Enrollment n
		inner join tlsa_CohortDates cd on cd.Cohort = -1
		where n.ExitDate is null or n.ExitDate >= cd.CohortStart
		group by HouseholdID) hh on hh.HouseholdID = hhid.HouseholdID

update hhid
set hhid.Exit2HHType = case when hhid.ExitDate < cd.CohortStart 
		or hhid.EntryDate >= cd.CohortStart then hhid.EntryHHType 
		when hh.hh = 100 then 1
		when hh.hh in (110, 111) then 2
		when hh.hh = 10 then 3
		else 99 end
	, hhid.Step = '3.6.4'
from tlsa_HHID hhid 
inner join tlsa_CohortDates cd on cd.Cohort = -2
left outer join (select HouseholdID
	, sum(distinct case when n.Exit2Age between 18 and 65 then 100 
		when n.Exit2Age < 18 then 10 
		else 1 end) as hh
		from tlsa_Enrollment n
		inner join tlsa_CohortDates cd on cd.Cohort = -2
		where n.ExitDate is null or n.ExitDate >= cd.CohortStart
		group by HouseholdID) hh on hh.HouseholdID = hhid.HouseholdID
