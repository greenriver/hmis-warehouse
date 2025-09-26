/*
LSA Sample Code
05_01 to 05_11 LSAPerson Records and Demographics.sql  
https://github.com/HMIS/LSASampleCode

Last update: 8/21/2025

Source: LSA Programming Specifications v7
Relevant Sections:
	5.1.	Identify Active and Active in Residence (AIR) HouseholdIDs
			v7 Updates
			- 'AIR' (active in residence) has replaced 'AHAR' in all relevant column names (Step 5.1.2)
			- There must be a bednight in report period to set AIR = 1 for NBN shelters
	5.2.	Identify Active and Active in Residence (AIR) Enrollments
			v7 Updates
			- 'AIR' (active in residence) has replaced 'AHAR' in all relevant column names (Step 5.2.2)
			- There must be a bednight in report period to set AIR = 1 for NBN shelters
	5.3.	Get Active Clients for LSAPerson
			v7 Update
			- Limit tlsa_Person to people active in residence when LSAScope = 3 (Step 5.3/5.4)
	5.4.	LSAPerson Demographics
			v7 Update
			- Delete logic associated with Gender  (Step 5.3/5.4)
			- HMIS Client.csv column name change from Latinaeo to Latinao
	5.5.	Time Spent in ES/SH or on the Street – LSAPerson
	5.6.	Enrollments Relevant to Counting ES/SH/Street Dates
	5.7.	Get Dates to Exclude from Counts of ES/SH/Street Days (ch_Exclude)
	5.8.	Get Dates to Include in Counts of ES/SH/Street Days (ch_Include)
	5.9.	Get ES/SH/Street Episodes (ch_Episodes)
	5.10.	CHTime and CHTimeStatus – LSAPerson
	5.11.	EST/RRH/PSH/RRHSOAgeMin and EST/RRH/PSH/RRHSOAgeMax – LSAPerson



	5.1 Identify Active and Active-in-Residence HouseholdIDs
*/

	update hhid
	set hhid.Active = 1 
		, hhid.Step = '5.1.1'
	from tlsa_HHID HHID
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join lsa_Project p on p.ProjectID = hhid.ProjectID
	where (hhid.ExitDate is null or hhid.ExitDate >= rpt.ReportStart) 

	update hhid
	set hhid.AIR = 1 
		, hhid.Step = '5.1.2'
	from tlsa_HHID hhid
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	where (hhid.ExitDate is null or hhid.ExitDate > rpt.ReportStart) 
		and (hhid.LSAProjectType in (0, 2, 8)
			or (hhid.LSAProjectType = 1 and hhid.LastBedNight between rpt.ReportStart and rpt.ReportEnd)
			or (hhid.LSAProjectType in (3,13) and hhid.MoveInDate is not null)
		)
		
/*
	5.2  Identify Active and Active-in-Residence Enrollments
*/

	update n
	set n.Active = 1
		, n.Step = '5.2.1'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID and hhid.Active = 1
	where n.ExitDate is null or n.ExitDate >= rpt.ReportStart


	update n
	set n.AIR = 1
		, n.Step = '5.2.2'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID and hhid.AIR = 1
	where (n.ExitDate is null or n.ExitDate > rpt.ReportStart)
		and (n.LSAProjectType in (0, 2, 8)
			or (n.LSAProjectType = 1 and n.LastBedNight between rpt.ReportStart and rpt.ReportEnd)
			or (n.LSAProjectType in (3,13) and n.MoveInDate is not null)
		)
	
/*
	5.3 Get Active Clients for LSAPerson 
	5.4 LSAPerson Demographics 
*/
	truncate table tlsa_Person

	insert into tlsa_Person (PersonalID, HoHAdult, 
		VetStatus, DisabilityStatus, DVStatus, RaceEthnicity
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
			when c.RaceNone in (8,9) then 98
			when c.RaceNone = 99 then 99
			when (c.AmIndAkNative = 1 
					or c.Asian = 1
					or c.BlackAfAmerican = 1
					or c.NativeHIPacific = 1
					or c.White = 1
					or c.HispanicLatinao = 1
					or c.MidEastNAfrican = 1) then 
						(select cast (
							(case when r.AmIndAKNative = 1 then '1' else '' end
							+ case when r.Asian = 1 then '2' else '' end
							+ case when r.BlackAfAmerican = 1 then '3' else '' end
							+ case when r.NativeHIPacific = 1 then '4' else '' end
							+ case when r.White = 1 then '5' else '' end
							+ case when r.HispanicLatinao = 1 then '6' else '' end
							+ case when r.MidEastNAfrican = 1 then '7' else '' end) as int)
						from hmis_Client r
						where r.PersonalID = c.PersonalID)
			else 99 end 
		, rpt.ReportID
		, '5.3/5.4'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd 
		and (n.AIR = 1 or (n.Active = 1 and rpt.LSAScope <> 3))
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
		from lsa_Report rpt
		inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
		where (n.AIR = 1 or (n.Active = 1 and rpt.LSAScope <> 3))
		group by n.PersonalID) HoHAdult on HoHAdult.PersonalID = n.PersonalID
	inner join hmis_Client c on c.PersonalID = n.PersonalID
	left outer join 
		(select n.PersonalID, max(n.DisabilityStatus) as stat
		from lsa_Report rpt
		inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
		where (n.AIR = 1 or (n.Active = 1 and rpt.LSAScope <> 3))
		group by n.PersonalID) Disability on Disability.PersonalID = n.PersonalID
	left outer join 
		(select n.PersonalID, min(n.DVStatus) as stat
		from lsa_Report rpt
		inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
		where (n.AIR = 1 or (n.Active = 1 and rpt.LSAScope <> 3))
		group by n.PersonalID) DV on DV.PersonalID = n.PersonalID	

	update lp
	set lp.HIV = case when n.PersonalID is not null then 1
		when chk.PersonalID is not null then 0
		else -1 end
	from tlsa_Person lp
	left outer join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.AIR = 1 and n.ActiveAge between 18 and 65 and n.HIV = 1
	left outer join (select distinct n.PersonalID from tlsa_Enrollment n where n.AIR = 1 and n.ActiveAge between 18 and 65) chk on chk.PersonalID = lp.PersonalID

	update lp
	set lp.SMI = case when n.PersonalID is not null then 1
		when chk.PersonalID is not null then 0
		else -1 end
	from tlsa_Person lp
	left outer join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.AIR = 1 and n.ActiveAge between 18 and 65 and n.SMI = 1
	left outer join (select distinct n.PersonalID from tlsa_Enrollment n where n.AIR = 1 and n.ActiveAge between 18 and 65) chk on chk.PersonalID = lp.PersonalID

	update lp
	set lp.SUD = case when n.PersonalID is not null then 1
		when chk.PersonalID is not null then 0
		else -1 end
	from tlsa_Person lp
	left outer join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.AIR = 1 and n.ActiveAge between 18 and 65 and n.SUD = 1
	left outer join (select distinct n.PersonalID from tlsa_Enrollment n where n.AIR = 1 and n.ActiveAge between 18 and 65) chk on chk.PersonalID = lp.PersonalID

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


