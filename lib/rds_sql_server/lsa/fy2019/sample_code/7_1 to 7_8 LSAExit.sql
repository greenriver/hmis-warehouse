/*

LSA FY2019 Sample Code

Name:  7_1 to 7_8 LSAExit.sql  (File 7 of 10)
Date:  4/20/2020   
	   5/14/2020 - section 7.1 - remove extraneous join to hmis_Exit
			     - section 7.6 - correct "DateDeleted = 0" to "DateDeleted is null"
	   5/21/2020 - Sections 7.1 - 7.7 - add set of Step column to all INSERT and UPDATE statements	
	   6/4/2020  - 7.4.1 - corrections to UPDATE statement for HHVet, HHDisability, HHFleeingDV, and HHParent
	   6/18/2020 - 7.4.1 - join on HouseholdID vs. EnrollmentID for HHDisability, HHFleeingDV, and HHParent
	   7/9/2020 - 7.1 = correct disqualify.EntryDate <= dateadd(dd, 14, hhid.ExitDate) to remove = sign 
					7.3 - calculate ReturnTime using the *earliest* EntryDate for a return enrollment 
					7.4.2 - correct set of HHAdultAge 
					7.4.3 - correct set of AC3Plus  
					7.5 - correction to Entry/ExitDate join criteria fcr prior activity
					7.7.1-7.7.3 - align criteria for identifying PSH in SystemPath with specs
					7.7.2 - Clarification of rationale for additional step not defined by specs
	   7/23/2020 - 7.5 - correction to use most recent exit prior to the qualifying exit where the most 
					recent EnrollmentCoC = ReportCoC (neither were limited to most recent) to determine Stat 
				   7.8 - modify case statement for Return time to match specs 
	7/30/2020 -- 7.6.1 -- correct relationship between EntryDate and ExitDate for PRIOR enrollment, not the same one.
	8/6/2020 - 7.6.2.a -- correct WHERE clause for tlsa_HHID to include enrollments for e/e ES and SH/TH/RRH/PSH  
							(was previously excluding all but e/e ES by requiring TrackingMethod <> 3)
	8/13/2020 - 7.3 - revise query to ensure that only enrollments with entry dates after the qualifying exit 
					  are included in pool of potential returns
				7.7.4 and 7.7.5 - correct HHType column used for join to psh subquery
	8/19/2020 - 7.4 - add vet subquery / correct set of HHVet
	8/20/2020 - 7.2 - add columns to ORDER BY clause ensure consistency in the event of 
						> 1 enrollments with the same destination category and exit date
				7.5 - correct code to align with specs / logic for LSAHousehold system engagement status
				7.6.1 - add criteria to ensure enrollment used for Stat is earlier than the qualifying exit 
				7.7 - compare EntryDate instead of ExitDate to LastInactive for SystemPath enrollments (no change in output
						-- if any part of the enrollment is > LastInactive, the whole enrollment is --
						but aligning to specs to reduce confusion)
	8/27/2020 - 7.2 - split into three separate steps, further address issue (from 8/20) in 7.2.2 of disambiguation 
						when multiple enrollments meet selection criteria for QualifyingExitHHID
				7.5 - add columns to ORDER BY clause in subquery to disambiguate when there are > 1 
						enrollments with the same exit date
				7.6.3 - add Cohort to lastDay subquery in both the SELECT and the join to tlsa_Exit
				7.7.5 - correct typo (was pshpre / should be psh)
				7.8 - correct group by clause
	9/3/2020 - 7.1 - add DateDeleted criteria for hmis_EnrollmentCoC
				7.6.2 (a and b) - replace hardcoded value of 1 for Cohort with tlsa_Exit.Cohort in INSERT to sys_TimePadded 
								- use CohortEnd as sys_TimePadded.EndDate if the padded value > CohortEnd

	7.1 Identify Qualifying Exits in Exit Cohort Periods
*/

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
		and (select top 1 CoCCode 
			 from hmis_EnrollmentCoC 
			 where DateDeleted is null 
				and EnrollmentID = disqualify.EnrollmentID 
				and InformationDate <= dateadd(dd, 14, hhid.ExitDate)
			 order by InformationDate desc) = rpt.ReportCoC
	where disqualify.EnrollmentID is null
		and (rpt.LSAScope = 1 or p.ProjectID is not null)
		and (select top 1 coc.CoCCode
			from hmis_EnrollmentCoC coc
			where coc.EnrollmentID = hhid.EnrollmentID
				and coc.InformationDate <= rpt.ReportEnd
				and coc.DateDeleted is null
			order by coc.InformationDate desc) = rpt.ReportCoC

/*
	7.2 Select Reportable Exits
*/
	delete from tlsa_Exit

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
			order by case when qx.ExitDest between 1 and 6 then 2
                      when qx.ExitDest between 7 and 14 then 3
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
              when qx.ProjectType = 1 then 2
              when qx.ProjectType = 2 then 3 
              when qx.ProjectType = 8 then 4
              when qx.ProjectType = 13 and qx.MoveInDate is not null then 5
              when qx.ProjectType = 3 and qx.MoveInDate is not null then 6
              when qx.ProjectType = 13 then 7
              else 8 end
		, ex.ExitTo = qx.ExitDest
		, ex.Step = '7.2.3'
from tlsa_Exit ex
inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID

/*
	7.3 Return Time for Exit Cohort Households
*/
	
	update ex
	set ex.ReturnTime = coalesce (
			(select datediff(dd, qx.ExitDate, min(rn.EntryDate))
			from tlsa_hhid qx
			inner join tlsa_HHID rn on rn.HoHID = qx.HoHID 
				and case qx.ExitCohort 
						when -2 then rn.Exit2HHType
						when -1 then rn.Exit1HHType
						else rn.ActiveHHType end 
					= case qx.ExitCohort 
						when -2 then qx.Exit2HHType
						when -1 then qx.Exit1HHType
						else qx.ActiveHHType end 
				and rn.EntryDate between dateadd(dd, 15, qx.ExitDate) and dateadd(dd, 730, qx.ExitDate)
			inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = rn.EnrollmentID 
					and coc.InformationDate = rn.EntryDate 
					and coc.DateDeleted is null
			inner join lsa_Report rpt on coc.CoCCode = rpt.ReportCoC
			where qx.HouseholdID = ex.QualifyingExitHHID
			group by qx.ExitDate)
		, -1)
		, ex.Step = '7.3'
		from tlsa_Exit ex
		
/*
	7.4 Population Identifiers for LSAExit
*/

	update ex
	set HHVet = vet.vet
		, HHDisability = (select max(case when disability.DisabilityStatus = 1 then 1 else 0 end)
			from tlsa_Enrollment disability
			where disability.HouseholdID = hh.HouseholdID)
		, HHFleeingDV = (select max(case when dv.DVStatus = 1 then 1 else 0 end)
			from tlsa_Enrollment dv
			where dv.HouseholdID = hh.HouseholdID)
		, HoHRace =  case 
			when hoh.RaceNone in (8,9) then 98
			when hoh.AmIndAkNative + hoh.Asian + hoh.BlackAfAmerican + 
				hoh.NativeHIOtherPacific + hoh.White > 1 then 6
			when hoh.White = 1 and hoh.Ethnicity = 1 then 1
			when hoh.White = 1 then 0
			when hoh.BlackAfAmerican = 1 then 2
			when hoh.Asian = 1 then 3
			when hoh.AmIndAkNative = 1 then 4
			when hoh.NativeHIOtherPacific = 1 then 5
			else 99 end 
		, HoHEthnicity = case 
			when hoh.Ethnicity in (8,9) then 98
			when hoh.Ethnicity in (0,1) then hoh.Ethnicity
			else 99 end 
		, HHParent = (select max(case when parent.RelationshipToHoH = 2 then 1 else 0 end)
			from tlsa_Enrollment parent
			where parent.HouseholdID = hh.HouseholdID)
		, ex.Step = '7.4.1'
	from tlsa_Exit ex 
	inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID 
	inner join hmis_Client hoh on hoh.PersonalID = ex.HoHID
	inner join (
		select n.HouseholdID, n.PersonalID, n.EnrollmentID, hhid.ExitCohort
			, n.RelationshipToHoH
		from tlsa_Enrollment n
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID) hh on hh.HouseholdID = ex.QualifyingExitHHID and hh.ExitCohort = ex.Cohort
	inner join (select n.HouseholdID, hhid.ExitCohort, max(case when c.VeteranStatus = 1 then 1 else 0 end) as vet
		from tlsa_Enrollment n
		inner join hmis_Client c on c.PersonalID = n.PersonalID
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
		group by n.HouseholdID, hhid.ExitCohort) vet on vet.HouseholdID = ex.QualifyingExitHHID and vet.ExitCohort = ex.Cohort

update ex
set ex.HHAdultAge = case when ages.MaxAge not between 18 and 65 then -1
	when ages.MaxAge = 21 then 18
	when ages.MaxAge = 24 then 24
	when ages.MinAge between 55 and 65 then 55
	else 25 end
	, ex.Step = '7.4.2'
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
		, ex.Step = '7.4.3'
from tlsa_Exit ex

/*
	7.5 System Engagement Status for Exit Cohort Households
*/

	update ex
	set ex.Stat = 
		case when prior.HoHID is null then 1
			when prior.ExitDate >= dateadd(dd, -14, qx.EntryDate) then 5
			when prior.ExitDest between 1 and 6 then 2
			when prior.ExitDest between 7 and 14 then 3
			else 4 end 
		, ex.Step = '7.5'
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
	7.6  Last Inactive Date for Exit Cohorts
*/

--LastInactive = (EntryDate - 1 day) for any household where Stat <> 5
	--  and for any household where Stat = 5 but there is no enrollment for the HoHID/HHType
	--  active in the six days prior to the qualifying exit EntryDate. 
	update ex
	set ex.LastInactive = case 
		when dateadd(dd, -1, hhid.EntryDate) < '9/30/2012' then '9/30/2012' 
		else dateadd(dd, -1, hhid.EntryDate) end
		, ex.Step = '7.6.1'
	from tlsa_Exit ex
	inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID
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

	delete from sys_TimePadded

	insert into sys_TimePadded (HoHID, HHType, Cohort, StartDate, EndDate, Step)
	select distinct ex.HoHID, ex.HHType, ex.Cohort
		, hhid.EntryDate	
		, case when hhid.ExitDate is null 
			or dateadd(dd, 6, hhid.ExitDate) > cd.CohortEnd then cd.CohortEnd 
			else dateadd(dd, 6, hhid.ExitDate) end
		, '7.6.2.a'
	from tlsa_Exit ex
	inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID
	inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
	inner join tlsa_HHID possible on possible.HoHID = ex.HoHID and case ex.Cohort 
				when -2 then possible.Exit2HHType
				when -1 then possible.Exit1HHType
				else possible.ActiveHHType end = ex.HHType 
			and possible.ExitDate <= hhid.ExitDate
	where ex.LastInactive is null 
		and (possible.ProjectType in (2,3,8,13) or possible.TrackingMethod = 0)
	union
	select distinct ex.HoHID, ex.HHType, ex.Cohort
		, bn.DateProvided	
		, case when dateadd(dd, 6, bn.DateProvided) > cd.CohortEnd then cd.CohortEnd
			else dateadd(dd, 6, bn.DateProvided) end
		, '7.6.2.b'
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
		-- 5/14/2020 correct "DateDeleted = 0" to "DateDeleted is null"
		and bn.RecordType = 200 and bn.DateDeleted is null
	where ex.LastInactive is null 
		and possible.TrackingMethod = 3
		
	update ex
	set ex.LastInactive = coalesce(lastDay.inactive, '9/30/2012')
		, ex.Step = '7.6.3'
	from tlsa_Exit ex
	left outer join 
		(select ex.HoHID, ex.HHType, ex.Cohort, max(cal.theDate) as inactive
		  from tlsa_Exit ex
		  inner join tlsa_HHID hhid on hhid.HouseholdID = ex.QualifyingExitHHID
		  inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
		  inner join ref_Calendar cal on cal.theDate <= cd.CohortEnd
			and cal.theDate >= '10/1/2012'
		  left outer join
			 sys_TimePadded stp on stp.HoHID = ex.HoHID and stp.HHType = ex.HHType
			  and stp.Cohort = ex.Cohort
			  and cal.theDate between stp.StartDate and stp.EndDate
		  where stp.HoHID is null
			and cal.theDate < hhid.EntryDate
		group by ex.HoHID, ex.HHType, ex.Cohort
	  ) lastDay on lastDay.HoHID = ex.HoHID and lastDay.HHType = ex.HHType
			and lastDay.Cohort = ex.Cohort
	where ex.LastInactive is null

/*
	7.7 Set System Path for Exit Cohort Households
*/

--SystemPath is n/a for any household housed in PSH as of CohortStart
-- or any household housed for at least a year in RRH/PSH prior to exit
update ex
set ex.SystemPath = -1
	, ex.Step = '7.7.1'
from tlsa_Exit ex
inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
inner join tlsa_CohortDates cd on cd.Cohort = ex.Cohort
where (ex.ExitFrom = 6 and qx.MoveInDate < cd.CohortStart) 
	or (ex.ExitFrom in (5,6) and dateadd(dd, 365, qx.MoveInDate) <= qx.ExitDate)

--  This step is not mandatory and is therefore not defined in the specs -- the same result would be 
--  achieved by skipping it -- but it saves a lot of unnecessary processing in 7.7.3-7.7.5.
-- SystemPath can be set directly based on ExitFrom for
-- -Any first time homeless household (Stat = 1)
-- -Any household returning/re-engaging after 15-730 days (Stat in (2,3,4))
-- and any household whose LastInactive date is the day before the EntryDate for the qualifying exit. 

update ex
set ex.SystemPath = case ex.ExitFrom
	when 2 then 1
	when 3 then 2
	when 4 then 1
	when 5 then 4
	when 6 then 8
	else 8 end
	, ex.Step = '7.7.2'
from tlsa_Exit ex 
inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
where ex.SystemPath is null
	and (ex.Stat in (1,2,3,4) or ex.LastInactive = dateadd(dd, -1, qx.EntryDate))

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
	, ex.Step = '7.7.3'
from tlsa_Exit ex
inner join (select distinct ex.HoHID, ex.HHType, ex.Cohort
			, case when rrh.HoHID is not null then 100 else 0 end
				+ case when th.HoHID is not null then 10 else 0 end
				+ case when es.HoHID is not null then 1 else 0 end
				+ case when psh.HoHID is not null then 1000 else 0 end
					as summary
		from tlsa_Exit ex 
		inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
		left outer join tlsa_HHID es on es.ProjectType in (1,8)
			and es.HoHID = ex.HoHID and es.EntryDate <= qx.ExitDate and es.EntryDate > ex.LastInactive
			and (es.ActiveHHType = ex.HHType)
		left outer join tlsa_HHID th on th.ProjectType = 2
			and th.HoHID = ex.HoHID and th.EntryDate <= qx.ExitDate and th.EntryDate > ex.LastInactive
			and (th.ActiveHHType = ex.HHType)
		left outer join tlsa_HHID rrh on rrh.ProjectType = 13
			and rrh.HoHID = ex.HoHID and rrh.EntryDate <= qx.ExitDate and rrh.EntryDate > ex.LastInactive
			and (rrh.ActiveHHType = ex.HHType)
		left outer join tlsa_HHID psh on psh.ProjectType = 3
			and psh.HoHID = ex.HoHID and psh.EntryDate <= qx.ExitDate and psh.EntryDate > ex.LastInactive
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
	, ex.Step = '7.7.4'
from tlsa_Exit ex
inner join (select distinct ex.HoHID, ex.HHType, ex.Cohort
			, case when rrh.HoHID is not null then 100 else 0 end
				+ case when th.HoHID is not null then 10 else 0 end
				+ case when es.HoHID is not null then 1 else 0 end
				+ case when psh.HoHID is not null then 1000 else 0 end
					as summary
		from tlsa_Exit ex 
		inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
		left outer join tlsa_HHID es on es.ProjectType in (1,8)
			and es.HoHID = ex.HoHID and es.EntryDate <= qx.ExitDate and es.EntryDate > ex.LastInactive
			and (es.Exit1HHType = ex.HHType)
		left outer join tlsa_HHID th on th.ProjectType = 2
			and th.HoHID = ex.HoHID and th.EntryDate <= qx.ExitDate and th.EntryDate > ex.LastInactive
			and (th.Exit1HHType = ex.HHType)
		left outer join tlsa_HHID rrh on rrh.ProjectType = 13
			and rrh.HoHID = ex.HoHID and rrh.EntryDate <= qx.ExitDate and rrh.EntryDate > ex.LastInactive
			and (rrh.Exit1HHType = ex.HHType)
		left outer join tlsa_HHID psh on psh.ProjectType = 3
			and psh.HoHID = ex.HoHID and psh.EntryDate <= qx.ExitDate and psh.EntryDate > ex.LastInactive
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
	, ex.Step = '7.7.5'
from tlsa_Exit ex
inner join (select distinct ex.HoHID, ex.HHType, ex.Cohort
			, case when rrh.HoHID is not null then 100 else 0 end
				+ case when th.HoHID is not null then 10 else 0 end
				+ case when es.HoHID is not null then 1 else 0 end
				+ case when psh.HoHID is not null then 1000 else 0 end
					as summary
		from tlsa_Exit ex 
		inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID
		left outer join tlsa_HHID es on es.ProjectType in (1,8)
			and es.HoHID = ex.HoHID and es.EntryDate <= qx.ExitDate and es.EntryDate > ex.LastInactive
			and (es.Exit2HHType = ex.HHType)
		left outer join tlsa_HHID th on th.ProjectType = 2
			and th.HoHID = ex.HoHID and th.EntryDate <= qx.ExitDate and th.EntryDate > ex.LastInactive
			and (th.Exit2HHType = ex.HHType)
		left outer join tlsa_HHID rrh on rrh.ProjectType = 13
			and rrh.HoHID = ex.HoHID and rrh.EntryDate <= qx.ExitDate and rrh.EntryDate > ex.LastInactive
			and (rrh.Exit2HHType = ex.HHType)
		left outer join tlsa_HHID psh on psh.ProjectType = 3
			and psh.HoHID = ex.HoHID and psh.EntryDate <= qx.ExitDate and psh.EntryDate > ex.LastInactive
			and (psh.Exit2HHType = ex.HHType)
		) ptype on ptype.HoHID = ex.HoHID and ptype.HHType = ex.HHType 
		and ptype.Cohort = ex.Cohort
where ex.Cohort = -2 and ex.SystemPath is null

/*
	7.8 Select Data for Export to LSAExit
*/

delete from lsa_Exit
insert into lsa_Exit (RowTotal
	, Cohort, Stat, ExitFrom, ExitTo, ReturnTime, HHType
	, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
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
	, HHType, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
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
	, HHType, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
	, HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID
