/*
LSA FY2021 Sample Code

Name:  06 LSAHousehold.sql  
Date:  6 OCT 2021

	6.1 Get Unique Households and Population Identifiers for tlsa_Household
*/
	delete from tlsa_Household

	insert into tlsa_Household (HoHID, HHType
		, HHChronic, HHVet, HHDisability, HHFleeingDV
		, HoHRace, HoHEthnicity
		, HHParent, ReportID, Step)
	select distinct hhid.HoHID, hhid.ActiveHHType
		, case when min(case hhid.HHChronic when 0 then 99 else hhid.HHChronic end) = 99 then 0 else min(hhid.HHChronic) end
		, max(hhid.HHVet)
		, max(hhid.HHDisability)
		, max(hhid.HHFleeingDV)
		, lp.Race, lp.Ethnicity
		, max(hhid.HHParent)
		, lp.ReportID
		, '6.1'
	from tlsa_HHID hhid
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join tlsa_Person lp on lp.PersonalID = hhid.HoHID 
	where hhid.Active = 1
	group by hhid.HoHID, hhid.ActiveHHType, lp.Race, lp.Ethnicity
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

       
/*
	6.5 Set tlsa_Household Geography for Each Project Group 
	-- Enrollment with latest active date in report period for project group
*/

	update hh
	set hh.ESTGeography = case when hh.ESTStatus = 0 then -1 
			else coalesce(
				(select top 1 coc.GeographyType
				from tlsa_HHID hhid
				inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
				inner join lsa_ProjectCoC coc on coc.ProjectID = hhid.ProjectID 
				where hhid.Active = 1 and hhid.LSAProjectType in (0,1,2,8) 
					and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				order by case when hhid.ExitDate is null then rpt.ReportEnd else hhid.ExitDate end desc
					, hhid.EntryDate desc)
				, 99) end
		, hh.Step = '6.5.1'
	from tlsa_Household hh 

	update hh
	set hh.RRHGeography = case when hh.RRHStatus = 0 then -1 
			else coalesce(
				(select top 1 coc.GeographyType
				from tlsa_HHID hhid
				inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
				inner join lsa_ProjectCoC coc on coc.ProjectID = hhid.ProjectID 
				where hhid.Active = 1 and hhid.LSAProjectType = 13 
					and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				order by case when hhid.ExitDate is null then rpt.ReportEnd else hhid.ExitDate end desc
					, hhid.EntryDate desc)
				, 99) end
		, hh.Step = '6.5.2'
	from tlsa_Household hh 

	update hh
	set hh.PSHGeography = case when hh.PSHStatus = 0 then -1 
			else coalesce(
				(select top 1 coc.GeographyType
				from tlsa_HHID hhid
				inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
				inner join lsa_ProjectCoC coc on coc.ProjectID = hhid.ProjectID 
				where hhid.Active = 1 and hhid.LSAProjectType = 3 
					and hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				order by case when hhid.ExitDate is null then rpt.ReportEnd else hhid.ExitDate end desc
					, hhid.EntryDate desc)
				, 99) end
		, hh.Step = '6.5.3'
	from tlsa_Household hh 

/*
	6.6 Set tlsa_Household Living Situation for Each Project Group 
	--earliest active enrollment in project group
*/

	update hh
	set hh.ESTLivingSit = 
		case when hh.ESTStatus = 0 then -1
			when hn.EntryDate <> n.EntryDate then 99
			when hn.LivingSituation = 16 then 1 --Homeless - Street
			when hn.LivingSituation in (1,18) then 2	--Homeless - ES/SH
			when hn.LivingSituation = 27 then 3	--Interim Housing
			when hn.LivingSituation in (2,32) then 4	--Homeless - TH or host home
			when hn.LivingSituation = 14 then 5	--Hotel/Motel - no voucher
			when hn.LivingSituation = 29 then 6	--Residential project
			when hn.LivingSituation = 35 then 7	--Family		
			when hn.LivingSituation = 36 then 8	--Friends
			when hn.LivingSituation = 3 then 9	--PSH
			when hn.LivingSituation in (21,11) then 10	--PH - own
			when hn.LivingSituation = 10 then 11	--PH - rent no subsidy
			when hn.LivingSituation in (19,28,20,31,33,34) then 12	--PH - rent with subsidy
			when hn.LivingSituation = 15 then 13	--Foster care
			when hn.LivingSituation = 25 then 14	--Long-term care
			when hn.LivingSituation = 7 then 15	--Institutions - incarceration
			when hn.LivingSituation in (4,5,6) then 16	--Institutions - medical
			else 99	end
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
			when hn.EntryDate <> n.EntryDate then 99
			when hn.LivingSituation = 16 then 1 --Homeless - Street
			when hn.LivingSituation in (1,18) then 2	--Homeless - ES/SH
			when hn.LivingSituation = 27 then 3	--Interim Housing
			when hn.LivingSituation in (2,32) then 4	--Homeless - TH or host home
			when hn.LivingSituation = 14 then 5	--Hotel/Motel - no voucher
			when hn.LivingSituation = 29 then 6	--Residential project
			when hn.LivingSituation = 35 then 7	--Family		
			when hn.LivingSituation = 36 then 8	--Friends
			when hn.LivingSituation = 3 then 9	--PSH
			when hn.LivingSituation in (21,11) then 10	--PH - own
			when hn.LivingSituation = 10 then 11	--PH - rent no subsidy
			when hn.LivingSituation in (19,28,20,33,34) then 12	--PH - rent with subsidy
			when hn.LivingSituation = 15 then 13	--Foster care
			when hn.LivingSituation = 25 then 14	--Long-term care
			when hn.LivingSituation = 7 then 15	--Institutions - incarceration
			when hn.LivingSituation in (4,5,6) then 16	--Institutions - medical
			else 99	end	
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
			when hn.EntryDate <> n.EntryDate then 99
			when hn.LivingSituation = 16 then 1 --Homeless - Street
			when hn.LivingSituation in (1,18) then 2	--Homeless - ES/SH
			when hn.LivingSituation = 27 then 3	--Interim Housing
			when hn.LivingSituation in (2,32) then 4	--Homeless - TH or host home
			when hn.LivingSituation = 14 then 5	--Hotel/Motel - no voucher
			when hn.LivingSituation = 29 then 6	--Residential project
			when hn.LivingSituation = 35 then 7	--Family		
			when hn.LivingSituation = 36 then 8	--Friends
			when hn.LivingSituation = 3 then 9	--PSH
			when hn.LivingSituation in (21,11) then 10	--PH - own
			when hn.LivingSituation = 10 then 11	--PH - rent no subsidy
			when hn.LivingSituation in (19,28,20,33,34) then 12	--PH - rent with subsidy
			when hn.LivingSituation = 15 then 13	--Foster care
			when hn.LivingSituation = 25 then 14	--Long-term care
			when hn.LivingSituation = 7 then 15	--Institutions - incarceration
			when hn.LivingSituation in (4,5,6) then 16	--Institutions - medical
			else 99	end	
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
			(select max(hhid.HHFleeingDV)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType in (0,1,2,8)), 0)
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
			(select max(hhid.HHFleeingDV)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 13), 0)
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
			(select max(hhid.HHFleeingDV)
			 from tlsa_HHID hhid 
			 where hhid.Active = 1 and hhid.ActiveHHType = hh.HHType and hhid.HoHID = hh.HoHID
				and hhid.LSAProjectType = 3), 0)
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
			when prior.ExitDest between 1 and 6 then 2
			when prior.ExitDest between 7 and 14 then 3
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
	delete from sys_Time

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
			when dateadd(dd, -1, hh.FirstEntry) < '9/30/2012' then '9/30/2012'
			else dateadd(dd, -1, hh.FirstEntry) end
		, hh.Step = '6.12.1'
	from tlsa_Household hh 
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
		and bn.DateProvided between '10/1/2012' and rpt.ReportEnd
		and bn.DateProvided >= hhid.EntryDate
		and (bn.DateProvided < hhid.ExitDate or hhid.ExitDate is null)
		and bn.RecordType = 200 and bn.DateDeleted is null
		and hhid.LSAProjectType = 1
	where hh.LastInactive is null
		
	update hh
	set hh.LastInactive = coalesce(lastDay.inactive, '9/30/2012')
		, hh.Step = '6.12.3'
	from tlsa_Household hh
	left outer join 
		(select hh.HoHID, hh.HHType, max(cal.theDate) as inactive
		  from tlsa_Household hh
		  inner join lsa_Report rpt on rpt.ReportID = hh.ReportID
		  inner join ref_Calendar cal on cal.theDate <= rpt.ReportEnd
			and cal.theDate >= '10/1/2012'
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
	--added to sys_Time in the next statement.  
	update hh
	set hh.Other3917Days = (select datediff (dd,
			(select top 1 hn.DateToStreetESSH
			from tlsa_HHID hhid 
			inner join hmis_Enrollment hn on hn.EnrollmentID = hhid.EnrollmentID
			where hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				and hhid.EntryDate > hh.LastInactive
				and hn.DateToStreetESSH <= hh.LastInactive 
				and (hhid.LSAProjectType in (0,1,8)
					or hn.LivingSituation in (1,18,16)
					or (hn.LengthOfStay in (10,11) and hn.PreviousStreetESSH = 1)
					--5/14/2020 - correct 24 (deceased) to 25 (LTC/nursing home) 
					or (hn.LivingSituation in (4,5,6,7,15,25) 
						and hn.LengthOfStay in (2,3) and hn.PreviousStreetESSH = 1))
			order by hn.DateToStreetESSH asc)
		, hh.LastInactive)) + 1
		, hh.Step = '6.14.1'
	from tlsa_Household hh

	insert into sys_Time (HoHID, HHType, sysDate, sysStatus, Step)
	select distinct hh.HoHID, hh.HHType, cal.theDate, 7
		, '6.14.2'
	from tlsa_Household hh 
	inner join tlsa_HHID hhid on hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
		and hhid.EntryDate > hh.LastInactive 
	inner join hmis_Enrollment hn on hn.EnrollmentID = hhid.EnrollmentID
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate
	inner join ref_Calendar cal on 
		cal.theDate >= hn.DateToStreetESSH
		and cal.theDate < hn.EntryDate
	left outer join sys_Time other on other.HoHID = hh.HoHID and other.HHType = hh.HHType
		and other.sysDate = cal.theDate
	where other.sysDate is null and hhid.EnrollmentID in 
			(select top 1 hn.EnrollmentID
			from tlsa_HHID hhid 
			inner join hmis_Enrollment hn on hn.EnrollmentID = hhid.EnrollmentID
			where hhid.HoHID = hh.HoHID and hhid.ActiveHHType = hh.HHType
				and hhid.EntryDate > hh.LastInactive
				and hn.DateToStreetESSH <= hh.LastInactive 
				and (hhid.LSAProjectType in (0,1,8)
					or hn.LivingSituation in (1,18,16)
					or (hn.LengthOfStay in (10,11) and hn.PreviousStreetESSH = 1)
					or (hn.LivingSituation in (4,5,6,7,15,25) 
						and hn.LengthOfStay in (2,3) and hn.PreviousStreetESSH = 1))
			order by hn.DateToStreetESSH asc)

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

delete from lsa_Household
insert into lsa_Household(RowTotal
	, Stat, ReturnTime
	, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
	, HHAdult, HHChild, HHNoDOB
	, HHAdultAge, HHParent
	, ESTStatus, ESTGeography, ESTLivingSit, ESTDestination, ESTChronic, ESTVet, ESTDisability, ESTFleeingDV, ESTAC3Plus, ESTAdultAge, ESTParent
	, RRHStatus, RRHMoveIn, RRHGeography, RRHLivingSit, RRHDestination, RRHPreMoveInDays, RRHChronic, RRHVet, RRHDisability, RRHFleeingDV, RRHAC3Plus, RRHAdultAge, RRHParent
	, PSHStatus, PSHMoveIn, PSHGeography, PSHLivingSit, PSHDestination, PSHHousedDays, PSHChronic, PSHVet, PSHDisability, PSHFleeingDV, PSHAC3Plus, PSHAdultAge, PSHParent
	, ESDays, THDays, ESTDays, RRHPSHPreMoveInDays, RRHHousedDays, SystemDaysNotPSHHoused, SystemHomelessDays, Other3917Days, TotalHomelessDays
	, SystemPath, ESTAHAR, RRHAHAR, PSHAHAR, ReportID 
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
	, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
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
	, SystemPath, ESTAHAR, RRHAHAR, PSHAHAR, ReportID 
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
	, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
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
	, SystemPath, ESTAHAR, RRHAHAR, PSHAHAR, ReportID 

/*
	End LSAHousehold
*/

