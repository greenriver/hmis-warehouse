--clear out all intermediate and output tables except for lsa_Project
	truncate table ch_Episodes
	truncate table ch_Episodes_exit
	truncate table ch_Exclude
	truncate table ch_Exclude_exit
	truncate table ch_Include
	truncate table ch_Include_exit
	truncate table lsa_Affiliation
	truncate table lsa_Calculated
	truncate table lsa_Exit
	truncate table lsa_Funder
	truncate table lsa_HMISParticipation
	truncate table lsa_Household
	truncate table lsa_Inventory
	truncate table lsa_Organization
	truncate table lsa_Person
	truncate table lsa_Project
	truncate table lsa_ProjectCoC
	truncate table sys_Time
	truncate table sys_TimePadded
	truncate table sys_TimePadded_exit
	truncate table tlsa_AveragePops
	truncate table tlsa_CohortDates
	truncate table tlsa_CountPops
	truncate table tlsa_Enrollment
	truncate table tlsa_Exit
	truncate table tlsa_ExitHoHAdult
	truncate table tlsa_HHID
	truncate table tlsa_Household
	truncate table tlsa_Person
/*
LSA FY2024 Sample Code
Name:	03_02 to 03_06 HMIS Households and Enrollments.sql 

FY2024 Changes

		3.2 - Set ReportEnd = ReportStart if LSAScope = HIC
			- Set Exit and Point-in-Time Cohort dates only if LSAScope <> HIC
		3.3 - Adjust entry/exit dates to align with period of projects' HMIS participation if the dates conflict
			     and limit reported bednights to periods of HMIS participation
		3.3.1 - Operating end dates and HMIS participation end dates are considered inactive; enrollment dates 
				and bed nights must be < operating/HMIS end dates in order to be relevant. 

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
		when LSAProjectType = 1 and ExitDate <= rpt.ReportEnd then dateadd(dd, 1, LastBednight)
		when dateadd(dd, 90, LastBednight) <= rpt.ReportEnd then dateadd(dd, 1, LastBednight)
		-- When RRH MoveInDate = ExitDate, uses an effective ExitDate of MoveIn + 1 day so that subsequent
		--	sections can use the same logic for RRH and PSH.
		when LSAProjectType in (13,15) and core.MoveInDate = ExitDate and ExitDate = rpt.ReportEnd then NULL
		when LSAProjectType in (13,15) and core.MoveInDate = ExitDate and ExitDate < rpt.ReportEnd then dateadd(dd, 1, ExitDate)
		when ExitDate <= rpt.ReportEnd or (pEnd is null and ExitDate is null) then ExitDate   
		else pEnd end 
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
set hhid.EntryHHType = case when hh.hh = 100 then 1
		when hh.hh in (110, 111) then 2
		when hh.hh = 10 then 3
		else 99 end
	, hhid.Step = '3.6.3'
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
inner join (select HouseholdID
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
	, hhid.Step = '3.6.4'
from tlsa_HHID hhid 
inner join tlsa_CohortDates cd on cd.Cohort = -1
inner join (select HouseholdID
	, sum(distinct case when n.Exit1Age between 18 and 65 then 100 
		when n.Exit1Age < 18 then 10 
		else 1 end) as hh
		from tlsa_Enrollment n
		inner join tlsa_CohortDates cd on cd.Cohort = -1
			and (n.ExitDate is null or n.ExitDate > cd.CohortStart)
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
inner join (select HouseholdID
	, sum(distinct case when n.Exit2Age between 18 and 65 then 100 
		when n.Exit2Age < 18 then 10 
		else 1 end) as hh
		from tlsa_Enrollment n
		inner join tlsa_CohortDates cd on cd.Cohort = -2
			and (n.ExitDate is null or n.ExitDate > cd.CohortStart)
		group by HouseholdID) hh on hh.HouseholdID = hhid.HouseholdID

/*
LSA FY2024 Sample Code
Name:  04_01 Get Project Records.sql

FY2024 Changes
		
	None

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

	4.1 Get Project Records for Export
		Export records for continuum ES entry/exit (0), ES night-by-night (1), 
			SH (8), TH (2), RRH (13), PSH (3), and OPH (9 or 10) projects active in the report period
			and/or in the seven years prior to the report period.

		NOTE:   If used in production, must be modified to accept user-selected ProjectIDs as 
				parameters when LSAScope = 2.
*/	  	
	delete from lsa_Project

	insert into lsa_Project
		(ProjectID, OrganizationID, ProjectName
		 , OperatingStartDate, OperatingEndDate
		 , ContinuumProject, ProjectType, HousingType, RRHSubType
		 , ResidentialAffiliation, TargetPopulation
		 , HOPWAMedAssistedLivingFac
		 , DateCreated, DateUpdated, ExportID)
	select distinct 
		hp.ProjectID, hp.OrganizationID, left(hp.ProjectName, 200)
		, format(hp.OperatingStartDate, 'yyyy-MM-dd')
		, case when hp.OperatingEndDate is not null then format(hp.OperatingEndDate, 'yyyy-MM-dd') else null end
		, hp.ContinuumProject, hp.ProjectType
		, case when hp.RRHSubType = 1 then null else hp.HousingType end
		, case when hp.ProjectType = 13 then hp.RRHSubType else null end
		, case when hp.RRHSubType = 1 then hp.ResidentialAffiliation else null end
		, hp.TargetPopulation 
		, hp.HOPWAMedAssistedLivingFac
		, format(hp.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hp.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, rpt.ReportID
	from hmis_Project hp
	inner join hmis_ProjectCoC coc on coc.ProjectID = hp.ProjectID
		and coc.DateDeleted is null
	inner join lsa_Report rpt on rpt.ReportCoC = coc.CoCCode 
	where hp.DateDeleted is null
		and hp.ContinuumProject = 1 
		and hp.ProjectType in (0,1,2,3,8,9,10,13)
		and (hp.OperatingEndDate is null 
			 or	(hp.OperatingEndDate > rpt.LookbackDate
				 and hp.OperatingEndDate > hp.OperatingStartDate)
			)  
/*
LSA FY2024 Sample Code
Name:  04_02 to 04_08 Get Other PDDEs.sql

FY2024 Changes

	None

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

	4.2 Get Organization Records for Export
		Export organization records for all projects selected in 4.1.
		Organization.csv must have exactly one Organization record for each 
			OrganizationID in Project.csv 
*/	  	

	delete from lsa_Organization

	insert into lsa_Organization
		(OrganizationID, OrganizationName
		, VictimServiceProvider
		, DateCreated, DateUpdated, ExportID)
	select distinct ho.OrganizationID
		, left(ho.OrganizationName, 200)
		, ho.VictimServiceProvider	
		, format(ho.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(ho.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID
	from hmis_Organization ho
	inner join lsa_Project lp on lp.OrganizationID = ho.OrganizationID
	where ho.DateDeleted is null 

/*
	4.3 Get Funder Records for Export
		Get records for project funders with grants active in the report period.
		Funder.csv must have at least one Funder record for each ProjectID 
			in Project.csv where OperatingEndDate is NULL or > ReportStart. 
*/

	delete from lsa_Funder

	insert into lsa_Funder	
		 (FunderID, ProjectID, Funder, OtherFunder
		, StartDate, EndDate
		, DateCreated, DateUpdated, ExportID)
	select distinct hf.FunderID, hf.ProjectID, hf.Funder, hf.OtherFunder
		, format(hf.StartDate, 'yyyy-MM-dd')
		, case when hf.EndDate is not null then format(hf.EndDate, 'yyyy-MM-dd') else null end
		, format(hf.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hf.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID
	from hmis_Funder hf
	inner join lsa_Project lp on lp.ProjectID = hf.ProjectID
	inner join lsa_Report rpt on cast(lp.ExportID as int) = rpt.ReportID
	where hf.DateDeleted is null 
		and (hf.EndDate is null 
			 or	(hf.EndDate >= rpt.ReportStart
				 and hf.EndDate > hf.StartDate)
			)  
/*
	4.4 Get ProjectCoC Records for Export
		ProjectCoC.csv must have exactly one record for each ProjectID in Project.csv
			and the CoCCode must match ReportCoC 
*/

	delete from lsa_ProjectCoC
	 
	insert into lsa_ProjectCoC (
		  ProjectCoCID, ProjectID, CoCCode
		, Geocode
		, Address1, Address2, City, State
		, ZIP, GeographyType 
		, DateCreated, DateUpdated, ExportID
		)
	select hcoc.ProjectCoCID, hcoc.ProjectID, hcoc.CoCCode
		, hcoc.Geocode
		, left(hcoc.Address1, 100), left(hcoc.Address2, 100), left(hcoc.City, 50), hcoc.State
		, left(hcoc.ZIP, 5), hcoc.GeographyType
		, format(hcoc.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hcoc.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID
	from hmis_ProjectCoC hcoc
	inner join lsa_Project lp on lp.ProjectID = hcoc.ProjectID
	inner join lsa_Report rpt on cast(lp.ExportID as int) = rpt.ReportID
	where hcoc.DateDeleted is null
		and hcoc.CoCCode = rpt.ReportCoC

/*
	4.5 Get Inventory Records for Export
		Inventory.csv must have at least one record for each ProjectID 
			in Project.csv where OperatingEndDate is NULL or > ReportStart			
			and the CoCCode must match ReportCoC.
		Note that BedInventory is set up for lsa_Inventory in '02 LSA Output Tables.sql' as a computed column --
		    the value MUST equal the sum of the other xBedInventory columns -- so this code 
			does not select it into lsa_Inventory.
*/

	delete from lsa_Inventory 

	insert into lsa_Inventory (
		  InventoryID, ProjectID, CoCCode
		, HouseholdType, Availability
		, UnitInventory 
		--, BedInventory
		, CHVetBedInventory, YouthVetBedInventory, VetBedInventory
		, CHYouthBedInventory, YouthBedInventory
		, CHBedInventory, OtherBedInventory
		, ESBedType
		, InventoryStartDate, InventoryEndDate
		, DateCreated, DateUpdated, ExportID)
	select distinct hi.InventoryID, hi.ProjectID, hi.CoCCode
		, hi.HouseholdType
		, case when lp.ProjectType in (0,1) then hi.Availability else null end 
		, hi.UnitInventory 
		--, hi.BedInventory
		, hi.CHVetBedInventory, hi.YouthVetBedInventory, hi.VetBedInventory
		, hi.CHYouthBedInventory, hi.YouthBedInventory
		, hi.CHBedInventory, hi.OtherBedInventory
		, case when lp.ProjectType in (0,1) then hi.ESBedType else null end
		, format(hi.InventoryStartDate, 'yyyy-MM-dd')
		, case when isdate(cast(hi.InventoryEndDate as datetime)) = 1 then format(hi.InventoryEndDate, 'yyyy-MM-dd') else null end
		, format(hi.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hi.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID	
	from hmis_Inventory hi
	inner join lsa_Project lp on lp.ProjectID = hi.ProjectID
	inner join lsa_Report rpt on cast(lp.ExportID as int) = rpt.ReportID
	where hi.DateDeleted is null 
		and hi.CoCCode = rpt.ReportCoC
		and (hi.InventoryEndDate is null 
			or (hi.InventoryEndDate >= rpt.ReportStart
				and hi.InventoryEndDate > hi.InventoryStartDate)
			)
		and (lp.ProjectType <> 13 or lp.RRHSubType = 2)

/*
	4.6 Get HMIS Participation Records for Export
		HMISParticipation.csv must have at least one record for each ProjectID 
			in Project.csv 
*/

	delete from lsa_HMISParticipation

	insert into lsa_HMISParticipation (
		HMISParticipationID, ProjectID, 
		HMISParticipationType, 
		HMISParticipationStatusStartDate, HMISParticipationStatusEndDate,
		DateCreated, DateUpdated, ExportID)
	select distinct hp.HMISParticipationID
		, hp.ProjectID
		, hp.HMISParticipationType
		, format(hp.HMISParticipationStatusStartDate, 'yyyy-MM-dd')
		, case when isdate(cast(hp.HMISParticipationStatusEndDate as datetime)) = 1 then format(hp.HMISParticipationStatusEndDate, 'yyyy-MM-dd') else null end
		, format(hp.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hp.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID	
	from hmis_HMISParticipation hp
	inner join lsa_Project lp on lp.ProjectID = hp.ProjectID
	where hp.DateDeleted is null 
		and (lp.OperatingEndDate is null or lp.OperatingEndDate > (select ReportStart from lsa_Report))

	
/*
	4.7 Get Affiliation Records for Export
		Affiliation.csv must have at least one record for each ProjectID 
			in Project.csv active during the report period where 
			RRHSubType = 1 and ResidentialAffiliation = 1 
*/

	delete from lsa_Affiliation

	insert into lsa_Affiliation (
		AffiliationID, ProjectID, 
		ResProjectID, 
		DateCreated, DateUpdated, ExportID)
	select distinct a.AffiliationID
		, a.ProjectID
		, a.ResProjectID
		, format(a.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(a.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID	
	from hmis_Affiliation a
	inner join lsa_Project lp on lp.ProjectID = a.ProjectID
	where a.DateDeleted is null
		and lp.ProjectType = 13 and lp.RRHSubType = 1 and lp.ResidentialAffiliation = 1
		and (lp.OperatingEndDate is null or lp.OperatingEndDate > (select ReportStart from lsa_Report))
/*
LSA FY2024 Sample Code
Name:  05_01 to 05_11 LSAPerson.sql  

FY2024 Changes

		None

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode

	5.1 Identify Active and AHAR HouseholdIDs
*/

	update hhid
	set hhid.Active = 1 
		, hhid.Step = '5.1.1'
	from tlsa_HHID HHID
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join lsa_Project p on p.ProjectID = hhid.ProjectID
	where (hhid.ExitDate is null or hhid.ExitDate >= rpt.ReportStart) 

	update hhid
	set hhid.AHAR = 1 
		, hhid.Step = '5.1.2'
	from tlsa_HHID HHID
	where hhid.Active = 1 
		and (hhid.ExitDate is null or hhid.ExitDate > (select ReportStart from lsa_Report)) 
		and hhid.LSAProjectType not in (3,13,15)
		
	update hhid
	set hhid.AHAR = 1 
		, hhid.Step = '5.1.3'
	from tlsa_HHID HHID
	where hhid.Active = 1 
		and hhid.MoveInDate is not null
		and (hhid.ExitDate is null or hhid.ExitDate > (select ReportStart from lsa_Report)) 
		and hhid.LSAProjectType in (3,13)

/*
	5.2  Identify Active and AHAR Enrollments
*/

	update n
	set n.Active = 1
		, n.Step = '5.2.1'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID and hhid.Active = 1
	where n.ExitDate is null or n.ExitDate >= rpt.ReportStart


	update n
	set n.AHAR = 1
		, n.Step = '5.2.2'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID and hhid.AHAR = 1
	where n.Active = 1
		and (n.ExitDate is null or n.ExitDate > rpt.ReportStart)
		and n.LSAProjectType not in (3,13,15)
	
	update n
	set n.AHAR = 1 
		, n.Step = '5.2.3'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID and hhid.AHAR = 1
	where n.Active = 1 
		and n.MoveInDate is not null
		and (n.ExitDate is null or n.ExitDate > (select ReportStart from lsa_Report)) 
		and n.LSAProjectType in (3,13)
/*
	5.3 Get Active Clients for LSAPerson 
	5.4 LSAPerson Demographics 
*/
	truncate table tlsa_Person

	insert into tlsa_Person (PersonalID, HoHAdult, 
		VetStatus, DisabilityStatus, DVStatus, Gender, RaceEthnicity
		, ReportID, Step)
	select distinct n.PersonalID
		, HoHAdult.stat
		, case 
			when HoHAdult.stat not in (1,3) then -1 
			when c.VeteranStatus in (8,9) then 98
			when c.VeteranStatus in (0,1) then c.VeteranStatus
			else 99 end
		, case	
			when HoHAdult.stat = 0 then -1
			when Disability.stat = 1 then 1
			when Disability.stat = 0 then 0
			else 99 end 		 
		, case	
			when HoHAdult.stat = 0 then -1
			when DV.stat = 10 then 0 
			when DV.stat is null then 99
			else DV.stat end 	
		, case 
			when c.GenderNone in (8,9) then 98
			when c.GenderNone = 99 then 99
			when (c.Woman = 1
					or c.Man = 1
					or c.NonBinary = 1
					or c.CulturallySpecific = 1 
					or c.Transgender = 1 
					or c.Questioning = 1
					or c.DifferentIdentity = 1) then 
						(select cast (
							(case when c.Man = 1 then '1' else '' end
							+ case when c.CulturallySpecific = 1 then '2' else '' end 
							+ case when c.DifferentIdentity = 1 then '3' else '' end
							+ case when c.NonBinary = 1 then '4' else '' end
							+ case when c.Transgender = 1 then '5' else '' end
							+ case when c.Questioning = 1 then '6' else '' end
							+ case when c.Woman = 1 then '0' else '' end
							) as int)
						from hmis_Client g
						where g.PersonalID = c.PersonalID)
			else 99 end
		, case 
			when c.RaceNone in (8,9) then 98
			when c.RaceNone = 99 then 99
			when (c.AmIndAkNative = 1 
					or c.Asian = 1
					or c.BlackAfAmerican = 1
					or c.NativeHIPacific = 1
					or c.White = 1
					or c.HispanicLatinaeo = 1
					or c.MidEastNAfrican = 1) then 
						(select cast (
							(case when r.AmIndAKNative = 1 then '1' else '' end
							+ case when r.Asian = 1 then '2' else '' end
							+ case when r.BlackAfAmerican = 1 then '3' else '' end
							+ case when r.NativeHIPacific = 1 then '4' else '' end
							+ case when r.White = 1 then '5' else '' end
							+ case when r.HispanicLatinaeo = 1 then '6' else '' end
							+ case when r.MidEastNAfrican = 1 then '7' else '' end) as int)
						from hmis_Client r
						where r.PersonalID = c.PersonalID)
			else 99 end 
		, rpt.ReportID
		, '5.3/5.4'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd and n.Active = 1
	inner join 
	--   HoHAdult identifies people served as heads of household or adults at any time in the report period.
	--     There is no corresponding column in lsa_Person -- it is only used to identify records for which 
	--		demographic data are required / simplify the queries that set the column values.   	
	(select n.PersonalID, max(case when n.ActiveAge between 18 and 65 then 1
			else 0 end) 
		--Plus ever served-as-HoH = 2 
		  + max(case when n.RelationshipToHoH <> 1 then 0
			else 2 end) as stat
		--Equals:  0=Not HoH or Adult, 1=Adult, 2=HoH, 3=Both
		from tlsa_Enrollment n
		where n.Active = 1
		group by n.PersonalID) HoHAdult on HoHAdult.PersonalID = n.PersonalID
	inner join hmis_Client c on c.PersonalID = n.PersonalID
	left outer join 
		(select n.PersonalID, max(n.DisabilityStatus) as stat
		from tlsa_Enrollment n
		where n.Active = 1
		group by n.PersonalID) Disability on Disability.PersonalID = n.PersonalID
	left outer join 
		(select n.PersonalID, min(n.DVStatus) as stat
		from tlsa_Enrollment n
		where n.Active = 1
		group by n.PersonalID) DV on DV.PersonalID = n.PersonalID	

	update lp
	set lp.HIV = case when n.PersonalID is not null then 1
		when chk.PersonalID is not null then 0
		else -1 end
	from tlsa_Person lp
	left outer join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.ActiveAge between 18 and 65 and n.HIV = 1
	left outer join (select distinct n.PersonalID from tlsa_Enrollment n where n.AHAR = 1 and n.ActiveAge between 18 and 65) chk on chk.PersonalID = lp.PersonalID

	update lp
	set lp.SMI = case when n.PersonalID is not null then 1
		when chk.PersonalID is not null then 0
		else -1 end
	from tlsa_Person lp
	left outer join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.ActiveAge between 18 and 65 and n.SMI = 1
	left outer join (select distinct n.PersonalID from tlsa_Enrollment n where n.AHAR = 1 and n.ActiveAge between 18 and 65) chk on chk.PersonalID = lp.PersonalID

	update lp
	set lp.SUD = case when n.PersonalID is not null then 1
		when chk.PersonalID is not null then 0
		else -1 end
	from tlsa_Person lp
	left outer join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.ActiveAge between 18 and 65 and n.SUD = 1
	left outer join (select distinct n.PersonalID from tlsa_Enrollment n where n.AHAR = 1 and n.ActiveAge between 18 and 65) chk on chk.PersonalID = lp.PersonalID

	update lp
	set lp.DisabilityStatus = 1
	from tlsa_Person lp
	where lp.DisabilityStatus <> 1 and (lp.HIV = 1 or lp.SMI = 1 or lp.SUD = 1)

/*
	5.5 Get Dates for Three Year Period Relevant to Chronic Homelessness Status 
		 for Each Active Adult and Head of Household
*/

	-- CH status is based on HMIS enrollment data in the three year period ending on the client's 
	-- last active date in the report period.

	update lp
	set lp.LastActive =  
		(select max(case 
			when n.ExitDate is null and 
				(n.LastBednight is null or n.LastBednight = rpt.ReportEnd) then rpt.ReportEnd 
			when n.LastBednight is not null then dateadd(dd, 1, n.LastBednight)
			else n.ExitDate end) 
		from lsa_Report rpt
		inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd and n.Active = 1
		where n.PersonalID = lp.PersonalID)
		, lp.Step = '5.5.1'
	from tlsa_Person lp
	where lp.HoHAdult > 0

	--The start of the period is:  LastActive minus (3 years) plus (1 day) --
	--  i.e., only people who are chronically homeless as of their most recent
	--  unhoused date of service will be counted as chronically homeless.  
	update lp
	set lp.CHStart = dateadd(dd, 1, (dateadd(yyyy, -3, lp.LastActive)))
		, lp.Step = '5.5.2'
	from tlsa_Person lp
	where HoHAdult > 0 and lp.LastActive is not NULL

/*
	5.6 Enrollments Relevant to Counting ES/SH/Street Dates
*/

	update n
	set n.CH = 1
		, n.Step = '5.6'
	from tlsa_Person lp
	inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID	
		and n.EntryDate <= lp.LastActive
	where lp.HoHAdult > 0 
		and (n.ExitDate is null or (n.ExitDate > lp.CHStart))
	
/*
	5.7 Get Dates to Exclude from Counts of ES/SH/Street Days 
*/

	truncate table ch_Exclude

	-- ch_Exclude identifies dates between CHStart and LastActive when client was 
	--  housed in TH (EntryDate to the day before ExitDate) and/or RRH/PSH (MoveInDate to the day before ExitDate)
	--  i.e., dates when the client was NOT on the street or in ES/SH based on HMIS enrollment data.
	--  Regardless of any potentially conflicting data, these dates will not be counted as ESSHStreetDates.
	insert into ch_Exclude (PersonalID, excludeDate, Step)
	select distinct lp.PersonalID, cal.theDate, '5.7'
	from tlsa_Person lp
	inner join tlsa_Enrollment chn on chn.PersonalID = lp.PersonalID and chn.CH = 1
	inner join ref_Calendar cal on cal.theDate >=
			case when chn.LSAProjectType in (3,13,15) then chn.MoveInDate  
				else chn.EntryDate end
		and (cal.theDate < chn.ExitDate 
			or chn.ExitDate is null)
			and cal.theDate between lp.CHStart and lp.LastActive
	where chn.LSAProjectType in (2,3,13,15)

/*
	5.8 Get Dates to Include in Counts of ES/SH/Street Days 
*/
	--ch_Include identifies dates on which a client was in ES/SH or on the street 
	-- based on HMIS data (excluding any dates in ch_Exclude).

	truncate table ch_Include

	--Dates enrolled in ES entry/exit or SH (EntryDate to the day before ExitDate), 
	-- not including any dates already accounted for in ch_Exclude
	insert into ch_Include (PersonalID, ESSHStreetDate, Step)
	select distinct lp.PersonalID, cal.theDate, '5.8.1'
	from tlsa_Person lp
		inner join tlsa_Enrollment chn on chn.PersonalID = lp.PersonalID and chn.CH = 1
		inner join ref_Calendar cal on 
			cal.theDate >= chn.EntryDate 
		and (cal.theDate < chn.ExitDate or chn.ExitDate is null)
			and cal.theDate between lp.CHStart and lp.LastActive
		left outer join ch_Exclude chx on chx.excludeDate = cal.theDate
			and chx.PersonalID = chn.PersonalID
	where chn.LSAProjectType in (0,8)
		and chx.excludeDate is null

	--ES nbn bed nights (any valid DateProvided between CHStart and LastActive 
	-- that is not already accounted for in ch_Exclude, and not already in ch_Include)
	insert into ch_Include (PersonalID, ESSHStreetDate, Step)
	select distinct lp.PersonalID, cal.theDate, '5.8.2'
	from tlsa_Person lp
		inner join tlsa_Enrollment chn on chn.PersonalID = lp.PersonalID and chn.CH = 1
		inner join hmis_Services bn on bn.EnrollmentID = chn.EnrollmentID
			and bn.RecordType = 200 
			and bn.DateProvided >= chn.EntryDate 
			and (bn.DateProvided < chn.ExitDate or chn.ExitDate is null)
			and bn.DateDeleted is null
		inner join ref_Calendar cal on 
			cal.theDate = bn.DateProvided 
			and cal.theDate between lp.CHStart and lp.LastActive
		left outer join ch_Exclude chx on chx.excludeDate = cal.theDate
			and chx.PersonalID = chn.PersonalID
		left outer join ch_Include chi on chi.ESSHStreetDate = cal.theDate 
			and chi.PersonalID = chn.PersonalID
	where chn.LSAProjectType = 1 and chx.excludeDate is null
		and chi.ESSHStreetDate is null

	--ES/SH/Street dates from 3.917 DateToStreetESSH when EntryDates > CHStart --
	-- all dates 

	insert into ch_Include (PersonalID, ESSHStreetDate, Step)
	select distinct lp.PersonalID, cal.theDate, '5.8.3'
	from tlsa_Person lp
		inner join tlsa_Enrollment chn on chn.PersonalID = lp.PersonalID
			and chn.EntryDate > lp.CHStart and chn.CH = 1
		inner join hmis_Enrollment hn on hn.EnrollmentID = chn.EnrollmentID
		inner join ref_Calendar cal on 
			cal.theDate >= hn.DateToStreetESSH
			and cal.theDate between lp.CHStart and lp.LastActive
		left outer join ch_Exclude chx on chx.excludeDate = cal.theDate
			and chx.PersonalID = chn.PersonalID
		left outer join ch_Include chi on chi.ESSHStreetDate = cal.theDate 
			and chi.PersonalID = chn.PersonalID
	where chx.excludeDate is null
		and chi.ESSHStreetDate is null
		and (hn.LivingSituation between 100 and 199
			or (chn.LSAProjectType not in (0,1,8) and hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
			or (chn.LSAProjectType not in (0,1,8) and hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
					and hn.LivingSituation between 200 and 299) 
			)
		and ( 
			
			(-- for ES/SH/TH, count dates prior to EntryDate
				chn.LSAProjectType in (0,1,2,8) and cal.theDate < chn.EntryDate)
			or (-- for PSH/RRH, dates prior to and after EntryDate are counted for 
				-- as long as the client remains homeless in the project  
				chn.LSAProjectType in (3,13,15)
				and (cal.theDate < chn.MoveInDate
					 or (chn.MoveInDate is NULL and cal.theDate < chn.ExitDate)
					 or (chn.MoveInDate is NULL and chn.ExitDate is NULL and cal.theDate <= lp.LastActive)
					)
				)
			)						

	--Gaps of less than 7 nights between two ESSHStreet dates are counted as ESSHStreetDates
	-- 2023:	There should be no change in logic here; changes are to add comments and make the 
	--			code more readable.
	insert into ch_Include (PersonalID, ESSHStreetDate, Step)
	select gap.PersonalID, cal.theDate, '5.8.4'
	from
			(select s.PersonalID, s.ESSHStreetDate as StartDate, min(e.ESSHStreetDate) as EndDate
			from ch_Include s 
			--nogap identifies dates in ch_Include that have an ESSHStreetDate on the next day --
			--  i.e., not the start of a gap -- and they are excluded in the WHERE clause
			left outer join ch_Include nogap on nogap.PersonalID = s.PersonalID 
				and nogap.ESSHStreetDate = dateadd(dd, 1, s.ESSHStreetDate)
			-- e identifies ESSHStreetDates within 7 days after the start of a gap --
			-- i.e., potential end dates for the gap -- and the earliest one is selected as EndDate
			inner join ch_Include e on e.PersonalID = s.PersonalID 
				and e.ESSHStreetDate > s.ESSHStreetDate 
				and dateadd(dd, -7, e.ESSHStreetDate) <= s.ESSHStreetDate
			where nogap.PersonalID is null
			group by s.PersonalID, s.ESSHStreetDate) gap
		inner join ref_Calendar cal on cal.theDate > gap.StartDate and cal.theDate < gap.EndDate

/*
	5.9 Get ES/SH/Street Episodes
*/
	truncate table ch_Episodes

	-- For any given PersonalID:
	-- Any ESSHStreetDate in ch_Include without a record for the day before is the start of an episode (episodeStart).
	-- Any cdDate in ch_Include without a record for the day after is the end of an episode (episodeEnd).
	-- Each episodeStart combined with the next earliest episodeEnd represents one episode.
	-- The length of the episode is the difference in days between episodeStart and episodeEnd + 1 day.

	insert into ch_Episodes (PersonalID, episodeStart, episodeEnd, Step)
	select distinct s.PersonalID, s.ESSHStreetDate, min(e.ESSHStreetDate), '5.9.1'
	from ch_Include s 
	inner join ch_Include e on e.PersonalID = s.PersonalID  and e.ESSHStreetDate >= s.ESSHStreetDate
	--any date in ch_Include without a record for the day before is the start of an episode
	where s.PersonalID not in (select PersonalID from ch_Include where ESSHStreetDate = dateadd(dd, -1, s.ESSHStreetDate))
	--any date in ch_Include without a record for the day after is the end of an episode
		and e.PersonalID not in (select PersonalID from ch_Include where ESSHStreetDate = dateadd(dd, 1, e.ESSHStreetDate))
	group by s.PersonalID, s.ESSHStreetDate

	update chep 
	set episodeDays = datediff(dd, chep.episodeStart, chep.episodeEnd) + 1
		, Step = '5.9.2'
	from ch_Episodes chep

/*
	5.10 Set CHTime and CHTimeStatus 
*/

	--Any client with a 365+ day episode that overlaps with their
	--last year of activity meets the time criteria for CH
	update lp 
	set lp.CHTime = case when lp.HoHAdult = 0 then -1 else 0 end
		, lp.CHTimeStatus = -1
		, lp.Step = '5.10.1'
	from tlsa_Person lp	
	
	update lp 
	set CHTime = 365, CHTimeStatus = 1, lp.Step = '5.10.2'
	from tlsa_Person lp
		inner join ch_Episodes chep on chep.PersonalID = lp.PersonalID
			and chep.episodeDays >= 365
			and chep.episodeEnd > dateadd(yyyy, -1, lp.LastActive)
	where CHTime = 0

	--Clients with a total of 365+ days in the three year period and at least four episodes 
	--  meet time criteria for CH
	update lp 
	set lp.CHTime = case 
			when ep.episodeDays >= 365 then 365
			when ep.episodeDays between 270 and 364 then 270
			else 0 end
		, lp.CHTimeStatus = case
			when ep.episodeDays < 365 then -1 
			when ep.episodes >= 4 then 2
			else 3 end
		, lp.Step = '5.10.3'
	from tlsa_Person lp
	inner join (select chep.PersonalID
		, sum(chep.episodeDays) as episodeDays, count(distinct chep.episodeStart) as episodes
		from ch_Episodes chep
		group by chep.PersonalID) ep on ep.PersonalID = lp.PersonalID
	where lp.CHTime = 0

	--Clients with 3.917 data for an entry in their last year of activity 
	--  showing 12+ months and 4+ episodes meet time criteria for CH 
	update lp 
	set lp.CHTime = 400
		, lp.CHTimeStatus = 2
		, lp.Step = '5.10.4'
	from tlsa_Person lp
		inner join tlsa_Enrollment chn on chn.PersonalID = lp.PersonalID and chn.CH = 1
		inner join hmis_Enrollment hn on hn.EnrollmentID = chn.EnrollmentID
			and hn.MonthsHomelessPastThreeYears in (112,113) 
			and hn.TimesHomelessPastThreeYears = 4
			and chn.EntryDate > dateadd(yyyy, -1, lp.LastActive)
	where 
		lp.CHTime not in (-1,365) or lp.CHTimeStatus = 3

	--Anyone who doesn't meet CH time criteria and is missing data in 3.917 
	--for an active enrollment should be identified as missing data.
		
	update lp 
	set lp.CHTimeStatus = 99
		, lp.Step = '5.10.5'
	from tlsa_Person lp
		inner join tlsa_Enrollment chn on chn.PersonalID = lp.PersonalID and chn.CH = 1
		inner join hmis_Enrollment hn on hn.EnrollmentID = chn.EnrollmentID
	where (lp.CHTime in (0,270) or lp.CHTimeStatus = 3)
		and (hn.DateToStreetESSH > chn.EntryDate 
				or (hn.LivingSituation < 100 or hn.LivingSituation is null)
				or (hn.LengthOfStay in (8,9,99) or hn.LengthOfStay is null)
				or (chn.LSAProjectType not in (0,1,8) and hn.LivingSituation between 200 and 299 
						and hn.LengthOfStay in (2,3)
						and (hn.PreviousStreetESSH is null or hn.PreviousStreetESSH not in (0,1)))
				or (chn.LSAProjectType not in (0,1,8) and hn.LengthOfStay in (10,11) 
							and (hn.PreviousStreetESSH is null or hn.PreviousStreetESSH not in (0,1)))
				or ((chn.LSAProjectType in (0,1,8)
					  or hn.LivingSituation between 100 and 199
					  or (chn.LSAProjectType not in (0,1,8) and hn.LivingSituation between 200 and 299  
							and hn.LengthOfStay in (2,3)
							and hn.PreviousStreetESSH = 1)
					  or (chn.LSAProjectType not in (0,1,8) and hn.LengthOfStay in (10,11) 
							and hn.PreviousStreetESSH = 1)
					)
					and (
						hn.MonthsHomelessPastThreeYears in (8,9,99) 
							or hn.MonthsHomelessPastThreeYears is null
							or hn.TimesHomelessPastThreeYears in (8,9,99)
							or hn.TimesHomelessPastThreeYears is null
							or hn.DateToStreetESSH is null
						)
			))

/*
	5.11 EST/RRH/PSH/RRHSO AgeMin and AgeMax - LSAPerson
*/

	update lp 
	set ESTAgeMin = coalesce(
		(select min(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.LSAProjectType in (0,1,2,8) and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.1'
	from tlsa_Person lp

	update lp 
	set ESTAgeMax = coalesce(
		(select max(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.LSAProjectType in (0,1,2,8) and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.2'
	from tlsa_Person lp

	update lp 
	set RRHAgeMin = coalesce(
		(select min(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.LSAProjectType = 13 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.3'
	from tlsa_Person lp

	update lp 
	set RRHAgeMax = coalesce(
		(select max(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.LSAProjectType = 13 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.4'
	from tlsa_Person lp

	update lp 
	set PSHAgeMin = coalesce(
		(select min(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.LSAProjectType = 3 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.5'
	from tlsa_Person lp

	update lp 
	set PSHAgeMax = coalesce(
		(select max(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.LSAProjectType = 3 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.6'
	from tlsa_Person lp

	update lp 
	set RRHSOAgeMin = coalesce(
		(select min(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.LSAProjectType = 15 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.3'
	from tlsa_Person lp

	update lp 
	set RRHSOAgeMax = coalesce(
		(select max(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.LSAProjectType = 15 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.4'
	from tlsa_Person lp


/*
LSA FY2024 Sample Code
Name:  05_12 to 05_15 LSAPerson Project Group and Population Household Types.sql  

FY2024 Changes

		None

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode
	
	5.12 Set Population Identifiers for Active HouseholdIDs
*/

	update hhid
	set hhid.HHChronic = coalesce((select min(
			case when ((lp.CHTime = 365 and lp.CHTimeStatus in (1,2))
					or (lp.CHTime = 400 and lp.CHTimeStatus = 2))
					and lp.DisabilityStatus = 1 then 1
				when lp.CHTime in (365, 400) and lp.DisabilityStatus = 1 then 2
				when lp.CHTime in (365, 400) and lp.DisabilityStatus = 99 then 3
				when lp.CHTime in (365, 400) and lp.DisabilityStatus = 0 then 4
				when lp.CHTime = 270 and lp.DisabilityStatus = 1 and lp.CHTimeStatus = 99 then 5
				when lp.CHTime = 270 and lp.DisabilityStatus = 1 and lp.CHTimeStatus <> 99 then 6
				when lp.CHTimeStatus = 99 and lp.DisabilityStatus <> 0 then 9
				else null end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1 
				and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
			inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
			where n.HouseholdID = hhid.HouseholdID), 0)
		, hhid.HHVet = coalesce((select max(
					case when lp.VetStatus = 1 
						and n.ActiveAge between 18 and 65 
						and hh.ActiveHHType <> 3 then 1
					else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
			where n.HouseholdID = hhid.HouseholdID), 0)
		, hhid.HHDisability = coalesce((select max(
				case when lp.DisabilityStatus = 1 
					and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 1
				else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			where n.HouseholdID = hhid.HouseholdID), 0)
		, hhid.HHFleeingDV = coalesce((select min(
				case when lp.DVStatus = 1 
						and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 1
					when lp.DVStatus in (2,3) 
						and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 2
				else null end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			where n.HouseholdID = hhid.HouseholdID), 0)
		--Set HHAdultAge for active households based on HH member AgeGroup(s) 
		, hhid.HHAdultAge = (select 
				-- n/a except for AO and AC households 
				case when hhid.ActiveHHType not in (1,2) then -1
					-- n/a for AC households with members of unknown age
					when max(n.ActiveAge) >= 98 then -1
					-- 18-21
					when max(n.ActiveAge) = 21 then 18
					-- 22-24
					when max(n.ActiveAge) = 24 then 24
					-- 55+
					when min(n.ActiveAge) between 64 and 65 then 55
					-- all other combinations
					else 25 end
				from tlsa_Enrollment n 
				where n.HouseholdID = hhid.HouseholdID and n.Active = 1) 
		, hhid.AC3Plus = (select case sum(case when n.ActiveAge <= 17 and hh.ActiveHHType = 2 then 1
								else 0 end) 
							when 0 then 0 
							when 1 then 0 
							when 2 then 0 
							else 1 end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
				where n.Active = 1 and n.HouseholdID = hhid.HouseholdID) 
		, hhid.Step = '5.12.1'
	from tlsa_HHID hhid
	where hhid.Active = 1

	update hhid
	set hhid.HHParent = coalesce((select max(
			case when n.RelationshipToHoH = 2 then 1
				else 0 end)
		from tlsa_Enrollment n 
		where n.Active = 1 and n.HouseholdID = hhid.HouseholdID), 0)
		, hhid.Step = '5.12.2'
	from tlsa_HHID hhid
	where hhid.Active = 1


/*
	5.13 Set tlsa_Person Project Group and Population Household Types
*/


	update lp
	set lp.HHTypeEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)) 
		, lp.HoHEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and n.RelationshipToHoH = 1) 
		, lp.AdultEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and n.ActiveAge between 18 and 65) 
		, lp.AHAREST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType in (0,1,2,8)) 
		, lp.AHARHoHEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR= 1 and n.LSAProjectType in (0,1,2,8)
					and n.RelationshipToHoH = 1) 
		, lp.AHARAdultEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType in (0,1,2,8)
					and n.ActiveAge between 18 and 65) 
		, lp.HHChronicEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHChronic = 1)
		, lp.HHVetEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHVet = 1)
		, lp.HHDisabilityEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHDisability = 1)
		, lp.HHFleeingDVEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHFleeingDV = 1)
		, lp.HHParentEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHParent = 1)
		, lp.AC3PlusEST = (select sum(distinct case when hhid.AC3Plus = 1 then 1 else 0 end)
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8))
		, lp.HHTypeRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13) 
		, lp.HoHRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and n.RelationshipToHoH = 1) 
		, lp.AdultRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and n.ActiveAge between 18 and 65) 
		, lp.AHARRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 13) 
		, lp.AHARHoHRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 13
					and n.RelationshipToHoH = 1) 
		, lp.AHARAdultRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 13
					and n.ActiveAge between 18 and 65) 
		, lp.HHChronicRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHChronic = 1)
		, lp.HHVetRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHVet = 1)
		, lp.HHDisabilityRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHDisability = 1)
		, lp.HHFleeingDVRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHFleeingDV = 1)
		, lp.HHParentRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHParent = 1)
		, lp.AC3PlusRRH = (select sum(distinct case when hhid.AC3Plus = 1 then 1 else 0 end)
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13)
		, lp.HHTypePSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3) 
		, lp.HoHPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and n.RelationshipToHoH = 1) 
		, lp.AdultPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and n.ActiveAge between 18 and 65) 
		, lp.AHARPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 3) 
		, lp.AHARHoHPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 3
					and n.RelationshipToHoH = 1) 
		, lp.AHARAdultPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 3
					and n.ActiveAge between 18 and 65) 
		, lp.HHChronicPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHChronic = 1)
		, lp.HHVetPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHVet = 1)
		, lp.HHDisabilityPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHDisability = 1)
		, lp.HHFleeingDVPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHFleeingDV = 1)
		, lp.HHParentPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHParent = 1)
		, lp.AC3PlusPSH = (select sum(distinct case when hhid.AC3Plus = 1 then 1 else 0 end)
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3)
		, lp.HHTypeRRHSONoMI = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.MoveInDate is null and n.LSAProjectType = 15) 
		, lp.HHTypeRRHSOMI = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.MoveInDate is not null and n.LSAProjectType = 15) 
		, lp.HHTypeES = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1)) 
		, lp.HHTypeSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 8) 
		, lp.HHTypeTH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 2) 
		, lp.Step = '5.13.1'
	from tlsa_Person lp

	update lp 
	set lp.AC3PlusEST = case when lp.AC3PlusEST is NULL then -1 else cast(replace(cast(lp.AC3PlusEST as varchar), '0', '') as int) end 
	, lp.AC3PlusPSH = case when lp.AC3PlusPSH is NULL then -1 else cast(replace(cast(lp.AC3PlusPSH as varchar), '0', '') as int) end  
	, lp.AC3PlusRRH = case when lp.AC3PlusRRH is NULL then -1 else cast(replace(cast(lp.AC3PlusRRH as varchar), '0', '') as int) end  
	, lp.AdultEST = case when lp.AdultEST is NULL then -1 else cast(replace(cast(lp.AdultEST as varchar), '0', '') as int) end   
	, lp.AdultPSH = case when lp.AdultPSH is NULL then -1 else cast(replace(cast(lp.AdultPSH as varchar), '0', '') as int) end   
	, lp.AdultRRH = case when lp.AdultRRH is NULL then -1 else cast(replace(cast(lp.AdultRRH as varchar), '0', '') as int) end   
	, lp.AHARAdultEST = case when lp.AHARAdultEST is NULL then -1 else cast(replace(cast(lp.AHARAdultEST as varchar), '0', '') as int) end   
	, lp.AHARAdultPSH = case when lp.AHARAdultPSH is NULL then -1 else cast(replace(cast(lp.AHARAdultPSH as varchar), '0', '') as int) end 
	, lp.AHARAdultRRH = case when lp.AHARAdultRRH is NULL then -1 else cast(replace(cast(lp.AHARAdultRRH as varchar), '0', '') as int) end 
	, lp.AHAREST = case when lp.AHAREST is NULL then -1 else cast(replace(cast(lp.AHAREST as varchar), '0', '') as int) end 
	, lp.AHARHoHEST = case when lp.AHARHoHEST is NULL then -1 else cast(replace(cast(lp.AHARHoHEST as varchar), '0', '') as int) end 
	, lp.AHARHoHPSH = case when lp.AHARHoHPSH is NULL then -1 else cast(replace(cast(lp.AHARHoHPSH as varchar), '0', '') as int) end 
	, lp.AHARHoHRRH = case when lp.AHARHoHRRH is NULL then -1 else cast(replace(cast(lp.AHARHoHRRH as varchar), '0', '') as int) end 
	, lp.AHARPSH = case when lp.AHARPSH is NULL then -1 else cast(replace(cast(lp.AHARPSH as varchar), '0', '') as int) end 
	, lp.AHARRRH = case when lp.AHARRRH is NULL then -1 else cast(replace(cast(lp.AHARRRH as varchar), '0', '') as int) end 
	, lp.HHChronicEST = case when lp.HHChronicEST is NULL then -1 else cast(replace(cast(lp.HHChronicEST as varchar), '0', '') as int) end 
	, lp.HHChronicPSH = case when lp.HHChronicPSH is NULL then -1 else cast(replace(cast(lp.HHChronicPSH as varchar), '0', '') as int) end 
	, lp.HHChronicRRH = case when lp.HHChronicRRH is NULL then -1 else cast(replace(cast(lp.HHChronicRRH as varchar), '0', '') as int) end 
	, lp.HHDisabilityEST = case when lp.HHDisabilityEST is NULL then -1 else cast(replace(cast(lp.HHDisabilityEST as varchar), '0', '') as int) end 
	, lp.HHDisabilityPSH = case when lp.HHDisabilityPSH is NULL then -1 else cast(replace(cast(lp.HHDisabilityPSH as varchar), '0', '') as int) end 
	, lp.HHDisabilityRRH = case when lp.HHDisabilityRRH is NULL then -1 else cast(replace(cast(lp.HHDisabilityRRH as varchar), '0', '') as int) end 
	, lp.HHFleeingDVEST = case when lp.HHFleeingDVEST is NULL then -1 else cast(replace(cast(lp.HHFleeingDVEST as varchar), '0', '') as int) end 
	, lp.HHFleeingDVPSH = case when lp.HHFleeingDVPSH is NULL then -1 else cast(replace(cast(lp.HHFleeingDVPSH as varchar), '0', '') as int) end 
	, lp.HHFleeingDVRRH = case when lp.HHFleeingDVRRH is NULL then -1 else cast(replace(cast(lp.HHFleeingDVRRH as varchar), '0', '') as int) end 
	, lp.HHParentEST = case when lp.HHParentEST is NULL then -1 else cast(replace(cast(lp.HHParentEST as varchar), '0', '') as int) end 
	, lp.HHParentPSH = case when lp.HHParentPSH is NULL then -1 else cast(replace(cast(lp.HHParentPSH as varchar), '0', '') as int) end 
	, lp.HHParentRRH = case when lp.HHParentRRH is NULL then -1 else cast(replace(cast(lp.HHParentRRH as varchar), '0', '') as int) end 
	, lp.HHTypeEST = case when lp.HHTypeEST is NULL then -1 else cast(replace(cast(lp.HHTypeEST as varchar), '0', '') as int) end 
	, lp.HHTypePSH = case when lp.HHTypePSH is NULL then -1 else cast(replace(cast(lp.HHTypePSH as varchar), '0', '') as int) end 
	, lp.HHTypeRRH = case when lp.HHTypeRRH is NULL then -1 else cast(replace(cast(lp.HHTypeRRH as varchar), '0', '') as int) end 
	, lp.HHVetEST = case when lp.HHVetEST is NULL then -1 else cast(replace(cast(lp.HHVetEST as varchar), '0', '') as int) end 
	, lp.HHVetPSH = case when lp.HHVetPSH is NULL then -1 else cast(replace(cast(lp.HHVetPSH as varchar), '0', '') as int) end 
	, lp.HHVetRRH = case when lp.HHVetRRH is NULL then -1 else cast(replace(cast(lp.HHVetRRH as varchar), '0', '') as int) end 
	, lp.HoHEST = case when lp.HoHEST is NULL then -1 else cast(replace(cast(lp.HoHEST as varchar), '0', '') as int) end 
	, lp.HoHPSH = case when lp.HoHPSH is NULL then -1 else cast(replace(cast(lp.HoHPSH as varchar), '0', '') as int) end 
	, lp.HoHRRH = case when lp.HoHRRH is NULL then -1 else cast(replace(cast(lp.HoHRRH as varchar), '0', '') as int) end 
	, lp.HHTypeES = case when lp.HHTypeES is NULL then -1 else cast(replace(cast(lp.HHTypeES as varchar), '0', '') as int) end 
	, lp.HHTypeSH = case when lp.HHTypeSH is NULL then -1 else cast(replace(cast(lp.HHTypeSH as varchar), '0', '') as int) end 
	, lp.HHTypeTH = case when lp.HHTypeTH is NULL then -1 else cast(replace(cast(lp.HHTypeTH as varchar), '0', '') as int) end 
	, lp.PSHAgeMax = case when lp.PSHAgeMax is NULL then -1 else lp.PSHAgeMax end 
	, lp.PSHAgeMin = case when lp.PSHAgeMin is NULL then -1 else lp.PSHAgeMin end 
	, lp.RRHAgeMax = case when lp.RRHAgeMax is NULL then -1 else lp.RRHAgeMax end 
	, lp.RRHAgeMin = case when lp.RRHAgeMin is NULL then -1 else lp.RRHAgeMin end 
	, lp.ESTAgeMax = case when lp.ESTAgeMax is NULL then -1 else lp.ESTAgeMax end 
	, lp.ESTAgeMin = case when lp.ESTAgeMin is NULL then -1 else lp.ESTAgeMin end 
	, lp.RRHSOAgeMin = case when lp.RRHSOAgeMin is NULL then -1 else lp.RRHSOAgeMin end    
	, lp.RRHSOAgeMax = case when lp.RRHSOAgeMax is NULL then -1 else lp.RRHSOAgeMax end    
	, lp.HHTypeRRHSONoMI = case when lp.HHTypeRRHSONoMI is NULL then -1 else cast(replace(cast(lp.HHTypeRRHSONoMI as varchar), '0', '') as int) end 
	, lp.HHTypeRRHSOMI = case when lp.HHTypeRRHSOMI is NULL then -1 else cast(replace(cast(lp.HHTypeRRHSOMI as varchar), '0', '') as int) end 
	, Step = '5.13.2'
	from tlsa_Person lp
	
	/*
		5.14 Adult Age Population Identifiers - LSAPerson
	*/
	update lp
	set lp.HHAdultAgeAOEST = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 1 
					and hhid.LSAProjectType in (0,1,2,8)
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeACEST = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 2
					and hhid.LSAProjectType in (0,1,2,8)
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeAORRH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 1 
					and hhid.LSAProjectType = 13
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeACRRH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 2
					and hhid.LSAProjectType = 13
				where n.PersonalID = lp.PersonalID
					and n.Active = 1), -1)
		, lp.HHAdultAgeAOPSH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 1 
					and hhid.LSAProjectType = 3
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeACPSH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 2
					and hhid.LSAProjectType = 3
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.Step = '5.14'
	from tlsa_Person lp

/*
	5.15 Select Data for Export to LSAPerson
*/
	-- LSAPerson
	delete from lsa_Person
	insert into lsa_Person (RowTotal
		, Gender, RaceEthnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, AHARAdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, AHARAdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, AHARAdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, RRHSOAgeMin, RRHSOAgeMax, HHTypeRRHSONoMI, HHTypeRRHSOMI
		, HHTypeES, HHTypeSH, HHTypeTH, HIV, SMI, SUD
		, ReportID 
		)
	select count(distinct PersonalID)
		, Gender, RaceEthnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, AHARAdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, AHARAdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, AHARAdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, RRHSOAgeMin, RRHSOAgeMax, HHTypeRRHSONoMI, HHTypeRRHSOMI
		, HHTypeES, HHTypeSH, HHTypeTH, HIV, SMI, SUD
		, ReportID 
	from tlsa_Person
	group by 
		Gender, RaceEthnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, AHARAdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, AHARAdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, AHARAdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, RRHSOAgeMin, RRHSOAgeMax, HHTypeRRHSONoMI, HHTypeRRHSOMI
		, HHTypeES, HHTypeSH, HHTypeTH, HIV, SMI, SUD
		, ReportID 
	
/*
	End LSAPerson
*/
/*
LSA FY2024 Sample Code
Name:  06 LSAHousehold.sql  

FY2024 Changes

		Run code only if the LSAScope is not 'HIC'

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

	6.1 Get Unique Households and Population Identifiers for tlsa_Household
*/



	truncate table tlsa_Household

	insert into tlsa_Household (HoHID, HHType
		, HHChronic, HHVet, HHDisability, HHFleeingDV
		, HoHRaceEthnicity
		, HHParent, ReportID, Step)
	select distinct hhid.HoHID, hhid.ActiveHHType
		, case when min(case hhid.HHChronic when 0 then 99 else hhid.HHChronic end) = 99 then 0 
			else min(case hhid.HHChronic when 0 then 99 else hhid.HHChronic end) end
		, max(hhid.HHVet)
		, max(hhid.HHDisability)
		, case when min(case hhid.HHFleeingDV when 0 then 99 else hhid.HHFleeingDV end) = 99 then 0 
			else min(case hhid.HHFleeingDV when 0 then 99 else hhid.HHFleeingDV end) end
		, lp.RaceEthnicity
		, max(hhid.HHParent)
		, lp.ReportID
		, '6.1'
	from tlsa_HHID hhid
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join tlsa_Person lp on lp.PersonalID = hhid.HoHID 
	where hhid.Active = 1
	group by hhid.HoHID, hhid.ActiveHHType, lp.RaceEthnicity
		, lp.ReportID

/*
	6.2 Set Population Identifiers for LSAHousehold
*/
	update hh
	set HHChild = (select case when count(distinct n.PersonalID) >= 3 then 3
					else count(distinct n.PersonalID) end
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on n.HouseholdID = hhid.HouseholdID and n.Active = 1
				where n.ActiveAge < 18
				and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID)
		, HHAdult = (select case when count(distinct n.PersonalID) >= 3 then 3
					else count(distinct n.PersonalID) end
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on n.HouseholdID = hhid.HouseholdID and n.Active = 1
				where n.ActiveAge between 18 and 65 
					and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
					and n.PersonalID not in 
						(select n17.PersonalID 
						 from tlsa_HHID hh17
						 inner join tlsa_Enrollment n17 on n17.HouseholdID = hh17.HouseholdID and n17.Active = 1
						 where hh17.HoHID = hhid.HoHID and hh17.ActiveHHType = hhid.ActiveHHType
							and n17.ActiveAge < 18))
		, HHNoDOB = (select case when count(distinct n.PersonalID) >= 3 then 3
					else count(distinct n.PersonalID) end
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on n.HouseholdID = hhid.HouseholdID and n.Active = 1
				where n.ActiveAge in (98,99)
				and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID)
		, hh.Step = '6.2.1'
	from tlsa_Household hh
	 
	update hh 
	set hh.HHAdultAge = null, hh.Step = '6.2.2'
	from tlsa_Household hh

	update hh
	set hh.HHAdultAge = hhid.HHAdultAge, hh.Step = '6.2.3' 
	from tlsa_Household hh
	inner join tlsa_HHID hhid
		on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
			and hhid.Active = 1
	where hhid.HHAdultAge = 18

	update hh
	set hh.HHAdultAge = hhid.HHAdultAge, hh.Step = '6.2.4' 
	from tlsa_Household hh
	inner join tlsa_HHID hhid
		on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
			and hhid.Active = 1
	where hhid.HHAdultAge = 24 and hh.HHAdultAge is null

	update hh
	set hh.HHAdultAge = hhid.HHAdultAge, hh.Step = '6.2.5' 
	from tlsa_Household hh
	inner join tlsa_HHID hhid
		on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
			and hhid.Active = 1
	where hhid.HHAdultAge = 55 and hh.HHAdultAge is null

	update hh
	set hh.HHAdultAge = hhid.HHAdultAge, hh.Step = '6.2.6' 
	from tlsa_Household hh
	inner join tlsa_HHID hhid
		on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
			and hhid.Active = 1
	where hhid.HHAdultAge = 25 and hh.HHAdultAge is null

	update hh 
	set hh.HHAdultAge = -1, hh.Step = '6.2.7' 
	from tlsa_Household hh
	where hh.HHAdultAge is null

/*
	6.3 Set tlsa_Household Project Group Status Indicators
*/

	update hh
	set ESTStatus = case when n.nStat is null then 0 
			else n.nStat + n.xStat end
		, hh.Step = '6.3.1'
	from tlsa_Household hh
	left outer join 
		(select hhid.HoHID, hhid.ActiveHHType as HHType
			, min(case when hhid.EntryDate < rpt.ReportStart then 10 else 20 end) as nStat
			, min(case when hhid.ExitDate is null then 1 else 2 end) as xStat
		from tlsa_HHID hhid
		inner join lsa_Report rpt on hhid.EntryDate <= rpt.ReportEnd
		where hhid.Active = 1 and hhid.LSAProjectType in (0,1,2,8)
		group by hhid.HoHID, hhid.ActiveHHType
		) n on n.HoHID = hh.HoHID and n.HHType = hh.HHType

	update hh
	set hh.RRHStatus = case when n.nStat is null then 0 
			else n.nStat + n.xStat end
		, hh.Step = '6.3.2'
	from tlsa_Household hh
	left outer join 
		(select hhid.HoHID, hhid.ActiveHHType as HHType
			, min(case when hhid.EntryDate < rpt.ReportStart then 10 else 20 end) as nStat
			, min(case when hhid.ExitDate is null then 1 else 2 end) as xStat
		from tlsa_HHID hhid
		inner join lsa_Report rpt on hhid.EntryDate <= rpt.ReportEnd
		where hhid.Active = 1 and hhid.LSAProjectType = 13
		group by hhid.HoHID, hhid.ActiveHHType
		) n on n.HoHID = hh.HoHID and n.HHType = hh.HHType

	update hh
	set hh.PSHStatus = case when n.nStat is null then 0 
			else n.nStat + n.xStat end
		, hh.Step = '6.3.3'
	from tlsa_Household hh
	left outer join 
		(select hhid.HoHID, hhid.ActiveHHType as HHType
			, min(case when hhid.EntryDate < rpt.ReportStart then 10 else 20 end) as nStat
			, min(case when hhid.ExitDate is null then 1 else 2 end) as xStat
		from tlsa_HHID hhid
		inner join lsa_Report rpt on hhid.EntryDate <= rpt.ReportEnd
		where hhid.Active = 1 and hhid.LSAProjectType = 3
		group by hhid.HoHID, hhid.ActiveHHType
		) n on n.HoHID = hh.HoHID and n.HHType = hh.HHType

	update hh
	set hh.RRHSOStatus = case when n.nStat is null then 0 
			else n.nStat + n.xStat end
		, hh.Step = '6.3.4'
	from tlsa_Household hh
	left outer join 
		(select hhid.HoHID, hhid.ActiveHHType as HHType
			, min(case when hhid.EntryDate < rpt.ReportStart then 10 else 20 end) as nStat
			, min(case when hhid.ExitDate is null then 1 else 2 end) as xStat
		from tlsa_HHID hhid
		inner join lsa_Report rpt on hhid.EntryDate <= rpt.ReportEnd
		where hhid.Active = 1 and hhid.LSAProjectType = 15
		group by hhid.HoHID, hhid.ActiveHHType
		) n on n.HoHID = hh.HoHID and n.HHType = hh.HHType
		
/*
	6.4 Set tlsa_Household RRH and PSH Move-In Status Indicators
*/

	update hh
	set hh.RRHMoveIn = case when hh.RRHStatus = 0 then -1
		when n.MoveInStat is null then 0 
		else n.MoveInStat end
		, hh.Step = '6.4.1'
	from tlsa_Household hh
	left outer join 
		(select hhid.HoHID, hhid.ActiveHHType as HHType
			, min(case when hhid.MoveInDate >= rpt.ReportStart then 1 else 2 end) as MoveInStat
		from tlsa_HHID hhid
		inner join lsa_Report rpt on hhid.EntryDate <= rpt.ReportEnd
		where hhid.Active = 1 and hhid.MoveInDate is not null and hhid.LSAProjectType = 13
		group by hhid.HoHID, hhid.ActiveHHType
		) n on n.HoHID = hh.HoHID and n.HHType = hh.HHType

	update hh
	set hh.PSHMoveIn = case when hh.PSHStatus = 0 then -1
		when n.MoveInStat is null then 0 
		else n.MoveInStat end
		, hh.Step = '6.4.2'
	from tlsa_Household hh
	left outer join 
		(select hhid.HoHID, hhid.ActiveHHType as HHType
			, min(case when hhid.MoveInDate >= rpt.ReportStart then 1 else 2 end) as MoveInStat
		from tlsa_HHID hhid
		inner join lsa_Report rpt on hhid.EntryDate <= rpt.ReportEnd
		where hhid.Active = 1 and hhid.MoveInDate is not null and hhid.LSAProjectType = 3
		group by hhid.HoHID, hhid.ActiveHHType
		) n on n.HoHID = hh.HoHID and n.HHType = hh.HHType

	update hh
	set hh.RRHSOMoveIn = case when hh.RRHSOStatus = 0 then -1
		when n.MoveInStat is null then 0 
		else n.MoveInStat end
		, hh.Step = '6.4.3'
	from tlsa_Household hh
	left outer join 
		(select hhid.HoHID, hhid.ActiveHHType as HHType
			, min(case when hhid.MoveInDate >= rpt.ReportStart then 1 else 2 end) as MoveInStat
		from tlsa_HHID hhid
		inner join lsa_Report rpt on hhid.EntryDate <= rpt.ReportEnd
		where hhid.Active = 1 and hhid.MoveInDate is not null and hhid.LSAProjectType = 15
		group by hhid.HoHID, hhid.ActiveHHType
		) n on n.HoHID = hh.HoHID and n.HHType = hh.HHType

       
/*
	6.5 Set tlsa_Household Geography for Each Project Group 
	-- Enrollment with latest active date in report period for project group
*/


update hh
set ESTGeography = coc.GeographyType
	, Step = '6.5.1'
from tlsa_Household hh
inner join (select hh.HoHID, hh.HHType
	, MostRecent = (select top 1 ProjectID  
		from tlsa_HHID 
		where LSAProjectType in (0,1,2,8)
			and HoHID = hh.HoHID and ActiveHHType = hh.HHType
		order by coalesce(ExitDate, '9999-9-9') desc, EntryDate desc)
	from tlsa_Household hh
	where hh.ESTStatus > 2) p on p.HoHID = hh.HoHID and p.HHType = hh.HHType
inner join lsa_ProjectCoC coc on coc.ProjectID = p.MostRecent
inner join lsa_Report rpt on rpt.ReportCoC = coc.CoCCode

update hh
set RRHGeography = coc.GeographyType
	, Step = '6.5.2'
from tlsa_Household hh
inner join (select hh.HoHID, hh.HHType
	, MostRecent = (select top 1 ProjectID  
		from tlsa_HHID 
		where LSAProjectType = 13
			and HoHID = hh.HoHID and ActiveHHType = hh.HHType
		order by coalesce(ExitDate, '9999-9-9') desc, EntryDate desc)
	from tlsa_Household hh
	where hh.RRHStatus > 2) p on p.HoHID = hh.HoHID and p.HHType = hh.HHType
inner join lsa_ProjectCoC coc on coc.ProjectID = p.MostRecent
inner join lsa_Report rpt on rpt.ReportCoC = coc.CoCCode

update hh
set PSHGeography = coc.GeographyType
	, Step = '6.5.3'
from tlsa_Household hh
inner join (select hh.HoHID, hh.HHType
	, MostRecent = (select top 1 ProjectID  
		from tlsa_HHID 
		where LSAProjectType = 3
			and HoHID = hh.HoHID and ActiveHHType = hh.HHType
		order by coalesce(ExitDate, '9999-9-9') desc, EntryDate desc)
	from tlsa_Household hh
	where hh.PSHStatus > 2) p on p.HoHID = hh.HoHID and p.HHType = hh.HHType
inner join lsa_ProjectCoC coc on coc.ProjectID = p.MostRecent
inner join lsa_Report rpt on rpt.ReportCoC = coc.CoCCode

update hh
set hh.ESTGeography = case when hh.ESTGeography is not null then hh.ESTGeography
		when hh.ESTStatus > 2 then 99
		else -1 end 
	, hh.RRHGeography = case when hh.RRHGeography is not null then hh.RRHGeography	
		when hh.RRHStatus > 2 then 99
		else -1 end
	, hh.PSHGeography = case when PSHGeography is not null then PSHGeography	
		when PSHStatus > 2 then 99
		else -1 end
	, Step = '6.5.4'
from tlsa_Household hh

/*
	6.6 Set tlsa_Household Living Situation for Each Project Group 
	--earliest active enrollment in project group
*/

	update hh
	set hh.ESTLivingSit = 
		case when hh.ESTStatus = 0 then -1
			when hn.EntryDate <> n.EntryDate 
				or hn.LivingSituation is null 
				or (hn.LivingSituation = 435 and hn.RentalSubsidyType is null)
				then 99
			when hn.LivingSituation in (8,9) then 98
			when hn.LivingSituation = 435 then hn.RentalSubsidyType
			else hn.LivingSituation	end
		, hh.Step = '6.6.1'
	from tlsa_Household hh
	inner join hmis_Enrollment hn on hn.PersonalID = hh.HoHID
	inner join tlsa_Enrollment n on n.EnrollmentID = hn.EnrollmentID
	where hh.ESTStatus = 0 
		or hn.EnrollmentID in 
			(select top 1 hhid.EnrollmentID 
			 from tlsa_HHID hhid
			 where hhid.LSAProjectType in (0,1,2,8) 
				and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				and hhid.Active = 1
			 order by hhid.EntryDate asc)

	update hh
	set hh.RRHLivingSit = 
		case when hh.RRHStatus = 0 then -1 
			when hn.EntryDate <> n.EntryDate 
				or hn.LivingSituation is null 
				or (hn.LivingSituation = 435 and hn.RentalSubsidyType is null)
				then 99
			when hn.LivingSituation in (8,9) then 98
			when hn.LivingSituation = 435 then hn.RentalSubsidyType
			else hn.LivingSituation	end
	, hh.Step = '6.6.2'
	from tlsa_Household hh
	inner join hmis_Enrollment hn on hn.PersonalID = hh.HoHID
	inner join tlsa_Enrollment n on n.EnrollmentID = hn.EnrollmentID
	where hh.RRHStatus = 0  
		or hn.EnrollmentID in 
			(select top 1 hhid.EnrollmentID 
			 from tlsa_HHID hhid
			 where hhid.LSAProjectType = 13 
				and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				and hhid.Active = 1
			 order by hhid.EntryDate asc)

	update hh
	set hh.PSHLivingSit = 
		case when hh.PSHStatus = 0 then -1 
			when hn.EntryDate <> n.EntryDate 
				or hn.LivingSituation is null 
				or (hn.LivingSituation = 435 and hn.RentalSubsidyType is null)
				then 99
			when hn.LivingSituation in (8,9) then 98
			when hn.LivingSituation = 435 then hn.RentalSubsidyType
			else hn.LivingSituation	end
		, hh.Step = '6.6.3'
	from tlsa_Household hh
	inner join hmis_Enrollment hn on hn.PersonalID = hh.HoHID
	inner join tlsa_Enrollment n on n.EnrollmentID = hn.EnrollmentID
	where hh.PSHStatus = 0  
		or hn.EnrollmentID in 
			(select top 1 hhid.EnrollmentID 
			 from tlsa_HHID hhid
			 where hhid.LSAProjectType = 3 
				and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				and hhid.Active = 1
			 order by hhid.EntryDate asc) 

/*
	6.7 Set tlsa_Household Destination for Each Project Group 
	--most recent exit from project group for households not active in project group at ReportEnd
*/

	update hh
	set ESTDestination = 
		case when hh.ESTStatus not in (12,22) then -1
			 else hhid.ExitDest end
		, hh.Step = '6.7.1'
	from tlsa_Household hh 
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID
		and hhid.ActiveHHType = hh.HHType and hhid.Active = 1
	where hh.ESTStatus not in (12,22)  
		or hhid.EnrollmentID in 
			(select top 1 hhid.EnrollmentID 
			 from tlsa_HHID hhid
			 where hhid.LSAProjectType in (0,1,2,8) 
				and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				and hhid.Active = 1
			 order by hhid.ExitDate desc)

	update hh
	set RRHDestination = 
		case when hh.RRHStatus not in (12,22) then -1
			 else hhid.ExitDest end
		, hh.Step = '6.7.2'
	from tlsa_Household hh 
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID
		and hhid.ActiveHHType = hh.HHType and hhid.Active = 1
	where hh.RRHStatus not in (12,22)  
		or hhid.EnrollmentID in 
			(select top 1 hhid.EnrollmentID 
			 from tlsa_HHID hhid
			 where hhid.LSAProjectType = 13 
				and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				and hhid.Active = 1
			 order by hhid.ExitDate desc)

	update hh
	set PSHDestination = 
		case when hh.PSHStatus not in (12,22) then -1
			 else hhid.ExitDest end
		, hh.Step = '6.7.3'
	from tlsa_Household hh 
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID
		and hhid.ActiveHHType = hh.HHType and hhid.Active = 1
	where hh.PSHStatus not in (12,22)  
		or hhid.EnrollmentID in 
			(select top 1 hhid.EnrollmentID 
			 from tlsa_HHID hhid
			 where hhid.LSAProjectType = 3 
				and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				and hhid.Active = 1
			 order by hhid.ExitDate desc)

/*
	6.8	EST/RRH/PSH Population Identifiers for LSAHousehold
*/

	update hh 
	set ESTAC3Plus = coalesce (
			(select max(hhid.AC3Plus)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType in (0,1,2,8)), 0)
		, ESTVet = coalesce (
			(select max(hhid.HHVet)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType in (0,1,2,8)), 0)
		, ESTChronic = coalesce (
			(select min(hhid.HHChronic)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.HHChronic = 1 and hhid.LSAProjectType in (0,1,2,8)), 0)
		, ESTDisability = coalesce (
			(select max(hhid.HHDisability)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType in (0,1,2,8)), 0)
		, ESTFleeingDV = coalesce (
			(select min(hhid.HHFleeingDV)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType in (0,1,2,8) and hhid.HHFleeingDV > 0), 0)
		, ESTParent = coalesce (
			(select max(hhid.HHParent)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType in (0,1,2,8)), 0)
		, ESTAdultAge = coalesce (hh18.HHAdultAge,
			hh24.HHAdultAge,
			hh55.HHAdultAge,
			hh25.HHAdultAge,
			-1)
		, hh.Step = '6.8.1'
	from tlsa_Household hh
	left outer join tlsa_HHID hh18 on hh18.HHAdultAge = 18 
		and hh18.HoHID = hh.HoHID and hh18.ActiveHHType = hh.HHType
		and hh18.Active = 1 and hh18.LSAProjectType in (0,1,2,8)
	left outer join tlsa_HHID hh24 on hh24.HHAdultAge = 24 
		and hh24.HoHID = hh.HoHID and hh24.ActiveHHType = hh.HHType		
		and hh24.Active = 1 and hh24.LSAProjectType in (0,1,2,8)
	left outer join tlsa_HHID hh55 on hh55.HHAdultAge = 55 
		and hh55.HoHID = hh.HoHID and hh55.ActiveHHType = hh.HHType
		and hh55.Active = 1 and hh55.LSAProjectType in (0,1,2,8)
	left outer join tlsa_HHID hh25 on hh25.HHAdultAge = 25 
		and hh25.Active = 1 and hh25.HoHID = hh.HoHID and hh25.ActiveHHType = hh.HHType
		and hh25.LSAProjectType in (0,1,2,8)


	update hh 
	set RRHAC3Plus = coalesce (
			(select max(hhid.AC3Plus)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 13), 0)
		, RRHVet = coalesce (
			(select max(hhid.HHVet)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 13), 0)
		, RRHChronic = coalesce (
			(select min(hhid.HHChronic)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.HHChronic = 1 and hhid.LSAProjectType = 13), 0)
		, RRHDisability = coalesce (
			(select max(hhid.HHDisability)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 13), 0)
		, RRHFleeingDV = coalesce (
			(select min(hhid.HHFleeingDV)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 13 and hhid.HHFleeingDV > 0), 0)
		, RRHParent = coalesce (
			(select max(hhid.HHParent)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 13), 0)
		, RRHAdultAge = coalesce (hh18.HHAdultAge,
			hh24.HHAdultAge,
			hh55.HHAdultAge,
			hh25.HHAdultAge,
			-1)
		, hh.Step = '6.8.2'
	from tlsa_Household hh
	left outer join tlsa_HHID hh18 on hh18.HHAdultAge = 18 
		and hh18.HoHID = hh.HoHID and hh18.ActiveHHType = hh.HHType
		and hh18.Active = 1 and hh18.LSAProjectType = 13
	left outer join tlsa_HHID hh24 on hh24.HHAdultAge = 24 
		and hh24.HoHID = hh.HoHID and hh24.ActiveHHType = hh.HHType		
		and hh24.Active = 1 and hh24.LSAProjectType = 13
	left outer join tlsa_HHID hh55 on hh55.HHAdultAge = 55 
		and hh55.HoHID = hh.HoHID and hh55.ActiveHHType = hh.HHType
		and hh55.Active = 1 and hh55.LSAProjectType = 13
	left outer join tlsa_HHID hh25 on hh25.HHAdultAge = 25 
		and hh25.Active = 1 and hh25.HoHID = hh.HoHID and hh25.ActiveHHType = hh.HHType
		and hh25.LSAProjectType = 13

	update hh 
	set PSHAC3Plus = coalesce (
			(select max(hhid.AC3Plus)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 3), 0)
		, PSHVet = coalesce (
			(select max(hhid.HHVet)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 3), 0)
		, PSHChronic = coalesce (
			(select min(hhid.HHChronic)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.HHChronic = 1 and hhid.LSAProjectType = 3), 0)
		, PSHDisability = coalesce (
			(select max(hhid.HHDisability)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 3), 0)
		, PSHFleeingDV = coalesce (
			(select min(hhid.HHFleeingDV)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 3 and hhid.HHFleeingDV > 0), 0)
		, PSHParent = coalesce (
			(select max(hhid.HHParent)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 3), 0)
		, PSHAdultAge = coalesce (hh18.HHAdultAge,
			hh24.HHAdultAge,
			hh55.HHAdultAge,
			hh25.HHAdultAge,
			-1)
		, hh.Step = '6.8.3'
	from tlsa_Household hh
	left outer join tlsa_HHID hh18 on hh18.HHAdultAge = 18 
		and hh18.HoHID = hh.HoHID and hh18.ActiveHHType = hh.HHType
		and hh18.Active = 1 and hh18.LSAProjectType = 3
	left outer join tlsa_HHID hh24 on hh24.HHAdultAge = 24 
		and hh24.HoHID = hh.HoHID and hh24.ActiveHHType = hh.HHType		
		and hh24.Active = 1 and hh24.LSAProjectType = 3
	left outer join tlsa_HHID hh55 on hh55.HHAdultAge = 55 
		and hh55.HoHID = hh.HoHID and hh55.ActiveHHType = hh.HHType
		and hh55.Active = 1 and hh55.LSAProjectType = 3
	left outer join tlsa_HHID hh25 on hh25.HHAdultAge = 25 
		and hh25.Active = 1 and hh25.HoHID = hh.HoHID and hh25.ActiveHHType = hh.HHType
		and hh25.LSAProjectType = 3

/*
	6.9	System Engagement Status and Return Time 
*/

	update hh
	set hh.FirstEntry = (select min(hhid.EntryDate)
		from tlsa_HHID hhid
		where hhid.Active = 1 and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType)
		, hh.Step = '6.9.1'
	from tlsa_Household hh

	update hh
	set hh.StatEnrollmentID = 
	  (select top 1 prior.EnrollmentID
		from tlsa_HHID prior 
		where prior.ExitDate >= dateadd (dd,-730,hh.FirstEntry)
			and prior.ExitDate < hh.FirstEntry
			and prior.HoHID = hh.HoHID and prior.ActiveHHType = hh.HHType
		order by prior.ExitDate desc)
		, hh.Step = '6.9.2'
	from tlsa_Household hh  
	
	update hh
	set hh.Stat = case 
			when PSHStatus in (11,12) or RRHStatus in (11,12) or ESTStatus in (11,12)
				then 5
			when hh.StatEnrollmentID is null then 1
			when dateadd(dd, 15, prior.ExitDate) > hh.FirstEntry then 5 
			when prior.ExitDest between 400 and 499 then 2
			when prior.ExitDest between 100 and 399 then 3
			else 4 end  
		--Note:  ReturnTime is set to the actual number of days here and grouped into LSA categories
		--       in 6.19 like other counts of days
		, hh.ReturnTime = case 
			when PSHStatus in (11,12) or RRHStatus in (11,12) or ESTStatus in (11,12) 
				or hh.StatEnrollmentID is null 
				-- The line below has been corrected from >= to just >  
				or dateadd(dd, 15, prior.ExitDate) > hh.FirstEntry then -1
			else datediff(dd, prior.ExitDate, hh.FirstEntry) end
		, hh.Step = '6.9.3'
	from tlsa_Household hh
	left outer join tlsa_HHID prior on prior.EnrollmentID = hh.StatEnrollmentID 


/*
	6.10 Get Days In RRH Pre-Move-In
*/
	update hh
	set RRHPreMoveInDays = (select count(distinct cal.theDate)
			from tlsa_HHID hhid 
			inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
			inner join ref_Calendar cal on cal.theDate >= hhid.EntryDate
				and cal.theDate <= coalesce(
						  dateadd(dd, -1, hhid.MoveInDate)
						-- line below corrected to use the ExitDate and not ExitDate - 1
						, hhid.ExitDate
						, rpt.ReportEnd)
			where hhid.LSAProjectType = 13 
				and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.Active = 1) 
		, hh.Step = '6.10'
	from tlsa_Household hh

/*
	6.11 Get Dates Housed in PSH or RRH
*/
	truncate table sys_Time

	insert into sys_Time (HoHID, HHType, sysDate, sysStatus, Step)
	select distinct hhid.HoHID, hhid.ActiveHHType, cal.theDate
		, min(case hhid.LSAProjectType
				when 3 then 1
				else 2 end)
		, '6.11'
	from tlsa_HHID hhid
	inner join tlsa_Household hh on hh.HoHID = hhid.HoHID and hh.HHType = hhid.ActiveHHType
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join ref_Calendar cal on cal.theDate >= hhid.MoveInDate
		and (cal.theDate < hhid.ExitDate 
			or (hhid.ExitDate is null and cal.theDate <= rpt.ReportEnd))
		and cal.theDate >= rpt.LookbackDate
	where hhid.LSAProjectType in (3,13) and hhid.Active = 1
	group by hhid.HoHID, hhid.ActiveHHType, cal.theDate
/*
	6.12  Get Last Inactive Date
*/

	--LastInactive = (FirstEntry - 1 day) for any household where Stat <> 5
	--  and for any household where Stat = 5 but there is no enrollment for the HoHID/HHType
	--  active in the six days prior to First Entry. 
	update hh
	set hh.LastInactive = case 
			when dateadd(dd, -1, hh.FirstEntry) < dateadd(dd, -1, rpt.LookbackDate) then dateadd(dd, -1, rpt.LookbackDate)
			else dateadd(dd, -1, hh.FirstEntry) end
		, hh.Step = '6.12.1'
	from tlsa_Household hh 
	inner join lsa_Report rpt on rpt.ReportEnd >= hh.FirstEntry
	where hh.Stat <> 5 
		or (select top 1 hhid.EnrollmentID 
			from tlsa_HHID hhid
			inner join lsa_Report rpt on hhid.ExitDate < rpt.ReportStart
			where hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType 
			and dateadd(dd, 6, hhid.ExitDate) >= hh.FirstEntry) is null

	insert into sys_TimePadded (HoHID, HHType, Cohort, StartDate, EndDate, Step)
	select distinct hh.HoHID, hh.HHType, 1
		, hhid.EntryDate	
		, case when hhid.ExitDate is null then rpt.ReportEnd 
			else dateadd(dd, 6, hhid.ExitDate) end
		, '6.12.2.a'
	from tlsa_Household hh
	inner join lsa_Report rpt on rpt.ReportStart >= hh.FirstEntry
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
		and (hhid.Active = 1 or hhid.ExitDate < rpt.ReportStart) 
	where hh.LastInactive is null 
		and (hhid.LSAProjectType <> 1)
	union
	select distinct hh.HoHID, hh.HHType, 1
		, bn.DateProvided	
		, dateadd(dd, 6, bn.DateProvided)
		, '6.12.2.b'
	from tlsa_Household hh
	inner join lsa_Report rpt on rpt.ReportStart >= hh.FirstEntry
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
		and (hhid.Active = 1 or hhid.ExitDate < rpt.ReportStart) 
	inner join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID 
		and bn.DateProvided between rpt.LookbackDate and rpt.ReportEnd
		and bn.DateProvided >= hhid.EntryDate
		and (bn.DateProvided < hhid.ExitDate or hhid.ExitDate is null)
		and bn.RecordType = 200 and bn.DateDeleted is null
		and hhid.LSAProjectType = 1
	where hh.LastInactive is null
		
	update hh
	set hh.LastInactive = coalesce(lastDay.inactive, dateadd(dd, -1, rpt.LookbackDate))
		, hh.Step = '6.12.3'
	from tlsa_Household hh
	inner join lsa_Report rpt on rpt.ReportEnd >= hh.FirstEntry
	left outer join 
		(select hh.HoHID, hh.HHType, max(cal.theDate) as inactive
		  from tlsa_Household hh
		  inner join lsa_Report rpt on rpt.ReportID = hh.ReportID
		  inner join ref_Calendar cal on cal.theDate <= rpt.ReportEnd
			and cal.theDate >= rpt.LookbackDate
		  left outer join
			 sys_TimePadded stp on stp.HoHID = hh.HoHID and stp.HHType = hh.HHType
			  and cal.theDate between stp.StartDate and stp.EndDate
		  where stp.HoHID is null
			and cal.theDate < hh.FirstEntry
		group by hh.HoHID, hh.HHType
	  ) lastDay on lastDay.HoHID = hh.HoHID and lastDay.HHType = hh.HHType
	where hh.LastInactive is null

/*
	6.13 Get Dates of Other System Use
*/
	--Transitional Housing (sysStatus = 3) and SafeHaven/Entry-Exit ES (sysStatus = 4)
	insert into sys_Time (HoHID, HHType, sysDate, sysStatus, Step)
	select distinct hh.HoHID, hh.HHType, cal.theDate
		, min(case when hhid.LSAProjectType = 2 then 3 else 4 end)
		, '6.13.1'
	from tlsa_Household hh 
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join ref_Calendar cal on 
		cal.theDate >= hhid.EntryDate
		and cal.theDate > hh.LastInactive
		and cal.theDate <= coalesce(dateadd(dd, -1, hhid.ExitDate), rpt.ReportEnd)
		and cal.theDate >= rpt.LookbackDate
	left outer join sys_Time housed on housed.HoHID = hh.HoHID and housed.HHType = hh.HHType
		and housed.sysDate = cal.theDate
	where housed.sysDate is null 
		and hhid.LSAProjectType in (0,2,8) 
	group by hh.HoHID, hh.HHType, cal.theDate

	--Emergency Shelter (Night-by-Night) (sysStatus = 4)
	insert into sys_Time (HoHID, HHType, sysDate, sysStatus, Step)
	select distinct hh.HoHID, hh.HHType, cal.theDate, 4
		, '6.13.2'
	from tlsa_Household hh 
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200 and bn.DateDeleted is null
	inner join ref_Calendar cal on 
		cal.theDate = bn.DateProvided
		and cal.theDate > hh.LastInactive
		and cal.theDate between hhid.EntryDate and coalesce(dateadd(dd, -1, hhid.ExitDate), rpt.ReportEnd)
		and cal.theDate >= rpt.LookbackDate
	left outer join sys_Time other on other.HoHID = hh.HoHID and other.HHType = hh.HHType
		and other.sysDate = cal.theDate
	where other.sysDate is null and hhid.LSAProjectType = 1 
	
	--Homeless (Time prior to Move-In) in PSH and RRH (sysStatus = 5 and 6)
	insert into sys_Time (HoHID, HHType, sysDate, sysStatus, Step)
	select distinct hh.HoHID, hh.HHType, cal.theDate
		, min (case when hhid.LSAProjectType = 3 then 5 else 6 end)
		, '6.13.3'
	from tlsa_Household hh 
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join ref_Calendar cal on 
		cal.theDate >= hhid.EntryDate
		and cal.theDate <= coalesce(dateadd(dd, -1, hhid.MoveInDate), dateadd(dd, -1, hhid.ExitDate), rpt.ReportEnd)
		and cal.theDate >= rpt.LookbackDate
	left outer join sys_Time other on other.HoHID = hh.HoHID and other.HHType = hh.HHType
		and other.sysDate = cal.theDate
	where cal.theDate > hh.LastInactive
		and other.sysDate is null and hhid.LSAProjectType in (3,13)
	group by hh.HoHID, hh.HHType, cal.theDate

/*
	6.14 Get Other Dates Homeless from 3.917 Living Situation
*/
	--If there are enrollments in sys_Enrollment where EntryDate > LastInactive,
	-- dates between the earliest DateToStreetESSH and LastInactive --
	-- i.e., dates without a potential status conflict based on other system use --
	-- populate Other3917Days as the difference in days between DateToStreetESSH
	-- and LastInactive + 1. 

	--NOTE:  This statement will leave Other3917Days NULL for households without
	--at least one DateToStreetESSH prior to LastInactive.  Final value for Other3917Days
	--is the sum of days prior to LastInactive (if any) PLUS the count of dates 
	--after LastInactive that are added to sys_Time in the next statement.  
	update hh
	set hh.Other3917Days = (select datediff (dd,
			(select top 1 hn.DateToStreetESSH
			from tlsa_HHID hhid 
			inner join hmis_Enrollment hn on hn.EnrollmentID = hhid.EnrollmentID
			where hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				and hhid.EntryDate > hh.LastInactive
				and hn.DateToStreetESSH <= hh.LastInactive 
				and (hhid.LSAProjectType in (0,1,8)
					or hn.LivingSituation between 100 and 199
					or (hn.LengthOfStay in (10,11) and hn.PreviousStreetESSH = 1)
					or (hn.LivingSituation between 200 and 299 
						and hn.LengthOfStay in (2,3) and hn.PreviousStreetESSH = 1))
			order by hn.DateToStreetESSH asc)
		, hh.LastInactive)) + 1
		, hh.Step = '6.14.1'
	from tlsa_Household hh

	insert into sys_Time (HoHID, HHType, sysDate, sysStatus, Step)
	select distinct other3917.HoHID, other3917.HHType, cal.theDate, 7
		, '6.14.2'
	from ref_Calendar cal
	inner join (select hh.HoHID, hh.HHType
			, case when hn.DateToStreetESSH >= hh.LastInactive then hn.DateToStreetESSH else hh.LastInactive end as StartDate
			, hhid.EntryDate as EndDate
		from tlsa_Household hh 
		inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.EntryHHType = hh.HHType
		inner join hmis_Enrollment hn on hn.EnrollmentID = hhid.EnrollmentID
		where hhid.EntryDate > hh.LastInactive
			and (hhid.LSAProjectType in (0,1,8)
				or hn.LivingSituation between 100 and 199
				or (hn.LengthOfStay in (10,11) and hn.PreviousStreetESSH = 1)
				or (hn.LivingSituation between 200 and 299
					and hn.LengthOfStay in (2,3) and hn.PreviousStreetESSH = 1))
		) other3917 on other3917.StartDate <= cal.theDate and other3917.EndDate > cal.theDate
	left outer join sys_Time priorStat on priorStat.HoHID = other3917.HoHID and priorStat.HHType = other3917.HHType
		and priorStat.sysDate = cal.theDate
	where priorStat.sysDate is null 

/*
	6.15 Set System Use Days for LSAHousehold
*/
	update hh
	set ESDays = (select count(distinct st.sysDate)
			from sys_Time st 
			where st.sysStatus = 4
			and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, THDays = (select count(distinct st.sysDate)
			from sys_Time st 
			where st.sysStatus = 3
			and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, ESTDays = (select count(distinct st.sysDate)
			from sys_Time st 
			where st.sysStatus in (3,4)
			and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, RRHPSHPreMoveInDays = (select count(distinct st.sysDate)
			from sys_Time st 
			where st.sysStatus in (5,6)
			and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, RRHHousedDays = (select count(distinct st.sysDate)
			from sys_Time st 
			where st.sysStatus = 2
			and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, SystemDaysNotPSHHoused = (select count(distinct st.sysDate)
			from sys_Time st 
			where st.sysStatus in (2,3,4,5,6)
			and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, SystemHomelessDays = (select count(distinct st.sysDate)
			from sys_Time st 
			where st.sysStatus in (3,4,5,6)
			and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, Other3917Days = case 
				when Other3917Days is null then 0 
				else Other3917Days end 
				+ (select count(distinct st.sysDate)
					from sys_Time st 
					where st.sysStatus = 7
					and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, TotalHomelessDays = case 
				when Other3917Days is null then 0 
				else Other3917Days end + (select count(distinct st.sysDate)
			from sys_Time st 
			where st.sysStatus in (3,4,5,6,7)
			and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, PSHHousedDays = (select count(distinct st.sysDate)
			from sys_Time st 
			where st.sysStatus = 1
			and st.HoHID = hh.HoHID and st.HHType = hh.HHType)
		, Step = '6.15'
	from tlsa_Household hh

/*
	6.16 Update EST/RRH/PSHStatus 
*/

	update hh
	set hh.ESTStatus = 2
		, hh.Step = '6.16.1'
	from tlsa_Household hh
	inner join sys_Time st on st.HoHID = hh.HoHID and st.HHType = hh.HHType
	where hh.ESTStatus = 0 
		and st.sysStatus in (3,4) 

	update hh
	set hh.RRHStatus = 2
		, hh.Step = '6.16.2'
	from tlsa_Household hh
	inner join sys_Time st on st.HoHID = hh.HoHID and st.HHType = hh.HHType
	where hh.RRHStatus = 0 
		and st.sysStatus = 6

	update hh
	set hh.PSHStatus = 2
		, hh.Step = '6.16.3'
	from tlsa_Household hh
	inner join sys_Time st on st.HoHID = hh.HoHID and st.HHType = hh.HHType
	where hh.PSHStatus = 0 
		and st.sysStatus = 5

/*
	6.17 Set EST/RRH/PSHAHAR
*/
	update hh
	set ESTAHAR = 0, RRHAHAR = 0, PSHAHAR = 0
		, hh.Step = '6.17.1'
	from tlsa_Household hh

	update hh
	set hh.ESTAHAR = 1
		, hh.Step = '6.17.2'
	from tlsa_Household hh
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType 
	inner join tlsa_Enrollment n on n.HouseholdID = hhid.HouseholdID and n.PersonalID = hhid.HoHID
	where n.AHAR = 1 and hhid.LSAProjectType in (0,1,2,8)

	update hh
	set hh.RRHAHAR = 1
		, hh.Step = '6.17.3'
	from tlsa_Household hh
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType 
	inner join tlsa_Enrollment n on n.HouseholdID = hhid.HouseholdID and n.PersonalID = hhid.HoHID
	where n.AHAR = 1 and hhid.LSAProjectType = 13 

	update hh
	set hh.PSHAHAR = 1
		, hh.Step = '6.17.4'
	from tlsa_Household hh
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType 
	inner join tlsa_Enrollment n on n.HouseholdID = hhid.HouseholdID and n.PersonalID = hhid.HoHID
	where n.AHAR = 1 and hhid.LSAProjectType = 3 

/*
	6.18 Set SystemPath for LSAHousehold
*/

update hh
set hh.SystemPath = 
	case when hh.ESTStatus not in (21,22) and hh.RRHStatus not in (21,22) and hh.PSHMoveIn = 2 
		then -1
	when hh.ESDays >= 1 and hh.THDays = 0 and hh.RRHStatus = 0 and hh.PSHStatus = 0 
		then 1
	when hh.ESDays = 0 and hh.THDays >= 1 and hh.RRHStatus = 0 and hh.PSHStatus = 0 
		then 2
	when hh.ESDays >= 1 and hh.THDays >= 1 and hh.RRHStatus = 0 and hh.PSHStatus = 0 
		then 3
	when hh.ESTStatus = 0 and hh.RRHStatus >= 11 and hh.PSHStatus = 0 
		then 4
	when hh.ESDays >= 1 and hh.THDays = 0 and hh.RRHStatus >= 2 and hh.PSHStatus = 0 
		then 5
	when hh.ESDays = 0 and hh.THDays >= 1 and hh.RRHStatus >= 2 and hh.PSHStatus = 0 
		then 6
	when hh.ESDays >= 1 and hh.THDays >= 1 and hh.RRHStatus >= 2 and hh.PSHStatus = 0 
		then 7
	when hh.ESTStatus = 0 and hh.RRHStatus = 0 and hh.PSHStatus >= 11 and hh.PSHMoveIn <> 2
		then 8
	when hh.ESDays >= 1 and hh.THDays = 0 and hh.RRHStatus = 0 and hh.PSHStatus >= 11 and hh.PSHMoveIn <> 2
		then 9
	when hh.ESTStatus in (21,22) and hh.ESDays >= 1 and hh.THDays = 0 and hh.RRHStatus = 0 and hh.PSHStatus >= 11 and hh.PSHMoveIn = 2
		then 9
	when hh.ESDays >= 1 and hh.THDays = 0 and hh.RRHStatus >= 2 and hh.PSHStatus >= 11 and hh.PSHMoveIn <> 2
		then 10
	when hh.ESTStatus in (21,22) and hh.ESDays >= 1 and hh.THDays = 0 and hh.RRHStatus in (21,22) and hh.PSHStatus >= 11 and hh.PSHMoveIn = 2
		then 10
	when hh.ESTStatus = 0 and hh.RRHStatus >= 2 and hh.PSHStatus >= 11 and hh.PSHMoveIn <> 2
		then 11
	when hh.ESTStatus = 0 and hh.RRHStatus in (21,22) and hh.PSHStatus >= 11 and hh.PSHMoveIn = 2
		then 11
	else 12 end
	, hh.Step = '6.18'
from tlsa_Household hh

/*
	6.19 LSAHousehold
*/

truncate table lsa_Household
insert into lsa_Household(RowTotal
	, Stat, ReturnTime
	, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV, HoHRaceEthnicity
	, HHAdult, HHChild, HHNoDOB
	, HHAdultAge, HHParent
	, ESTStatus, ESTGeography, ESTLivingSit, ESTDestination, ESTChronic, ESTVet, ESTDisability, ESTFleeingDV, ESTAC3Plus, ESTAdultAge, ESTParent
	, RRHStatus, RRHMoveIn, RRHGeography, RRHLivingSit, RRHDestination, RRHPreMoveInDays, RRHChronic, RRHVet, RRHDisability, RRHFleeingDV, RRHAC3Plus, RRHAdultAge, RRHParent
	, PSHStatus, PSHMoveIn, PSHGeography, PSHLivingSit, PSHDestination, PSHHousedDays, PSHChronic, PSHVet, PSHDisability, PSHFleeingDV, PSHAC3Plus, PSHAdultAge, PSHParent
	, ESDays, THDays, ESTDays, RRHPSHPreMoveInDays, RRHHousedDays, SystemDaysNotPSHHoused, SystemHomelessDays, Other3917Days, TotalHomelessDays
	, SystemPath, ESTAHAR, RRHAHAR, PSHAHAR, RRHSOStatus, RRHSOMoveIn, ReportID 
)
select count (distinct HoHID + cast(HHType as nvarchar)), Stat
	, case when Stat in (1,5) then -1
		when ReturnTime between 15 and 30 then 30
		when ReturnTime between 31 and 60 then 60
		when ReturnTime between 61 and 90 then 90
		when ReturnTime between 91 and 180 then 180
		when ReturnTime between 181 and 365 then 365
		when ReturnTime between 366 and 547 then 547
		when ReturnTime >= 548 then 730
		else ReturnTime end
	, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV, HoHRaceEthnicity
	, HHAdult, HHChild, HHNoDOB
	, HHAdultAge, HHParent
	, ESTStatus, ESTGeography, ESTLivingSit, ESTDestination, ESTChronic, ESTVet, ESTDisability, ESTFleeingDV, ESTAC3Plus, ESTAdultAge, ESTParent
	, RRHStatus, RRHMoveIn, RRHGeography, RRHLivingSit, RRHDestination 	
	, case when RRHPreMoveInDays between 1 and 7 then 7
		when RRHPreMoveInDays between 8 and 30 then 30 
		when RRHPreMoveInDays between 31 and 60 then 60 
		when RRHPreMoveInDays between 61 and 90 then 90 
		when RRHPreMoveInDays between 91 and 180 then 180 
		when RRHPreMoveInDays between 181 and 365 then 365 
		when RRHPreMoveInDays between 366 and 547 then 547 
		when RRHPreMoveInDays between 548 and 730 then 730 
		when RRHPreMoveInDays between 731 and 1094 then 1094 
		when RRHPreMoveInDays > 1094 then 1095
		else RRHPreMoveInDays end 
	, RRHChronic, RRHVet, RRHDisability, RRHFleeingDV, RRHAC3Plus, RRHAdultAge, RRHParent
	, PSHStatus, PSHMoveIn, PSHGeography, PSHLivingSit, PSHDestination	
	--NOTE:  Groupings for PSHHousedDays differ from all other xDays columns
	, case when PSHHousedDays between 1 and 90 then 3
		when PSHHousedDays between 91 and 180 then 6 
		when PSHHousedDays between 181 and 365 then 12 
		when PSHHousedDays between 366 and 730 then 24 
		when PSHHousedDays between 731 and 1095 then 36 
		when PSHHousedDays between 1096 and 1460 then 48 
		when PSHHousedDays between 1461 and 1825 then 60 
		when PSHHousedDays between 1826 and 2555 then 84 
		when PSHHousedDays between 2556 and 3650 then 120 
		when PSHHousedDays > 3650 then 121
		else PSHHousedDays end 
, PSHChronic, PSHVet, PSHDisability, PSHFleeingDV, PSHAC3Plus, PSHAdultAge, PSHParent
	, case when ESDays between 1 and 7 then 7
		when ESDays between 8 and 30 then 30 
		when ESDays between 31 and 60 then 60 
		when ESDays between 61 and 90 then 90 
		when ESDays between 91 and 180 then 180 
		when ESDays between 181 and 365 then 365 
		when ESDays between 366 and 547 then 547 
		when ESDays between 548 and 730 then 730 
		when ESDays between 731 and 1094 then 1094 
		when ESDays > 1094 then 1095
		else ESDays end 
	, case when THDays between 1 and 7 then 7
		when THDays between 8 and 30 then 30 
		when THDays between 31 and 60 then 60 
		when THDays between 61 and 90 then 90 
		when THDays between 91 and 180 then 180 
		when THDays between 181 and 365 then 365 
		when THDays between 366 and 547 then 547 
		when THDays between 548 and 730 then 730 
		when THDays between 731 and 1094 then 1094 
		when THDays > 1094 then 1095
		else THDays end 
	, case when ESTDays between 1 and 7 then 7
		when ESTDays between 8 and 30 then 30 
		when ESTDays between 31 and 60 then 60 
		when ESTDays between 61 and 90 then 90 
		when ESTDays between 91 and 180 then 180 
		when ESTDays between 181 and 365 then 365 
		when ESTDays between 366 and 547 then 547 
		when ESTDays between 548 and 730 then 730 
		when ESTDays between 731 and 1094 then 1094 
		when ESTDays > 1094 then 1095
		else ESTDays end 
	, case when RRHPSHPreMoveInDays between 1 and 7 then 7
		when RRHPSHPreMoveInDays between 8 and 30 then 30 
		when RRHPSHPreMoveInDays between 31 and 60 then 60 
		when RRHPSHPreMoveInDays between 61 and 90 then 90 
		when RRHPSHPreMoveInDays between 91 and 180 then 180 
		when RRHPSHPreMoveInDays between 181 and 365 then 365 
		when RRHPSHPreMoveInDays between 366 and 547 then 547 
		when RRHPSHPreMoveInDays between 548 and 730 then 730 
		when RRHPSHPreMoveInDays between 731 and 1094 then 1094 
		when RRHPSHPreMoveInDays > 1094 then 1095
		else RRHPSHPreMoveInDays end 
	, case when RRHHousedDays between 1 and 7 then 7
		when RRHHousedDays between 8 and 30 then 30 
		when RRHHousedDays between 31 and 60 then 60 
		when RRHHousedDays between 61 and 90 then 90 
		when RRHHousedDays between 91 and 180 then 180 
		when RRHHousedDays between 181 and 365 then 365 
		when RRHHousedDays between 366 and 547 then 547 
		when RRHHousedDays between 548 and 730 then 730 
		when RRHHousedDays between 731 and 1094 then 1094 
		when RRHHousedDays > 1094 then 1095
		else RRHHousedDays end 
	, case when SystemDaysNotPSHHoused between 1 and 7 then 7
		when SystemDaysNotPSHHoused between 8 and 30 then 30 
		when SystemDaysNotPSHHoused between 31 and 60 then 60 
		when SystemDaysNotPSHHoused between 61 and 90 then 90 
		when SystemDaysNotPSHHoused between 91 and 180 then 180 
		when SystemDaysNotPSHHoused between 181 and 365 then 365 
		when SystemDaysNotPSHHoused between 366 and 547 then 547 
		when SystemDaysNotPSHHoused between 548 and 730 then 730 
		when SystemDaysNotPSHHoused between 731 and 1094 then 1094 
		when SystemDaysNotPSHHoused > 1094 then 1095
		else SystemDaysNotPSHHoused end 
	, case when SystemHomelessDays between 1 and 7 then 7
		when SystemHomelessDays between 8 and 30 then 30 
		when SystemHomelessDays between 31 and 60 then 60 
		when SystemHomelessDays between 61 and 90 then 90 
		when SystemHomelessDays between 91 and 180 then 180 
		when SystemHomelessDays between 181 and 365 then 365 
		when SystemHomelessDays between 366 and 547 then 547 
		when SystemHomelessDays between 548 and 730 then 730 
		when SystemHomelessDays between 731 and 1094 then 1094 
		when SystemHomelessDays > 1094 then 1095
		else SystemHomelessDays end 
	, case when Other3917Days between 1 and 7 then 7
		when Other3917Days between 8 and 30 then 30 
		when Other3917Days between 31 and 60 then 60 
		when Other3917Days between 61 and 90 then 90 
		when Other3917Days between 91 and 180 then 180 
		when Other3917Days between 181 and 365 then 365 
		when Other3917Days between 366 and 547 then 547 
		when Other3917Days between 548 and 730 then 730 
		when Other3917Days between 731 and 1094 then 1094 
		when Other3917Days > 1094 then 1095
		else Other3917Days end 
	, case when TotalHomelessDays between 1 and 7 then 7
		when TotalHomelessDays between 8 and 30 then 30 
		when TotalHomelessDays between 31 and 60 then 60 
		when TotalHomelessDays between 61 and 90 then 90 
		when TotalHomelessDays between 91 and 180 then 180 
		when TotalHomelessDays between 181 and 365 then 365 
		when TotalHomelessDays between 366 and 547 then 547 
		when TotalHomelessDays between 548 and 730 then 730 
		when TotalHomelessDays between 731 and 1094 then 1094 
		when TotalHomelessDays > 1094 then 1095
		else TotalHomelessDays end 
	, SystemPath, ESTAHAR, RRHAHAR, PSHAHAR, RRHSOStatus, RRHSOMoveIn, ReportID 
from tlsa_Household
group by Stat	
	, case when Stat in (1,5) then -1
		when ReturnTime between 15 and 30 then 30
		when ReturnTime between 31 and 60 then 60
		when ReturnTime between 61 and 90 then 90
		when ReturnTime between 91 and 180 then 180
		when ReturnTime between 181 and 365 then 365
		when ReturnTime between 366 and 547 then 547
		when ReturnTime >= 548 then 730
		else ReturnTime end
	, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV, HoHRaceEthnicity
	, HHAdult, HHChild, HHNoDOB
	, HHAdultAge, HHParent
	, ESTStatus, ESTGeography, ESTLivingSit, ESTDestination, ESTChronic, ESTVet, ESTDisability, ESTFleeingDV, ESTAC3Plus, ESTAdultAge, ESTParent
	, RRHStatus, RRHMoveIn, RRHGeography, RRHLivingSit, RRHDestination	
	, case when RRHPreMoveInDays between 1 and 7 then 7
		when RRHPreMoveInDays between 8 and 30 then 30 
		when RRHPreMoveInDays between 31 and 60 then 60 
		when RRHPreMoveInDays between 61 and 90 then 90 
		when RRHPreMoveInDays between 91 and 180 then 180 
		when RRHPreMoveInDays between 181 and 365 then 365 
		when RRHPreMoveInDays between 366 and 547 then 547 
		when RRHPreMoveInDays between 548 and 730 then 730 
		when RRHPreMoveInDays between 731 and 1094 then 1094 
		when RRHPreMoveInDays > 1094 then 1095
		else RRHPreMoveInDays end 
	, RRHChronic, RRHVet, RRHDisability, RRHFleeingDV, RRHAC3Plus, RRHAdultAge, RRHParent
	, PSHStatus, PSHMoveIn, PSHGeography, PSHLivingSit, PSHDestination	
	, case when PSHHousedDays between 1 and 90 then 3
		when PSHHousedDays between 91 and 180 then 6 
		when PSHHousedDays between 181 and 365 then 12 
		when PSHHousedDays between 366 and 730 then 24 
		when PSHHousedDays between 731 and 1095 then 36 
		when PSHHousedDays between 1096 and 1460 then 48 
		when PSHHousedDays between 1461 and 1825 then 60 
		when PSHHousedDays between 1826 and 2555 then 84 
		when PSHHousedDays between 2556 and 3650 then 120 
		when PSHHousedDays > 3650 then 121
		else PSHHousedDays end 
, PSHChronic, PSHVet, PSHDisability, PSHFleeingDV, PSHAC3Plus, PSHAdultAge, PSHParent
	, case when ESDays between 1 and 7 then 7
		when ESDays between 8 and 30 then 30 
		when ESDays between 31 and 60 then 60 
		when ESDays between 61 and 90 then 90 
		when ESDays between 91 and 180 then 180 
		when ESDays between 181 and 365 then 365 
		when ESDays between 366 and 547 then 547 
		when ESDays between 548 and 730 then 730 
		when ESDays between 731 and 1094 then 1094 
		when ESDays > 1094 then 1095
		else ESDays end 
	, case when THDays between 1 and 7 then 7
		when THDays between 8 and 30 then 30 
		when THDays between 31 and 60 then 60 
		when THDays between 61 and 90 then 90 
		when THDays between 91 and 180 then 180 
		when THDays between 181 and 365 then 365 
		when THDays between 366 and 547 then 547 
		when THDays between 548 and 730 then 730 
		when THDays between 731 and 1094 then 1094 
		when THDays > 1094 then 1095
		else THDays end 
	, case when ESTDays between 1 and 7 then 7
		when ESTDays between 8 and 30 then 30 
		when ESTDays between 31 and 60 then 60 
		when ESTDays between 61 and 90 then 90 
		when ESTDays between 91 and 180 then 180 
		when ESTDays between 181 and 365 then 365 
		when ESTDays between 366 and 547 then 547 
		when ESTDays between 548 and 730 then 730 
		when ESTDays between 731 and 1094 then 1094 
		when ESTDays > 1094 then 1095
		else ESTDays end 
	, case when RRHPSHPreMoveInDays between 1 and 7 then 7
		when RRHPSHPreMoveInDays between 8 and 30 then 30 
		when RRHPSHPreMoveInDays between 31 and 60 then 60 
		when RRHPSHPreMoveInDays between 61 and 90 then 90 
		when RRHPSHPreMoveInDays between 91 and 180 then 180 
		when RRHPSHPreMoveInDays between 181 and 365 then 365 
		when RRHPSHPreMoveInDays between 366 and 547 then 547 
		when RRHPSHPreMoveInDays between 548 and 730 then 730 
		when RRHPSHPreMoveInDays between 731 and 1094 then 1094 
		when RRHPSHPreMoveInDays > 1094 then 1095
		else RRHPSHPreMoveInDays end 
	, case when RRHHousedDays between 1 and 7 then 7
		when RRHHousedDays between 8 and 30 then 30 
		when RRHHousedDays between 31 and 60 then 60 
		when RRHHousedDays between 61 and 90 then 90 
		when RRHHousedDays between 91 and 180 then 180 
		when RRHHousedDays between 181 and 365 then 365 
		when RRHHousedDays between 366 and 547 then 547 
		when RRHHousedDays between 548 and 730 then 730 
		when RRHHousedDays between 731 and 1094 then 1094 
		when RRHHousedDays > 1094 then 1095
		else RRHHousedDays end 
	, case when SystemDaysNotPSHHoused between 1 and 7 then 7
		when SystemDaysNotPSHHoused between 8 and 30 then 30 
		when SystemDaysNotPSHHoused between 31 and 60 then 60 
		when SystemDaysNotPSHHoused between 61 and 90 then 90 
		when SystemDaysNotPSHHoused between 91 and 180 then 180 
		when SystemDaysNotPSHHoused between 181 and 365 then 365 
		when SystemDaysNotPSHHoused between 366 and 547 then 547 
		when SystemDaysNotPSHHoused between 548 and 730 then 730 
		when SystemDaysNotPSHHoused between 731 and 1094 then 1094 
		when SystemDaysNotPSHHoused > 1094 then 1095
		else SystemDaysNotPSHHoused end 
	, case when SystemHomelessDays between 1 and 7 then 7
		when SystemHomelessDays between 8 and 30 then 30 
		when SystemHomelessDays between 31 and 60 then 60 
		when SystemHomelessDays between 61 and 90 then 90 
		when SystemHomelessDays between 91 and 180 then 180 
		when SystemHomelessDays between 181 and 365 then 365 
		when SystemHomelessDays between 366 and 547 then 547 
		when SystemHomelessDays between 548 and 730 then 730 
		when SystemHomelessDays between 731 and 1094 then 1094 
		when SystemHomelessDays > 1094 then 1095
		else SystemHomelessDays end 
	, case when Other3917Days between 1 and 7 then 7
		when Other3917Days between 8 and 30 then 30 
		when Other3917Days between 31 and 60 then 60 
		when Other3917Days between 61 and 90 then 90 
		when Other3917Days between 91 and 180 then 180 
		when Other3917Days between 181 and 365 then 365 
		when Other3917Days between 366 and 547 then 547 
		when Other3917Days between 548 and 730 then 730 
		when Other3917Days between 731 and 1094 then 1094 
		when Other3917Days > 1094 then 1095
		else Other3917Days end 
	, case when TotalHomelessDays between 1 and 7 then 7
		when TotalHomelessDays between 8 and 30 then 30 
		when TotalHomelessDays between 31 and 60 then 60 
		when TotalHomelessDays between 61 and 90 then 90 
		when TotalHomelessDays between 91 and 180 then 180 
		when TotalHomelessDays between 181 and 365 then 365 
		when TotalHomelessDays between 366 and 547 then 547 
		when TotalHomelessDays between 548 and 730 then 730 
		when TotalHomelessDays between 731 and 1094 then 1094 
		when TotalHomelessDays > 1094 then 1095
		else TotalHomelessDays end 
	, SystemPath, ESTAHAR, RRHAHAR, PSHAHAR, RRHSOStatus, RRHSOMoveIn, ReportID 

/*
LSA FY2024 Sample Code
Name:  07 LSAExit.sql  

FY2024 Changes
		
	Run code only if the LSAScope is not 'HIC'
	Use intermediate reporting tables specific to LSAExit (ch_Include_exit, ch_Exclude_exit, ch_Episodes_exit, sys_TimePadded_exit)
		rather than truncating and re-using the tables used for LSAPerson and LSAHousehold

	(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

7.1 Identify Qualifying Exits in Exit Cohort Periods
*/
select * from lsa_Exit
if (select LSAScope from lsa_Report) <> 3
begin

	update hhid
	set hhid.ExitCohort = cd.Cohort
		, hhid.Step = '7.1'
	from tlsa_HHID hhid
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join tlsa_CohortDates cd on hhid.ExitDate between cd.CohortStart and cd.CohortEnd
		and cd.Cohort between -2 and 0
	left outer join lsa_Project p on p.ProjectID = hhid.ProjectID 
	left outer join tlsa_HHID disqualify on disqualify.HoHID = hhid.HoHID
		and ((cd.Cohort = -2 and disqualify.Exit2HHType = hhid.Exit2HHType) 
				or (cd.Cohort = -1 and disqualify.Exit1HHType = hhid.Exit1HHType)
				or (cd.Cohort = 0 and disqualify.ActiveHHType = hhid.ActiveHHType)
			)
		and	disqualify.EnrollmentID <> hhid.EnrollmentID 
		and disqualify.EntryDate < dateadd(dd, 14, hhid.ExitDate)
		and (disqualify.ExitDate is null or disqualify.ExitDate > hhid.ExitDate)
	where disqualify.EnrollmentID is null
		and (rpt.LSAScope = 1 or p.ProjectID is not null)

/*
	7.2 Select Reportable Exits
*/
	truncate table tlsa_Exit

	insert into tlsa_Exit (Cohort, HoHID, HHType, ReportID, Step)
	select distinct hhid.ExitCohort, hhid.HoHID
		, case hhid.ExitCohort when -2 then hhid.Exit2HHType
			when -1 then hhid.Exit1HHType
			else hhid.ActiveHHType end
		, rpt.ReportID
		, '7.2.1'
	from tlsa_HHID hhid
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	where hhid.ExitCohort is not null 

update ex
set ex.QualifyingExitHHID = (select top 1 qx.HouseholdID 
			from tlsa_HHID qx 
			where qx.ExitCohort = ex.Cohort and qx.HoHID = ex.HoHID
				and case ex.Cohort when -2 then qx.Exit2HHType
					when -1 then qx.Exit1HHType
					else qx.ActiveHHType end
					= ex.HHType
			order by case when qx.ExitDest between 400 and 499 then 2
                      when qx.ExitDest between 100 and 399 then 3
                      else 4 end asc
					 , qx.ExitDate asc
					 , qx.ExitDest asc
					 , qx.EntryDate desc
					 , qx.EnrollmentID desc
			)
		, ex.Step = '7.2.2'
from tlsa_Exit ex

update ex
set ex.ExitFrom = case 
              when qx.LSAProjectType in (0, 1) then 2
              when qx.LSAProjectType = 2 then 3 
              when qx.LSAProjectType = 8 then 4
              when qx.LSAProjectType = 13 and qx.MoveInDate is not null then 5
              when qx.LSAProjectType = 3 and qx.MoveInDate is not null then 6
              when qx.LSAProjectType = 13 then 7
              when qx.LSAProjectType = 3 then 8 
              when qx.LSAProjectType = 15 and qx.MoveInDate is not null then 9
			  else 10  end
		, ex.ExitTo = qx.ExitDest
		, ex.ReturnStart = dateadd(dd, 15, qx.ExitDate)
		, ex.ReturnEnd = dateadd(dd, 730, qx.ExitDate)
		, ex.Step = '7.2.3'
from tlsa_Exit ex
inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID

/*
	7.3 Return Time for Exit Cohort Households
*/

update ex
set ReturnDate = (select min(rn.EntryDate)
		from tlsa_HHID rn
		where rn.HoHID = ex.HoHID	 
			and rn.EntryDate between ex.ReturnStart and ex.ReturnEnd
			and ex.HHType = case ex.Cohort when 0 then rn.ActiveHHType	
				when -1 then rn.Exit1HHType
				else rn.Exit2HHType end)
		, Step = '7.3.1'
from tlsa_Exit ex

update ex 
set ReturnTime = case when ReturnDate is null then -1
		else datediff(dd, ExitDate, ReturnDate) end
	, Step = '7.3.2' 
from tlsa_Exit ex 
		
/*
	7.4 HoH and Adult Members of Exit Cohorts
*/

	truncate table tlsa_ExitHoHAdult

	insert into tlsa_ExitHoHAdult (
		PersonalID, QualifyingExitHHID,
		Cohort, CHStart, LastActive, 
		Step)
	select distinct n.PersonalID, ex.QualifyingExitHHID,
		ex.Cohort, 
		dateadd(dd, 1, (dateadd(yy, -3, max(n.ExitDate)))),
		max(n.ExitDate), '7.4.1'
	from tlsa_Exit ex
	inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID
	inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
	inner join tlsa_Enrollment n on n.HouseholdID = ex.QualifyingExitHHID 
		and n.ExitDate between cd.CohortStart and cd.CohortEnd
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
	where (n.RelationshipToHoH = 1 
			or (cd.Cohort = 0 and n.ActiveAge between 18 and 65)
			or (cd.Cohort = -1 and n.Exit1Age between 18 and 65)
			or (cd.Cohort = -2 and n.Exit2Age between 18 and 65))
		and (ex.ExitFrom <> 3 or hhid.EntryDate > dateadd(yy, -1, hhid.ExitDate))
		and (ex.ExitFrom not in (5,6) or hhid.MoveInDate > dateadd(yy, -1, hhid.ExitDate))
	group by n.PersonalID, ex.QualifyingExitHHID, ex.Cohort

	update hoha
	set hoha.DisabilityStatus = 1, Step = '7.4.2'
	from tlsa_ExitHoHAdult hoha
	inner join tlsa_Enrollment n on n.HouseholdID = hoha.QualifyingExitHHID 
		and n.PersonalID = hoha.PersonalID and n.DisabilityStatus = 1

	update hoha
	set hoha.DisabilityStatus = 0, Step = '7.4.3'
	from tlsa_ExitHoHAdult hoha
	inner join tlsa_Enrollment n on n.HouseholdID = hoha.QualifyingExitHHID 
		and n.PersonalID = hoha.PersonalID and n.DisabilityStatus = 0
	where hoha.DisabilityStatus is null

	update hoha
	set hoha.DisabilityStatus = 99, Step = '7.4.4'
	from tlsa_ExitHoHAdult hoha
	where hoha.DisabilityStatus is null



	update hoha
	set CHTime = 400, CHTimeStatus = 2, Step = '7.4.5'
	from tlsa_ExitHoHAdult hoha
	inner join tlsa_CohortDates cd on cd.Cohort = hoha.Cohort
	inner join tlsa_Enrollment n on n.HouseholdID = hoha.QualifyingExitHHID 
		and n.ExitDate between cd.CohortStart and cd.CohortEnd
		and n.EntryDate > dateadd(yyyy, -1, hoha.LastActive)
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
	where (n.RelationshipToHoH = 1 
			or (cd.Cohort = 0 and n.ActiveAge between 18 and 65)
			or (cd.Cohort = -1 and n.Exit1Age between 18 and 65)
			or (cd.Cohort = -2 and n.Exit2Age between 18 and 65))
		and hn.MonthsHomelessPastThreeYears in (112,113) 
		and hn.TimesHomelessPastThreeYears = 4
		and hn.EntryDate = n.EntryDate 
/*
	7.5 Get Dates to Exclude from Counts of ES/SH/Street Days
*/

	truncate table ch_Exclude_exit

	insert into ch_Exclude_exit (PersonalID, excludeDate, Step)
	select distinct ha.PersonalID, cal.theDate, '7.5'
	from tlsa_ExitHoHAdult ha
	inner join tlsa_Enrollment chn on chn.PersonalID = ha.PersonalID 
	inner join ref_Calendar cal on cal.theDate >=
			case when chn.LSAProjectType in (3,13) then chn.MoveInDate  
				else chn.EntryDate end
		and cal.theDate < chn.ExitDate
			and cal.theDate between 
				(select min(earliest.CHStart) from tlsa_ExitHoHAdult earliest where earliest.PersonalID = ha.PersonalID) 
				and (select max(latest.LastActive) from tlsa_ExitHoHAdult latest where latest.PersonalID = ha.PersonalID)
	where chn.LSAProjectType in (2,3,13) and ha.CHTime is null

/*
	7.6 Get Dates to Include in Counts of ES/SH/Street Days 
*/
	--ch_Include_exit identifies dates on which a client was in ES/SH or on the street 
	-- (excluding any dates in ch_Exclude_exit) 
	truncate table ch_Include_exit

	--Dates enrolled in ES entry/exit or SH
	insert into ch_Include_exit (PersonalID, ESSHStreetDate, Step)
	select distinct ha.PersonalID, cal.theDate, '7.6.1'
	from tlsa_ExitHoHAdult ha
		inner join tlsa_Enrollment chn on chn.PersonalID = ha.PersonalID 
		inner join ref_Calendar cal on 
			cal.theDate >= chn.EntryDate 
		and cal.theDate < chn.ExitDate
			and cal.theDate between 
				(select min(earliest.CHStart) from tlsa_ExitHoHAdult earliest where earliest.PersonalID = ha.PersonalID) 
				and (select max(latest.LastActive) from tlsa_ExitHoHAdult latest where latest.PersonalID = ha.PersonalID)
		left outer join ch_Exclude_exit chx on chx.excludeDate = cal.theDate
			and chx.PersonalID = chn.PersonalID
	where chn.LSAProjectType in (0,8)
		and chx.excludeDate is null
		and ha.CHTime is null

	--ES nbn bed nights
	insert into ch_Include_exit (PersonalID, ESSHStreetDate, Step)
	select distinct ha.PersonalID, cal.theDate, '7.6.2'
	from tlsa_ExitHoHAdult ha
		inner join tlsa_Enrollment chn on chn.PersonalID = ha.PersonalID 
		inner join hmis_Services bn on bn.EnrollmentID = chn.EnrollmentID
			and bn.RecordType = 200 
			and bn.DateProvided >= chn.EntryDate 
			and bn.DateProvided < chn.ExitDate
			and bn.DateDeleted is null
		inner join ref_Calendar cal on 
			cal.theDate = bn.DateProvided 
			and cal.theDate between 
			(select min(earliest.CHStart) from tlsa_ExitHoHAdult earliest where earliest.PersonalID = ha.PersonalID) 
				and (select max(latest.LastActive) from tlsa_ExitHoHAdult latest where latest.PersonalID = ha.PersonalID)
		left outer join ch_Exclude_exit chx on chx.excludeDate = cal.theDate
			and chx.PersonalID = chn.PersonalID
		left outer join ch_Include_exit chi on chi.ESSHStreetDate = cal.theDate 
			and chi.PersonalID = chn.PersonalID
	where chn.LSAProjectType = 1 and chx.excludeDate is null
		and chi.ESSHStreetDate is null
		and ha.CHTime is null

	--ES/SH/Street dates from 3.917 DateToStreetESSH when EntryDates > CHStart.

	insert into ch_Include_exit (PersonalID, ESSHStreetDate, Step)
	select distinct ha.PersonalID, cal.theDate, '7.6.3'
	from tlsa_ExitHoHAdult ha
		inner join tlsa_Enrollment chn on chn.PersonalID = ha.PersonalID
			and chn.EntryDate > ha.CHStart 
		inner join hmis_Enrollment hn on hn.EnrollmentID = chn.EnrollmentID
		inner join ref_Calendar cal on 
			cal.theDate >= hn.DateToStreetESSH
			and cal.theDate between 			
				(select min(earliest.CHStart) from tlsa_ExitHoHAdult earliest where earliest.PersonalID = ha.PersonalID) 
				and (select max(latest.LastActive) from tlsa_ExitHoHAdult latest where latest.PersonalID = ha.PersonalID)
		left outer join ch_Exclude_exit chx on chx.excludeDate = cal.theDate
			and chx.PersonalID = chn.PersonalID
		left outer join ch_Include_exit chi on chi.ESSHStreetDate = cal.theDate 
			and chi.PersonalID = chn.PersonalID
	where chx.excludeDate is null
		and chi.ESSHStreetDate is null
		and ha.CHTime is null
		and (hn.LivingSituation between 100 and 199
			or (chn.LSAProjectType not in (0,1,8) and hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
			or (chn.LSAProjectType not in (0,1,8) and hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
					and hn.LivingSituation between 200 and 299) 
			)
		and ( 
			
			(-- for ES/SH/TH, count dates prior to EntryDate
				chn.LSAProjectType in (0,1,2,8) and cal.theDate < chn.EntryDate)
			or (-- for PSH/RRH, dates prior to and after EntryDate are counted for 
				-- as long as the client remains homeless in the project  
				chn.LSAProjectType in (3,13,15)
				and (cal.theDate < chn.MoveInDate
					 or (chn.MoveInDate is NULL and cal.theDate < chn.ExitDate)
					)
				)
			)						

	--Gaps of less than 7 nights between two ESSHStreet dates are counted
	insert into ch_Include_exit (PersonalID, ESSHStreetDate, Step)
	select gap.PersonalID, cal.theDate, '7.6.4'
	from (select distinct s.PersonalID, s.ESSHStreetDate as StartDate, min(e.ESSHStreetDate) as EndDate
			from ch_Include_exit s 
				inner join ch_Include_exit e on e.PersonalID = s.PersonalID and e.ESSHStreetDate > s.ESSHStreetDate 
					and dateadd(dd, -7, e.ESSHStreetDate) <= s.ESSHStreetDate
			where s.PersonalID not in 
				(select PersonalID 
				from ch_Include_exit 
				where ESSHStreetDate = dateadd(dd, 1, s.ESSHStreetDate))
			group by s.PersonalID, s.ESSHStreetDate) gap
		inner join ref_Calendar cal on cal.theDate between gap.StartDate and gap.EndDate
		left outer join ch_Include_exit chi on chi.PersonalID = gap.PersonalID 
			and chi.ESSHStreetDate = cal.theDate
	where chi.ESSHStreetDate is null

/*
	7.7 Get ES/SH/Street Episodes
*/
	truncate table ch_Episodes_exit

	-- For any given PersonalID:
	--	Any ESSHStreetDate in ch_Include_exit without a record for the day before is the start of an episode (episodeStart).
	--	Any ESSHStreetDate in ch_Include_exit without a record for the day after is the end of an episode (episodeEnd).
	--	Each episodeStart combined with the next earliest episodeEnd represents one episode.
	--	The length of the episode is the difference in days between episodeStart and episodeEnd + 1 day.

	insert into ch_Episodes_exit (PersonalID, episodeStart, Step)
	select s.PersonalID, s.ESSHStreetDate, '7.7.1a'
	from ch_Include_exit s 
	--any date in ch_Include_exit without a record for the day before is the start of an episode
	where not exists (select 1
			from ch_Include_exit 
			where ESSHStreetDate = dateadd(dd, -1, s.ESSHStreetDate)
			and PersonalID = s.PersonalID)

	update chep
	set chep.episodeEnd = (select min(ESSHStreetDate)
			from ch_Include_exit chix
			where PersonalID = chep.PersonalID
				and ESSHStreetDate > chep.episodeStart
				and not exists (select 1
					from ch_Include_exit
					where ESSHStreetDate = dateadd(dd, 1, chix.ESSHStreetDate)
					and PersonalID = chix.PersonalID) 
			)
		, Step = '7.7.1b'
	from ch_Episodes_exit chep

	update chep 
	set episodeDays = datediff(dd, chep.episodeStart, chep.episodeEnd) + 1
		, Step = '7.7.2'
	from ch_Episodes_exit chep

/*
	7.8 Set CHTime and CHTimeStatus 
*/

	--Any client with a 365+ day episode that overlaps with their
	--last year of activity meets the time criteria for CH
	update ha 
	set CHTime = 365, CHTimeStatus = 1, ha.Step = '7.8.1'
	from tlsa_ExitHoHAdult ha
		inner join ch_Episodes_exit chep on chep.PersonalID = ha.PersonalID
			and chep.episodeEnd > dateadd(yyyy, -1, ha.LastActive) 
			and chep.episodeStart <= dateadd(yyyy, -1, chep.episodeEnd)

	--Clients with a total of 365+ days in the three year period and at least four episodes 
	--  meet time criteria for CH
	update ha
	set ha.CHTime = case when time_sum.count_days >= 365 then 365
			when time_sum.count_days >= 270 then 270
			else NULL end
		, ha.CHTimeStatus = case when time_sum.count_eps >= 4 then 2
			when time_sum.count_eps < 4 then 3
			else NULL end 
	    , ha.Step = '7.8.2'
	from tlsa_ExitHoHAdult ha
	inner join (select hoha.PersonalID, hoha.Cohort
			, count(distinct chi.ESSHStreetDate) as count_days 
			, count(distinct chep.episodeStart) as count_eps
		from tlsa_ExitHoHAdult hoha 
		inner join ch_Include_exit chi on chi.PersonalID = hoha.PersonalID 
			and chi.ESSHStreetDate between hoha.CHStart and hoha.LastActive
		inner join ch_Episodes_exit chep on chep.PersonalID = hoha.PersonalID
			and chep.episodeEnd between hoha.CHStart and hoha.LastActive 
		group by hoha.PersonalID, hoha.Cohort) time_sum on time_sum.PersonalID = ha.PersonalID and time_sum.Cohort = ha.Cohort
	where ha.CHTime is null

/*
	7.9 Population Identifiers for LSAExit
*/

	update ex
	set HHChronic = case when ch.ch is null then 0
		else ch.ch end
		, Step = '7.9.1'
	from tlsa_Exit ex
	left outer join 
		(select ha.QualifyingExitHHID, min(
			case when ((ha.CHTime = 365 and ha.CHTimeStatus in (1,2))
							or (ha.CHTime = 400 and ha.CHTimeStatus = 2))
							and ha.DisabilityStatus = 1 then 1
						when ha.CHTime in (365, 400) and ha.DisabilityStatus = 1 then 2
						when ha.CHTime in (365, 400) and ha.DisabilityStatus = 99 then 3
						when ha.CHTime in (365, 400) and ha.DisabilityStatus = 0 then 4
						when ha.CHTime = 270 and ha.DisabilityStatus = 1 and ha.CHTimeStatus = 99 then 5
						when ha.CHTime = 270 and ha.DisabilityStatus = 1 and ha.CHTimeStatus <> 99 then 6
						when ha.CHTimeStatus = 99 and ha.DisabilityStatus <> 0 then 9
						else null end) as ch
		from tlsa_ExitHoHAdult ha
		group by ha.QualifyingExitHHID) ch on ch.QualifyingExitHHID = ex.QualifyingExitHHID

	update ex
	set HHVet = case when vet.vet is null then 0 else vet.vet end
		, HHDisability = (select max(case when disability.DisabilityStatus = 1 then 1 else 0 end)
			from tlsa_Enrollment disability
			where disability.HouseholdID = hh.HouseholdID
				and (hhid.HoHID = disability.PersonalID
					or (
						(ex.Cohort = 0 and disability.ActiveAge between 18 and 65)
						 or (ex.Cohort = -1 and disability.Exit1Age between 18 and 65)
						 or (ex.Cohort = -2 and disability.Exit2Age between 18 and 65)		
						)
					))
		, HHFleeingDV = coalesce((select min(dv.DVStatus)
				from tlsa_Enrollment dv
				where dv.HouseholdID = hh.HouseholdID
					and dv.DVStatus between 1 and 3
					and (dv.RelationshipToHoH = 1 
							or (ex.Cohort = 0 and dv.ActiveAge between 18 and 65)
							or (ex.Cohort = -1 and dv.Exit1Age between 18 and 65)
							or (ex.Cohort = -2 and dv.Exit2Age between 18 and 65)
						)), 0)
		, HoHRaceEthnicity =  (select case when r.RaceNone in (8,9) then 98
			when r.RaceNone = 99 then 99
			when (r.AmIndAkNative = 1 
					or r.Asian = 1
					or r.BlackAfAmerican = 1
					or r.NativeHIPacific = 1
					or r.White = 1
					or r.HispanicLatinaeo = 1
					or r.MidEastNAfrican = 1) then 
						(select cast (
							(case when r.AmIndAKNative = 1 then '1' else '' end
							+ case when r.Asian = 1 then '2' else '' end
							+ case when r.BlackAfAmerican = 1 then '3' else '' end
							+ case when r.NativeHIPacific = 1 then '4' else '' end
							+ case when r.White = 1 then '5' else '' end
							+ case when r.HispanicLatinaeo = 1 then '6' else '' end
							+ case when r.MidEastNAfrican = 1 then '7' else '' end) as int))
			else 99 end 
			from hmis_Client r
			where r.PersonalID = hoh.PersonalID) 
		, HHParent = (select max(case when parent.RelationshipToHoH = 2 then 1 else 0 end)
			from tlsa_Enrollment parent
			where parent.HouseholdID = hh.HouseholdID)
		, ex.Step = '7.9.2'
	from tlsa_Exit ex 
	inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID 
	inner join hmis_Client hoh on hoh.PersonalID = ex.HoHID
	inner join (
		select n.HouseholdID, n.PersonalID, n.EnrollmentID, hhid.ExitCohort
			, n.RelationshipToHoH
		from tlsa_Enrollment n
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
			) hh on hh.HouseholdID = ex.QualifyingExitHHID and hh.ExitCohort = ex.Cohort
	left outer join (select n.HouseholdID, hhid.ExitCohort, max(case when c.VeteranStatus = 1 then 1 else 0 end) as vet
		from tlsa_Enrollment n
		inner join hmis_Client c on c.PersonalID = n.PersonalID
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
		where case hhid.ExitCohort 
			when 0 then n.ActiveAge
			when -1 then n.Exit1Age
			when -2 then n.Exit2Age end between 18 and 65
		group by n.HouseholdID, hhid.ExitCohort) vet on vet.HouseholdID = ex.QualifyingExitHHID and vet.ExitCohort = ex.Cohort

	update ex
	set ex.HHAdultAge = case when ages.MaxAge > 65 or ex.HHType not in (1,2) then -1
		when ages.MaxAge = 21 then 18
		when ages.MaxAge = 24 then 24
		when ages.MinAge between 55 and 65 then 55
		else 25 end
		, ex.Step = '7.9.3'
	from tlsa_Exit ex
	inner join (select hhid.HoHID, case hhid.ExitCohort 
			when 0 then hhid.ActiveHHType
			when -1 then hhid.Exit1HHType
			when -2 then hhid.Exit2HHType end as HHType
		, hhid.ExitCohort as Cohort
		, max(case hhid.ExitCohort 
			when 0 then n.ActiveAge
			when -1 then n.Exit1Age
			when -2 then n.Exit2Age end) as MaxAge
		, min(case hhid.ExitCohort 
			when 0 then n.ActiveAge
			when -1 then n.Exit1Age
			when -2 then n.Exit2Age end) as MinAge
	from tlsa_HHID hhid
	inner join tlsa_Enrollment n on n.HouseholdID = hhid.HouseholdID 
	group by hhid.HoHID, case hhid.ExitCohort 
			when 0 then hhid.ActiveHHType
			when -1 then hhid.Exit1HHType
			when -2 then hhid.Exit2HHType end 
		, hhid.ExitCohort
	) ages on ages.HoHID = ex.HoHID and ages.Cohort = ex.Cohort and ages.HHType = ex.HHType

update ex 
set ex.AC3Plus = 
		(select case count(distinct n.PersonalID)
			when 0 then 0
			when 1 then 0
			when 2 then 0 
			else 1 end
		from tlsa_HHID hhid
		inner join tlsa_Enrollment n on n.HouseholdID = hhid.HouseholdID 
		where case hhid.ExitCohort 
			when 0 then n.ActiveAge 
			when -1 then n.Exit1Age 
			when -2 then n.Exit2Age end <= 17
		 and case hhid.ExitCohort 
			when 0 then hhid.ActiveHHType 
			when -1 then hhid.Exit1HHType
			when -2 then hhid.Exit2HHType end = 2
		 and hhid.HouseholdID = ex.QualifyingExitHHID)
		, ex.Step = '7.9.4'
from tlsa_Exit ex

/*
	7.10 System Engagement Status for Exit Cohort Households
*/

	update ex
	set ex.Stat = 
		case when prior.HoHID is null then 1
			when prior.ExitDate >= dateadd(dd, -14, qx.EntryDate) then 5
			when prior.ExitDest between 400 and 499 then 2
			when prior.ExitDest between 100 and 399 then 3
			else 4 end 
		, ex.Step = '7.10'
	from tlsa_Exit ex 
	inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
	left outer join tlsa_HHID prior on prior.HoHID = ex.HoHID 
		and (select top 1 last.EnrollmentID 
			from tlsa_HHID last
			where last.HoHID = qx.HoHID
				and case ex.Cohort	
					when -2 then last.Exit2HHType
					when -1 then last.Exit1HHType
					else last.ActiveHHType end
					= ex.HHType
				and last.EntryDate < qx.EntryDate
				and last.ExitDate between dateadd(dd, -730, qx.EntryDate) and qx.ExitDate
			order by last.ExitDate desc
				, last.ExitDest asc
				, last.EntryDate asc
				, last.EnrollmentID desc
			) = prior.EnrollmentID

/*
	7.11  Last Inactive Date for Exit Cohorts
*/

--LastInactive = (EntryDate - 1 day) for any household where Stat <> 5
	--  and for any household where Stat = 5 but there is no enrollment for the HoHID/HHType
	--  active in the six days prior to the qualifying exit EntryDate. 
	update ex
	set ex.LastInactive = case 
		when hhid.EntryDate < cd.LookbackDate then dateadd(dd, -1, cd.LookbackDate) 
		else dateadd(dd, -1, hhid.EntryDate) end
		, ex.Step = '7.11.1'
	from tlsa_Exit ex
	inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID
	inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
	where ex.Stat <> 5 
		or (select top 1 prior.EnrollmentID 
			from tlsa_HHID prior
			inner join tlsa_Enrollment pn on pn.PersonalID = prior.HoHID 
				and pn.HouseholdID = prior.HouseholdID
			where pn.EntryDate < hhid.EntryDate 
				and prior.HoHID = ex.HoHID and case ex.Cohort 
				when -2 then prior.Exit2HHType
				when -1 then prior.Exit1HHType
				else prior.ActiveHHType end = ex.HHType
			and dateadd(dd, 6, prior.ExitDate) >= hhid.EntryDate) is null

	truncate table sys_TimePadded_exit

	insert into sys_TimePadded_exit (HoHID, HHType, Cohort, StartDate, EndDate, Step)
	select distinct ex.HoHID, ex.HHType, ex.Cohort
		, possible.EntryDate	
		, case when dateadd(dd, 6, possible.ExitDate) > cd.CohortEnd then cd.CohortEnd 
			else dateadd(dd, 6, possible.ExitDate) end
		, '7.11.2.a'
	from tlsa_Exit ex
	inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID
	inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
	inner join tlsa_HHID possible on possible.HoHID = ex.HoHID and case ex.Cohort 
				when -2 then possible.Exit2HHType
				when -1 then possible.Exit1HHType
				else possible.ActiveHHType end = ex.HHType 
			and possible.ExitDate <= hhid.ExitDate
	where ex.LastInactive is null 
		and possible.LSAProjectType in (0,2,3,8,13)
	union
	select distinct ex.HoHID, ex.HHType, ex.Cohort
		, bn.DateProvided	
		, case when dateadd(dd, 6, bn.DateProvided) > cd.CohortEnd then cd.CohortEnd
			else dateadd(dd, 6, bn.DateProvided) end
		, '7.11.2.b'
	from tlsa_Exit ex
	inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID
	inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
	inner join tlsa_HHID possible on possible.HoHID = ex.HoHID and case ex.Cohort 
				when -2 then possible.Exit2HHType
				when -1 then possible.Exit1HHType
				else possible.ActiveHHType end = ex.HHType 
			and possible.ExitDate <= hhid.ExitDate
	inner join hmis_Services bn on bn.EnrollmentID = possible.EnrollmentID 
		and bn.DateProvided <= cd.CohortEnd
		and bn.DateProvided >= possible.EntryDate and bn.DateProvided < possible.ExitDate
		and bn.RecordType = 200 and bn.DateDeleted is null
	where ex.LastInactive is null 
		and possible.LSAProjectType = 1
		
	update ex
	set ex.LastInactive = coalesce(lastDay.inactive, dateadd(dd, -1, cd.LookbackDate))
		, ex.Step = '7.11.3'
	from tlsa_Exit ex
	inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
	left outer join 
		(select ex.HoHID, ex.HHType, ex.Cohort, max(cal.theDate) as inactive
		  from tlsa_Exit ex
		  inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID
		  inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
		  inner join ref_Calendar cal on cal.theDate <= cd.CohortEnd
			and cal.theDate >= cd.LookbackDate
		  left outer join
			 sys_TimePadded_exit stp on stp.HoHID = ex.HoHID and stp.HHType = ex.HHType
			  and stp.Cohort = ex.Cohort
			  and cal.theDate between stp.StartDate and stp.EndDate
		  where stp.HoHID is null
			and cal.theDate < hhid.EntryDate
		group by ex.HoHID, ex.HHType, ex.Cohort
	  ) lastDay on lastDay.HoHID = ex.HoHID and lastDay.HHType = ex.HHType
			and lastDay.Cohort = ex.Cohort
	where ex.LastInactive is null

/*
	7.12 Set System Path for Exit Cohort Households
*/

--SystemPath is n/a for any household housed in PSH as of CohortStart
-- or any household housed for at least a year in RRH/PSH prior to exit
update ex
set ex.SystemPath = -1
	, ex.Step = '7.12.1'
from tlsa_Exit ex
inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
where (ex.ExitFrom = 6 and qx.MoveInDate < cd.CohortStart) 
	or (ex.ExitFrom in (5,6) and dateadd(dd, 365, qx.MoveInDate) <= qx.ExitDate)


update ex
set ex.SystemPath = case ptype.summary
	when 1 then 1
	when 10 then 2
	when 11 then 3
	when 100 then 4
	when 101 then 5
	when 110 then 6
	when 111 then 7
	when 1000 then 8
	when 1001 then 9
	when 1101 then 10
	when 1100 then 11
	else 12 end 
	, ex.Step = '7.12.2'
from tlsa_Exit ex
inner join (select distinct ex.HoHID, ex.HHType, ex.Cohort
			, case when rrh.HoHID is not null then 100 else 0 end
				+ case when th.HoHID is not null then 10 else 0 end
				+ case when es.HoHID is not null then 1 else 0 end
				+ case when psh.HoHID is not null then 1000 else 0 end
					as summary
		from tlsa_Exit ex 
		inner join tlsa_CohortDates cd on cd.ReportID = ex.ReportID and cd.Cohort = ex.Cohort
		inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
		left outer join tlsa_HHID es on es.LSAProjectType in (0,1,8)
			and es.HoHID = ex.HoHID and es.EntryDate <= qx.ExitDate 
			and (es.EntryDate > ex.LastInactive
					or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (es.ExitDate > dateadd(dd, -1, cd.LookbackDate) or es.ExitDate is NULL))
				)
			and (es.ActiveHHType = ex.HHType)
		left outer join tlsa_HHID th on th.LSAProjectType = 2
			and th.HoHID = ex.HoHID and th.EntryDate <= qx.ExitDate 
			and (th.EntryDate > ex.LastInactive
					or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (th.ExitDate > dateadd(dd, -1, cd.LookbackDate) or th.ExitDate is NULL))
				)
			and (th.ActiveHHType = ex.HHType)
		left outer join tlsa_HHID rrh on rrh.LSAProjectType = 13
			and rrh.HoHID = ex.HoHID and rrh.EntryDate <= qx.ExitDate 
			and (rrh.EntryDate > ex.LastInactive
				or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (rrh.ExitDate > dateadd(dd, -1, cd.LookbackDate) or rrh.ExitDate is NULL))
				)
			and (rrh.ActiveHHType = ex.HHType)
		left outer join tlsa_HHID psh on psh.LSAProjectType = 3
			and psh.HoHID = ex.HoHID and psh.EntryDate <= qx.ExitDate 
			and (psh.EntryDate > ex.LastInactive
					or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (psh.ExitDate > dateadd(dd, -1, cd.LookbackDate) or psh.ExitDate is NULL))
				)
			and (psh.ActiveHHType = ex.HHType)
		) ptype on ptype.HoHID = ex.HoHID and ptype.HHType = ex.HHType 
		and ptype.Cohort = ex.Cohort
where ex.Cohort = 0 and ex.SystemPath is null

update ex
set ex.SystemPath = case ptype.summary
	when 1 then 1
	when 10 then 2
	when 11 then 3
	when 100 then 4
	when 101 then 5
	when 110 then 6
	when 111 then 7
	when 1000 then 8
	when 1001 then 9
	when 1101 then 10
	when 1100 then 11
	else 12 end 
	, ex.Step = '7.12.3'
from tlsa_Exit ex
inner join (select distinct ex.HoHID, ex.HHType, ex.Cohort
			, case when rrh.HoHID is not null then 100 else 0 end
				+ case when th.HoHID is not null then 10 else 0 end
				+ case when es.HoHID is not null then 1 else 0 end
				+ case when psh.HoHID is not null then 1000 else 0 end
					as summary
		from tlsa_Exit ex 
		inner join tlsa_CohortDates cd on cd.ReportID = ex.ReportID and cd.Cohort = ex.Cohort
		inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
		left outer join tlsa_HHID es on es.LSAProjectType in (0,1,8)
			and es.HoHID = ex.HoHID and es.EntryDate <= qx.ExitDate 
			and (es.EntryDate > ex.LastInactive
					or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (es.ExitDate > dateadd(dd, -1, cd.LookbackDate) or es.ExitDate is NULL))
				)
			and (es.Exit1HHType = ex.HHType)
		left outer join tlsa_HHID th on th.LSAProjectType = 2
			and th.HoHID = ex.HoHID and th.EntryDate <= qx.ExitDate 
			and (th.EntryDate > ex.LastInactive
					or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (th.ExitDate > dateadd(dd, -1, cd.LookbackDate) or th.ExitDate is NULL))
				)
			and (th.Exit1HHType = ex.HHType)
		left outer join tlsa_HHID rrh on rrh.LSAProjectType = 13
			and rrh.HoHID = ex.HoHID and rrh.EntryDate <= qx.ExitDate 
			and (rrh.EntryDate > ex.LastInactive
				or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (rrh.ExitDate > dateadd(dd, -1, cd.LookbackDate) or rrh.ExitDate is NULL))
				)
			and (rrh.Exit1HHType = ex.HHType)
		left outer join tlsa_HHID psh on psh.LSAProjectType = 3
			and psh.HoHID = ex.HoHID and psh.EntryDate <= qx.ExitDate 
			and (psh.EntryDate > ex.LastInactive
					or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (psh.ExitDate > dateadd(dd, -1, cd.LookbackDate) or psh.ExitDate is NULL))
				)
			and (psh.Exit1HHType = ex.HHType)
		) ptype on ptype.HoHID = ex.HoHID and ptype.HHType = ex.HHType 
		and ptype.Cohort = ex.Cohort
where ex.Cohort = -1 and ex.SystemPath is null

update ex
set ex.SystemPath = case ptype.summary
	when 1 then 1
	when 10 then 2
	when 11 then 3
	when 100 then 4
	when 101 then 5
	when 110 then 6
	when 111 then 7
	when 1000 then 8
	when 1001 then 9
	when 1101 then 10
	when 1100 then 11
	else 12 end 
	, ex.Step = '7.12.4'
from tlsa_Exit ex
inner join (select distinct ex.HoHID, ex.HHType, ex.Cohort
			, case when rrh.HoHID is not null then 100 else 0 end
				+ case when th.HoHID is not null then 10 else 0 end
				+ case when es.HoHID is not null then 1 else 0 end
				+ case when psh.HoHID is not null then 1000 else 0 end
					as summary
		from tlsa_Exit ex 
		inner join tlsa_CohortDates cd on cd.ReportID = ex.ReportID and cd.Cohort = ex.Cohort
		inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
		left outer join tlsa_HHID es on es.LSAProjectType in (0,1,8)
			and es.HoHID = ex.HoHID and es.EntryDate <= qx.ExitDate 
			and (es.EntryDate > ex.LastInactive
					or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (es.ExitDate > dateadd(dd, -1, cd.LookbackDate) or es.ExitDate is NULL))
				)
			and (es.Exit2HHType = ex.HHType)
		left outer join tlsa_HHID th on th.LSAProjectType = 2
			and th.HoHID = ex.HoHID and th.EntryDate <= qx.ExitDate 
			and (th.EntryDate > ex.LastInactive
					or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (th.ExitDate > dateadd(dd, -1, cd.LookbackDate) or th.ExitDate is NULL))
				)
			and (th.Exit2HHType = ex.HHType)
		left outer join tlsa_HHID rrh on rrh.LSAProjectType = 13
			and rrh.HoHID = ex.HoHID and rrh.EntryDate <= qx.ExitDate 
			and (rrh.EntryDate > ex.LastInactive
				or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (rrh.ExitDate > dateadd(dd, -1, cd.LookbackDate) or rrh.ExitDate is NULL))
				)
			and (rrh.Exit2HHType = ex.HHType)
		left outer join tlsa_HHID psh on psh.LSAProjectType = 3
			and psh.HoHID = ex.HoHID and psh.EntryDate <= qx.ExitDate 
			and (psh.EntryDate > ex.LastInactive
					or (ex.LastInactive = dateadd(dd, -1, cd.LookbackDate) and (psh.ExitDate > dateadd(dd, -1, cd.LookbackDate) or psh.ExitDate is NULL))
				)
			and (psh.Exit2HHType = ex.HHType)
		) ptype on ptype.HoHID = ex.HoHID and ptype.HHType = ex.HHType 
		and ptype.Cohort = ex.Cohort
where ex.Cohort = -2 and ex.SystemPath is null

/*
	7.13 Select Data for Export to LSAExit
*/

truncate table lsa_Exit
insert into lsa_Exit (RowTotal
	, Cohort, Stat, ExitFrom, ExitTo, ReturnTime, HHType
	, HHVet, HHChronic, HHDisability, HHFleeingDV, HoHRaceEthnicity
	, HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID)
select count (distinct HoHID + cast(HHType as nvarchar))
	, Cohort, Stat, ExitFrom, ExitTo
	, case when ReturnTime between 15 and 30 then 30
		when ReturnTime between 31 and 60 then 60
		when ReturnTime between 61 and 90 then 90
		when ReturnTime between 91 and 180 then 180
		when ReturnTime between 181 and 365 then 365
		when ReturnTime between 366 and 547 then 547
		when ReturnTime between 548 and 730 then 730
		else ReturnTime end
	, HHType, HHVet, HHChronic, HHDisability, HHFleeingDV, HoHRaceEthnicity
	, HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID
from tlsa_Exit
group by Cohort, Stat, ExitFrom, ExitTo
	, case when ReturnTime between 15 and 30 then 30
		when ReturnTime between 31 and 60 then 60
		when ReturnTime between 61 and 90 then 90
		when ReturnTime between 91 and 180 then 180
		when ReturnTime between 181 and 365 then 365
		when ReturnTime between 366 and 547 then 547
		when ReturnTime between 548 and 730 then 730
		else ReturnTime end
	, HHType, HHVet, HHChronic, HHDisability, HHFleeingDV, HoHRaceEthnicity
	, HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID

end -- END IF LSAScope <> HIC

/*
	End LSAExit
*/
/*
LSA FY2024 Sample Code
Name:  08 LSACalculated Averages for LSAHousehold and LSAExit.sql  

FY2024 Changes

	Run code only if the LSAScope is not 'HIC'
		
	(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)/

Uses static reference tables:
	ref_RowValues - Required Cohort, Universe, SystemPath values for each RowID
	ref_RowPopulations - Required Populations for each RowID 
					and (for rows 1-9) whether the RowID is required by SystemPath for the Population
	ref_PopHHTypes -  HHTypes required in LSACalculated for each Population by PopID

Populates and references:
	tlsa_AveragePops - By PopID -- HoHID, HHType, and Cohort for each population member


	8.3 Populations for Average Days from LSAHousehold and LSAExit
*/
 
if (select LSAScope from lsa_Report) <> 3
begin

	truncate table tlsa_AveragePops

	insert into tlsa_AveragePops (PopID, Cohort, Step)
	select 0, Cohort, '8.3.1'
	from tlsa_CohortDates cd
	where cd.Cohort between -2 and 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 10, 1, hh.HoHID, hh.HHType, '8.3.2'
	from tlsa_Household hh 
	where hh.HHAdultAge = 18 and hh.HHType = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 11, 1, hh.HoHID, hh.HHType, '8.3.3'
	from tlsa_Household hh 
	where hh.HHAdultAge = 24 and hh.HHType = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 12, 1, hh.HoHID, hh.HHType, '8.3.4'
	from tlsa_Household hh 
	where hh.HHType = 2 and hh.HHParent = 1 and HHAdultAge in (18,24)

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 13, 1, hh.HoHID, hh.HHType, '8.3.5'
	from tlsa_Household hh 
	where hh.HHVet = 1 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 14, 1, hh.HoHID, hh.HHType, '8.3.6'
	from tlsa_Household hh 
	where hh.HHVet = 0 and hh.HHAdultAge in (25, 55) and hh.HHType = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 15, 1, hh.HoHID, hh.HHType, '8.3.7'
	from tlsa_Household hh 
	where hh.HHChronic = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 16, 1, hh.HoHID, hh.HHType, '8.3.8'
	from tlsa_Household hh 
	where hh.HHChronic in (1,2)

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 17, 1, hh.HoHID, hh.HHType, '8.3.9'
	from tlsa_Household hh 
	where hh.HHChronic in (0,3)

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 18, 1, hh.HoHID, hh.HHType, '8.3.10'
	from tlsa_Household hh 
	where hh.HHDisability = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 19, 1, hh.HoHID, hh.HHType, '8.3.11'
	from tlsa_Household hh 
	where hh.HHFleeingDV = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 20, 1, hh.HoHID, hh.HHType, '8.3.12'
	from tlsa_Household hh 
	where hh.Stat = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 21, 1, hh.HoHID, hh.HHType, '8.3.13'
	from tlsa_Household hh 
	where hh.Stat = 2

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 22, 1, hh.HoHID, hh.HHType, '8.3.14'
	from tlsa_Household hh 
	where hh.PSHMoveIn = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 
		case when hh.HoHRaceEthnicity = 1 then 23
			when hh.HoHRaceEthnicity = 16 then 24
			when hh.HoHRaceEthnicity = 2 then 25
			when hh.HoHRaceEthnicity = 26 then 26
			when hh.HoHRaceEthnicity = 3 then 27
			when hh.HoHRaceEthnicity = 36 then 28
			when hh.HoHRaceEthnicity = 6 then 29
			when hh.HoHRaceEthnicity = 7 then 30
			when hh.HoHRaceEthnicity = 67 then 31
			when hh.HoHRaceEthnicity = 4 then 32
			when hh.HoHRaceEthnicity = 46 then 33
			when hh.HoHRaceEthnicity = 5 then 34
			when hh.HoHRaceEthnicity = 56 then 35
			when hh.HoHRaceEthnicity >=12 and hh.HoHRaceEthnicity not in (98,99) and cast(hh.HoHRaceEthnicity as nvarchar) not like '%6%' then 36
			when hh.HoHRaceEthnicity >=126 and cast(hh.HoHRaceEthnicity as nvarchar) like '%6%' then 37
			else null end
		, 1, hh.HoHID, hh.HHType, '8.3.15'
	from tlsa_Household hh 
	where hh.HoHRaceEthnicity not in (98,99)

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 38, 1, hh.HoHID, hh.HHType, '8.3.16'
	from tlsa_Household hh 
	where cast(hh.HoHRaceEthnicity as nvarchar) like '%1%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 39, 1, hh.HoHID, hh.HHType, '8.3.17'
	from tlsa_Household hh 
	where cast(hh.HoHRaceEthnicity as nvarchar) like '%2%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 40, 1, hh.HoHID, hh.HHType, '8.3.18'
	from tlsa_Household hh 
	where cast(hh.HoHRaceEthnicity as nvarchar) like '%3%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 41, 1, hh.HoHID, hh.HHType, '8.3.19'
	from tlsa_Household hh 
	where cast(hh.HoHRaceEthnicity as nvarchar) like '%6%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 42, 1, hh.HoHID, hh.HHType, '8.3.20'
	from tlsa_Household hh 
	where cast(hh.HoHRaceEthnicity as nvarchar) like '%7%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 43, 1, hh.HoHID, hh.HHType, '8.3.21'
	from tlsa_Household hh 
	where cast(hh.HoHRaceEthnicity as nvarchar) like '%4%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 44, 1, hh.HoHID, hh.HHType, '8.3.22'
	from tlsa_Household hh 
	where cast(hh.HoHRaceEthnicity as nvarchar) like '%5%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 45, 1, hh.HoHID, hh.HHType, '8.3.23'
	from tlsa_Household hh 
	where hh.HHAdultAge = 55 and hh.HHType = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 46, 1, hh.HoHID, hh.HHType, '8.3.24'
	from tlsa_Household hh 
	where hh.HHParent = 1 and hh.HHType = 3

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 47, 1, hh.HoHID, hh.HHType, '8.3.25'
	from tlsa_Household hh 
	where hh.HHChild = 3 and hh.HHType = 2

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 48, 1, hh.HoHID, hh.HHType, '8.3.26'
	from tlsa_Household hh 
	where hh.HHFleeingDV = 2 

	-- End LSAHousehold populations / begin LSAExit populations

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 10, ex.Cohort, ex.HoHID, ex.HHType, '8.3.27'
	from tlsa_Exit ex
	where ex.HHAdultAge = 18 and ex.HHType = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 11, ex.Cohort, ex.HoHID, ex.HHType, '8.3.28'
	from tlsa_Exit ex
	where ex.HHAdultAge = 24 and ex.HHType = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 12, ex.Cohort, ex.HoHID, ex.HHType, '8.3.29'
	from tlsa_Exit ex
	where ex.HHType = 2 and ex.HHParent = 1 and HHAdultAge in (18,24)

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 13, ex.Cohort, ex.HoHID, ex.HHType, '8.3.30'
	from tlsa_Exit ex
	where ex.HHVet = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 14, ex.Cohort, ex.HoHID, ex.HHType, '8.3.31'
	from tlsa_Exit ex
	where ex.HHVet = 0 and ex.HHAdultAge in (25, 55) and ex.HHType = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 15, ex.Cohort, ex.HoHID, ex.HHType, '8.3.32'
	from tlsa_Exit ex
	where ex.HHChronic = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 16, ex.Cohort, ex.HoHID, ex.HHType, '8.3.33'
	from tlsa_Exit ex
	where ex.HHChronic in (1,2)

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 17, ex.Cohort, ex.HoHID, ex.HHType, '8.3.34'
	from tlsa_Exit ex
	where ex.HHChronic in (0,3)

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 18, ex.Cohort, ex.HoHID, ex.HHType, '8.3.35'
	from tlsa_Exit ex
	where ex.HHDisability = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 19, ex.Cohort, ex.HoHID, ex.HHType, '8.3.36'
	from tlsa_Exit ex
	where ex.HHFleeingDV = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 20, ex.Cohort, ex.HoHID, ex.HHType, '8.3.37'
	from tlsa_Exit ex
	where ex.Stat = 1

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 21, ex.Cohort, ex.HoHID, ex.HHType, '8.3.38'
	from tlsa_Exit ex
	where ex.Stat = 2

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 
		case when ex.HoHRaceEthnicity = 1 then 23
			when ex.HoHRaceEthnicity = 16 then 24
			when ex.HoHRaceEthnicity = 2 then 25
			when ex.HoHRaceEthnicity = 26 then 26
			when ex.HoHRaceEthnicity = 3 then 27
			when ex.HoHRaceEthnicity = 36 then 28
			when ex.HoHRaceEthnicity = 6 then 29
			when ex.HoHRaceEthnicity = 7 then 30
			when ex.HoHRaceEthnicity = 67 then 31
			when ex.HoHRaceEthnicity = 4 then 32
			when ex.HoHRaceEthnicity = 46 then 33
			when ex.HoHRaceEthnicity = 5 then 34
			when ex.HoHRaceEthnicity = 56 then 35
			when ex.HoHRaceEthnicity >=12 and ex.HoHRaceEthnicity not in (98,99) and cast(ex.HoHRaceEthnicity as nvarchar) not like '%6%' then 36
			when ex.HoHRaceEthnicity >=126 and cast(ex.HoHRaceEthnicity as nvarchar) like '%6%' then 37
			else null end
		, ex.Cohort, ex.HoHID, ex.HHType, '8.3.39'
	from tlsa_Exit ex
	where ex.HoHRaceEthnicity not in (98,99)

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 38, 1, ex.HoHID, ex.HHType, '8.3.40'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%1%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 39, 1, ex.HoHID, ex.HHType, '8.3.41'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%2%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 40, 1, ex.HoHID, ex.HHType, '8.3.42'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%3%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 41, 1, ex.HoHID, ex.HHType, '8.3.43'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%6%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 42, 1, ex.HoHID, ex.HHType, '8.3.44'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%7%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 43, 1, ex.HoHID, ex.HHType, '8.3.45'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%4%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 44, 1, ex.HoHID, ex.HHType, '8.3.46'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%5%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 45, ex.Cohort, ex.HoHID, ex.HHType, '8.3.47'
	from tlsa_Exit ex
	where ex.HHAdultAge = 55 and ex.HHType = 1 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 46, ex.Cohort, ex.HoHID, ex.HHType, '8.3.48'
	from tlsa_Exit ex
	where ex.HHParent = 1 and ex.HHType = 3

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 47, ex.Cohort, ex.HoHID, ex.HHType, '8.3.49'
	from tlsa_Exit ex
	where ex.AC3Plus = 1 and ex.HHType = 2

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 48, ex.Cohort, ex.HoHID, ex.HHType, '8.3.50'
	from tlsa_Exit ex
	where ex.HHFleeingDV = 2

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct rp.PopID, p1.Cohort, p1.HoHID, p1.HHType, '8.3.51'
	from ref_RowPopulations rp
	inner join tlsa_AveragePops p1 on p1.PopID = rp.Pop1
	inner join tlsa_AveragePops p2 on p2.PopID = rp.Pop2	
		and p1.Cohort = p2.Cohort 
		and p1.HHType = p2.HHType and p1.HoHID = p2.HoHID

/*
	8.4-8.7 Average Days from LSAHousehold 
 */

	truncate table lsa_Calculated 

	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select case rv.RowID 
		when 1 then avg(hh.ESDays)
		when 2 then avg(hh.THDays)
		when 3 then avg(hh.ESTDays)
		when 4 then avg(hh.RRHPSHPreMoveInDays) 
		when 5 then avg(hh.SystemHomelessDays)
		when 6 then avg(hh.Other3917Days)
		when 7 then avg(hh.TotalHomelessDays)
		when 8 then avg(hh.RRHHousedDays)
		when 9 then avg(hh.SystemDaysNotPSHHoused)
		when 10 then avg(hh.PSHHousedDays)
		when 11 then avg(hh.PSHHousedDays)
		when 12 then avg(hh.RRHPreMoveInDays)
		when 13 then avg(hh.RRHPreMoveInDays)
		when 14 then avg(hh.RRHPreMoveInDays)
		when 15 then avg(hh.RRHHousedDays)
		else avg(hh.RRHHousedDays) end,
		rv.Cohort, rv.Universe, ph.HHType,
		rp.PopID, rv.SystemPath, rv.RowID, 
		hh.ReportID, '8.4-8.7'
	from tlsa_Household hh 
	inner join tlsa_AveragePops pop on (pop.PopID = 0 or (pop.HHType = hh.HHType and pop.HoHID = hh.HoHID)) and pop.Cohort = 1
	inner join ref_RowPopulations rp on rp.PopID = pop.PopID and rp.RowMin between 1 and 16
	inner join ref_PopHHTypes ph on ph.PopID = rp.PopID and (ph.HHType = hh.HHType or ph.HHType = 0)
	inner join ref_RowValues rv on rv.RowID between rp.RowMin and rp.RowMax 
			and ((rp.ByPath is null and rv.SystemPath = -1) 
				or (rp.ByPath = 1 and rv.SystemPath <> -1 and rv.SystemPath = hh.SystemPath))
	where rv.RowID between 1 and 16
		and case rv.RowID 
				when 1 then hh.ESDays
				when 2 then hh.THDays
				when 3 then hh.ESTDays
				when 4 then hh.RRHPSHPreMoveInDays 
				when 5 then hh.SystemHomelessDays
				when 6 then hh.Other3917Days
				when 7 then hh.TotalHomelessDays
				when 8 then hh.RRHHousedDays
				when 9 then hh.SystemDaysNotPSHHoused
				when 10 then hh.PSHHousedDays
				when 11 then hh.PSHHousedDays
				when 12 then hh.RRHPreMoveInDays
				when 13 then hh.RRHPreMoveInDays
				when 14 then hh.RRHPreMoveInDays
				when 15 then hh.RRHHousedDays
			else hh.RRHHousedDays end > 0
		and (rv.RowID <> 10 or (hh.PSHMoveIn in (1,2) and hh.PSHStatus in (12,22)))
		and (rv.RowID <> 11 or (hh.PSHMoveIn in (1,2) and hh.PSHStatus in (11,21)))
		and (rv.RowID <> 12 or (hh.RRHStatus in (12,22) and hh.RRHMoveIn = 0))
		and (rv.RowID <> 13 or (hh.RRHStatus in (11,21) and hh.RRHMoveIn = 0))
		and (rv.RowID <> 14 or (hh.RRHStatus > 2 and hh.RRHMoveIn in (1,2)))
		and (rv.RowID <> 15 or (hh.RRHStatus in (12,22) and hh.RRHMoveIn in (1,2)))
		and (rv.RowID <> 16 or (hh.RRHStatus in (11,21) and hh.RRHMoveIn in (1,2)))
	group by rv.RowID, rv.Cohort, rv.Universe, ph.HHType,
		rp.PopID, rv.SystemPath, rv.RowID, 
		hh.ReportID

/*
	8.8-8.10 Average Days from LSAExit 
*/


	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(ex.ReturnTime),
		rv.Cohort, rv.Universe, ph.HHType,
		rp.PopID, rv.SystemPath, rv.RowID, 
		ex.ReportID, '8.8-8.10'
	from tlsa_Exit ex 
	inner join tlsa_AveragePops pop on pop.Cohort = ex.Cohort and (pop.PopID = 0 or (pop.HHType = ex.HHType and pop.HoHID = ex.HoHID)) 
	inner join ref_RowPopulations rp on rp.PopID = pop.PopID 
	inner join ref_PopHHTypes ph on ph.PopID = rp.PopID and (ph.HHType = 0 or ph.HHType = ex.HHType)
	inner join ref_RowValues rv on rv.RowID between rp.RowMin and rp.RowMax 
			and (rv.SystemPath = -1 or rv.SystemPath = ex.SystemPath)
			and rv.Cohort = ex.Cohort 
			and rv.Universe = case 
				when ex.ExitTo between 400 and 499 then 2
				when ex.ExitTo between 100 and 399 then 3
				else 4 end
	where (rv.RowID between 18 and 36 or rv.RowID between 63 and 66) 
		and ex.ReturnTime > 0
		and (rv.RowID not between 18 and 22 or ex.ExitFrom = (rv.RowID - 16))
		and (rv.RowID <> 63 or ex.ExitFrom = 7)
		and (rv.RowID <> 64 or ex.ExitFrom = 8)
		and (rv.RowID <> 65 or ex.ExitFrom = 9)
		and (rv.RowID <> 66 or ex.ExitFrom = 10)
		and (rv.RowID <> 36 or ex.SystemPath <> -1)
	group by rv.RowID, rv.Cohort, rv.Universe, ph.HHType,
		rp.PopID, rv.SystemPath, rv.RowID, 
		ex.ReportID

/*
	8.11 Average Days to Return by Exit Destination 
*/

	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(ex.ReturnTime),
		rv.Cohort, rv.Universe, ph.HHType,
		rp.PopID, rv.SystemPath, rv.RowID, 
		ex.ReportID, '8.11'
	from tlsa_Exit ex 
	inner join tlsa_AveragePops pop on pop.Cohort = ex.Cohort and (pop.PopID = 0 or (pop.HHType = ex.HHType and pop.HoHID = ex.HoHID)) 
	inner join ref_RowPopulations rp on rp.PopID = pop.PopID 
	inner join ref_PopHHTypes ph on ph.PopID = rp.PopID and (ph.HHType = 0 or ph.HHType = ex.HHType)
	inner join ref_RowValues rv on rv.RowID between rp.RowMin and rp.RowMax 
			and rv.RowID = case ex.ExitTo 
				when 101 then 101
				when 116 then 102
				when 118 then 103
				when 204 then 104
				when 205 then 105
				when 206 then 106
				when 207 then 107
				when 215 then 108
				when 225 then 109
				when 302 then 110
				when 312 then 111
				when 313 then 112
				when 314 then 113
				when 327 then 114
				when 329 then 115
				when 332 then 116
				when 410 then 117
				when 411 then 118
				when 419 then 119
				when 420 then 120
				when 421 then 121
				when 422 then 122
				when 423 then 123
				when 426 then 124
				when 428 then 125
				when 431 then 126
				when 433 then 127
				when 434 then 128
				when 436 then 129
				when 437 then 130
				when 438 then 131
				when 439 then 132
				when 440 then 133
				when 24 then 134
				when 98 then 135
				else 136 end
			and rv.Cohort = ex.Cohort 
			and rv.Universe = case 
				when ex.ExitTo between 400 and 499 then 2
				when ex.ExitTo between 100 and 399 then 3
				else 4 end
	where rv.RowID between 101 and 136 
		and ex.ReturnTime > 0
	group by rv.RowID, rv.Cohort, rv.Universe, ph.HHType,
		rp.PopID, rv.SystemPath, rv.RowID, 
		ex.ReportID

end -- END IF LSAScope <> HIC

/*
	End LSACalculated Averages for LSAHousehold and LSAExit
*/
/*
LSA FY2024 Sample Code
Name:  09 LSACalculated AHAR Counts.sql  

FY2024 Changes

	Section 9.6 - Get OPH Point-in-Time Counts for HIC

	(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)
	
Uses static reference tables:
	ref_RowValues - Required Cohort, Universe, SystemPath values for each RowID
	ref_RowPopulations - Required Populations for each RowID 
					and (for rows 1-9) whether the RowID is required by SystemPath for the Population
	ref_PopHHTypes -  HHTypes required in LSACalculated for each Population by PopID
Populates and references:
	tlsa_CountPops - By PopID -- HouseholdID and/or PersonalID for each population member
	
  9 Populations for AHAR Counts 
*/
	truncate table tlsa_CountPops 

	insert into tlsa_CountPops (PopID, Step)
	values (0, '9.1.0')

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 10, HouseholdID, '9.1.1' 
	from tlsa_HHID
	where AHAR = 1 and HHAdultAge = 18 
		and ActiveHHType = 1

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 11, HouseholdID, '9.1.2' 
	from tlsa_HHID
	where AHAR = 1 and HHAdultAge = 24 
		and ActiveHHType = 1

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 12, HouseholdID, '9.1.3' 
	from tlsa_HHID
	where AHAR = 1 and HHParent = 1 and HHAdultAge in (18,24)
		and ActiveHHType = 2

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 13, HouseholdID, '9.1.4' 
	from tlsa_HHID
	where AHAR = 1 and HHVet = 1

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 14, HouseholdID, '9.1.5' 
	from tlsa_HHID
	where AHAR = 1 and HHVet = 0 and HHAdultAge in (25,55)
	and ActiveHHType = 1

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 15, HouseholdID, '9.1.6' 
	from tlsa_HHID
	where AHAR = 1 and HHChronic = 1

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 18, HouseholdID, '9.1.7' 
	from tlsa_HHID
	where AHAR = 1 and HHDisability = 1

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 19, HouseholdID, '9.1.8'
	from tlsa_HHID
	where AHAR = 1 and HHFleeingDV = 1

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 45, HouseholdID, '9.1.9' 
	from tlsa_HHID
	where AHAR = 1 and HHAdultAge = 55
		and ActiveHHType = 1

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 46, HouseholdID, '9.1.10' 
	from tlsa_HHID
	where AHAR = 1 and HHParent = 1 and ActiveHHType = 3

	insert into tlsa_CountPops (PopID, HouseholdID, Step)
	select distinct 48, HouseholdID, '9.1.11'
	from tlsa_HHID
	where AHAR = 1 and HHFleeingDV = 2

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 50, n.PersonalID, '9.1.12' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and lp.VetStatus = 1

	insert into tlsa_CountPops (PopID, PersonalID, HouseholdID, Step) 
	select distinct 51, hhid.HoHID, hhid.HouseholdID, '9.1.13'
	from tlsa_HHID hhid 
	where hhid.AHAR = 1 and hhid.HHAdultAge in (18,24) and hhid.HHParent = 1 and hhid.ActiveHHType = 2

	insert into tlsa_CountPops (PopID, PersonalID, HouseholdID, Step) 
	select distinct 52, hhid.HoHID, hhid.HouseholdID, '9.1.14' 
	from tlsa_HHID hhid 
	where hhid.AHAR = 1 and hhid.HHParent = 1 and hhid.ActiveHHType = 3

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 53, n.PersonalID, '9.1.15' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and lp.DisabilityStatus = 1 and (
		(lp.CHTime = 365 and lp.CHTimeStatus in (1,2))
		or (lp.CHTime = 400 and lp.CHTimeStatus = 2))

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 54, n.PersonalID, '9.1.16' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and lp.DisabilityStatus = 1

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 55, n.PersonalID, '9.1.17' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and lp.DVStatus = 1

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 
	  case when lp.RaceEthnicity = 1 then 56
			when lp.RaceEthnicity = 16 then 57
			when lp.RaceEthnicity = 2 then 58
			when lp.RaceEthnicity = 26 then 59
			when lp.RaceEthnicity = 3 then 60
			when lp.RaceEthnicity = 36 then 61
			when lp.RaceEthnicity = 6 then 62
			when lp.RaceEthnicity = 7 then 63
			when lp.RaceEthnicity = 67 then 64
			when lp.RaceEthnicity = 4 then 65
			when lp.RaceEthnicity = 46 then 66
			when lp.RaceEthnicity = 5 then 67
			when lp.RaceEthnicity = 56 then 68
			when lp.RaceEthnicity >= 12 and lp.RaceEthnicity not in (98,99) and cast(lp.RaceEthnicity as nvarchar) not like '%6%' then 69
			when lp.RaceEthnicity >= 126 and cast(lp.RaceEthnicity as nvarchar) like '%6%' then 70 else null end
		, n.PersonalID, '9.1.18' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and lp.RaceEthnicity not in (98,99) 

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 71, n.PersonalID, '9.1.19' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and cast(lp.RaceEthnicity as nvarchar) like '%1%' 

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 72, n.PersonalID, '9.1.20' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and cast(lp.RaceEthnicity as nvarchar) like '%2%' 

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 73, n.PersonalID, '9.1.21' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and cast(lp.RaceEthnicity as nvarchar) like '%3%' 

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 74, n.PersonalID, '9.1.22' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and cast(lp.RaceEthnicity as nvarchar) like '%6%' 

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 75, n.PersonalID, '9.1.23' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and cast(lp.RaceEthnicity as nvarchar) like '%7%' 

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 76, n.PersonalID, '9.1.24' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and cast(lp.RaceEthnicity as nvarchar) like '%4%' 

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 77, n.PersonalID, '9.1.25' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and cast(lp.RaceEthnicity as nvarchar) like '%5%' 


	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct case lp.Gender
		when 0 then 78
		when 1 then 79
		when 2 then 80
		when 5 then 81
		when 4 then 82
		when 6 then 83
		when 3 then 84
		else 85 end, n.PersonalID, '9.1.26' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and lp.Gender not in (98, 99)

	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct case max(n.ActiveAge)
		when 0 then 86
		when 2 then 87
		when 5 then 88
		when 17 then 89
		when 21 then 90
		when 24 then 91
		when 34 then 92
		when 44 then 93
		when 54 then 94
		when 64 then 95
		else 96 end
		, n.PersonalID, '9.1.27'
	from tlsa_Enrollment n 
	where n.ActiveAge not in (98,99) and n.AHAR = 1 
	group by n.PersonalID


	insert into tlsa_CountPops (PopID, PersonalID, Step) 
	select distinct 97, n.PersonalID, '9.1.28' 
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID 
	where n.AHAR = 1 and lp.DVStatus in (2,3)

	insert into tlsa_CountPops (PopID, PersonalID, HouseholdID, Step)
	select distinct case when hhid.ActiveHHType = 1 and n.ActiveAge = 21 then 1190
			when hhid.ActiveHHType = 1 and n.ActiveAge = 24 then 1191
			when hhid.ActiveHHType = 2 and n.ActiveAge = 21 then 1290
			else 1291 end
		, n.PersonalID, hhid.HouseholdID, '9.1.29'
	from tlsa_Enrollment n
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	where hhid.HHAdultAge in (18,24)
		and n.ActiveAge in (21,24)
		and (ActiveHHType = 1 or (ActiveHHType = 2 and HHParent = 1)) 
		and n.AHAR = 1

    insert into tlsa_CountPops (PopID, PersonalID, HouseholdID, Step)
	select distinct rp.PopID, p1.PersonalID, p1.HouseholdID, '9.1.30'
	from ref_RowPopulations rp
	inner join tlsa_CountPops p1 on p1.PopID = rp.Pop1
	inner join tlsa_CountPops p2 on p2.PopID = rp.Pop2 and p2.PersonalID = p1.PersonalID
	where rp.RowMin >= 53 and rp.RowMax <> 64

/*
	9.2 Identify Point-in-Time Cohorts for AHAR Counts
*/

	update n
	set PITOctober = (select distinct case when cd.Cohort is null then 0 else 1 end
						from tlsa_CohortDates cd
						where (cd.CohortStart < n.ExitDate or n.ExitDate is NULL) 
							and n.EntryDate <= cd.CohortStart and cd.Cohort = 10)
	  , PITJanuary = (select distinct case when cd.Cohort is null then 0 else 1 end
						from tlsa_CohortDates cd
						where (cd.CohortStart < n.ExitDate or n.ExitDate is NULL) 
							and n.EntryDate <= cd.CohortStart and cd.Cohort = 11)
	  , PITApril = (select distinct case when cd.Cohort is null then 0 else 1 end
						from tlsa_CohortDates cd
						where (cd.CohortStart < n.ExitDate or n.ExitDate is NULL) 
							and n.EntryDate <= cd.CohortStart and cd.Cohort = 12)
	  , PITJuly = (select distinct case when cd.Cohort is null then 0 else 1 end
						from tlsa_CohortDates cd
						where (cd.CohortStart < n.ExitDate or n.ExitDate is NULL) 
							and n.EntryDate <= cd.CohortStart and cd.Cohort = 13)
	  , Step = '9.2.1'
	from tlsa_Enrollment n
	where n.LSAProjectType in (0,2,8) 
		and n.AHAR = 1

	update n
	set n.PITOctober = PIT.PITOctober
		, n.PITJanuary = PIT.PITJanuary
		, n.PITApril = PIT.PITApril
		, n.PITJuly = PIT.PITJuly
		, n.Step = '9.2.2'
	from tlsa_Enrollment n
	inner join (select distinct nbn.EnrollmentID 
		  , PITOctober = max(case when cd1.Cohort is null then 0 else 1 end)
		  , PITJanuary = max(case when cd2.Cohort is null then 0 else 1 end)
		  , PITApril = max(case when cd3.Cohort is null then 0 else 1 end)
		  , PITJuly = max(case when cd4.Cohort is null then 0 else 1 end)
		from tlsa_Enrollment nbn
		inner join tlsa_CohortDates cd on cd.CohortEnd >= nbn.EntryDate 
			and (nbn.ExitDate is NULL or nbn.ExitDate > cd.CohortStart) 
		inner join hmis_Services bn on bn.EnrollmentID = nbn.EnrollmentID
			and nbn.EntryDate <= bn.DateProvided
			and (nbn.ExitDate is NULL or nbn.ExitDate > bn.DateProvided)
		left outer join tlsa_CohortDates cd1 on cd1.CohortStart = bn.DateProvided and cd1.Cohort = 10 
		left outer join tlsa_CohortDates cd2 on cd2.CohortStart = bn.DateProvided and cd2.Cohort = 11 
		left outer join tlsa_CohortDates cd3 on cd3.CohortStart = bn.DateProvided and cd3.Cohort = 12 
		left outer join tlsa_CohortDates cd4 on cd4.CohortStart = bn.DateProvided and cd4.Cohort = 13 
		where nbn.LSAProjectType = 1
			and nbn.AHAR = 1
		group by nbn.EnrollmentID) PIT on PIT.EnrollmentID = n.EnrollmentID

	update n
	set PITOctober = (select distinct case when cd.Cohort is null then 0 else 1 end
						from tlsa_CohortDates cd
						where (cd.CohortStart < n.ExitDate or n.ExitDate is NULL) 
							and n.MoveInDate <= cd.CohortStart and cd.Cohort = 10)
	  , PITJanuary = (select distinct case when cd.Cohort is null then 0 else 1 end
						from tlsa_CohortDates cd
						where (cd.CohortStart < n.ExitDate or n.ExitDate is NULL) 
							and n.MoveInDate <= cd.CohortStart and cd.Cohort = 11)
	  , PITApril = (select distinct case when cd.Cohort is null then 0 else 1 end
						from tlsa_CohortDates cd
						where (cd.CohortStart < n.ExitDate or n.ExitDate is NULL) 
							and n.MoveInDate <= cd.CohortStart and cd.Cohort = 12)
	  , PITJuly = (select distinct case when cd.Cohort is null then 0 else 1 end
						from tlsa_CohortDates cd
						where (cd.CohortStart < n.ExitDate or n.ExitDate is NULL) 
							and n.MoveInDate <= cd.CohortStart and cd.Cohort = 13)
	  , Step = '9.2.3'
	from tlsa_Enrollment n
	where n.LSAProjectType in (3,13) 
		and n.AHAR = 1

/*
	9.3 Counts of People and Households by Project and Household Characteristics

*/

	delete from lsa_Calculated where ReportRow in (53,54)
	
	insert into lsa_Calculated (Value, Cohort, Universe, HHType, Population, SystemPath, ProjectID
		, ReportRow, ReportID, Step)
	select distinct case when rv.RowID = 53 then count(distinct n.PersonalID) 
			else count(distinct hhid.HoHID + cast(hhid.ActiveHHType as varchar)) end
		, rv.Cohort, rv.Universe, ph.HHType, rp.PopID, rv.SystemPath
		, case when rv.Universe = 10 then hhid.ProjectID else null end
		, rv.RowID, (select distinct ReportID from lsa_Report), '9.3.1'
	from ref_RowValues rv
	inner join ref_RowPopulations rp on rv.RowID between rp.RowMin and rp.RowMax 
	inner join ref_PopHHTypes ph on ph.PopID = rp.PopID
	inner join tlsa_CountPops pop on rp.PopID = pop.PopID 
	inner join tlsa_HHID hhid on (rp.PopID = 0 or hhid.HouseholdID = pop.HouseholdID)
		and (hhid.ActiveHHType = ph.HHType or ph.HHType = 0)
		and (
				rv.Universe = 10 
				or (rv.Universe = 11 and hhid.LSAProjectType in (0,1))
				or (rv.Universe = 12 and hhid.LSAProjectType = 8)
				or (rv.Universe = 13 and hhid.LSAProjectType = 2)
				or (rv.Universe = 14 and hhid.LSAProjectType = 13)
				or (rv.Universe = 15 and hhid.LSAProjectType = 3)
				or (rv.Universe = 16 and hhid.LSAProjectType in (0,1,2,8))
			)
	inner join tlsa_Enrollment n on n.HouseholdID = hhid.HouseholdID
			and case rv.Cohort	
				when 1 then n.AHAR
				when 10 then n.PITOctober
				when 11 then n.PITJanuary
				when 12 then n.PITApril
				else n.PITJuly end = 1 
		where rv.RowID in (53,54)
		group by rv.RowID, rv.Cohort, rv.Universe, ph.HHType, rp.PopID, rv.SystemPath
			, case when rv.Universe = 10 then hhid.ProjectID else null end

/*
	9.4 Counts of People by Project and Personal Characteristics
*/

	delete from lsa_Calculated where ReportRow = 55

	insert into lsa_Calculated (Value, Cohort, Universe, HHType, Population, SystemPath, ProjectID
		, ReportRow, ReportID, Step)
	select distinct count(distinct n.PersonalID) 
		, rv.Cohort, rv.Universe, ph.HHType, rp.PopID, rv.SystemPath
		, case when rv.Universe = 10 then hhid.ProjectID else null end
		, rv.RowID, (select distinct ReportID from lsa_Report), '9.4.1'
	from ref_RowValues rv
	inner join ref_RowPopulations rp on rv.RowID between rp.RowMin and rp.RowMax 
	inner join ref_PopHHTypes ph on ph.PopID = rp.PopID
	inner join tlsa_CountPops pop on rp.PopID = pop.PopID
		and (rv.Universe <> 10 or rp.ByProject = 1)
	inner join tlsa_Enrollment n on n.PersonalID = pop.PersonalID
			and (n.HouseholdID = pop.HouseholdID or pop.HouseholdID is null)
			and case rv.Cohort	
				when 1 then n.AHAR
				when 10 then n.PITOctober
				when 11 then n.PITJanuary
				when 12 then n.PITApril
				else n.PITJuly end = 1 
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID 
		and (hhid.ActiveHHType = ph.HHType or ph.HHType = 0)
		and (
				rv.Universe = 10 
				or (rv.Universe = 11 and hhid.LSAProjectType in (0,1))
				or (rv.Universe = 12 and hhid.LSAProjectType = 8)
				or (rv.Universe = 13 and hhid.LSAProjectType = 2)
				or (rv.Universe = 14 and hhid.LSAProjectType = 13)
				or (rv.Universe = 15 and hhid.LSAProjectType = 3)
				or (rv.Universe = 16 and hhid.LSAProjectType in (0,1,2,8))
			)
		where rv.RowID = 55 
		group by rv.Cohort, rv.Universe, ph.HHType, rp.PopID, rv.SystemPath
			, case when rv.Universe = 10 then hhid.ProjectID else null end
			, rv.RowID

/*
	9.5 Counts of Bednights

		By ProjectID (Universe 10)
			Night-by-night ES - 9.5.1
			Entry-exit ES/TH/SH/RRH/PSH - 9.5.2
		By project type ES (Universe 11) - 9.5.3
		By project type SH/TH/RRH/PSH (Universe 12-15) - 9.5.4
		ES/SH/TH unduplicated (Universe 16) - 9.5.5

*/

	-- By ProjectID (Universe 10) - night by night ES

	delete from lsa_Calculated where ReportRow in (56,57)


	insert into lsa_Calculated (Value, Cohort, Universe, HHType, Population, SystemPath, ProjectID, ReportRow, ReportID, Step)
	select distinct count(distinct n.PersonalID + cast(bn.DateProvided as varchar)), 1, 10, ph.HHType, pop.PopID, -1
			, hhid.ProjectID
			, case when pop.PopID in (0,10,11) then 56 else 57 end 
			, (select distinct ReportID from lsa_Report), '9.5.1'
		from hmis_Services bn
		inner join tlsa_Enrollment n on n.EnrollmentID = bn.EnrollmentID
				and (n.ExitDate is null or n.ExitDate > bn.DateProvided)
				and n.EntryDate <= bn.DateProvided
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID 
		inner join tlsa_CountPops pop on (pop.HouseholdID = n.HouseholdID and pop.PopID in (10,11))
			or (pop.PersonalID = n.PersonalID and pop.PopID in (50,53))
			or (pop.PopID = 0)
		inner join ref_PopHHTypes ph on ph.PopID = pop.PopID and (ph.HHType = 0 or ph.HHType = hhid.ActiveHHType)
		inner join lsa_Report rpt on rpt.ReportStart <= bn.DateProvided and rpt.ReportEnd >= bn.DateProvided
		where n.LSAProjectType = 1 and bn.RecordType = 200 and bn.DateDeleted is NULL and n.AHAR = 1
		group by ph.HHType, hhid.ProjectID, pop.PopID

	-- By ProjectID (Universe 10) - entry-exit ES, SH, TH, RRH, and PSH 
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select distinct count (distinct n.PersonalID + cast(cal.theDate as nvarchar))
		, 1, 10, ph.HHType
		, pop.PopID, -1 
		, case when pop.PopID in (0,10,11) then 56 else 57 end 
		, n.ProjectID
		, rpt.ReportID, '9.5.2'
	from tlsa_Enrollment n 
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join tlsa_CountPops pop on (pop.HouseholdID = n.HouseholdID and pop.PopID in (10,11))
		or (pop.PersonalID = n.PersonalID and pop.PopID in (50,53))
		or (pop.PopID = 0)
	inner join ref_PopHHTypes ph on ph.PopID = pop.PopID and (ph.HHType = 0 or ph.HHType = hhid.ActiveHHType)
	inner join lsa_Report rpt on rpt.ReportEnd >= 
		case when n.LSAProjectType in (0,2,8) then n.EntryDate
			else n.MoveInDate end
	inner join ref_Calendar cal on cal.theDate >=
		case when n.LSAProjectType in (0,2,8) then n.EntryDate
			else n.MoveInDate end
		and cal.theDate >= rpt.ReportStart
		and cal.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
		and n.LSAProjectType in (0,2,3,8,13)
	where n.AHAR = 1 
	group by n.ProjectID, rpt.ReportID, ph.HHType, pop.PopID
	
	-- All ES (Universe 11) 
	insert into lsa_Calculated (Value, Cohort, Universe, HHType, Population, SystemPath, ProjectID, ReportRow, ReportID, Step)
	select distinct count(distinct es.bn), 1, 11, es.HHType, es.PopID, -1, NULL
		, case when es.PopID in (0,10,11) then 56 else 57 end 
		, (select distinct ReportID from lsa_Report), '9.5.3'
	from 
		(select distinct n.PersonalID + cast(bn.DateProvided as varchar) as bn, ph.HHType as HHType, pop.PopID
			from hmis_Services bn
			inner join tlsa_Enrollment n on n.EnrollmentID = bn.EnrollmentID
				and (n.ExitDate is null or n.ExitDate > bn.DateProvided)
				and n.EntryDate <= bn.DateProvided
			inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID 
			inner join tlsa_CountPops pop on (pop.HouseholdID = n.HouseholdID and pop.PopID in (10,11))
				or (pop.PersonalID = n.PersonalID and pop.PopID in (50,53))
				or (pop.PopID = 0)
			inner join ref_PopHHTypes ph on ph.PopID = pop.PopID and (ph.HHType = 0 or ph.HHType = hhid.ActiveHHType)
			inner join lsa_Report rpt on rpt.ReportStart <= bn.DateProvided and rpt.ReportEnd >= bn.DateProvided
			where hhid.LSAProjectType = 1 and bn.RecordType = 200 and bn.DateDeleted is NULL and n.AHAR = 1
		union all
		select distinct n.PersonalID + cast(cal.theDate as varchar), ph.HHType, pop.PopID
		from tlsa_Enrollment n 
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
		inner join tlsa_CountPops pop on (pop.HouseholdID = n.HouseholdID and pop.PopID in (10,11))
			or (pop.PersonalID = n.PersonalID and pop.PopID in (50,53))
			or (pop.PopID = 0)
		inner join ref_PopHHTypes ph on ph.PopID = pop.PopID and (ph.HHType = 0 or ph.HHType = hhid.ActiveHHType)
		inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
		inner join ref_Calendar cal on cal.theDate >= n.EntryDate
			and cal.theDate >= rpt.ReportStart
			and cal.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
			and n.LSAProjectType = 0
		where n.AHAR = 1) es
	group by es.HHType, es.PopID
		
	-- By Project Type SH/TH/RRH/PSH (Universe 12-15)
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select distinct count (distinct n.PersonalID + cast(cal.theDate as nvarchar))
		, 1, case n.LSAProjectType 
				when 8 then 12
				when 2 then 13
				when 13 then 14 else 15 end 
		, ph.HHType
		, pop.PopID, -1
		, case when pop.PopID in (0,10,11) then 56 else 57 end 
		, rpt.ReportID, '9.5.4'
	from tlsa_Enrollment n 
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join tlsa_CountPops pop on (pop.HouseholdID = n.HouseholdID and pop.PopID in (10,11))
		or (pop.PersonalID = n.PersonalID and pop.PopID in (50,53))
		or (pop.PopID = 0)
	inner join ref_PopHHTypes ph on ph.PopID = pop.PopID and (ph.HHType = 0 or ph.HHType = hhid.ActiveHHType)
	inner join lsa_Report rpt on rpt.ReportEnd >= 
		case when n.LSAProjectType in (2,8) then n.EntryDate
			else n.MoveInDate end
	inner join ref_Calendar cal on cal.theDate >=
		case when n.LSAProjectType in (2,8) then n.EntryDate
			else n.MoveInDate end
		and cal.theDate >= rpt.ReportStart
		and cal.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
		and n.LSAProjectType in (2,3,8,13)
	where n.AHAR = 1 
	group by case n.LSAProjectType 
				when 8 then 12
				when 2 then 13
				when 13 then 14 else 15 end, rpt.ReportID, ph.HHType, pop.PopID

	-- Unduplicated ES/SH/TH (Universe 16) 
	insert into lsa_Calculated (Value, Cohort, Universe, HHType, Population, SystemPath, ProjectID, ReportRow, ReportID, Step)
	select distinct count(distinct est.bn), 1, 16, est.HHType, est.PopID, -1, NULL
		, case when est.PopID in (0,10,11) then 56 else 57 end 
		, (select distinct ReportID from lsa_Report), '9.5.5'
	from 
		(select distinct n.PersonalID + cast(bn.DateProvided as varchar) as bn, ph.HHType as HHType, pop.PopID
			from hmis_Services bn
			inner join tlsa_Enrollment n on n.EnrollmentID = bn.EnrollmentID and n.EntryDate <= bn.DateProvided 
				and (n.ExitDate is null or n.ExitDate > bn.DateProvided)
			inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID 
			inner join tlsa_CountPops pop on (pop.HouseholdID = n.HouseholdID and pop.PopID in (10,11))
				or (pop.PersonalID = n.PersonalID and pop.PopID in (50,53))
				or (pop.PopID = 0)
			inner join ref_PopHHTypes ph on ph.PopID = pop.PopID and (ph.HHType = 0 or ph.HHType = hhid.ActiveHHType)
			inner join lsa_Report rpt on rpt.ReportStart <= bn.DateProvided and rpt.ReportEnd >= bn.DateProvided
			where hhid.LSAProjectType = 1 and bn.RecordType = 200 and bn.DateDeleted is NULL and n.AHAR = 1
		union all
		select distinct n.PersonalID + cast(cal.theDate as varchar), ph.HHType, pop.PopID
		from tlsa_Enrollment n 
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
		inner join tlsa_CountPops pop on (pop.HouseholdID = n.HouseholdID and pop.PopID in (10,11))
			or (pop.PersonalID = n.PersonalID and pop.PopID in (50,53))
			or (pop.PopID = 0)
		inner join ref_PopHHTypes ph on ph.PopID = pop.PopID and (ph.HHType = 0 or ph.HHType = hhid.ActiveHHType)
		inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
		inner join ref_Calendar cal on cal.theDate >= n.EntryDate
			and cal.theDate >= rpt.ReportStart
			and cal.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
			and n.LSAProjectType in (0,2,8)
		where n.AHAR = 1) est
	group by est.HHType, est.PopID


/*
	9.6.	Get OPH Point-In-Time Counts for HIC
	
*/

	delete from lsa_Calculated where Step = '9.6'

	insert into lsa_Calculated (Value, Cohort, Universe, HHType, Population, SystemPath, ProjectID, ReportRow, ReportID, Step)
	select count(distinct hh.PersonalID), 1, 10, 0, 0, -1, p.ProjectID, 53, rpt.ReportID, '9.6'
	from lsa_Project p 
	inner join lsa_HMISParticipation hp on hp.ProjectID = p.ProjectID 
	inner join lsa_Report rpt on rpt.ReportStart >= hp.HMISParticipationStatusStartDate
		and (hp.HMISParticipationStatusEndDate is null or hp.HMISParticipationStatusEndDate > rpt.ReportStart)
	inner join hmis_Enrollment hn on hn.ProjectID = p.ProjectID and hn.EntryDate <= rpt.ReportStart and hn.MoveInDate <= rpt.ReportStart 
		and hn.MoveInDate >= hn.EntryDate and hn.RelationshipToHoH = 1
		and hn.EnrollmentCoC = rpt.ReportCoC
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID
	inner join (select hhn.ProjectID, hhn.HouseholdID, hhn.PersonalID, hhn.EntryDate as StartDate, coalesce(hhx.ExitDate, getdate()) as EndDate
		from hmis_Enrollment hhn
		left outer join hmis_Exit hhx on hhx.EnrollmentID = hhn.EnrollmentID 
		where hhn.DateDeleted is null and hhx.DateDeleted is null) hh on hh.HouseholdID = hn.HouseholdID 
			and hh.StartDate <= rpt.ReportStart and hh.EndDate > ReportStart
	where rpt.LSAScope = 3 and hp.HMISParticipationType = 1 and p.ProjectType in (9,10)
		and (hx.ExitDate is null or hx.ExitDate > rpt.ReportStart)
		and hn.DateDeleted is null and hx.DateDeleted is null
	group by p.ProjectID, rpt.ReportID
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
		and p.OperatingEndDate between dateadd(dd, 1, cd.CohortStart) and cd.CohortEnd
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
	inner join lsa_Project p on p.ProjectID = n.ProjectID
	left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID and x.DateDeleted is null
		and x.ExitDate <= rpt.ReportEnd
	left outer join lsa_HMISParticipation part on part.ProjectID = n.ProjectID
		and part.HMISParticipationType = 1
		and part.HMISParticipationStatusStartDate <= n.EntryDate
		and (part.HMISParticipationStatusEndDate is null
			or part.HMISParticipationStatusEndDate > x.ExitDate
			or (x.ExitDate is null and part.HMISParticipationStatusEndDate > rpt.ReportEnd))
	where hoh.RelationshipToHoH = 1 and hoh.EnrollmentCoC = rpt.ReportCoC and part.ProjectID is null
		and (x.ExitDate is null or x.ExitDate >= ReportStart)
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
/*
LSA FY2024 Sample Code
Name: 11 LSAReport DQ and ReportDate.sql

FY2024 Changes
		
		None

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

	Please note that if this code is used in production, the first statement in section 11.6 
	should be reviewed and updated if necessary to set SSNValid to 0 include any system default 
	for missing SSN values that would not be identified by the existing code.
	
	11.1 HMIS HouseholdIDs With No CoC Identifier Active in LSA Projects During Report Period
*/
update rpt
set rpt.NoCoC = (select count (distinct n.HouseholdID)
			from hmis_Enrollment n 
			inner join lsa_Project p on p.ProjectID = n.ProjectID
				and p.ProjectType in (0,1,2,3,8,13)
			inner join lsa_Organization org on org.OrganizationID = p.OrganizationID
				and org.VictimServiceProvider = 0
			left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.DateDeleted is null
			where n.EntryDate <= rpt.ReportEnd 
				and (x.ExitDate is null or x.ExitDate >= rpt.ReportStart)
				and n.RelationshipToHoH = 1 
				and (n.EnrollmentCoC is null 
					or n.EnrollmentCoC not in (select coc.CoCCode 
						from hmis_ProjectCoC coc 
						where coc.ProjectID = p.ProjectID
							and coc.DateDeleted is null)
					)
				and n.DateDeleted is null 
			)
from lsa_Report rpt

/*
	11.2 HMIS HouseholdIDs Without Exactly One HoH Active in LSA Projects During Report Period
*/

update rpt
set rpt.NotOneHoH = (select count (distinct n.HouseholdID)
			from hmis_Enrollment n 
			inner join lsa_Project p on p.ProjectID = n.ProjectID
				and p.ProjectType in (0,1,2,3,8,13)
			inner join lsa_Organization org on org.OrganizationID = p.OrganizationID
				and org.VictimServiceProvider = 0
			inner join (select distinct hh.HouseholdID
				from hmis_Enrollment hh
				inner join lsa_Report coc on coc.ReportCoC = hh.EnrollmentCoC
				where hh.DateDeleted is null
				) coc on coc.HouseholdID = n.HouseholdID
			left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.DateDeleted is null
			left outer join (select hn.HouseholdID, count(distinct hn.EnrollmentID) as hoh
				from hmis_Enrollment hn
				where hn.RelationshipToHoH = 1 and hn.DateDeleted is null 
				group by hn.HouseholdID
				) hoh on hoh.HouseholdID = n.HouseholdID
			where n.EntryDate <= rpt.ReportEnd 
				and (x.ExitDate is null or x.ExitDate >= rpt.ReportStart)
				and n.DateDeleted is null
				and (hoh.hoh <> 1 or hoh.HouseholdID is null)
			)
from lsa_Report rpt

/*
	11.3 HMIS Enrollments Associated with LSA Households But Excluded from LSA Due to Invalid RelatioshipToHoH
*/

update rpt
set rpt.RelationshipToHoH = (select count(distinct hn.EnrollmentID)
			from hmis_Enrollment hn
			inner join tlsa_HHID hhid on hhid.HouseholdID = hn.HouseholdID	
			left outer join hmis_Exit x on x.EnrollmentID = hn.EnrollmentID 
					and x.DateDeleted is null
			where hhid.Active = 1 
				and hn.EntryDate <= rpt.ReportEnd 
				and (x.ExitDate is null or x.ExitDate >= rpt.ReportStart)
				and hn.DateDeleted is null
				and (hn.RelationshipToHoH is null or hn.RelationshipToHoH not in (1,2,3,4,5))
	)
from lsa_Report rpt

/*
	11.4 Invalid HMIS Move-In Dates for RRH and PSH Enrollments Included in LSA
*/

update rpt
set rpt.MoveInDate = 
	(select count(distinct hhid.EnrollmentID)
		from tlsa_HHID hhid
		inner join hmis_Enrollment hn on hn.EnrollmentID = hhid.EnrollmentID
		where hhid.LSAProjectType in (3,13,15)
			and hhid.Active = 1 
			and hhid.MoveInDate is null 
			and hn.MoveInDate <= rpt.ReportEnd
	)
from lsa_Report rpt

/*
	11.5 Counts of Clients/Households/Enrollments 
*/

update rpt
set rpt.UnduplicatedClient = (select count(distinct PersonalID)
	from tlsa_Person)
	, rpt.HouseholdEntry = (select count(distinct HouseholdID)
		from tlsa_HHID 
		where Active = 1)
	, rpt.ClientEntry = (select count(distinct EnrollmentID)
		from tlsa_Enrollment 
		where Active = 1)
	, rpt.AdultHoHEntry = (select count(distinct EnrollmentID)
		from tlsa_Enrollment 
		where Active = 1
		and (ActiveAge between 18 and 65 or RelationshipToHoH = 1))
	, rpt.ClientExit = (select count(distinct EnrollmentID)
		from tlsa_Enrollment 
		where Active = 1 and ExitDate is not NULL)
from lsa_Report rpt

/*
	11.6 SSN Issues 
*/

update lp
set lp.SSNValid = case when c.SSNDataQuality in (8,9) then 9
		when SUBSTRING(c.SSN,1,3) in ('000','666')
				or LEN(c.SSN) <> 9
				or SUBSTRING(c.SSN,4,2) = '00'
				or SUBSTRING(c.SSN,6,4) ='0000'
				or c.SSN is null
				or c.SSN = ''
				or c.SSN like '%[^0-9]%'
				or left(c.SSN,1) = '9'
				or c.SSN in ('111111111','222222222','333333333','444444444'
						,'555555555','777777777','888888888'
						, '123456789', '234567890', '345678901', '456789012', '567890123'
						, '678901234', '789012345', '890123456', '901234567')
			then 0 else 1 end 
from tlsa_Person lp
inner join hmis_Client c on c.PersonalID = lp.PersonalID

update rpt
set SSNNotProvided = (select count(distinct PersonalID)
	from tlsa_Person
	where SSNValid = 9)
	, SSNMissingOrInvalid = (select count(distinct PersonalID)
		from tlsa_Person
		where SSNValid = 0)
from lsa_Report rpt

update rpt
set rpt.ClientSSNNotUnique = case when ssn.people is null then 0 else ssn.people end
	, rpt.DistinctSSNValueNotUnique = case when ssn.SSNs is null then 0 else ssn.SSNs end 
from lsa_Report rpt
left outer join 
	(select lp.ReportID, count(distinct lp.PersonalID) as people, count(distinct c.SSN) as SSNs
	from tlsa_Person lp
	inner join hmis_Client c on c.PersonalID = lp.PersonalID
	inner join (select distinct dupe.PersonalID, dupeSSN.SSN
		from tlsa_Person dupe
		inner join hmis_Client dupeSSN on dupeSSN.PersonalID = dupe.PersonalID
	) other on other.PersonalID <> lp.PersonalID and other.SSN = c.SSN
	where lp.SSNValid = 1
	group by lp.ReportID) ssn on ssn.ReportID = rpt.ReportID

/*
	11.7 Enrollment Data Issues 
*/

update rpt
set rpt.DisablingCond = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	where n.Active = 1
	and n.DisabilityStatus = 99
	)
from lsa_Report rpt

update rpt
set rpt.LivingSituation = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.LivingSituation is null or hn.LivingSituation in (8,9,99))
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65))
from lsa_Report rpt

update rpt
set rpt.LengthOfStay = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.LengthOfStay is null or hn.LengthOfStay in (8,9,99))
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65))
from lsa_Report rpt

update rpt
set rpt.HomelessDate = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.DateToStreetESSH > hn.EntryDate
		 or (hn.DateToStreetESSH is null 
				and (n.LSAProjectType in (0,1,8)
					 or hn.LivingSituation between 100 and 199
					 or hn.PreviousStreetESSH = 1
					)
			)
		)
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
	)
from lsa_Report rpt

update rpt
set rpt.TimesHomeless = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.TimesHomelessPastThreeYears is NULL
		or hn.TimesHomelessPastThreeYears not in (1,2,3,4)) 
	and (n.LSAProjectType in (0,1,8)
			or hn.LivingSituation between 100 and 199
			or hn.PreviousStreetESSH = 1)
	and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65))
from lsa_Report rpt

update rpt
set rpt.MonthsHomeless = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.MonthsHomelessPastThreeYears is NULL
		or hn.MonthsHomelessPastThreeYears not between 101 and 113) 
	and (n.LSAProjectType in (0,1,8)
		or hn.LivingSituation between 100 and 199
		or hn.PreviousStreetESSH = 1)
	and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65))
from lsa_Report rpt

update rpt
set rpt.Destination = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
		and x.DateDeleted is null
	where n.Active = 1 and n.ExitDate is not null
		and (x.Destination is null
			or x.Destination in (8,9,17,30,99)
			or (x.Destination = 435 and x.DestinationSubsidyType is null))
	)
from lsa_Report rpt

/*
	11.8 Set ReportDate for LSAReport
*/
update lsa_Report set ReportDate = getdate()
