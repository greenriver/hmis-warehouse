/*
LSA FY2019 Sample Code

Name:  5_1 to 5_19 LSAPerson.sql  
Date:  4/7/2020   
	   5/14/2020 - Section 5.10 - removed extraneous update statements 
	   5/21/2020 - Sections 5.1-5.18 - add set of Step column to all insert and update statements
	   6/4/2020  - 5.8.1-5.9.1 - change ch_Include.chDate column name to ESSHStreetDate per specs
				   5.8.3 - correct WHERE criteria / use all DateToStreetESSH records dated after CHStart 
						   instead of just the earliest one
				   5.9.3 -> 5.10.1 - change UPDATE statement for CHTime/CHTimeStatus for non-HoH children 
						   from 5.9.3 to 5.10.1 and renumber other 5.10 statements accordingly.
				   5.10.2 and 5.10.4 - use 1 year instead of x days in DATEADD functions for consistency with specs.
				   5.15.1 - use AHAREST instead of HHTypeEST in case statement setting AdultEST.
				   5.16.3 - use HoHPSH instead of HoHAdult in case statement setting AHARHoHPSH.
		6/11/2020 - 5.10.5 - add parentheses in 2 places to isolate 'or' conditions
					5.14.2, 5.15.2, and 5.16.2 - update to include people in households whose ExitDate 
						and MoveInDate are on ReportStart for AHARRRH, AdultRRH, AHARHoHRRH.
		6/18/2020 - 5.17.2 - correct step number (was 5.17.1)
					5.18.8 - correct to set values for AC3PlusEST/RRH/PSH to 0 or 1 (was -1 or 1)
		7/2/2020 -  5.14.2, 5.15.2, 5.16.2 -- add requirement that MoveInDate is not null in order to count
						RRH households for AHAR
				 -  5.15.1-5.15.3 - remove extraneous check for CO HHType when setting AHAR Adult identifiers
		7/30/2020 - 5.8.3 - correct join criteria for tlsa_Enrollment chn to include CH = 1
					5.8.3 and 5.8.4 - correct join criteria to ref_Calendar to use tlsa_Enrollment.EntryDate vs hmis_Enrollment
					5.8.4 - correct criteria to include LastActive in ESSHStreetDates (was excluding)
		8/11/2020 - 5.8.3-4 - rewrite to correspond more closely to the way the business logic is expressed in the specs.
						All dates are inserted in 5.8.3; 5.8.4 has been deleted.
		8/13/2020 - 5.7 - Exclude RRH ExitDates from count of ESSHStreetDates if MoveInDate = ExitDate (GitHub #436)
		8/27/2020 - 5.8.3 - Add 'or ProjectType in (1,8)' to WHERE clause 
		9/3/2020 - 5.10.4 and 5.10.5 - use tlsa_Enrollment.EntryDate vs hmis_Enrollment.EntryDate
				 - 5.8.3 - remove 'or ProjectType in (1,8)' added to the WHERE clause on 8/27 (regardless of project type 
						- and consistent with the specs - we are not counting ES/SH/Street dates prior to project entry  
						if LivingSituation indicates that the client was not in ES/SH or on the street)
				
	5.1 Get Active HMIS HouseholdIDs
*/

	update hhid
	set hhid.Active = 1 
		, hhid.Step = '5.1'
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

/*
	5.2  Get Active Enrollments
*/

	update n
	set n.Active = 1
		, n.Step = '5.2'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID and hhid.Active = 1
	where n.ExitDate is null or n.ExitDate >= rpt.ReportStart

/*
	5.3 Get Active Clients for tlsa_Person 
	5.4 LSAPerson Demographics 
		(Gender, Race, Ethnicity, VetStatus, DisabilityStatus, and DVStatus)
*/
	delete from tlsa_Person

	insert into tlsa_Person (PersonalID, HoHAdult, 
		Gender, Ethnicity, Race, VetStatus, DisabilityStatus, DVStatus, ReportID, Step)
	select distinct n.PersonalID
		, HoHAdult.stat
	, case 
			when HoHAdult.stat = 0 then -1 
			when c.Gender in (8,9) then 98
			when c.Gender in (0,1,2) then c.Gender + 1
			when c.Gender in (3,4) then c.Gender
			else 99 end 
		, case 
			when HoHAdult.stat = 0 then -1 
			when c.Ethnicity in (8,9) then 98
			when c.Ethnicity in (0,1) then c.Ethnicity
			else 99 end 	
		, case 
			when HoHAdult.stat = 0 then -1 
			when c.RaceNone in (8,9) then 98
			when c.AmIndAkNative + c.Asian + c.BlackAfAmerican + 
				c.NativeHIOtherPacific + c.White > 1 then 6
			when c.White = 1 and c.Ethnicity = 1 then 1
			when White = 1 then 0
			when c.BlackAfAmerican = 1 then 2
			when c.Asian = 1 then 3
			when c.AmIndAkNative = 1 then 4
			when c.NativeHIOtherPacific = 1 then 5
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
		, rpt.ReportID
		, '5.3-5.4'
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
				(hhid.LastBedNight is null or hhid.LastBedNight = rpt.ReportEnd) then rpt.ReportEnd 
			when hhid.LastBednight is not null then dateadd(dd, 1, hhid.LastBednight)
			else n.ExitDate end) 
		from lsa_Report rpt
		inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd and n.Active = 1
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
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
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
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
			case when chn.ProjectType in (3,13) then chn.MoveInDate  
				else chn.EntryDate end
		and ((cal.theDate < chn.ExitDate 
			or (chn.ProjectType = 13 and chn.MoveInDate = chn.ExitDate and cal.theDate = chn.MoveInDate)
			or chn.ExitDate is null))
			and cal.theDate between lp.CHStart and lp.LastActive
	where chn.ProjectType in (2,3,13)

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
	where (chn.ProjectType = 8 or (chn.ProjectType = 1 and chn.TrackingMethod = 0))
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
	where chn.ProjectType = 1 and chn.TrackingMethod = 3 and chx.excludeDate is null
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
			or (chn.ProjectType not in (1,8) and hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
			or (chn.ProjectType not in (1,8) and hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
					and hn.LivingSituation in (4,5,6,7,15,25)) 
			)
		and ( 
			
			(-- for ES/SH/TH, count dates prior to EntryDate
				chn.ProjectType in (1,2,8) and cal.theDate < chn.EntryDate)
			or (-- for PSH/RRH, dates prior to and after EntryDate are counted for 
				-- as long as the client remains homeless in the project  
				chn.ProjectType in (3,13)
				and (cal.theDate < chn.MoveInDate
					 or (chn.MoveInDate is NULL and cal.theDate < chn.ExitDate)
					 or (chn.MoveInDate is NULL and chn.ExitDate is NULL and cal.theDate <= lp.LastActive)
					)
				)
			)						

	--Gaps of less than 7 nights between two ESSHStreet dates are counted
	insert into ch_Include (PersonalID, ESSHStreetDate, Step)
	select gap.PersonalID, cal.theDate, '5.8.5'
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
				or (chn.ProjectType not in (1,8) and hn.LivingSituation in (4,5,6,7,15,25) 
						and hn.LengthOfStay in (2,3)
						and (hn.PreviousStreetESSH is null or hn.PreviousStreetESSH not in (0,1)))
				or (chn.ProjectType not in (1,8) and hn.LengthOfStay in (10,11) 
							and (hn.PreviousStreetESSH is null or hn.PreviousStreetESSH not in (0,1)))
				or ((chn.ProjectType in (1,8)
					  or hn.LivingSituation in (1,16,18)
					  or (chn.ProjectType not in (1,8) and hn.LivingSituation in (4,5,6,7,15,25) 
							and hn.LengthOfStay in (2,3)
							and hn.PreviousStreetESSH = 1)
					  or (chn.ProjectType not in (1,8) and hn.LengthOfStay in (10,11) 
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
		 where n.PersonalID = lp.PersonalID and n.ProjectType in (1,2,8) and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.1'
	from tlsa_Person lp

	update lp 
	set ESTAgeMax = coalesce(
		(select max(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.ProjectType in (1,2,8) and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.2'
	from tlsa_Person lp

	update lp 
	set RRHAgeMin = coalesce(
		(select min(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.ProjectType = 13 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.3'
	from tlsa_Person lp

	update lp 
	set RRHAgeMax = coalesce(
		(select max(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.ProjectType = 13 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.4'
	from tlsa_Person lp

	update lp 
	set PSHAgeMin = coalesce(
		(select min(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.ProjectType = 3 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.5'
	from tlsa_Person lp

	update lp 
	set PSHAgeMax = coalesce(
		(select max(n.ActiveAge) 
		 from tlsa_Enrollment n
		 where n.PersonalID = lp.PersonalID and n.ProjectType = 3 and n.Active = 1)
		 , -1)
		, lp.Step = '5.11.6'
	from tlsa_Person lp


/*
	5.12 Set tlsa_Person Project Group Identifiers by Household Type
*/
	update tlsa_Person 
	set HHTypeEST = null, HHTypeRRH = null, HHTypePSH = null

	--set EST HHType 
	update lp
	set lp.HHTypeEST = 
		case when hh.HHTypeCombined is null then -1
		else hh.HHTypeCombined end	
		, lp.Step = '5.12.1'
	from tlsa_Person lp
		left outer join --Level 2 - combine HHTypes into a single value
		 (select HHTypes.PersonalID
			, cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				as HHTypeCombined
			from --Level 1 - get distinct HHTypes for EST
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.ProjectType in (1,2,8) and n.Active = 1) HHTypes  
			group by HHTypes.PersonalID
			) hh on hh.PersonalID = lp.PersonalID

	--set RRH HHType 
	update lp
	set lp.HHTypeRRH = 
		case when hh.HHTypeCombined is null then -1
		else hh.HHTypeCombined end	
		, lp.Step = '5.12.2'
	from tlsa_Person lp
		left outer join --Level 2 - combine HHTypes into a single value
		 (select HHTypes.PersonalID
			, cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				as HHTypeCombined
			from --Level 1 - get distinct HHTypes for EST
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.ProjectType = 13 and n.Active = 1) HHTypes  
			group by HHTypes.PersonalID
			) hh on hh.PersonalID = lp.PersonalID

	--set PSH HHType 
	update lp
	set lp.HHTypePSH = 
		case when hh.HHTypeCombined is null then -1
		else hh.HHTypeCombined end	
		, lp.Step = '5.12.3'
	from tlsa_Person lp
		left outer join --Level 2 - combine HHTypes into a single value
		 (select HHTypes.PersonalID
			, cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				as HHTypeCombined
			from --Level 1 - get distinct HHTypes for EST
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.ProjectType = 3 and n.Active = 1) HHTypes  
			group by HHTypes.PersonalID
			) hh on hh.PersonalID = lp.PersonalID

/*
	5.13 Set tlsa_Person Head of Household Identifiers by HHType for Each Project Group 
*/

	--set EST HoH identifiers 
	update lp
	set lp.HoHEST = 
		case when lp.HoHAdult not in (2,3) or lp.HHTypeEST = -1 then -1
		else isnull
			(
				(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.Active = 1 and n.ProjectType in (1,2,8) and n.RelationshipToHoH = 1) HHTypes  
				where HHTypes.PersonalID = lp.PersonalID)
			, -1) end	
		, lp.Step = '5.13.1'
	from tlsa_Person lp

	--set RRH HoH identifiers 
	update lp
	set lp.HoHRRH = 
		case when lp.HoHAdult not in (2,3) or lp.HHTypeRRH = -1 then -1
		else isnull
			(
				(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.Active = 1 and n.ProjectType = 13 and n.RelationshipToHoH = 1) HHTypes  
				where HHTypes.PersonalID = lp.PersonalID)
			, -1) end	
		, lp.Step = '5.13.2'
	from tlsa_Person lp

	--set PSH HoH identifiers 
	update lp
	set lp.HoHPSH = 
		case when lp.HoHAdult not in (2,3) or lp.HHTypePSH = -1 then -1
		else isnull
			(
				(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.Active = 1 and n.ProjectType = 3 and n.RelationshipToHoH = 1) HHTypes  
				where HHTypes.PersonalID = lp.PersonalID)
			, -1) end	
		, lp.Step = '5.13.3'
	from tlsa_Person lp

/*
	5.14 Set tlsa_Person AHAR Identifiers by HHType for each Project Group
*/

	--set EST AHAR HHType 
	update lp
	set lp.AHAREST = 
		case when lp.HHTypeEST = -1 then -1
			else isnull
				(
					(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.Active = 1 and n.ProjectType in (1,2,8)
							and (n.ExitDate is null or n.ExitDate > (select ReportStart from lsa_Report))) HHTypes  
					where HHTypes.PersonalID = lp.PersonalID)
				, -1) end	
		, lp.Step = '5.14.1'
	from tlsa_Person lp
	
	--set RRH HHType 
	update lp
	set lp.AHARRRH = 
		case when lp.HHTypeRRH = -1 then -1
			else isnull
				(
					(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join lsa_Report rpt on n.Active = 1
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.ProjectType = 13
							and n.MoveInDate is not null
							and 
							(n.ExitDate is null 
							 or n.ExitDate > rpt.ReportStart
							 or (n.MoveInDate = n.ExitDate and n.MoveInDate = rpt.ReportStart))) HHTypes  
					where HHTypes.PersonalID = lp.PersonalID)
				, -1) end		
		, lp.Step = '5.14.2'
	from tlsa_Person lp

	--set PSH HHType 
	update lp
	set lp.AHARPSH = 
		case when lp.HHTypePSH = -1 then -1
			else isnull
				(
					(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.Active = 1 and n.ProjectType = 3 and n.MoveInDate is not null 
							and (n.ExitDate is null or n.ExitDate > (select ReportStart from lsa_Report))) HHTypes  
					where HHTypes.PersonalID = lp.PersonalID)
				, -1) end	
		, lp.Step = '5.14.3'
	from tlsa_Person lp

/*
	5.15 Set tlsa_Person AHAR Adult Identifiers by HHType for each Project Group
*/

	--set AdultEST
	update lp
	set lp.AdultEST = 
		case when lp.HoHAdult not in (1,3) or lp.AHAREST = -1 then -1
			else isnull
				(
					(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.Active = 1 and n.ProjectType in (1,2,8) and n.ActiveAge between 18 and 65
							and (n.ExitDate is null or n.ExitDate > (select ReportStart from lsa_Report))) HHTypes  
					where HHTypes.PersonalID = lp.PersonalID)
				, -1) end	
		, lp.Step = '5.15.1'
	from tlsa_Person lp

	--set AdultRRH 
	update lp
	set lp.AdultRRH = 
		case when lp.HoHAdult not in (1,3) or lp.AHARRRH = -1 then -1
			else isnull
				(
					(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join lsa_Report rpt on n.Active = 1
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.ProjectType = 13
							and n.MoveInDate is not null
							and n.ActiveAge between 18 and 65
							and 
							(n.ExitDate is null 
							 or n.ExitDate > rpt.ReportStart
							 or (n.MoveInDate = n.ExitDate and n.MoveInDate = rpt.ReportStart
							 ))) HHTypes  
					where HHTypes.PersonalID = lp.PersonalID)
				, -1) end	
		, lp.Step = '5.15.2'
	from tlsa_Person lp

	--set AdultPSH 
	update lp
	set lp.AdultPSH = 
		case when lp.HoHAdult not in (1,3) or lp.AHARPSH = -1 then -1
			else isnull
				(
					(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.Active = 1 and n.ProjectType = 3 and n.MoveInDate is not null 
							and (n.ExitDate is null or n.ExitDate > (select ReportStart from lsa_Report))
							and n.ActiveAge between 18 and 65) HHTypes  
					where HHTypes.PersonalID = lp.PersonalID)
				, -1) end	
		, lp.Step = '5.15.3'
	from tlsa_Person lp

/*
	5.16 Set tlsa_Person AHAR Head of Household Identifiers by HHType for each Project Group
*/

	update lp
	set lp.AHARHoHEST = 
		case when lp.HoHEST = -1 or lp.AHAREST = -1 then -1
			else isnull
				(
					(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.Active = 1 and n.ProjectType in (1,2,8) and n.RelationshipToHoH = 1
							and (n.ExitDate is null or n.ExitDate > (select ReportStart from lsa_Report))) HHTypes  
				where HHTypes.PersonalID = lp.PersonalID)
				, -1) end	
		, lp.Step = '5.16.1'
	from tlsa_Person lp
	
	--set RRH HHType 
	update lp
	set lp.AHARHoHRRH = 
		case when lp.HoHRRH = -1 or lp.AHARRRH = -1 then -1
			else isnull
				(
					(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join lsa_Report rpt on n.Active = 1
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.ProjectType = 13
							and n.RelationshipToHoH = 1
							and n.MoveInDate is not null
							and 
							(n.ExitDate is null 
							 or n.ExitDate > rpt.ReportStart
							 or (n.MoveInDate = n.ExitDate and n.MoveInDate = rpt.ReportStart
							 ))) HHTypes  
					where HHTypes.PersonalID = lp.PersonalID)
				, -1) end	
		, lp.Step = '5.16.2'
	from tlsa_Person lp

	--set PSH HHType 
	update lp
	set lp.AHARHoHPSH = 
		case when lp.HoHPSH = -1 or lp.AHARPSH = -1 then -1
			else isnull
				(
					(select cast(replace(cast(sum(HHTypes.HHTypeEach) as nvarchar), '0', '') as int)
				 from 
					 (select distinct n.PersonalID
						, case when hhid.ActiveHHType = 1 then 1000
							when hhid.ActiveHHType = 2 then 200
							when hhid.ActiveHHType = 3 then 30
							else 9 end as HHTypeEach
						from tlsa_Enrollment n
						inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
						where n.Active = 1 and n.ProjectType = 3 and n.MoveInDate is not null 
							and (n.ExitDate is null or n.ExitDate > (select ReportStart from lsa_Report))
							and n.RelationshipToHoH = 1) HHTypes  
					where HHTypes.PersonalID = lp.PersonalID)
				, -1) end	
		, lp.Step = '5.16.3'
	from tlsa_Person lp

/*
	5.17 Set Population Identifiers for Active HouseholdIDs
*/

	update hhid
	set hhid.HHChronic = (select max(
					case when (n.ActiveAge not between 18 and 65 and n.PersonalID <> hh.HoHID)
						or lp.DisabilityStatus <> 1 then 0
					when (lp.CHTime = 365 and lp.CHTimeStatus in (1,2))
						or (lp.CHTime = 400 and lp.CHTimeStatus = 2) then 1
					else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
			where n.HouseholdID = hhid.HouseholdID)
		, hhid.HHVet = (select max(
					case when lp.VetStatus = 1 
						and n.ActiveAge between 18 and 65 
						and hh.ActiveHHType <> 3 then 1
					else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
			where n.HouseholdID = hhid.HouseholdID)
		, hhid.HHDisability = (select max(
				case when lp.DisabilityStatus = 1 
					and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 1
				else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			where n.HouseholdID = hhid.HouseholdID)
		, hhid.HHFleeingDV = (select max(
				case when lp.DVStatus = 1 
					and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 1
				else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			where n.HouseholdID = hhid.HouseholdID)
		--Set HHAdultAge for active households based on HH member AgeGroup(s) 
		, hhid.HHAdultAge = (select 
				-- n/a for households with member(s) of unknown age
				case when max(n.ActiveAge) >= 98 then -1
					-- n/a for CO households
					when max(n.ActiveAge) <= 17 then -1
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
		, hhid.Step = '5.17.1'
	from tlsa_HHID hhid
	where hhid.Active = 1

	update hhid
	set hhid.HHParent = (select max(
			case when n.RelationshipToHoH = 2 then 1
				else 0 end)
		from tlsa_Enrollment n 
		where n.Active = 1 and n.HouseholdID = hhid.HouseholdID)
		, hhid.Step = '5.17.2'
	from tlsa_HHID hhid
	where hhid.Active = 1

/*
	5.18 Set tlsa_Person Population Identifiers from Active Households
*/

	update lp
	set lp.HHChronicEST = -1
		, lp.HHVetEST = -1
		, lp.HHDisabilityEST = -1
		, lp.HHFleeingDVEST = -1
		, lp.HHParentEST = -1
		, lp.Step = '5.18.1'
	from tlsa_Person lp
	where HHTypeEST = -1
	
	update lp
	set lp.HHChronicEST = case popHHTypes.HHChronic
			when '0' then -1
			else convert(int,replace(popHHTypes.HHChronic, '0', '')) end
	   , lp.HHVetEST = case popHHTypes.HHVet
			when '0' then -1
			else convert(int,replace(popHHTypes.HHVet, '0', '')) end
	   , lp.HHDisabilityEST = case popHHTypes.HHDisability
			when '0' then -1
			else convert(int,replace(popHHTypes.HHDisability, '0', '')) end
	   , lp.HHFleeingDVEST = case popHHTypes.HHFleeingDV
			when '0' then -1
			else convert(int,replace(popHHTypes.HHFleeingDV, '0', '')) end
	   , lp.HHParentEST = case popHHTypes.HHParent
			when '0' then -1
			else convert(int,replace(popHHTypes.HHParent, '0', '')) end
		, lp.Step = '5.18.2'
	from tlsa_Person lp
		inner join (select distinct lp.PersonalID
			, HHChronic = (select convert(varchar(4),sum(distinct
					case when hhid.HHChronic = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType in (1,2,8)
				where n.PersonalID = lp.PersonalID)
			, HHVet = (select convert(varchar(4),sum(distinct
					case when hhid.HHVet = 0 then 0 
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType in (1,2,8)
				where n.PersonalID = lp.PersonalID)
			, HHDisability = (select convert(varchar(4),sum(distinct
					case when hhid.HHDisability = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType in (1,2,8)
				where n.PersonalID = lp.PersonalID)
			, HHFleeingDV = (select convert(varchar(4),sum(distinct
					case when hhid.HHFleeingDV = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType in (1,2,8)
				where n.PersonalID = lp.PersonalID)
			, HHParent = (select convert(varchar(4),sum(distinct
					case when hhid.HHParent = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType in (1,2,8)
				where n.PersonalID = lp.PersonalID)
			from tlsa_Person lp
	) popHHTypes on popHHTypes.PersonalID = lp.PersonalID
	where lp.HHTypeEST <> -1

	update lp
	set lp.HHChronicRRH = -1
		, lp.HHVetRRH = -1
		, lp.HHDisabilityRRH = -1
		, lp.HHFleeingDVRRH = -1
		, lp.HHParentRRH = -1
		, lp.Step = '5.18.3'
	from tlsa_Person lp
	where HHTypeRRH = -1

	update lp
	set lp.HHChronicRRH = case popHHTypes.HHChronic
			when '0' then -1
			else convert(int,replace(popHHTypes.HHChronic, '0', '')) end
	   , lp.HHVetRRH = case popHHTypes.HHVet
			when '0' then -1
			else convert(int,replace(popHHTypes.HHVet, '0', '')) end
	   , lp.HHDisabilityRRH = case popHHTypes.HHDisability
			when '0' then -1
			else convert(int,replace(popHHTypes.HHDisability, '0', '')) end
	   , lp.HHFleeingDVRRH = case popHHTypes.HHFleeingDV
			when '0' then -1
			else convert(int,replace(popHHTypes.HHFleeingDV, '0', '')) end
	   , lp.HHParentRRH = case popHHTypes.HHParent
			when '0' then -1
			else convert(int,replace(popHHTypes.HHParent, '0', '')) end
		, lp.Step = '5.18.4'
	from tlsa_Person lp
		inner join (select distinct lp.PersonalID
			, HHChronic = (select convert(varchar(4),sum(distinct
					case when hhid.HHChronic = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 13
				where n.PersonalID = lp.PersonalID)
			, HHVet = (select convert(varchar(4),sum(distinct
					case when hhid.HHVet = 0 then 0 
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 13
				where n.PersonalID = lp.PersonalID)
			, HHDisability = (select convert(varchar(4),sum(distinct
					case when hhid.HHDisability = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 13
				where n.PersonalID = lp.PersonalID)
			, HHFleeingDV = (select convert(varchar(4),sum(distinct
					case when hhid.HHFleeingDV = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 13
				where n.PersonalID = lp.PersonalID)
			, HHParent = (select convert(varchar(4),sum(distinct
					case when hhid.HHParent = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 13
				where n.PersonalID = lp.PersonalID)
			from tlsa_Person lp
	) popHHTypes on popHHTypes.PersonalID = lp.PersonalID
	where lp.HHTypeRRH <> -1

	update lp
	set lp.HHChronicPSH = -1
		, lp.HHVetPSH = -1
		, lp.HHDisabilityPSH = -1
		, lp.HHFleeingDVPSH = -1
		, lp.HHParentPSH = -1
		, lp.Step = '5.18.5'
	from tlsa_Person lp
	where HHTypePSH = -1

	update lp
	set lp.HHChronicPSH = case popHHTypes.HHChronic
			when '0' then -1
			else convert(int,replace(popHHTypes.HHChronic, '0', '')) end
	   , lp.HHVetPSH = case popHHTypes.HHVet
			when '0' then -1
			else convert(int,replace(popHHTypes.HHVet, '0', '')) end
	   , lp.HHDisabilityPSH = case popHHTypes.HHDisability
			when '0' then -1
			else convert(int,replace(popHHTypes.HHDisability, '0', '')) end
	   , lp.HHFleeingDVPSH = case popHHTypes.HHFleeingDV
			when '0' then -1
			else convert(int,replace(popHHTypes.HHFleeingDV, '0', '')) end
	   , lp.HHParentPSH = case popHHTypes.HHParent
			when '0' then -1
			else convert(int,replace(popHHTypes.HHParent, '0', '')) end
		, lp.Step = '5.18.6'
	from tlsa_Person lp
		inner join (select distinct lp.PersonalID
			, HHChronic = (select convert(varchar(4),sum(distinct
					case when hhid.HHChronic = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 3
				where n.PersonalID = lp.PersonalID)
			, HHVet = (select convert(varchar(4),sum(distinct
					case when hhid.HHVet = 0 then 0 
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 3
				where n.PersonalID = lp.PersonalID)
			, HHDisability = (select convert(varchar(4),sum(distinct
					case when hhid.HHDisability = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 3
				where n.PersonalID = lp.PersonalID)
			, HHFleeingDV = (select convert(varchar(4),sum(distinct
					case when hhid.HHFleeingDV = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 3
				where n.PersonalID = lp.PersonalID)
			, HHParent = (select convert(varchar(4),sum(distinct
					case when hhid.HHParent = 0 then 0
						when hhid.ActiveHHType = 1 then 1000
						when hhid.ActiveHHType = 2 then 200
						when hhid.ActiveHHType = 3 then 30
						when hhid.ActiveHHType = 99 then 9
						else 0 end))
				from tlsa_HHID hhid
				inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
						and n.Active = 1 and n.ProjectType = 3
				where n.PersonalID = lp.PersonalID)
			from tlsa_Person lp
	) popHHTypes on popHHTypes.PersonalID = lp.PersonalID
	where lp.HHTypePSH <> -1


	update lp
	set lp.HHAdultAgeAOEST = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 1 
					and hhid.ProjectType in (1,2,8)
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeACEST = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 2
					and hhid.ProjectType in (1,2,8)
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeAORRH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 1 
					and hhid.ProjectType = 13
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeACRRH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 2
					and hhid.ProjectType = 13
				where n.PersonalID = lp.PersonalID), -1)
		, lp.HHAdultAgeAOPSH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 1 
					and hhid.ProjectType = 3
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeACPSH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 2
					and hhid.ProjectType = 3
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.Step = '5.18.7'
	from tlsa_Person lp

	update lp
	set lp.AC3PlusEST = coalesce((select max(hhid.AC3Plus) 
				from tlsa_HHID hhid
					inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID
					and n.ProjectType in (1,2,8) and n.Active = 1), 0)
		, lp.AC3PlusRRH = coalesce((select max(hhid.AC3Plus) 
				from tlsa_HHID hhid
					inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID
					and n.ProjectType = 13 and n.Active = 1), 0)		
		, lp.AC3PlusPSH = coalesce((select max(hhid.AC3Plus) 
				from tlsa_HHID hhid
					inner join tlsa_Enrollment n on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID
					and n.ProjectType = 3 and n.Active = 1), 0)
		, lp.Step = '5.18.8'
	from tlsa_Person lp

/*
	5.19 Select Data for Export to LSAPerson
*/
	-- LSAPerson
	delete from lsa_Person
	insert into lsa_Person (RowTotal
		, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, ReportID 
		)
	select count(distinct PersonalID)
		, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, ReportID 
	from tlsa_Person
	group by 
		Gender, Race, Ethnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, ReportID 
	
/*
	End LSAPerson
*/