/*
LSA FY2019 Sample Code

Name:  3_2 to 3_6 HMIS Households and Enrollments.sql 

Date:	4/16/2020 -- original 
		4/30/2020 -- create two separate scripts from original file (3_1 to 3_6 households and enrollments.sql):
					 - 3_1 LSAReport Parameters and Vendor Info Hardcoded Sample Data.sql
				     - 3_2 to 3_6 HMIS Households and Enrollments.sql
		5/14/2020 -- 3.3 - HoH enrollment EntryDate must be prior to project OperatingEndDate
					     - Exit destination must be 99 when effective exit date differs from HMIS
		5/21/2020 -- set value for Step columns in sections 3.3-3.6
		5/28/2020 -- section 3.3 
						- INSERT statement to tlsa_HHID:
							- include 'hoh.MoveInDate > p.OperatingEndDate' in CASE statement list of conditions
								where tlsa_HHID.MoveInDate should be set to NULL
						- UPDATE statement to set ExitDest:
							- correct host home destination (HMIS value 32) from LSA category 10 to 11
							- remove 'hx.ExitDate = hhid.ExitDate' from left outer join to hmis_Exit 
				  -- section 3.4 - set DVStatus for tlsa_Enrollment in a separate step after INSERT 
									to ensure records are dated prior to ExitDate (actual or effective) if it exists
				  -- 3.5.2 and 3.5.3 - add missing parentheses to CASE
				  -- 3.6.2 - corrected table aliases in joins for adult/child/noDOB ExitDate
		6/4/2020 -- 3.5.1/2/3 -- corrections to FROM joins so that ActiveAge, Exit1Age, and Exit2Age are calculated for all enrollments
						and not just for those active during the relevant cohort period.
					3.5.2/3 -- simplified CASE statement/removed redundancies - no change to output
					3.3.1 - correction so that all enrollments located in ReportCoC at any time are included in tlsa_HHID 
							instead of limiting it to enrollment in ReportCoC as of the most recent EnrollmentCoC record.
		7/2/2020 - 3.3.1 - add 'and p.ContinuumProject = 1' -- was inadvertently deleted on a previous update
		8/6/2020 - 3.5.2 and 3.5.3 - align Exit1/Exit2Age calculation to specs
					3.3.1, 3.4.1, 3.4.2 - specify DateDeleted is null 
		8/13/2020 - 3.3.1 - Project's operating end date must be null or after start date in order to include in LSA
					3.4.1 - if HH member EntryDate < HoH EntryDate, insert enrollment to tlsa_Enrollment w/ HoH EntryDate
						(required per specs section 3.3 -- code was omitting these enrollments altogether)
					3.5.2 and 3.5.3 - use EntryAge when ExitDate is NULL (case statement) 
		8/19/2020 - 3.4.1 - specify DateDeleted is NULL for hmis_Exit join
						  - remove EntryAge calculation from INSERT to tlsa_Enrollment 
					3.4.2 - calculate EntryAge based on tlsa_Enrollment.EntryDate instead of hmis_Enrollment
							(values may differ since 8/13/2020 change to 3.4.1)
					3.4.3 - re-number step from 3.4.2
		8/27/2020 - 3.4 -- use the effective EntryDate as the basis for comparisons to/setting of MoveInDate rather 
							than the raw HMIS value.  Split set of MoveInDate in tlsa_Enrollment into a separate step AFTER 
							insert of records to simplify this and re-numbered steps.  
		9/10/2020 - 3.5.1 - if a person's DOB is invalidated for any enrollment, age is considered unknown for all.

	3.2 Cohort Dates 
*/
	delete from tlsa_CohortDates

	insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, ReportID)
	select 1, rpt.ReportStart, rpt.ReportEnd, rpt.ReportID
	from lsa_Report rpt

	insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, ReportID)
	select 0, rpt.ReportStart,
		case when dateadd(mm, -6, rpt.ReportEnd) <= rpt.ReportStart 
			then rpt.ReportEnd
			else dateadd(mm, -6, rpt.ReportEnd) end
		, rpt.ReportID
	from lsa_Report rpt

	insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, ReportID)
	select -1, dateadd(yyyy, -1, rpt.ReportStart)
		, dateadd(yyyy, -1, rpt.ReportEnd)
		, rpt.ReportID
	from lsa_Report rpt

	insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, ReportID)
	select -2, dateadd(yyyy, -2, rpt.ReportStart)
		, dateadd(yyyy, -2, rpt.ReportEnd)
		, rpt.ReportID
	from lsa_Report rpt

	insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, ReportID)
	select distinct case cal.mm 
		when 10 then 10
		when 1 then 11 
		when 4 then 12 
		else 13 end
		, cal.theDate
		, cal.theDate
		, rpt.ReportID
	from lsa_Report rpt 
	inner join ref_Calendar cal 
		on cal.theDate between rpt.ReportStart and rpt.ReportEnd
	where (cal.mm = 10 and cal.dd = 31 and cal.yyyy = year(rpt.ReportStart))
		or (cal.mm = 1 and cal.dd = 31 and cal.yyyy = year(rpt.ReportEnd))
		or (cal.mm = 4 and cal.dd = 30 and cal.yyyy = year(rpt.ReportEnd))
		or (cal.mm = 7 and cal.dd = 31 and cal.yyyy = year(rpt.ReportEnd))

	insert into tlsa_CohortDates (Cohort, CohortStart, CohortEnd, ReportID)
	select 20, dateadd(dd, 1, dateadd(yyyy, -3, rpt.ReportEnd)), rpt.ReportEnd, rpt.ReportID
	from lsa_Report rpt

/*
	3.3 HMIS HouseholdIDs 
*/
delete from tlsa_HHID

insert into tlsa_HHID (
	  HouseholdID, HoHID, EnrollmentID
	, ProjectID, ProjectType, TrackingMethod
	, EntryDate
	, MoveInDate
	, ExitDate
	, LastBedNight
	, Step)
select distinct hoh.HouseholdID, hoh.PersonalID, hoh.EnrollmentID
	, hoh.ProjectID, p.ProjectType, p.TrackingMethod
	, hoh.EntryDate 
	, case when hoh.MoveInDate > rpt.ReportEnd 
			or p.ProjectType not in (3,13) 
			or hoh.MoveInDate < hoh.EntryDate 
			or hoh.MoveInDate > p.OperatingEndDate then null
		when p.ProjectType = 3 and (hoh.MoveInDate < hx.ExitDate or hx.ExitDate is null) 
			then hoh.MoveInDate
		when p.ProjectType = 13 and (hoh.MoveInDate <= hx.ExitDate or hx.ExitDate is null) 
			then hoh.MoveInDate
		else null end
	, case when p.ProjectType = 1 and p.TrackingMethod = 3 and hx.ExitDate > dateadd(dd, 1, bn.LastBednight)
			then dateadd(dd, 1, bn.LastBednight)
		when p.ProjectType = 1 and p.TrackingMethod = 3 and hx.ExitDate is null 
			and dateadd(dd, 90, bn.LastBednight) <= rpt.ReportEnd then dateadd(dd, 1, bn.LastBednight) 
		when p.OperatingEndDate <= rpt.ReportEnd and hx.ExitDate is null then p.OperatingEndDate
		else hx.ExitDate end
	, bn.LastBednight
	, '3.3.1'
from hmis_Enrollment hoh
inner join lsa_Report rpt on rpt.ReportEnd >= hoh.EntryDate
inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hoh.EnrollmentID 
	and coc.CoCCode = rpt.ReportCoC and coc.InformationDate <= rpt.ReportEnd
	and coc.DateDeleted is null
inner join hmis_Project p on p.ProjectID = hoh.ProjectID
	and p.DateDeleted is null
left outer join hmis_Exit hx on hx.EnrollmentID = hoh.EnrollmentID
	and hx.ExitDate <= rpt.ReportEnd 
	and (hx.ExitDate <= p.OperatingEndDate or p.OperatingEndDate is null)
	and hx.DateDeleted is null
left outer join hmis_Enrollment hohCheck on hohCheck.HouseholdID = hoh.HouseholdID
	and hohCheck.RelationshipToHoH = 1 and hohCheck.EnrollmentID <> hoh.EnrollmentID
	and hohCheck.DateDeleted is null
left outer join (select distinct svc.EnrollmentID, max(svc.DateProvided) as LastBednight
		from hmis_Services svc
		inner join hmis_Enrollment nbn on nbn.EnrollmentID = svc.EnrollmentID
		left outer join hmis_Exit nbnx on nbnx.EnrollmentID = nbn.EnrollmentID
		inner join hmis_Project p on p.ProjectID = nbn.ProjectID 
			and p.ProjectType = 1 and p.TrackingMethod = 3 
			and (p.OperatingEndDate is null or p.OperatingEndDate >= DateProvided)
		inner join lsa_Report rpt on svc.DateProvided between '10/1/2012' and rpt.ReportEnd
		where svc.RecordType = 200 and svc.DateDeleted is null
			and svc.DateProvided >= nbn.EntryDate 
			and (nbnx.ExitDate is null or svc.DateProvided < nbnx.ExitDate)
		group by svc.EnrollmentID
		) bn on bn.EnrollmentID = hoh.EnrollmentID
where hoh.DateDeleted is null
	and hoh.RelationshipToHoH = 1
	and hohCheck.EnrollmentID is null 
	and p.ContinuumProject = 1 
	and (p.OperatingEndDate is null 
		-- 5/14/2020 EntryDate must be prior to OperatingEndDate
		or (hoh.EntryDate < p.OperatingEndDate and p.OperatingEndDate >= '10/1/2012'))
	and	(hx.ExitDate is null or 
			(hx.ExitDate >= '10/1/2012' and hx.ExitDate > hoh.EntryDate) 
		)
	and ((p.ProjectType in (2,3,8,13))
			or (p.ProjectType = 1 and p.TrackingMethod = 0)
			or (p.ProjectType = 1 and p.TrackingMethod = 3 and bn.LastBednight is not null)
		)

		update hhid
		set hhid.ExitDest = case	
				-- 5/14/2020 exit destination must be 99 when the effective exit date differs from HMIS
				when hx.ExitDate is null or hx.ExitDate <> hhid.ExitDate then 99
				when hx.Destination = 3 then 1 --PSH
				when hx.Destination = 31 then 2	--PH - rent/temp subsidy
				when hx.Destination in (19,20,21,26,28,33,34) then 3	--PH - rent/own with subsidy
				when hx.Destination in (10,11) then 4	--PH - rent/own no subsidy
				when hx.Destination = 22 then 5	--Family - perm
				when hx.Destination = 23 then 6	--Friends - perm
				when hx.Destination in (15,25) then 7	--Institutions - group/assisted
				when hx.Destination in (4,5,6) then 8	--Institutions - medical
				when hx.Destination = 7 then 9	--Institutions - incarceration
				when hx.Destination in (14,29) then 10	--Temporary - not homeless
				when hx.Destination in (1,2,18,27,32) then 11	--Homeless - ES/SH/TH/host home
				when hx.Destination = 16 then 12	--Homeless - Street
				when hx.Destination = 12 then 13	--Family - temp
				when hx.Destination = 13 then 14	--Friends - temp
				when hx.Destination = 24 then 15	--Deceased
				else 99	end
			, hhid.Step = '3.3.2'
		from tlsa_HHID hhid
		left outer join hmis_Exit hx on hx.EnrollmentID = hhid.EnrollmentID
			and hx.DateDeleted is null 
		where hhid.ExitDate is not null	

/*
	3.4  HMIS Client Enrollments
*/
	delete from tlsa_Enrollment

	insert into tlsa_Enrollment 
		(EnrollmentID, PersonalID, HouseholdID
		, RelationshipToHoH
		, ProjectID, ProjectType, TrackingMethod
		, EntryDate, ExitDate
		, DisabilityStatus
		, Step)
	select distinct hn.EnrollmentID, hn.PersonalID, hn.HouseholdID
		, hn.RelationshipToHoH
		, hhid.ProjectID, hhid.ProjectType, hhid.TrackingMethod
		, case when hhid.EntryDate > hn.EntryDate then hhid.EntryDate else hn.EntryDate end
		, case when hx.ExitDate >= hhid.ExitDate then hhid.ExitDate
			when hx.ExitDate is NULL and hhid.ExitDate is not NULL then hhid.ExitDate
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
	where hn.RelationshipToHoH in (1,2,3,4,5)
		and hn.EntryDate <= isnull(hhid.ExitDate, rpt.ReportEnd)
		and (hx.ExitDate is null or 
				(hx.ExitDate > hhid.EntryDate and hx.ExitDate >= '10/1/2012'
					and hx.ExitDate > hn.EntryDate)) 

	update n 
	set n.MoveInDate = 	case when hhid.MoveInDate < n.EntryDate then n.EntryDate
			when hhid.MoveInDate > n.ExitDate then NULL
			when hhid.MoveInDate = n.ExitDate and 
				(hhid.ExitDate is NULL or hhid.ExitDate > n.ExitDate) then NULL
			else hhid.MoveInDate end 
		, Step = '3.4.2'
	from tlsa_Enrollment n
	inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID

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
	, n.Step = '3.4.3'
from tlsa_Enrollment n
inner join hmis_Client c on c.PersonalID = n.PersonalID

	update n
	set n.DVStatus = (select min(case when dv.DomesticViolenceVictim = 1 and dv.CurrentlyFleeing = 1 then 1
				when dv.DomesticViolenceVictim = 1 and dv.CurrentlyFleeing = 0 then 2 
				when dv.DomesticViolenceVictim = 1 then 3
				when dv.DomesticViolenceVictim = 0 then 10
				when dv.DomesticViolenceVictim in (8,9) then 98
				else null end) 
			from lsa_Report rpt 
			inner join hmis_HealthAndDV dv on dv.EnrollmentID = n.EnrollmentID 
				 and dv.DateDeleted is null
				 and dv.InformationDate <= rpt.ReportEnd
				 and (dv.InformationDate <= n.ExitDate or n.ExitDate is null))
		, n.Step = '3.4.4'
	from tlsa_Enrollment n

/*
	3.5 Enrollment Ages - Active and Exit
		NOTE:  EntryAge is included in the 3.4 insert statement
*/

	update n
	set n.EntryAge = 99, n.Step = '3.5.1'
	from tlsa_Enrollment n
	inner join tlsa_Enrollment DOBIssue on DOBIssue.PersonalID = n.PersonalID
		and DOBIssue.EntryAge = 99

	update n
	set n.ActiveAge = case when n.ExitDate < rpt.ReportStart
				or n.EntryDate >= rpt.ReportStart 
				or n.EntryAge in (98,99) then n.EntryAge
			--  If enrollment is inactive, age is unknown, 
			--		or entry is in report period, use EntryAge; 
			--  Otherwise, recalculate age as of ReportStart 
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
		, n.Step = '3.5.2'
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd 
	inner join hmis_Client c on c.PersonalID = n.PersonalID

	update n
	set n.Exit1Age = case when (n.ExitDate not between cd.CohortStart and cd.CohortEnd or n.ExitDate is null)
				or (n.ExitDate between cd.CohortStart and cd.CohortEnd and n.EntryDate >= cd.CohortStart)
				or n.EntryAge in (98,99) then n.EntryAge
			--  If exit is prior to cohort start, age is unknown, 
			--		or entry is in or after cohort period, use EntryAge; 
			--  Otherwise, recalculate age as of CohortStart 
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
		, n.Step = '3.5.3'
	from  tlsa_Enrollment n
	inner join tlsa_CohortDates cd on cd.Cohort = -1 
	inner join hmis_Client c on c.PersonalID = n.PersonalID

	update n
	set n.Exit2Age = case when (n.ExitDate not between cd.CohortStart and cd.CohortEnd or n.ExitDate is null)
				or (n.ExitDate between cd.CohortStart and cd.CohortEnd and n.EntryDate >= cd.CohortStart)
				or n.EntryAge in (98,99) then n.EntryAge
			--  If exit is prior to cohort start, age is unknown, 
			--		or entry is in or after cohort period, use EntryAge; 
			--  Otherwise, recalculate age as of CohortStart 
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
	inner join tlsa_CohortDates cd on cd.Cohort = -2 
	inner join hmis_Client c on c.PersonalID = n.PersonalID

/*
	3.6 Household Types
*/

-- Note:  Code here and elsewhere uses 'between 18 and 65' instead of 'between 21 and 65' because the output
--        is the same (there are no values of 18, 19, or 20) and it is easier to understand without consulting 
--		  the LSA Dictionary.
	update hhid
	set hhid.EntryHHType = case 
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is null
				and noDOB.EnrollmentID is null then 1
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is not null then 2
			when adult.EnrollmentID is null 
				and child.EnrollmentID is not null
				and noDOB.EnrollmentID is null then 3	
			else 99 end
		, hhid.Step = '3.6.1'
	from tlsa_HHID hhid 
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.EntryAge between 18 and 65
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.EntryAge < 18
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.EntryAge in (98,99)

	update hhid
	set hhid.ActiveHHType = case 
			when hhid.ExitDate < rpt.ReportStart 
				or hhid.EntryDate >= rpt.ReportStart then hhid.EntryHHType
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is null
				and noDOB.EnrollmentID is null then 1
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is not null then 2
			when adult.EnrollmentID is null 
				and child.EnrollmentID is not null
				and noDOB.EnrollmentID is null then 3	
			else 99 end
		, hhid.Step = '3.6.2'
	from tlsa_HHID hhid 
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate 
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.ActiveAge between 18 and 65
		and (adult.ExitDate is null or adult.ExitDate >= rpt.ReportStart)
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.ActiveAge < 18
		and (child.ExitDate is null or child.ExitDate >= rpt.ReportStart)
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.ActiveAge in (98,99)
		and (noDOB.ExitDate is null or noDOB.ExitDate >= rpt.ReportStart)

	update hhid
	set hhid.Exit1HHType = case 
			when hhid.ExitDate < cd.CohortStart 
				or hhid.EntryDate >= cd.CohortStart then hhid.EntryHHType 
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is null
				and noDOB.EnrollmentID is null then 1
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is not null then 2
			when adult.EnrollmentID is null 
				and child.EnrollmentID is not null
				and noDOB.EnrollmentID is null then 3	
			else 99 end
		, hhid.Step = '3.6.3'
	from tlsa_HHID hhid
	inner join tlsa_CohortDates cd on cd.CohortEnd <> hhid.EntryDate and cd.Cohort = -1
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.Exit1Age between 18 and 65 and adult.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.Exit1Age < 18 and child.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.Exit1Age in (98,99) and noDOB.ExitDate between cd.CohortStart and cd.CohortEnd

	update hhid
	set hhid.Exit2HHType = case 
			when hhid.ExitDate < cd.CohortStart 
				or hhid.EntryDate >= cd.CohortStart then hhid.EntryHHType 
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is null
				and noDOB.EnrollmentID is null then 1
			when adult.EnrollmentID is not null 
				and child.EnrollmentID is not null then 2
			when adult.EnrollmentID is null 
				and child.EnrollmentID is not null
				and noDOB.EnrollmentID is null then 3	
			else 99 end
		, hhid.Step = '3.6.4'
	from tlsa_HHID hhid
	inner join tlsa_CohortDates cd on cd.CohortEnd <> hhid.EntryDate and cd.Cohort = -2
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.Exit2Age between 18 and 65 and adult.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.Exit2Age < 18 and child.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.Exit2Age in (98,99) and noDOB.ExitDate between cd.CohortStart and cd.CohortEnd