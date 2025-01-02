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
	select distinct 38, ex.Cohort, ex.HoHID, ex.HHType, '8.3.40'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%1%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 39, ex.Cohort, ex.HoHID, ex.HHType, '8.3.41'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%2%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 40, ex.Cohort, ex.HoHID, ex.HHType, '8.3.42'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%3%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 41, ex.Cohort, ex.HoHID, ex.HHType, '8.3.43'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%6%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 42, ex.Cohort, ex.HoHID, ex.HHType, '8.3.44'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%7%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 43, ex.Cohort, ex.HoHID, ex.HHType, '8.3.45'
	from tlsa_Exit ex 
	where cast(ex.HoHRaceEthnicity as nvarchar) like '%4%' 

	insert into tlsa_AveragePops (PopID, Cohort, HoHID, HHType, Step)
	select distinct 44, ex.Cohort, ex.HoHID, ex.HHType, '8.3.46'
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