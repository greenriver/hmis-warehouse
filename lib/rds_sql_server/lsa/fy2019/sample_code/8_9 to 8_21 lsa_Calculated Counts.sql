/*
LSA FY2019 Sample Code

Name:  8_9 to 8_21 lsa_Calculated counts (File 9 of 10)
Date:  4/15/2020   
	   5/21/2020 - add set of Step column to all INSERT statements
	   7/23/2020 - delete HHChronic criteria from 8.9 -- not relevant
				Corrections to 8.9-8.18 to consistently reflect that a bednight is counted for RRH when 
					the MoveInDate occurs on the ExitDate.
				Corrections to 8.10.2, 8.12.2, 8.14.2 to remove RRH/PSH criteria to counts for ES/SH/TH combined
		8/6/2020 - 8.13 - Correct anomalies in WHERE clause
				   8.14 - Apply max(age) criteria to point-in-time cohorts as well as active cohort for counts by age group.
						The specs do not exclude the PIT cohorts from the requirement and it removes the possibility of 
						overlapping enrollments with different ActiveAge values causing double counts.
				   8.15 - Use tlsa_HHID vs. tlsa_Enrollment Active = 1 for bednight counts
						- Limit bednight counts to nbn ES projects.
				   8.17-8.18 - remove extraneous 'WHERE n.Active = 1' - no change to output but entry/exit/bednight criteria
						in joins already ensure this
				   8.19-8.21 - Require DateDeleted is NULL in joins to HMIS tables
				   8.21 - Include exit date and appropriate CoCCode criteria
		8/13/2020 - 8.18.2 - correct value for Step column inserted to lsa_Calculated
		8/19/2020 - 8.9 and 8.11 - add counts for PopID 6 (CH) 
					8.12.2 - remove duplicate 'pop.SystemPath is null' from WHERE clause
		8/20/2020 - 8.14 - split out counts of parenting children/youth, which are limited to HoH
							into separate steps (former 8.14.1 is now 8.14.1 and 8.14.2, and
							former 8.14.2 is now 8.14.3 and 8.14.4)
						   use tlsa_Person.DVStatus instead of tlsa_HHID.HHFleeingDV (personal characteristic vs household)
		8/25/2020 - (Final Step) - Note that export of lsa_Calculated values to LSACalculated.csv must omit the Step column.
		8/27/2020 - 8.9 - include HHChronic criteria in join to ref_Populations
					8.21 - correct exit date criteria in WHERE clause
		9/3/2020 -  8.21 - limit count to projects in lsa_Project
		9/10/2020 - 8.14.1 and .3 -- correction in WHERE clause re: latest age and popIDs
		9/17/2020 - 8.13 - add max age criteria for popIDs 145-148
					8.20 - in WHERE clause, LastBednight <= dateadd(dd, -90, cd.CohortEnd) (was just <)
		9/24/2020 - 8.9 through 8.14 - limit relevant bednights to those >= entry and < exit dates (if non-NULL)
						because enrollment dates may have been adjusted in tlsa_HHID/tlsa_Enrollment
		10/29/2020 - 8.21 Correction to comment identifying section name / no change to code 
		11/23/2020 - 8.17 & 8.18.1/2 - add Active = 1 to WHERE clause 
					 8.21 - remove EntryDate > ReportStart criteria from left join to hmis_Exit

	8.9 Get Counts of People by Project ID and Household Characteristics
*/
	--Count people in households by ProjectID for:
	--AO/AC/CO/All All: Disabled Adult/HoH, CH Adult/HoH, Adult/HoH Fleeing DV,
	--  and:  AO Youth, AO/AC Vet, AC Youth Parent, CO Parent,
	delete from lsa_Calculated where ReportRow >= 53

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.PersonalID)
		, cd.Cohort, 10 as Universe
		, coalesce(pop.HHType, 0) 
		, pop.PopID as PopID
		, -1, 53
		, n.ProjectID		
		, cd.ReportID, '8.9'
	from tlsa_Enrollment n 
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateDeleted is null
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (hhid.HHVet = pop.HHVet or pop.HHVet is null)
		and (hhid.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (hhid.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (hhid.HHChronic = pop.HHChronic or pop.HHChronic is null)
	inner join tlsa_CohortDates cd on cd.CohortEnd >= n.EntryDate
		  and (cd.CohortStart < n.ExitDate 
			or n.ExitDate is null
			or (n.ProjectType = 13 and n.ExitDate = cd.CohortStart and n.MoveInDate = cd.CohortStart))
	where n.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopID between 0 and 10 and pop.PopType = 1 
		and pop.SystemPath is null
		and (
			 --for RRH and PSH, count only people who are housed in period
			(n.ProjectType in (3,13) and n.MoveInDate <= cd.CohortEnd) 
			--for night-by-night ES, count only people with bednights in period
			or (n.TrackingMethod = 3 and n.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= n.EntryDate 
				and (bn.DateProvided < n.ExitDate or n.ExitDate is null))
			or (n.TrackingMethod = 0 and n.ProjectType = 1)
			or (n.ProjectType in (2,8))
			)
	group by cd.Cohort, pop.PopID, n.ProjectID, cd.ReportID, pop.HHType

/*
	8.10 Get Counts of People by Project Type and Household Characteristics
*/
	--Unduplicated count of people in households for each project type
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct n.PersonalID)
		, cd.Cohort, case n.ProjectType 
			when 1 then 11 
			when 8 then 12	
			when 2 then 13	
			when 13 then 14	
			else 15 end
		, coalesce(pop.HHType, 0) 
		, pop.PopID, -1, 53
		, cd.ReportID, '8.10.1'
	from tlsa_Enrollment n 
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateDeleted is null	
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (hhid.HHVet = pop.HHVet or pop.HHVet is null)
		and (hhid.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (hhid.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (hhid.HHChronic = pop.HHChronic or pop.HHChronic is null)
	inner join tlsa_CohortDates cd on cd.CohortEnd >= n.EntryDate
		  and (cd.CohortStart < n.ExitDate 
			or n.ExitDate is null
			or (n.ProjectType = 13 and n.ExitDate = cd.CohortStart and n.MoveInDate = cd.CohortStart))
	where n.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopID between 0 and 10 and pop.PopType = 1
		and pop.SystemPath is null
		and (
			 --for RRH and PSH, count only people who are housed in period
			(n.ProjectType in (3,13) and n.MoveInDate <= cd.CohortEnd) 
			--for night-by-night ES, count only people with bednights in period
			or (n.TrackingMethod = 3 and n.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= n.EntryDate 
				and (bn.DateProvided < n.ExitDate or n.ExitDate is null))
			or (n.TrackingMethod = 0 and n.ProjectType = 1)
			or (n.ProjectType in (2,8))
			)
	group by cd.Cohort, pop.PopID 
			, n.ProjectType 
			, cd.ReportID
			, pop.HHType

	--Unduplicated count of people in households for ES/SH/TH combined
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct n.PersonalID)
		, cd.Cohort, 16 as Universe
		, coalesce(pop.HHType, 0) 
		, pop.PopID, -1, 53
		, cd.ReportID, '8.10.2'
	from tlsa_Enrollment n 
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateDeleted is null	
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (hhid.HHVet = pop.HHVet or pop.HHVet is null)
		and (hhid.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (hhid.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (hhid.HHChronic = pop.HHChronic or pop.HHChronic is null)
	inner join tlsa_CohortDates cd on cd.CohortEnd >= n.EntryDate
		  and (cd.CohortStart < n.ExitDate 
			or n.ExitDate is null)
	where n.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopID between 0 and 10 and pop.PopType = 1
		and pop.SystemPath is null
		and (
			(n.TrackingMethod = 3 and n.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= n.EntryDate 
				and (bn.DateProvided < n.ExitDate or n.ExitDate is null))
			or (n.TrackingMethod = 0 and n.ProjectType = 1)
			or (n.ProjectType in (2,8))
			)
	group by cd.Cohort, pop.PopID 
			, cd.ReportID
			, pop.HHType

/*
	8.11 Get Counts of Households by Project ID 
*/
	--Count households
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct cast(hhid.HoHID as nvarchar) + cast(hhid.ActiveHHType as nvarchar))
		, cd.Cohort, 10 
		, coalesce(pop.HHType, 0)
		, pop.PopID, -1, 54
		, hhid.ProjectID, cd.ReportID, '8.11'
	from tlsa_HHID hhid 
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= hhid.EntryDate and (bn.DateProvided < hhid.ExitDate or hhid.ExitDate is null)
		and bn.DateDeleted is null
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (hhid.HHVet = pop.HHVet or pop.HHVet is null)
		and (hhid.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (hhid.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (hhid.HHChronic = pop.HHChronic or pop.HHChronic is null)
	inner join tlsa_CohortDates cd on cd.CohortEnd >= hhid.EntryDate
		  and (cd.CohortStart < hhid.ExitDate 
			or hhid.ExitDate is null
			or (hhid.ProjectType = 13 and hhid.ExitDate = cd.CohortStart and hhid.MoveInDate = cd.CohortStart))
	where hhid.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopID between 0 and 10 and pop.PopType = 1
		and pop.SystemPath is null
		and (
			 --for RRH and PSH, count only people who are housed in period
			(hhid.ProjectType in (3,13) and hhid.MoveInDate <= cd.CohortEnd) 
			--for night-by-night ES, count only people with bednights in period
			or (hhid.TrackingMethod = 3 and hhid.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= hhid.EntryDate 
				and (bn.DateProvided < hhid.ExitDate or hhid.ExitDate is null))
			or (hhid.TrackingMethod = 0 and hhid.ProjectType = 1)
			or (hhid.ProjectType in (2,8))
			)
	group by cd.Cohort, pop.PopID, hhid.ProjectID, cd.ReportID
		, pop.HHType


/*
	8.12 Get Counts of Households by Project Type 
*/
--Unduplicated count households for each project type
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct cast(hhid.HoHID as nvarchar) + cast(hhid.ActiveHHType as nvarchar))
		, cd.Cohort, case hhid.ProjectType 
			when 1 then 11 
			when 8 then 12	
			when 2 then 13	
			when 13 then 14	
			else 15 end as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID, -1, 54
		, cd.ReportID, '8.12.1'
	from tlsa_HHID hhid 
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= hhid.EntryDate and (bn.DateProvided < hhid.ExitDate or hhid.ExitDate is null)
		and bn.DateDeleted is null
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (hhid.HHVet = pop.HHVet or pop.HHVet is null)
		and (hhid.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (hhid.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (hhid.HHChronic = pop.HHChronic or pop.HHChronic is null)
	inner join tlsa_CohortDates cd on cd.CohortEnd >= hhid.EntryDate
		  and (cd.CohortStart < hhid.ExitDate 
			or hhid.ExitDate is null
			or (hhid.ProjectType = 13 and hhid.ExitDate = cd.CohortStart and hhid.MoveInDate = cd.CohortStart))
	where hhid.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopID between 0 and 10 and pop.PopType = 1 
		and pop.SystemPath is null
		and (
			 --for RRH and PSH, count only people who are housed in period
			(hhid.ProjectType in (3,13) and hhid.MoveInDate <= cd.CohortEnd) 
			--for night-by-night ES, count only people with bednights in period
			or (hhid.TrackingMethod = 3 and hhid.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= hhid.EntryDate 
				and (bn.DateProvided < hhid.ExitDate or hhid.ExitDate is null))
			or (hhid.TrackingMethod = 0 and hhid.ProjectType = 1)
			or (hhid.ProjectType in (2,8))
			)
	group by cd.Cohort, pop.PopID, case hhid.ProjectType 
			when 1 then 11 
			when 8 then 12	
			when 2 then 13	
			when 13 then 14	
			else 15 end, cd.ReportID
		, pop.HHType 

	--Unduplicated count of households for ES/SH/TH combined
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct cast(hhid.HoHID as nvarchar) + cast(hhid.ActiveHHType as nvarchar))
		, cd.Cohort, 16 as Universe
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID, -1, 54
		, cd.ReportID, '8.12.2'
	from tlsa_HHID hhid 
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= hhid.EntryDate and (bn.DateProvided < hhid.ExitDate or hhid.ExitDate is null)
		and bn.DateDeleted is null
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (hhid.HHVet = pop.HHVet or pop.HHVet is null)
		and (hhid.HHDisability = pop.HHDisability or pop.HHDisability is null)
		and (hhid.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (hhid.HHChronic = pop.HHChronic or pop.HHChronic is null)
	inner join tlsa_CohortDates cd on cd.CohortEnd >= hhid.EntryDate
		  and (cd.CohortStart < hhid.ExitDate 
			or hhid.ExitDate is null)
	where hhid.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopID between 0 and 10 and pop.PopType = 1 
		and pop.SystemPath is null
		and (--for night-by-night ES, count only people with bednights in period
			(hhid.TrackingMethod = 3 and hhid.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= hhid.EntryDate 
				and (bn.DateProvided < hhid.ExitDate or hhid.ExitDate is null))
			or (hhid.TrackingMethod = 0 and hhid.ProjectType = 1)
			or (hhid.ProjectType in (2,8))
			)
	group by cd.Cohort, pop.PopID, cd.ReportID
		, pop.HHType 

/*
	8.13 Get Counts of People by ProjectID and Personal Characteristics
*/
	--Count people with specific characteristic
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct lp.PersonalID)
		, cd.Cohort, 10 
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID, -1, 55
		, n.ProjectID, cd.ReportID, '8.13'
	from tlsa_Person lp
	inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null	
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
			 or pop.CHTime is null)
		and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
		and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
		and (n.ActiveAge = pop.Age or pop.Age is null)
	inner join tlsa_CohortDates cd on cd.CohortEnd >= n.EntryDate
		  and (cd.CohortStart < n.ExitDate 
			or n.ExitDate is null
			or (n.ProjectType = 13 and n.ExitDate = cd.CohortStart and n.MoveInDate = cd.CohortStart))
	left outer join (select n.PersonalID, hhid.ActiveHHType as HHType, hhid.ProjectType, max(n.ActiveAge) as Age
		from tlsa_Enrollment n
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
		group by n.PersonalID, hhid.ActiveHHType, hhid.ProjectType
		) latest on latest.PersonalID = n.PersonalID and latest.HHType = hhid.ActiveHHType
			and latest.ProjectType = hhid.ProjectType and latest.Age = n.ActiveAge
	where n.Active = 1 and cd.Cohort between 1 and 13
		and (pop.PopID in (3,6) or pop.popID between 145 and 148)
		and pop.PopType = 3
		and pop.ProjectLevelCount = 1
		and (
			 --for RRH and PSH, count only people who are housed in period
			(n.ProjectType in (3,13) and n.MoveInDate <= cd.CohortEnd) 
			--for night-by-night ES, count only people with bednights in period
			or (n.TrackingMethod = 3 and n.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= n.EntryDate 
				and (bn.DateProvided < n.ExitDate or n.ExitDate is null))
			or (n.TrackingMethod = 0 and n.ProjectType = 1)
			or (n.ProjectType in (2,8))
			)
		and 
			(pop.PopID < 145 or latest.Age is not null)	
	group by cd.Cohort, pop.PopID, n.ProjectID, cd.ReportID
		, pop.HHType

/*
	8.14 Get Counts of People by Project Type and Personal Characteristics
*/
	--Count people with specific characteristics for each project type
	-- EXCEPT popIDs 113-144, which are limited to HoH and counted in next step
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct lp.PersonalID)
		, cd.Cohort, case n.ProjectType 
			when 1 then 11 
			when 8 then 12	
			when 2 then 13	
			when 13 then 14	
			else 15 end 
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID, -1, 55
		, cd.ReportID, '8.14.1'
	from tlsa_Person lp
	inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
			 or pop.CHTime is null)
		and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
		and (lp.DVStatus = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
		and (n.ActiveAge = pop.Age or pop.Age is null)
		and (lp.Gender = pop.Gender or pop.Gender is null)
		and (lp.Race = pop.Race or pop.Race is null)
		and (lp.Ethnicity = pop.Ethnicity or pop.Ethnicity is null)
	left outer join (select n.PersonalID, hhid.ActiveHHType as HHType, hhid.ProjectType, max(n.ActiveAge) as Age
		from tlsa_Enrollment n
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
		group by n.PersonalID, hhid.ActiveHHType, hhid.ProjectType
		) latest on latest.PersonalID = n.PersonalID and latest.HHType = hhid.ActiveHHType
			and latest.ProjectType = hhid.ProjectType and latest.Age = n.ActiveAge
	inner join tlsa_CohortDates cd on cd.CohortEnd >= n.EntryDate
		  and (cd.CohortStart < n.ExitDate 
			or n.ExitDate is null
			or (n.ProjectType = 13 and n.ExitDate = cd.CohortStart and n.MoveInDate = cd.CohortStart))
	where n.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopType = 3 and pop.PopID not between 113 and 144
		and (
			 --for RRH and PSH, count only people who are housed in period
			(n.ProjectType in (3,13) and n.MoveInDate <= cd.CohortEnd) 
			--for night-by-night ES, count only people with bednights in period
			or (n.TrackingMethod = 3 and n.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= n.EntryDate 
				and (bn.DateProvided < n.ExitDate or n.ExitDate is null))
			or (n.TrackingMethod = 0 and n.ProjectType = 1)
			or (n.ProjectType in (2,8))
			)
		and 
			(
				(pop.PopID not between 24 and 34 and pop.PopID not between 145 and 148)
				or latest.Age is not null
			)
	group by cd.Cohort, pop.PopID, n.ProjectType, cd.ReportID
		, pop.HHType

	--Count people with specific characteristics for each project type
	--  (counts of PopIDs 113-144 for parenting children/youth limited to HoH)
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct lp.PersonalID)
		, cd.Cohort, case n.ProjectType 
			when 1 then 11 
			when 8 then 12	
			when 2 then 13	
			when 13 then 14	
			else 15 end 
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID, -1, 55
		, cd.ReportID, '8.14.2'
	from tlsa_Person lp
	inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID
	inner join tlsa_HHID hhid on hhid.EnrollmentID = n.EnrollmentID
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null	
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
			 or pop.CHTime is null)
		and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
		and (lp.DVStatus = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
		and (n.ActiveAge = pop.Age or pop.Age is null)
		and (lp.Gender = pop.Gender or pop.Gender is null)
		and (lp.Race = pop.Race or pop.Race is null)
		and (lp.Ethnicity = pop.Ethnicity or pop.Ethnicity is null)
	left outer join (select n.PersonalID, hhid.ActiveHHType as HHType, hhid.ProjectType, max(n.ActiveAge) as Age
		from tlsa_Enrollment n
		inner join tlsa_HHID hhid on hhid.EnrollmentID = n.EnrollmentID 
		group by n.PersonalID, hhid.ActiveHHType, hhid.ProjectType
		) latest on latest.PersonalID = n.PersonalID and latest.HHType = hhid.ActiveHHType
			and latest.ProjectType = hhid.ProjectType and latest.Age = n.ActiveAge
	inner join tlsa_CohortDates cd on cd.CohortEnd >= n.EntryDate
		  and (cd.CohortStart < n.ExitDate 
			or n.ExitDate is null
			or (n.ProjectType = 13 and n.ExitDate = cd.CohortStart and n.MoveInDate = cd.CohortStart))
	where n.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopType = 3 and pop.PopID between 113 and 144
		and (
			 --for RRH and PSH, count only people who are housed in period
			(n.ProjectType in (3,13) and n.MoveInDate <= cd.CohortEnd) 
			--for night-by-night ES, count only people with bednights in period
			or (n.TrackingMethod = 3 and n.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= n.EntryDate 
				and (bn.DateProvided < n.ExitDate or n.ExitDate is null))
			or (n.TrackingMethod = 0 and n.ProjectType = 1)
			or (n.ProjectType in (2,8))
			)
		and (
			(pop.PopID not between 113 and 128)
			or
			(latest.Age is not null)
			)
	group by cd.Cohort, pop.PopID, n.ProjectType, cd.ReportID
		, pop.HHType


	--Count people with specific characteristics for ES/SH/TH combined
	-- EXCEPT popIDs 113-144, which are limited to HoH and counted in next step
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct lp.PersonalID)
		, cd.Cohort, 16 
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID, -1, 55
		, cd.ReportID, '8.14.3'
	from tlsa_Person lp
	inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
			 or pop.CHTime is null)
		and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
		and (lp.DVStatus = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
		and (n.ActiveAge = pop.Age or pop.Age is null)
		and (lp.Gender = pop.Gender or pop.Gender is null)
		and (lp.Race = pop.Race or pop.Race is null)
		and (lp.Ethnicity = pop.Ethnicity or pop.Ethnicity is null)
	left outer join (select n.PersonalID, hhid.ActiveHHType as HHType, hhid.ProjectType, max(n.ActiveAge) as Age
		from tlsa_Enrollment n
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
		where hhid.ProjectType in (1,2,8)
		group by n.PersonalID, hhid.ActiveHHType, hhid.ProjectType
		) latest on latest.PersonalID = n.PersonalID and latest.HHType = hhid.ActiveHHType
			and latest.ProjectType = hhid.ProjectType and latest.Age = n.ActiveAge
	inner join tlsa_CohortDates cd on cd.CohortEnd >= n.EntryDate
		  and (cd.CohortStart < n.ExitDate 
			or n.ExitDate is null)
	where n.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopType = 3 and pop.PopID not between 113 and 144
		and (
			--for night-by-night ES, count only people with bednights in period
			(n.TrackingMethod = 3 and n.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= n.EntryDate 
				and (bn.DateProvided < n.ExitDate or n.ExitDate is null))
			or (n.TrackingMethod = 0 and n.ProjectType = 1)
			or (n.ProjectType in (2,8))
			)
		and 
			(
				(pop.PopID not between 24 and 34 and pop.PopID not between 145 and 148)
				or latest.Age is not null
			)
	group by cd.Cohort, pop.PopID, cd.ReportID
		, pop.HHType

	--Count people with specific characteristics for ES/SH/TH combined
	-- popIDs 113-144, which are limited to HoH 
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct lp.PersonalID)
		, cd.Cohort, 16 
		, coalesce(pop.HHType, 0) as HHType
		, pop.PopID, -1, 55
		, cd.ReportID, '8.14.4'
	from tlsa_Person lp
	inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID and hhid.HoHID = n.PersonalID
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
		and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
			 or pop.CHTime is null)
		and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
		and (lp.DVStatus = pop.HHFleeingDV or pop.HHFleeingDV is null)
		and (hhid.HHParent = pop.HHParent or pop.HHParent is null)
		and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
		and (n.ActiveAge = pop.Age or pop.Age is null)
		and (lp.Gender = pop.Gender or pop.Gender is null)
		and (lp.Race = pop.Race or pop.Race is null)
		and (lp.Ethnicity = pop.Ethnicity or pop.Ethnicity is null)
	left outer join (select n.PersonalID, hhid.ActiveHHType as HHType, hhid.ProjectType, max(n.ActiveAge) as Age
		from tlsa_Enrollment n
		inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID and hhid.HoHID = n.PersonalID
		where hhid.ProjectType in (1,2,8)
		group by n.PersonalID, hhid.ActiveHHType, hhid.ProjectType
		) latest on latest.PersonalID = n.PersonalID and latest.HHType = hhid.ActiveHHType
			and latest.ProjectType = hhid.ProjectType and latest.Age = n.ActiveAge
	inner join tlsa_CohortDates cd on cd.CohortEnd >= n.EntryDate
		  and (cd.CohortStart < n.ExitDate 
			or n.ExitDate is null)
	where n.Active = 1 and cd.Cohort between 1 and 13
		and pop.PopType = 3 and pop.PopID between 113 and 144
		and (
			--for night-by-night ES, count only people with bednights in period
			(n.TrackingMethod = 3 and n.ProjectType = 1
				and bn.DateProvided between cd.CohortStart and cd.CohortEnd
				and bn.DateProvided >= n.EntryDate 
				and (bn.DateProvided < n.ExitDate or n.ExitDate is null))
			or (n.TrackingMethod = 0 and n.ProjectType = 1)
			or (n.ProjectType in (2,8))
			)
		and 
			(pop.PopID not between 113 and 128
			or latest.Age is not null)	
	group by cd.Cohort, pop.PopID, cd.ReportID
		, pop.HHType

/*
	8.15 Get Counts of Bed Nights in Report Period by Project ID
*/
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.PersonalID + cast(est.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(rrhpsh.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(bnd.theDate as nvarchar))
		, 1, 10, coalesce(pop.HHType, 0)
		, pop.PopID, -1, 56
		, n.ProjectID
		, rpt.ReportID, '8.15'
	from tlsa_Enrollment n 
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and n.ProjectType = 1 and hhid.TrackingMethod = 3
		and bn.DateDeleted is null
	inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
	left outer join ref_Calendar est on est.theDate >= n.EntryDate
		and est.theDate >= rpt.ReportStart
		and est.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
		and ((n.ProjectType = 1 and n.TrackingMethod = 0)
				or n.ProjectType in (2,8))
	left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= n.MoveInDate
		and rrhpsh.theDate >= rpt.ReportStart
		and (rrhpsh.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
				or (n.ProjectType = 13 and rrhpsh.theDate = n.MoveinDate and rrhpsh.theDate = n.ExitDate))
		and n.ProjectType in (3,13)
	left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
		and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
		and n.ProjectType = 1 and n.TrackingMethod = 3
	where hhid.Active = 1 and  pop.PopID in (0,1,2) and pop.SystemPath is null and pop.PopType = 1
	group by n.ProjectID, rpt.ReportID, pop.PopID, pop.HHType

/*
	8.16 Get Counts of Bed Nights in Report Period by Project Type
*/
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct n.PersonalID + cast(est.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(rrhpsh.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(bnd.theDate as nvarchar))
		, 1, case n.ProjectType 
			when 1 then 11 
			when 8 then 12	
			when 2 then 13	
			when 13 then 14	
			else 15 end 
		, coalesce(pop.HHType, 0)
		, pop.PopID, -1, 56
		, rpt.ReportID, '8.16.1'
	from tlsa_Enrollment n 
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null
	inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
	left outer join ref_Calendar est on est.theDate >= n.EntryDate
		and est.theDate >= rpt.ReportStart
		and est.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
		and ((n.ProjectType = 1 and n.TrackingMethod = 0)
				or n.ProjectType in (2,8))
	left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= n.MoveInDate
		and rrhpsh.theDate >= rpt.ReportStart
		and (rrhpsh.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
				or (n.ProjectType = 13 and rrhpsh.theDate = n.MoveinDate and rrhpsh.theDate = n.ExitDate))
		and n.ProjectType in (3,13)
	left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
		and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
		and n.ProjectType = 1 and n.TrackingMethod = 3
	where hhid.Active = 1 and pop.PopID in (0,1,2) and pop.SystemPath is null and pop.PopType = 1
	group by rpt.ReportID, pop.PopID, pop.HHType, n.ProjectType

	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct n.PersonalID + cast(est.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(bnd.theDate as nvarchar))
		, 1, 16
		, coalesce(pop.HHType, 0)
		, pop.PopID, -1, 56
		, rpt.ReportID, '8.16.2'
	from tlsa_Enrollment n 
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and (hhid.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null
	inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
	left outer join ref_Calendar est on est.theDate >= n.EntryDate
		and est.theDate >= rpt.ReportStart
		and est.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
		and ((n.ProjectType = 1 and n.TrackingMethod = 0)
				or n.ProjectType in (2,8))
	left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
		and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
		and n.ProjectType = 1 and n.TrackingMethod = 3
	where hhid.Active = 1 and pop.PopID in (0,1,2) and pop.SystemPath is null and pop.PopType = 1
		and n.ProjectType in (1,8,2)
	group by rpt.ReportID, pop.PopID, pop.HHType

/*
	8.17 Get Counts of Bed Nights in Report Period by Project ID/Personal Char
*/
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.PersonalID + cast(est.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(rrhpsh.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(bnd.theDate as nvarchar))
		, 1, 10, coalesce(pop.HHType, 0)
		, pop.PopID, -1, 57
		, n.ProjectID
		, rpt.ReportID, '8.17'
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
			 or pop.CHTime is null)
		and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
		and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null
	inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
	left outer join ref_Calendar est on est.theDate >= n.EntryDate
		and est.theDate >= rpt.ReportStart
		and est.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
		and ((n.ProjectType = 1 and n.TrackingMethod = 0)
				or n.ProjectType in (2,8))
	left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= n.MoveInDate
		and rrhpsh.theDate >= rpt.ReportStart
		and (rrhpsh.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
				or (n.ProjectType = 13 and rrhpsh.theDate = n.MoveinDate and rrhpsh.theDate = n.ExitDate))
		and n.ProjectType in (3,13)
	left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
		and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
		and n.ProjectType = 1 and n.TrackingMethod = 3
	where n.Active = 1 and pop.PopID in (3,6) and pop.PopType = 3
	group by n.ProjectID, rpt.ReportID, pop.PopID, pop.HHType

/*
	8.18 Get Counts of Bed Nights in Report Period by Project Type/Personal Char
*/
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct n.PersonalID + cast(est.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(rrhpsh.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(bnd.theDate as nvarchar))
		, 1, case n.ProjectType 
			when 1 then 11 
			when 8 then 12	
			when 2 then 13	
			when 13 then 14	
			else 15 end 
		, coalesce(pop.HHType, 0)
		, pop.PopID, -1, 57
		, rpt.ReportID, '8.18.1'
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
			 or pop.CHTime is null)
		and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
		and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null
	inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
	left outer join ref_Calendar est on est.theDate >= n.EntryDate
		and est.theDate >= rpt.ReportStart
		and est.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
		and ((n.ProjectType = 1 and n.TrackingMethod = 0)
				or n.ProjectType in (2,8))
	left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= n.MoveInDate
		and rrhpsh.theDate >= rpt.ReportStart
		and (rrhpsh.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
				or (n.ProjectType = 13 and rrhpsh.theDate = n.MoveinDate and rrhpsh.theDate = n.ExitDate))
		and n.ProjectType in (3,13)
	left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
		and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
		and n.ProjectType = 1 and n.TrackingMethod = 3
	where n.Active = 1 and pop.PopID in (3,6) and pop.PopType = 3
	group by rpt.ReportID, pop.PopID, pop.HHType, n.ProjectType

	--ES/SH/TH unduplicated
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ReportID, Step)
	select count (distinct n.PersonalID + cast(est.theDate as nvarchar))
		+ count (distinct n.PersonalID + cast(bnd.theDate as nvarchar))
		, 1, 16
		, coalesce(pop.HHType, 0)
		, pop.PopID, -1, 57
		, rpt.ReportID, '8.18.2'
	from tlsa_Enrollment n 
	inner join tlsa_Person lp on lp.PersonalID = n.PersonalID
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join ref_Populations pop on
		(hhid.ActiveHHType = pop.HHType or pop.HHType is null)
		and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
			 or pop.CHTime is null)
		and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
		and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
	left outer join hmis_Services bn on bn.EnrollmentID = hhid.EnrollmentID
		and bn.RecordType = 200
		and bn.DateProvided >= n.EntryDate and (bn.DateProvided < n.ExitDate or n.ExitDate is null)
		and bn.DateDeleted is null
	inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
	left outer join ref_Calendar est on est.theDate >= n.EntryDate
		and est.theDate >= rpt.ReportStart
		and est.theDate < coalesce(n.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
		and ((n.ProjectType = 1 and n.TrackingMethod = 0)
				or n.ProjectType in (2,8))
	left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
		and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
		and n.ProjectType = 1 and n.TrackingMethod = 3
	where n.Active = 1 and pop.PopID in (3,6) and pop.PopType = 3
		and n.ProjectType in (1,8,2)
	group by rpt.ReportID, pop.PopID, pop.HHType

/*
	8.19 Get Counts of Enrollments Active after Operating End Date by ProjectID
*/
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct n.EnrollmentID), 20, 10, 0, 0, -1
		, case when hx.ExitDate is null then 58
			else 59 end 
		, p.ProjectID, cd.ReportID, '8.19'
	from tlsa_Enrollment n
	left outer join hmis_Exit hx on hx.EnrollmentID = n.EnrollmentID 
		and hx.DateDeleted is null
	inner join hmis_Project p on p.ProjectID = n.ProjectID 
	inner join tlsa_CohortDates cd on cd.Cohort = 20 and p.OperatingEndDate between cd.CohortStart and cd.CohortEnd
	where (hx.ExitDate is null or hx.ExitDate > p.OperatingEndDate)
		and p.ProjectType in (1,2,3,8,13)
	group by case when hx.ExitDate is null then 58
			else 59 end 
		, p.ProjectID, cd.ReportID

/*
	8.20 Get Counts of Night-by-Night Enrollments with Exit Date Discrepancies
*/
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct hn.EnrollmentID), 20, 10, 0, 0, -1
		, case when hx.ExitDate is null then 60
			else 61 end 
		, p.ProjectID, cd.ReportID, '8.20'
	from tlsa_Enrollment n
	inner join tlsa_CohortDates cd on cd.Cohort = 20
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
	inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID 
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
		and hx.DateDeleted is NULL
	inner join hmis_Project p on p.ProjectID = hn.ProjectID and p.ProjectType = 1 and p.TrackingMethod = 3 and p.ContinuumProject = 1
	left outer join (select distinct svc.EnrollmentID, max(svc.DateProvided) as LastBednight
		from hmis_Services svc
		inner join hmis_Enrollment nbn on nbn.EnrollmentID = svc.EnrollmentID
		inner join hmis_Project p on p.ProjectID = nbn.ProjectID 
			and p.ProjectType = 1 and p.TrackingMethod = 3 
			and (p.OperatingEndDate is null or p.OperatingEndDate >= DateProvided)
		inner join tlsa_CohortDates cd on cd.Cohort = 20 
			and svc.DateProvided between cd.CohortStart and cd.CohortEnd
		where svc.RecordType = 200 and svc.DateDeleted is null
		group by svc.EnrollmentID
		) bn on bn.EnrollmentID = hhid.EnrollmentID
	where (hx.ExitDate is null and bn.LastBednight <= dateadd(dd, -90, cd.CohortEnd))
		or (hx.ExitDate <> dateadd(dd, 1, bn.LastBednight))
	group by case when hx.ExitDate is null then 60
			else 61 end 
		, p.ProjectID, cd.ReportID

/*
	8.21 Get Counts of Households with no Enrollment CoC Record
*/
	insert into lsa_Calculated
		(Value, Cohort, Universe, HHType
		, Population, SystemPath, ReportRow, ProjectID, ReportID, Step)
	select count (distinct hn.HouseholdID), 1, 10, 0, 0, -1, 62, p.ProjectID, rpt.ReportID, '8.21'
	from lsa_Report rpt
	inner join hmis_Enrollment hn on hn.EntryDate <= rpt.ReportEnd
	inner join lsa_Project p on p.ProjectID = hn.ProjectID and p.ProjectType not in (9,10)
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID 
		and hx.DateDeleted is null
	left outer join hmis_Enrollment hoh on hoh.HouseholdID = hn.HouseholdID 
		and hoh.RelationshipToHoH = 1 
		and hoh.DateDeleted is null
	left outer join (select distinct coc.EnrollmentID, coc.InformationDate, coc.CoCCode
					from hmis_EnrollmentCoC coc
					where coc.CoCCode is not null
						and coc.DateDeleted is null) coccode on coccode.EnrollmentID = hoh.EnrollmentID 
						and coccode.InformationDate <= rpt.ReportEnd 
	where hn.DateDeleted is null 
		and coccode.CoCCode is null
		and (hx.ExitDate is null or 
				(hx.ExitDate >= rpt.ReportStart and hx.ExitDate > hn.EntryDate))
	group by p.ProjectID, rpt.ReportID

	/*
		
		NOTE:  Export of lsa_Calculated data to LSACalculated.csv has to exclude the Step column.

		alter lsa_Calculated drop column Step

		select Value, Cohort, Universe, HHType, Population, SystemPath, ProjectID, ReportRow, ReportID
		from lsa_Calculated
	*/