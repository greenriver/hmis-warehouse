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
		, ex.Step = '7.2.3'
from tlsa_Exit ex
inner join tlsa_HHID qx on qx.HouseholdID = ex.QualifyingExitHHID

/*
	7.3 Return Time for Exit Cohort Households
*/
	
	update ex
	set ex.ReturnTime = coalesce (
			(select datediff(dd, qx.ExitDate, min(rn.EntryDate))
			from tlsa_HHID qx
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
			inner join hmis_Enrollment coc on coc.EnrollmentID = rn.EnrollmentID 
			inner join lsa_Report rpt on coc.EnrollmentCoC = rpt.ReportCoC
			where qx.HouseholdID = ex.QualifyingExitHHID
			group by qx.ExitDate)
		, -1)
		, ex.Step = '7.3'
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

	insert into ch_Episodes_exit (PersonalID, episodeStart, episodeEnd, Step)
	select distinct s.PersonalID, s.ESSHStreetDate, min(e.ESSHStreetDate), '7.7.1'
	from ch_Include_exit s 
	inner join ch_Include_exit e on e.PersonalID = s.PersonalID  and e.ESSHStreetDate >= s.ESSHStreetDate
	--any date in ch_Include_exit without a record for the day before is the start of an episode
	where s.PersonalID not in (select PersonalID from ch_Include_exit where ESSHStreetDate = dateadd(dd, -1, s.ESSHStreetDate))
	--any date in ch_Include_exit without a record for the day after is the end of an episode
		and e.PersonalID not in (select PersonalID from ch_Include_exit where ESSHStreetDate = dateadd(dd, 1, e.ESSHStreetDate))
	group by s.PersonalID, s.ESSHStreetDate

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
		, HHFleeingDV = coalesce((select min(
				case when dv.DVStatus = 1 then 1
					else 2 end)
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
	set ex.HHAdultAge = case when ages.MaxAge not between 18 and 65 then -1
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