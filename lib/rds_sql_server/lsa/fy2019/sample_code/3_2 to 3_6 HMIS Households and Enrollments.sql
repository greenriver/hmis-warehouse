/*
LSA FY2019 Sample Code

Name:  3_2 to 3_6 HMIS Households and Enrollments.sql 

Date:	4/16/2020 -- original 
		4/30/2020 -- create two separate scripts from original file (3_1 to 3_6 households and enrollments.sql):
					 - 3_1 LSAReport Parameters and Vendor Info Hardcoded Sample Data.sql
				     - 3_2 to 3_6 HMIS Households and Enrollments.sql
		5/14/2020 -- 3.3 - HoH enrollment EntryDate must be prior to project OperatingEndDate
					     - Exit destination must be 99 when effective exit date differs from HMIS
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
	, LastBedNight)
select distinct hoh.HouseholdID, hoh.PersonalID, hoh.EnrollmentID
	, hoh.ProjectID, p.ProjectType, p.TrackingMethod
	, hoh.EntryDate 
	, case when hoh.MoveInDate > rpt.ReportEnd 
			or p.ProjectType not in (3,13) 
			or hoh.MoveInDate < hoh.EntryDate then null
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
where hoh.RelationshipToHoH = 1
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
			when hx.Destination in (14,29,32) then 10	--Temporary - not homeless
			when hx.Destination in (1,2,18,27) then 11	--Homeless - ES/SH/TH
			when hx.Destination = 16 then 12	--Homeless - Street
			when hx.Destination = 12 then 13	--Family - temp
			when hx.Destination = 13 then 14	--Friends - temp
			when hx.Destination = 24 then 15	--Deceased
			else 99	end
		from tlsa_HHID hhid
		left outer join hmis_Exit hx on hx.EnrollmentID = hhid.EnrollmentID
			and hx.ExitDate = hhid.ExitDate 
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
		, EntryDate, MoveInDate, ExitDate
		, EntryAge
		, DisabilityStatus, DVStatus)
	select distinct hn.EnrollmentID, hn.PersonalID, hn.HouseholdID
		, hn.RelationshipToHoH
		, hhid.ProjectID, hhid.ProjectType, hhid.TrackingMethod
		, hn.EntryDate
		, case when hhid.MoveInDate < hn.EntryDate then hn.EntryDate
			when hhid.MoveInDate > hx.ExitDate then NULL
			when hhid.MoveInDate = hx.ExitDate and 
				(hhid.ExitDate is NULL or hhid.ExitDate > hx.ExitDate) then NULL
			else hhid.MoveInDate end 
		, case when hx.ExitDate >= hhid.ExitDate then hhid.ExitDate
			when hx.ExitDate is NULL and hhid.ExitDate is not NULL then hhid.ExitDate
			else hx.ExitDate end
		, case when c.DOBDataQuality in (8,9) then 98
			when c.DOB is null 
				or c.DOB = '1/1/1900'
				or c.DOB > hn.EntryDate
				or (hn.RelationshipToHoH = 1 and c.DOB = hn.EntryDate)
				or DATEADD(yy, 105, c.DOB) <= hn.EntryDate 
				or c.DOBDataQuality is null
				or c.DOBDataQuality not in (1,2) then 99
			when DATEADD(yy, 65, c.DOB) <= hn.EntryDate then 65
			when DATEADD(yy, 55, c.DOB) <= hn.EntryDate then 64
			when DATEADD(yy, 45, c.DOB) <= hn.EntryDate then 54
			when DATEADD(yy, 35, c.DOB) <= hn.EntryDate then 44
			when DATEADD(yy, 25, c.DOB) <= hn.EntryDate then 34
			when DATEADD(yy, 22, c.DOB) <= hn.EntryDate then 24
			when DATEADD(yy, 18, c.DOB) <= hn.EntryDate then 21
			when DATEADD(yy, 6, c.DOB) <= hn.EntryDate then 17
			when DATEADD(yy, 3, c.DOB) <= hn.EntryDate then 5
			when DATEADD(yy, 1, c.DOB) <= hn.EntryDate then 2
			else 0 end 	
		, case when hn.DisablingCondition in (0,1) then hn.DisablingCondition 
			else null end
		, dvstat.DVStatus 
	from tlsa_HHID hhid
	inner join hmis_Enrollment hn on hn.HouseholdID = hhid.HouseholdID
	inner join hmis_Client c on c.PersonalID = hn.PersonalID 
	inner join lsa_Report rpt on rpt.ReportEnd >= hn.EntryDate
	left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID	
		and hx.ExitDate <= rpt.ReportEnd
	left outer join (select dv.EnrollmentID, min(case when dv.DomesticViolenceVictim = 1 and dv.CurrentlyFleeing = 1 then 1
			when dv.DomesticViolenceVictim = 1 and dv.CurrentlyFleeing = 0 then 2 
			when dv.DomesticViolenceVictim = 1 then 3
			when dv.DomesticViolenceVictim = 0 then 10
			when dv.DomesticViolenceVictim in (8,9) then 98
			else null end) as DVStatus
		from hmis_HealthAndDV dv
		inner join lsa_Report rpt on rpt.ReportEnd >= dv.InformationDate
		group by dv.EnrollmentID) dvstat on dvstat.EnrollmentID = hn.EnrollmentID 
	where hn.RelationshipToHoH in (1,2,3,4,5)
		and hn.EntryDate between hhid.EntryDate and isnull(hhid.ExitDate, rpt.ReportEnd)
		and (hx.ExitDate is null or 
				(hx.ExitDate > hhid.EntryDate and hx.ExitDate >= '10/1/2012'
					and hx.ExitDate > hn.EntryDate)) 

/*
	3.5 Enrollment Ages - Active and Exit
		NOTE:  EntryAge is included in the 3.4 insert statement
*/
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
	from lsa_Report rpt
	inner join tlsa_Enrollment n on n.EntryDate <= rpt.ReportEnd 
		and (n.ExitDate is null or n.ExitDate >= rpt.ReportStart)
	inner join hmis_Client c on c.PersonalID = n.PersonalID

	update n
	set n.Exit1Age = case when n.ExitDate < cd.CohortStart
				or n.EntryDate > cd.CohortEnd
				or n.EntryDate between cd.CohortStart and cd.CohortEnd 
					and n.ExitDate between cd.CohortStart and cd.CohortEnd
				or n.EntryAge in (98,99) then n.EntryAge
			--  If exit is prior to cohort start, age is unknown, 
			--		or entry is in cohort period, use EntryAge; 
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
	from tlsa_CohortDates cd
	inner join tlsa_Enrollment n on n.EntryDate <= cd.CohortEnd 
		and (n.ExitDate is null or n.ExitDate >= cd.CohortStart)
	inner join hmis_Client c on c.PersonalID = n.PersonalID
	where cd.Cohort = -1

	update n
	set n.Exit2Age = case when n.ExitDate < cd.CohortStart
				or n.EntryDate > cd.CohortEnd
				or n.EntryDate between cd.CohortStart and cd.CohortEnd 
					and n.ExitDate between cd.CohortStart and cd.CohortEnd
				or n.EntryAge in (98,99) then n.EntryAge
			--  If exit is prior to cohort start, age is unknown, 
			--		or entry is in cohort period, use EntryAge; 
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
	from tlsa_CohortDates cd
	inner join tlsa_Enrollment n on n.EntryDate <= cd.CohortEnd 
		and (n.ExitDate is null or n.ExitDate >= cd.CohortStart)
	inner join hmis_Client c on c.PersonalID = n.PersonalID
	where cd.Cohort = -2

/*
	3.6 Household Types
*/
	
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
	from tlsa_HHID hhid 
	inner join lsa_Report rpt on rpt.ReportEnd >= hhid.EntryDate 
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.ActiveAge between 18 and 65
		and (adult.ExitDate is null or hhid.ExitDate >= rpt.ReportStart)
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.ActiveAge < 18
		and (child.ExitDate is null or hhid.ExitDate >= rpt.ReportStart)
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.ActiveAge in (98,99)
		and (noDOB.ExitDate is null or hhid.ExitDate >= rpt.ReportStart)

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
	from tlsa_HHID hhid
	inner join tlsa_CohortDates cd on cd.CohortEnd <> hhid.EntryDate and cd.Cohort = -2
	left outer join tlsa_Enrollment adult on adult.HouseholdID = hhid.HouseholdID 
		and adult.Exit2Age between 18 and 65 and adult.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment child on child.HouseholdID = hhid.HouseholdID 
		and child.Exit2Age < 18 and child.ExitDate between cd.CohortStart and cd.CohortEnd
	left outer join tlsa_Enrollment noDOB on noDOB.HouseholdID = hhid.HouseholdID 
		and noDOB.Exit2Age in (98,99) and noDOB.ExitDate between cd.CohortStart and cd.CohortEnd