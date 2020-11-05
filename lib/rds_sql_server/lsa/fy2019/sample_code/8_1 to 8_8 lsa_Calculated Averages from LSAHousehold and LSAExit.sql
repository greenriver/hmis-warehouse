/*
LSA FY2019 Sample Code

Name:  8_1 to 8_8 lsa_Calculated averages from LSAHousehold and LSAExit (File 8 of 10)
Date:  4/7/2020   
	   5/21/2020 - Add set of Step column to all INSERT statements
	   7/23/2020 - Correct set of Step to '8.1/8.2' (was '8.1/2.1')
					- Correct WHERE clause in 8.3 from PSHStatus > 0 to PSHStatus between 11 and 22
					- Split 8.6 and 8.7 into separate statements to produce appropriate ReportRow and SystemPath values
					  (see GitHub issue #290)
		7/30/2020 - step 8.1/2.9 - correct criteria for SystemPath consistent with specs
		9/2/2020 - remove 'pop.PopID between 0 and 4' from the WHERE clause in 8.6, add it to 8.7 (where it belongs), 
					 and add SystemPath criteria to join to ref_Populations in 8.7
		10/1/2020 - 8.5 - correct set of ReportRow for new ExitFrom values 7 and 8 (w/ related changes in specs section 8.5
					and dictionary list 33/ReportRow).
					8.1 and 8.2 - correct step numbering
		10/22/2020 - 8.7 - specify that records in ref_Populations used for counts should be PopType 1 (household characteristics) 
						/ exclude PopType 3 (personal characteristics)

	8.1 and 8.2 Average Days for Length of Time Homeless 
*/
	delete from lsa_Calculated
	--AVERAGE DAYS IN ES/SH 
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select distinct avg(ESDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, coalesce(pop.SystemPath, -1)
		, 1 as ReportRow
		, lh.ReportID
		, '8.1/2.1'
	from tlsa_Household lh
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.ESDays > 0
		and pop.LOTH = 1
		and (lh.SystemPath in (1,3,5,7,9,10,12) or pop.SystemPath is null)
	group by pop.PopID
		, pop.HHType
		, pop.SystemPath
		, lh.ReportID
	
	-- AVERAGE DAYS IN TH
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select distinct avg(lh.THDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, coalesce(pop.SystemPath, -1)
		, 2 as ReportRow
		, lh.ReportID
		, '8.1/2.2'
	from tlsa_Household lh
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.THDays > 0 
		and pop.LOTH = 1
		and (lh.SystemPath in (2,3,6,7,12) or pop.SystemPath is null)
	group by pop.PopID
		, pop.HHType
		, pop.SystemPath
		, lh.ReportID

	--AVERAGE DAYS in ES/SH/TH combined
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select distinct avg(lh.ESTDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, coalesce(pop.SystemPath, -1)
		, 3 as ReportRow
		, lh.ReportID
		, '8.1/2.3'
	from tlsa_Household lh
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.ESTDays > 0 
		and pop.LOTH = 1
		and (lh.SystemPath in (3,7,12) or pop.SystemPath is null)
	group by pop.PopID
		, pop.HHType
		, pop.SystemPath
		, lh.ReportID

	--AVERAGE DAYS in RRH/PSH Pre-MoveIn
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select distinct avg(lh.RRHPSHPreMoveInDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, coalesce(pop.SystemPath, -1)
		, 4 as ReportRow
		, lh.ReportID
		, '8.1/2.4'
	from tlsa_Household lh
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.RRHPSHPreMoveInDays > 0 
		and pop.LOTH = 1
		and (lh.SystemPath in (4,5,6,7,8,9,10,11,12) or pop.SystemPath is null)
	group by pop.PopID
		, pop.HHType
		, pop.SystemPath
		, lh.ReportID

	--AVERAGE DAYS Enrolled in ES/SH/TH/RRH/PSH PROJECTS WHILE HOMELESS
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lh.SystemHomelessDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, coalesce(pop.SystemPath, -1)
		, 5 as ReportRow
		, lh.ReportID
		, '8.1/2.5'
	from tlsa_Household lh
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.SystemHomelessDays > 0 
		and pop.LOTH = 1
		and (lh.SystemPath in (5,6,7,8,9,10,11,12) or pop.SystemPath is null)
	group by pop.PopID
		, pop.HHType
		, pop.SystemPath
		, lh.ReportID

	--AVERAGE DAYS Not Enrolled in ES/SH/TH/RRH/PSH PROJECTS 
	--  and DOCUMENTED HOMELESS BASED ON 3.917
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lh.Other3917Days) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, coalesce(pop.SystemPath, -1)
		, 6 as ReportRow
		, lh.ReportID
		, '8.1/2.6'
	from tlsa_Household lh
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.Other3917Days > 0 
		and pop.LOTH = 1
		and (lh.SystemPath <> -1 or pop.SystemPath is null)
	group by pop.PopID
		, pop.HHType
		, pop.SystemPath
		, lh.ReportID

	--AVERAGE DAYS HOMELESS IN ES/SH/TH/RRH/PSH projects +
	-- DAYS DOCUMENTED HOMELESS BASED ON 3.917
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lh.TotalHomelessDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, coalesce(pop.SystemPath, -1)
		, 7 as ReportRow
		, lh.ReportID
		, '8.1/2.7'
	from tlsa_Household lh
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.TotalHomelessDays > 0 
		and pop.LOTH = 1
		and (lh.SystemPath <> -1 or pop.SystemPath is null)
	group by pop.PopID
		, pop.HHType
		, pop.SystemPath
		, lh.ReportID

	--AVERAGE DAYS HOUSED IN RRH
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lh.RRHHousedDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, coalesce(pop.SystemPath, -1)
		, 8 as ReportRow
		, lh.ReportID
		, '8.1/2.8'
	from tlsa_Household lh
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.RRHHousedDays > 0 
		and pop.LOTH = 1
		and (lh.SystemPath in (4,5,6,7,10,11,12) or pop.SystemPath is null)
	group by pop.PopID
		, pop.HHType
		, pop.SystemPath
		, lh.ReportID

	--AVERAGE DAYS Enrolled in ES/SH/TH/RRH/PSH PROJECTS and not Housed in PSH
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lh.SystemDaysNotPSHHoused) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, coalesce(pop.SystemPath, -1)
		, 9 as ReportRow
		, lh.ReportID
		, '8.1/2.9'
	from tlsa_Household lh
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.SystemDaysNotPSHHoused > 0 
		and pop.LOTH = 1
		and (lh.SystemPath <> -1 or pop.SystemPath is null)
	group by pop.PopID
		, pop.HHType
		, pop.SystemPath
		, lh.ReportID

/*	
	8.3 Cumulative Length of Time Housed in PSH
*/
	--Time Housed in PSH 
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lh.PSHHousedDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID
		, -1 as SystemPath
		--Row 10 = households that exited, 11 = active on the last day
		, case when PSHStatus in (12,22) then 10 else 11 end as ReportRow
		, lh.ReportID
		, '8.3'
	from tlsa_Household lh 
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.PSHMoveIn > 0 and lh.PSHStatus between 11 and 22
		and pop.Core = 1
	group by pop.PopID
		, pop.HHType
		, case when PSHStatus in (12,22) then 10 else 11 end 
		, lh.ReportID
/*
	8.4 Length of Time in RRH Projects
*/
	--Time in RRH not housed
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lh.RRHPreMoveInDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID
		, -1 as SystemPath
		--Row 14 = all households placed in PH
		, case when lh.RRHMoveIn in (1,2) then 14
			--Row 12 = exited households not placed in PH
			when RRHStatus in (12,22) then 12 
			--Row 13 = active households not placed in PH
			else 13 end as ReportRow
		, lh.ReportID
		, '8.4.1'
	from tlsa_Household lh 
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.RRHStatus > 2 and pop.Core = 1
	group by pop.PopID
		, pop.HHType
		, case when lh.RRHMoveIn in (1,2) then 14
			when RRHStatus in (12,22) then 12 
			else 13 end 
		, lh.ReportID

	--Time housed in RRH
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lh.RRHHousedDays) as Value
		, 1 as Cohort, -1 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, -1 as SystemPath
		--Row 15 = exited households
		, case when RRHStatus in (12,22) then 15 
			--Row 16 = active households 
			else 16 end as ReportRow
		, lh.ReportID
		, '8.4.2'
	from tlsa_Household lh 
	inner join ref_Populations pop on
		(lh.HHType = pop.HHType or pop.HHType is null)
		and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lh.HHVet = pop.HHVet or pop.HHVet is null)
		and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lh.HHParent = pop.HHParent or pop.HHParent is null)
		and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
		and (lh.HHChild = pop.HHChild or pop.HHChild is null)
		and (lh.Stat = pop.Stat or pop.Stat is null)
		and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
		and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lh.RRHMoveIn in (1,2)
		and pop.Core = 1
	group by pop.PopID
		, pop.HHType
		, case when RRHStatus in (12,22) then 15 
			else 16 end
		, lh.ReportID
/*
	8.5 Days to Return/Re-engage by Last Project Type
*/
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lx.ReturnTime) as Value
		, lx.Cohort, 
		case when lx.ExitTo between 1 and 6 then 2
			when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
		, coalesce(pop.HHType, 0) 
		, pop.PopID as Population
		, -1 as SystemPath
		, case lx.ExitFrom 
			when 7 then 63 
			when 8 then 64
			else lx.ExitFrom + 16 end as ReportRow
		, lx.ReportID
		, '8.5'
	from tlsa_Exit lx
	inner join ref_Populations pop on
		(lx.HHType = pop.HHType or pop.HHType is null)
		and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lx.HHVet = pop.HHVet or pop.HHVet is null)
		and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lx.HHParent = pop.HHParent or pop.HHParent is null)
		and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
		and (lx.Stat = pop.Stat or pop.Stat is null)
		and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	where lx.ReturnTime > 0 
		and pop.Core = 1
	group by pop.PopID, lx.ReportID
		, lx.Cohort
		, lx.ExitFrom
		, case when lx.ExitTo between 1 and 6 then 2
			when lx.ExitTo between 7 and 14 then 3 else 4 end
		, pop.HHType
/*
	8.6 Days to Return/Re-engage by Population 
*/

	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lx.ReturnTime) as Value
		, lx.Cohort, 
		case when lx.ExitTo between 1 and 6 then 2
			when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID as Population
		, -1 as SystemPath
		, 23 as ReportRow
		, lx.ReportID
		, '8.6'
	from tlsa_Exit lx
	inner join ref_Populations pop on
		(lx.HHType = pop.HHType or pop.HHType is null)
		and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lx.HHVet = pop.HHVet or pop.HHVet is null)
		and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lx.HHParent = pop.HHParent or pop.HHParent is null)
		and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
		and (lx.Stat = pop.Stat or pop.Stat is null)
		and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
		and (lx.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lx.ReturnTime > 0 
		and pop.ReturnSummary = 1 
		and pop.SystemPath is null
	group by pop.PopID, lx.ReportID
		, lx.Cohort
		, case when lx.ExitTo between 1 and 6 then 2
			when lx.ExitTo between 7 and 14 then 3 else 4 end
		, pop.HHType

/*
	
	8.7 Days to Return/Re-engage by Population / SystemPath
*/
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lx.ReturnTime) as Value
		, lx.Cohort, 
		case when lx.ExitTo between 1 and 6 then 2
			when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
		, coalesce(pop.HHType, 0) 
		, pop.PopID as Population
		, case when pop.SystemPath is null then -1 else pop.SystemPath end
		, case when pop.SystemPath is null then 36 else pop.SystemPath + 23 end as ReportRow
		, lx.ReportID
		, '8.7'
	from tlsa_Exit lx
	inner join ref_Populations pop on
		(lx.HHType = pop.HHType or pop.HHType is null)
		and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lx.HHVet = pop.HHVet or pop.HHVet is null)
		and (lx.SystemPath = pop.SystemPath or pop.SystemPath is null)
	where lx.ReturnTime > 0 
	    and lx.SystemPath <> -1 --290
		and pop.PopID between 0 and 4 and pop.PopType = 1
	group by pop.PopID, lx.ReportID
		, lx.Cohort
		, case when lx.ExitTo between 1 and 6 then 2
			when lx.ExitTo between 7 and 14 then 3 else 4 end
		, pop.HHType
		, case when pop.SystemPath is null then -1 else pop.SystemPath end
		, case when pop.SystemPath is null then 36 else pop.SystemPath + 23 end 

/*
	8.8 Days to Return/Re-engage by Exit Destination
*/
	insert into lsa_Calculated (Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select avg(lx.ReturnTime) as Value
		, lx.Cohort, 
		case when lx.ExitTo between 1 and 6 then 2
			when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
		, coalesce(pop.HHType, 0) 
		, pop.PopID as Population
		, -1 as SystemPath
		, case when lx.ExitTo between 1 and 15 then lx.ExitTo + 36 else 52 end as ReportRow
		, lx.ReportID
		, '8.8'
	from tlsa_Exit lx
	inner join ref_Populations pop on
		(lx.HHType = pop.HHType or pop.HHType is null)
		and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (lx.HHVet = pop.HHVet or pop.HHVet is null)
		and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (lx.HHParent = pop.HHParent or pop.HHParent is null)
		and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
		and (lx.Stat = pop.Stat or pop.Stat is null)
		and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
		and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
	where lx.ReturnTime > 0 
		and pop.Core = 1
	group by pop.PopID, lx.ReportID
		, lx.Cohort
		, case when lx.ExitTo between 1 and 6 then 2
			when lx.ExitTo between 7 and 14 then 3 else 4 end
		, pop.HHType
		, case when lx.ExitTo between 1 and 15 then lx.ExitTo + 36 else 52 end

