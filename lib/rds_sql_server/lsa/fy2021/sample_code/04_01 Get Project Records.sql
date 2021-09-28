/*
Name:  04_01 Get Project Records.sql

Date:	26 AUG 2021 

	4.1 Get Project Records for Export
		Export records for continuum ES (1), SH (8), TH (2), RRH (13), PSH (3), and OPH (9 or 10)
		projects active in the report period.

		NOTE:   If used in production, must be modified to accept user-selected ProjectIDs as 
				parameters when LSAScope = 2.
*/	  	
	delete from lsa_Project

	insert into lsa_Project
		(ProjectID, OrganizationID, ProjectName
		 , OperatingStartDate, OperatingEndDate
		 , ContinuumProject, ProjectType, HousingType
		 , TrackingMethod, HMISParticipatingProject
		 , TargetPopulation
		 , HOPWAMedAssistedLivingFac
		 , DateCreated, DateUpdated, ExportID)
	select distinct 
		hp.ProjectID, hp.OrganizationID, left(hp.ProjectName, 100)
		, format(hp.OperatingStartDate, 'yyyy-MM-dd')
		, case when hp.OperatingEndDate is not null then format(hp.OperatingEndDate, 'yyyy-MM-dd') else null end
		, hp.ContinuumProject, hp.ProjectType, hp.HousingType
		, hp.TrackingMethod, hp.HMISParticipatingProject
		, hp.TargetPopulation 
		, hp.HOPWAMedAssistedLivingFac
		, format(hp.DateCreated, 'yyyy-MM-dd hh:mm:ss')
		, format(hp.DateUpdated, 'yyyy-MM-dd hh:mm:ss')
		, rpt.ReportID
	from hmis_Project hp
	inner join lsa_Report rpt on hp.OperatingStartDate <= rpt.ReportEnd
	inner join hmis_ProjectCoC coc on coc.CoCCode = rpt.ReportCoC
		and coc.ProjectID = hp.ProjectID
		and coc.DateDeleted is null
	where hp.DateDeleted is null
		and hp.ContinuumProject = 1 
		and hp.ProjectType in (1,2,3,8,9,10,13)
		and hp.OperatingStartDate <= rpt.ReportEnd
		and (hp.OperatingEndDate is null 
			 or	(hp.OperatingEndDate >= '10/1/2012'
				 and hp.OperatingEndDate > hp.OperatingStartDate)
			)  
