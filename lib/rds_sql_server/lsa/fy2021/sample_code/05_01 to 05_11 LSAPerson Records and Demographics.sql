/*
LSA FY2021 Sample Code

Name:  05_01 to 05_11 LSAPerson.sql
Date:  09 SEP 2021

	5.1 Identify Active and AHAR HouseholdIDs
*/

	update hhid
	set hhid.Active = 1
		, hhid.Step = '5.1.1'
	from tlsa_HHID HHID
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join lsa_Project p on p.ProjectID = hhid.ProjectID
	where (hhid.ExitDate is null or hhid.ExitDate >= rpt.ReportStart)
		and (select top 1 coc.CoCCode
			from hmis_EnrollmentCoC coc
			where coc.EnrollmentID = hhid.EnrollmentID
				and coc.InformationDate <= rpt.ReportEnd
				and coc.DateDeleted is null
			order by coc.InformationDate desc) = rpt.ReportCoC

	update hhid
	set hhid.AHAR = 1
		, hhid.Step = '5.1.2'
	from tlsa_HHID HHID
	where hhid.Active = 1
		and (hhid.ExitDate is null or hhid.ExitDate > (select ReportStart from lsa_Report))
		and hhid.LSAProjectType not in (3,13)

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
	where n.Active = 1
		and (n.ExitDate is null or n.ExitDate > rpt.ReportStart)
		and n.LSAProjectType not in (3,13)

	update n
	set n.AHAR = 1
		, n.Step = '5.2.3'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	where n.Active = 1
		and n.MoveInDate is not null
		and (n.ExitDate is null or n.ExitDate > (select ReportStart from lsa_Report))
		and n.LSAProjectType in (3,13)
/*
	5.3 Get Active Clients for LSAPerson
	5.4 LSAPerson Demographics
*/
	delete from tlsa_Person

	insert into tlsa_Person (PersonalID, HoHAdult,
		Ethnicity, VetStatus, DisabilityStatus, DVStatus, Gender, Race, ReportID, Step)
	select distinct n.PersonalID
		, HoHAdult.stat
		, case
			when HoHAdult.stat = 0 then -1
			when c.Ethnicity in (8,9) then 98
			when c.Ethnicity in (0,1) then c.Ethnicity
			else 99 end
		, case
			when HoHAdult.stat not in (1,3) then -1
			when c.VeteranStatus in (8,9) then 98
			when c.VeteranStatus in (0,1) then c.VeteranStatus
			else 99 end
		, case
			when HoHAdult.stat = 0 then -1
			when Disability.stat is null then 99
			else Disability.stat end
		, case
			when HoHAdult.stat = 0 then -1
			when DV.stat = 10 then 0
			when DV.stat is null then 99
			else DV.stat end
		, case
			when HoHAdult.stat = 0 then -1
			when c.GenderNone in (8,9) then 98
			when c.Questioning = 1 then 5
			-- when c.NoSingleGender = 1 then 4
			when c.Female = 1 and c.Male = 1 then 4
			when c.Transgender = 1 then 3
			when c.Female = 1 then 1
			when c.Male = 1 then 2
			else 99 end
		, case
			when HoHAdult.stat = 0 then -1
			when c.RaceNone in (8,9) then 98
			when c.RaceNone = 99 then 99
			when (c.AmIndAkNative = 1
					or c.Asian = 1
					or c.BlackAfAmerican = 1
					or c.NativeHIOtherPacific = 1
					or c.White = 1) then
						(select cast (
							(case when r.AmIndAKNative = 1 then '1' else '' end
							+ case when r.Asian = 1 then '2' else '' end
							+ case when r.BlackAfAmerican = 1 then '3' else '' end
							+ case when r.NativeHIOtherPacific = 1 then '4' else '' end
							+ case when r.White = 1 then '5' else '' end) as int)
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

	--The start of the period is:  LastActive minus (3 years) plus (1 day)
	update lp
	set lp.CHStart = dateadd(dd, 1, (dateadd(yyyy, -3, lp.LastActive)))
		, lp.Step = '5.5.2'
	from tlsa_Person lp
	where HoHAdult > 0

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

	-- ch_Exclude identifies dates between CHStart and LastActive when client was enrolled in TH
	-- or housed in RRH/PSH.
	delete from ch_Exclude

	insert into ch_Exclude (PersonalID, excludeDate, Step)
	select distinct lp.PersonalID, cal.theDate, '5.7'
	from tlsa_Person lp
	inner join tlsa_Enrollment chn on chn.PersonalID = lp.PersonalID and chn.CH = 1
	inner join ref_Calendar cal on cal.theDate >=
			case when chn.LSAProjectType in (3,13) then chn.MoveInDate
				else chn.EntryDate end
		and (cal.theDate < chn.ExitDate
			or chn.ExitDate is null)
			and cal.theDate between lp.CHStart and lp.LastActive
	where chn.LSAProjectType in (2,3,13)

/*
	5.8 Get Dates to Include in Counts of ES/SH/Street Days
*/
	--ch_Include identifies dates on which a client was in ES/SH or on the street
	-- (excluding any dates in ch_Exclude) based on:
	--	 HMIS entry/exit dates for enrollments in those project types
	--   Responses to DE 3.917 when EntryDate > CHStart
	--   Bed nights in nbn ES
	delete from ch_Include

	--Dates enrolled in ES entry/exit or SH
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

	--ES nbn bed nights
	insert into ch_Include (PersonalID, ESSHStreetDate, Step)
	select distinct lp.PersonalID, cal.theDate, '5.8.2'
	from tlsa_Person lp
		inner join tlsa_Enrollment chn on chn.PersonalID = lp.PersonalID and chn.CH = 1
		inner join tlsa_HHID hhid on hhid.HouseholdID = chn.HouseholdID
		inner join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
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

	--ES/SH/Street dates from 3.917 DateToStreetESSH when EntryDates > CHStart.

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
		and (hn.LivingSituation in (1,18,16)
			or (chn.LSAProjectType not in (1,8) and hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
			or (chn.LSAProjectType not in (1,8) and hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
					and hn.LivingSituation in (4,5,6,7,15,25))
			)
		and (

			(-- for ES/SH/TH, count dates prior to EntryDate
				chn.LSAProjectType in (0,1,2,8) and cal.theDate < chn.EntryDate)
			or (-- for PSH/RRH, dates prior to and after EntryDate are counted for
				-- as long as the client remains homeless in the project
				chn.LSAProjectType in (3,13)
				and (cal.theDate < chn.MoveInDate
					 or (chn.MoveInDate is NULL and cal.theDate < chn.ExitDate)
					 or (chn.MoveInDate is NULL and chn.ExitDate is NULL and cal.theDate <= lp.LastActive)
					)
				)
			)

	--Gaps of less than 7 nights between two ESSHStreet dates are counted
	insert into ch_Include (PersonalID, ESSHStreetDate, Step)
	select gap.PersonalID, cal.theDate, '5.8.4'
	from (select distinct s.PersonalID, s.ESSHStreetDate as StartDate, min(e.ESSHStreetDate) as EndDate
			from ch_Include s
				inner join ch_Include e on e.PersonalID = s.PersonalID and e.ESSHStreetDate > s.ESSHStreetDate
					and dateadd(dd, -7, e.ESSHStreetDate) <= s.ESSHStreetDate
			where s.PersonalID not in
				(select PersonalID
				from ch_Include
				where ESSHStreetDate = dateadd(dd, 1, s.ESSHStreetDate))
			group by s.PersonalID, s.ESSHStreetDate) gap
		inner join ref_Calendar cal on cal.theDate between gap.StartDate and gap.EndDate
		left outer join ch_Include chi on chi.PersonalID = gap.PersonalID
			and chi.ESSHStreetDate = cal.theDate
	where chi.ESSHStreetDate is null

/*
	5.9 Get ES/SH/Street Episodes
*/
	delete from ch_Episodes

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
				or (hn.LivingSituation in (8,9,99) or hn.LivingSituation is null)
				or (hn.LengthOfStay in (8,9,99) or hn.LengthOfStay is null)
				or (chn.LSAProjectType not in (0,1,8) and hn.LivingSituation in (4,5,6,7,15,25)
						and hn.LengthOfStay in (2,3)
						and (hn.PreviousStreetESSH is null or hn.PreviousStreetESSH not in (0,1)))
				or (chn.LSAProjectType not in (0,1,8) and hn.LengthOfStay in (10,11)
							and (hn.PreviousStreetESSH is null or hn.PreviousStreetESSH not in (0,1)))
				or ((chn.LSAProjectType in (0,1,8)
					  or hn.LivingSituation in (1,16,18)
					  or (chn.LSAProjectType not in (0,1,8) and hn.LivingSituation in (4,5,6,7,15,25)
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
	5.11 EST/RRH/PSH AgeMin and AgeMax - LSAPerson
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
