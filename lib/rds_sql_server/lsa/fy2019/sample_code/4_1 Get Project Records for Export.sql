/*
Name:  4_1 Get Project Records for Export.sql

Date:	4/2/2020 -- original 
		4/30/2020 -- create two separate scripts from original file (4_1 to 4_6 PDDEs for export.sql):
					 - 4_1 Get Project Records for Export.sql
				     - 4_2 to 4_6 Other PDDEs for Export.sql
				  -- correct all date formatting from yyyy-mm-dd to yyyy-MM-dd
		5/21/2020 -- add 'and coc.ProjectID = hp.ProjectID' to hmis_ProjectCoC join

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
		 , DateCreated, DateUpdated, ExportID)
	select distinct 
		hp.ProjectID, hp.OrganizationID, left(hp.ProjectName, 50)
		, format(hp.OperatingStartDate, 'yyyy-MM-dd')
		, case when hp.OperatingEndDate is not null then format(hp.OperatingEndDate, 'yyyy-MM-dd') else null end
		, hp.ContinuumProject, hp.ProjectType, hp.HousingType
		, hp.TrackingMethod, hp.HMISParticipatingProject
		, hp.TargetPopulation 
		, format(hp.DateCreated, 'yyyy-MM-dd hh:mm:ss')
		, format(hp.DateUpdated, 'yyyy-MM-dd hh:mm:ss')
		, rpt.ReportID
	from hmis_Project hp
	inner join lsa_Report rpt on hp.OperatingStartDate <= rpt.ReportEnd
	inner join hmis_ProjectCoC coc on coc.CoCCode = rpt.ReportCoC
		and coc.ProjectID = hp.ProjectID
	where hp.DateDeleted is null
		and hp.ContinuumProject = 1 
		and hp.ProjectType in (1,2,3,8,9,10,13)
		and hp.OperatingStartDate <= rpt.ReportEnd
		and (hp.OperatingEndDate is null 
			 or	(hp.OperatingEndDate >= rpt.ReportStart
				 and hp.OperatingEndDate > hp.OperatingStartDate)
			)  