/*
LSA FY2023 Sample Code
Name:  04_01 Get Project Records.sql

FY2023 Changes
		
		-Remove columns TrackingMethod, HMISParticipatingProject
		-Add ProjectType 0 (ES entry/exit) to WHERE clause
		-Add column RRHSubType, logic for ResidentialAffiliation
		-Expand ProjectName up to 200 characters in length

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

	4.1 Get Project Records for Export
		Export records for continuum ES entry/exit (0), ES night-by-night (1), 
			SH (8), TH (2), RRH (13), PSH (3), and OPH (9 or 10) projects active in the report period
			and/or in the seven years prior to the report period.

		NOTE:   If used in production, must be modified to accept user-selected ProjectIDs as 
				parameters when LSAScope = 2.
*/	  	
	delete from lsa_Project

	insert into lsa_Project
		(ProjectID, OrganizationID, ProjectName
		 , OperatingStartDate, OperatingEndDate
		 , ContinuumProject, ProjectType, HousingType, RRHSubType
		 , ResidentialAffiliation, TargetPopulation
		 , HOPWAMedAssistedLivingFac
		 , DateCreated, DateUpdated, ExportID)
	select distinct 
		hp.ProjectID, hp.OrganizationID, left(hp.ProjectName, 200)
		, format(hp.OperatingStartDate, 'yyyy-MM-dd')
		, case when hp.OperatingEndDate is not null then format(hp.OperatingEndDate, 'yyyy-MM-dd') else null end
		, hp.ContinuumProject, hp.ProjectType
		, case when hp.RRHSubType = 1 then null else hp.HousingType end
		, case when hp.ProjectType = 13 then hp.RRHSubType else null end
		, case when hp.RRHSubType = 1 then hp.ResidentialAffiliation else null end
		, hp.TargetPopulation 
		, hp.HOPWAMedAssistedLivingFac
		, format(hp.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hp.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, rpt.ReportID
	from hmis_Project hp
	inner join hmis_ProjectCoC coc on coc.ProjectID = hp.ProjectID
		and coc.DateDeleted is null
	inner join lsa_Report rpt on rpt.ReportCoC = coc.CoCCode 
	where hp.DateDeleted is null
		and hp.ContinuumProject = 1 
		and hp.ProjectType in (0,1,2,3,8,9,10,13)
		and (hp.OperatingEndDate is null 
			 or	(hp.OperatingEndDate >= rpt.LookbackDate
				 and hp.OperatingEndDate > hp.OperatingStartDate)
			)  
