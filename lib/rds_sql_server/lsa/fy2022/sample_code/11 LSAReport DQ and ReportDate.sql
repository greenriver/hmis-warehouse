/*
LSA FY2022 Sample Code
Name: 11 LSAReport DQ and ReportDate.sql

FY2022 Changes
		-Limit DQ to reporting period / active cohort
		-Remove counts and DQ columns for 3 year period 
		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

	Please note that if this code is used in production, the first statement in section 11.6 
	should be reviewed and updated if necessary to set SSNValid to 0 include any system default 
	for missing SSN values that would not be identified by the existing code.
	
	11.1 HMIS HouseholdIDs With No CoC Identifier Active in LSA Projects During Report Period
*/
update rpt
set rpt.NoCoC = (select count (distinct n.HouseholdID)
			from hmis_Enrollment n 
			inner join lsa_Project p on p.ProjectID = n.ProjectID
				and p.ProjectType in (1,2,3,8,13)
				and p.HMISParticipatingProject = 1
			inner join lsa_Organization org on org.OrganizationID = p.OrganizationID
				and org.VictimServiceProvider = 0
			inner join hmis_ProjectCoC pcoc on pcoc.ProjectID = p.ProjectID
				and pcoc.DateDeleted is null 
			left outer join hmis_EnrollmentCoC coc on 
				coc.HouseholdID = n.HouseholdID
				and coc.InformationDate <= rpt.ReportEnd
				and coc.CoCCode = pcoc.CoCCode
				and coc.DateDeleted is null 
			left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.DateDeleted is null
			where n.EntryDate <= rpt.ReportEnd 
				and (x.ExitDate is null or x.ExitDate >= rpt.ReportStart)
				and n.RelationshipToHoH = 1 
				and coc.CoCCode is null
				and n.DateDeleted is null 
			)
from lsa_Report rpt

/*
	11.2 HMIS HouseholdIDs Without Exactly One HoH Active in LSA Projects During Report Period
*/

update rpt
set rpt.NotOneHoH = (select count (distinct n.HouseholdID)
			from hmis_Enrollment n 
			inner join lsa_Project p on p.ProjectID = n.ProjectID
				and p.ProjectType in (1,2,3,8,13)
				and p.HMISParticipatingProject = 1
			inner join lsa_Organization org on org.OrganizationID = p.OrganizationID
				and org.VictimServiceProvider = 0
			left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID 
				and x.DateDeleted is null
			left outer join (select hn.HouseholdID, count(distinct hn.EnrollmentID) as hoh
				from hmis_Enrollment hn
				where hn.RelationshipToHoH = 1 and hn.DateDeleted is null 
				group by hn.HouseholdID
				) hoh on hoh.HouseholdID = n.HouseholdID
			where n.EntryDate <= rpt.ReportEnd 
				and (x.ExitDate is null or x.ExitDate >= rpt.ReportStart)
				and n.DateDeleted is null
				and (hoh.hoh <> 1 or hoh.HouseholdID is null)
				and (select top 1 coc.CoCCode
					from hmis_EnrollmentCoC coc
					where coc.HouseholdID = n.HouseholdID
						and coc.InformationDate <= rpt.ReportEnd
						and coc.DateDeleted is null
					order by coc.InformationDate desc) = rpt.ReportCoC
			)
from lsa_Report rpt

/*
	11.3 HMIS Enrollments Associated with LSA Households But Excluded from LSA Due to Invalid RelatioshipToHoH
*/

update rpt
set rpt.RelationshipToHoH = (select count(distinct hn.EnrollmentID)
			from hmis_Enrollment hn
			inner join tlsa_HHID hhid on hhid.HouseholdID = hn.HouseholdID	
			left outer join hmis_Exit x on x.EnrollmentID = hn.EnrollmentID 
					and x.DateDeleted is null
			where hhid.Active = 1 
				and hn.EntryDate <= rpt.ReportEnd 
				and (x.ExitDate is null or x.ExitDate >= rpt.ReportStart)
				and hn.DateDeleted is null
				and (hn.RelationshipToHoH is null or hn.RelationshipToHoH not in (1,2,3,4,5))
	)
from lsa_Report rpt

/*
	11.4 Invalid HMIS Move-In Dates for RRH and PSH Enrollments Included in LSA
*/

update rpt
set rpt.MoveInDate = 
	(select count(distinct hhid.EnrollmentID)
		from tlsa_HHID hhid
		inner join hmis_Enrollment hn on hn.EnrollmentID = hhid.EnrollmentID
		where hhid.LSAProjectType in (3,13)
			and hhid.Active = 1 
			and hhid.MoveInDate is null 
			and hn.MoveInDate is not NULL
	)
from lsa_Report rpt

/*
	11.5 Counts of Clients/Households/Enrollments 
*/

update rpt
set rpt.UnduplicatedClient = (select count(distinct PersonalID)
	from tlsa_Person)
	, rpt.HouseholdEntry = (select count(distinct HouseholdID)
		from tlsa_HHID 
		where Active = 1)
	, rpt.ClientEntry = (select count(distinct EnrollmentID)
		from tlsa_Enrollment 
		where Active = 1)
	, rpt.AdultHoHEntry = (select count(distinct EnrollmentID)
		from tlsa_Enrollment 
		where Active = 1
		and (ActiveAge between 18 and 65 or RelationshipToHoH = 1))
	, rpt.ClientExit = (select count(distinct EnrollmentID)
		from tlsa_Enrollment 
		where Active = 1 and ExitDate is not NULL)
from lsa_Report rpt

/*
	11.6 SSN Issues 
*/

update lp
set lp.SSNValid = case when c.SSNDataQuality in (8,9) then 9
		when SUBSTRING(c.SSN,1,3) in ('000','666')
				or LEN(c.SSN) <> 9
				or SUBSTRING(c.SSN,4,2) = '00'
				or SUBSTRING(c.SSN,6,4) ='0000'
				or c.SSN is null
				or c.SSN = ''
				or c.SSN like '%[^0-9]%'
				or left(c.SSN,1) = '9'
				or c.SSN in ('123456789','111111111','222222222','333333333','444444444'
						,'555555555','777777777','888888888')
			then 0 else 1 end 
from tlsa_Person lp
inner join hmis_Client c on c.PersonalID = lp.PersonalID

update rpt
set SSNNotProvided = (select count(distinct PersonalID)
	from tlsa_Person
	where SSNValid = 9)
	, SSNMissingOrInvalid = (select count(distinct PersonalID)
		from tlsa_Person
		where SSNValid = 0)
from lsa_Report rpt

update rpt
set rpt.ClientSSNNotUnique = case when ssn.people is null then 0 else ssn.people end
	, rpt.DistinctSSNValueNotUnique = case when ssn.SSNs is null then 0 else ssn.SSNs end 
from lsa_Report rpt
left outer join 
	(select lp.ReportID, count(distinct lp.PersonalID) as people, count(distinct c.SSN) as SSNs
	from tlsa_Person lp
	inner join hmis_Client c on c.PersonalID = lp.PersonalID
	inner join (select distinct dupe.PersonalID, dupeSSN.SSN
		from tlsa_Person dupe
		inner join hmis_Client dupeSSN on dupeSSN.PersonalID = dupe.PersonalID
	) other on other.PersonalID <> lp.PersonalID and other.SSN = c.SSN
	where lp.SSNValid = 1
	group by lp.ReportID) ssn on ssn.ReportID = rpt.ReportID

/*
	11.7 Enrollment Data Issues 
*/

update rpt
set rpt.DisablingCond = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	where n.Active = 1
	and n.DisabilityStatus = 99
	)
from lsa_Report rpt

update rpt
set rpt.LivingSituation = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.LivingSituation is null or hn.LivingSituation in (8,9,99))
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65))
from lsa_Report rpt

update rpt
set rpt.LengthOfStay = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.LengthOfStay is null or hn.LengthOfStay in (8,9,99))
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65))
from lsa_Report rpt

update rpt
set rpt.HomelessDate = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.DateToStreetESSH > hn.EntryDate
		 or (hn.DateToStreetESSH is null 
				and (n.LSAProjectType in (0,1,8)
					 or hn.LivingSituation in (1,16,18)
					 or hn.PreviousStreetESSH = 1
					)
			)
		)
		and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
	)
from lsa_Report rpt

update rpt
set rpt.TimesHomeless = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.TimesHomelessPastThreeYears is NULL
		or hn.TimesHomelessPastThreeYears not in (1,2,3,4)) 
	and (n.LSAProjectType in (0,1,8)
			or hn.LivingSituation in (1,16,18)
			or hn.PreviousStreetESSH = 1)
	and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65))
from lsa_Report rpt

update rpt
set rpt.MonthsHomeless = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	inner join hmis_Enrollment hn on n.EnrollmentID = hn.EnrollmentID
	where n.Active = 1
	and (hn.MonthsHomelessPastThreeYears is NULL
		or hn.MonthsHomelessPastThreeYears not between 101 and 113) 
	and (n.LSAProjectType in (0,1,8)
		or hn.LivingSituation in (1,16,18)
		or hn.PreviousStreetESSH = 1)
	and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65))
from lsa_Report rpt

update rpt
set rpt.Destination = (select count(distinct n.EnrollmentID)
	from tlsa_Enrollment n
	left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
		and x.DateDeleted is null
	where n.Active = 1 and n.ExitDate is not null
		and (x.Destination is null
			or x.Destination in (8,9,17,27,30,99))
	)
from lsa_Report rpt

/*
	11.8 Set ReportDate for LSAReport
*/
update lsa_Report set ReportDate = getdate()