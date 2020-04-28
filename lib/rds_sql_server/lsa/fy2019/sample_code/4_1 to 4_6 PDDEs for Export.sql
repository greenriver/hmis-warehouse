/*
LSA FY2019 Sample Code

Name:  4_1 to 4_6 PDDEs for export.sql
Date:  4/2/2020


	4.1 Get Project Records for Export
		Export records for continuum ES (1), SH (8), TH (2), RRH (13), PSH (3), and OPH (9 or 10)
		projects active in the report period.

		NOTE:   If used in production, must be modified to accept user-selected ProjectIDs as
				parameters when LSAScope = 2.
*/
	-- delete from lsa_Project

	-- insert into lsa_Project
	-- 	(ProjectID, OrganizationID, ProjectName
	-- 	 , OperatingStartDate, OperatingEndDate
	-- 	 , ContinuumProject, ProjectType, HousingType
	-- 	 , TrackingMethod, HMISParticipatingProject
	-- 	 , TargetPopulation
	-- 	 , DateCreated, DateUpdated, ExportID)
	-- select distinct
	-- 	hp.ProjectID, hp.OrganizationID, left(hp.ProjectName, 50)
	-- 	, format(hp.OperatingStartDate, 'yyyy-MM-dd')
	-- 	, case when hp.OperatingEndDate is not null then format(hp.OperatingEndDate, 'yyyy-MM-dd') else null end
	-- 	, hp.ContinuumProject, hp.ProjectType, hp.HousingType
	-- 	, hp.TrackingMethod, hp.HMISParticipatingProject
	-- 	, hp.TargetPopulation
	-- 	, format(hp.DateCreated, 'yyyy-MM-dd hh:mm:ss')
	-- 	, format(hp.DateUpdated, 'yyyy-MM-dd hh:mm:ss')
	-- 	, rpt.ReportID
	-- from hmis_Project hp
	-- inner join lsa_Report rpt on hp.OperatingStartDate <= rpt.ReportEnd
	-- inner join hmis_ProjectCoC coc on coc.CoCCode = rpt.ReportCoC
	-- where hp.DateDeleted is null
	-- 	and hp.ContinuumProject = 1
	-- 	and hp.ProjectType in (1,2,3,8,9,10,13)
	-- 	and hp.OperatingStartDate <= rpt.ReportEnd
	-- 	and (hp.OperatingEndDate is null
	-- 		 or	(hp.OperatingEndDate >= rpt.ReportStart
	-- 			 and hp.OperatingEndDate > hp.OperatingStartDate)
	-- 		)

/*
	4.2 Get Organization Records for Export
		Export organization records for all projects selected in 4.2.
		Organization.csv must have exactly one Organization record for each
			OrganizationID in Project.csv
*/

	delete from lsa_Organization

	insert into lsa_Organization
		(OrganizationID, OrganizationName
		, VictimServicesProvider
		, DateCreated, DateUpdated, ExportID)
	select distinct ho.OrganizationID
		, left(ho.OrganizationName, 50)
		, ho.VictimServicesProvider
		, format(ho.DateCreated, 'yyyy-MM-dd hh:mm:ss')
		, format(ho.DateUpdated, 'yyyy-MM-dd hh:mm:ss')
		, lp.ExportID
	from hmis_Organization ho
	inner join lsa_Project lp on lp.OrganizationID = ho.OrganizationID
	where ho.DateDeleted is null

/*
	4.3 Get Funder Records for Export
		Get records for project funders with grants active in the report period.
		Funder.csv must have at least one Funder record for each ProjectID
			in Project.csv.
*/

	delete from lsa_Funder

	insert into lsa_Funder
		 (FunderID, ProjectID, Funder
		, StartDate, EndDate
		, DateCreated, DateUpdated, ExportID)
	select distinct hf.FunderID, hf.ProjectID, hf.Funder
		, format(hf.StartDate, 'yyyy-MM-dd')
		, case when hf.EndDate is not null then format(hf.EndDate, 'yyyy-MM-dd') else null end
		, format(hf.DateCreated, 'yyyy-MM-dd hh:mm:ss')
		, format(hf.DateUpdated, 'yyyy-MM-dd hh:mm:ss')
		, lp.ExportID
	from hmis_Funder hf
	inner join lsa_Project lp on lp.ProjectID = hf.ProjectID
	inner join lsa_Report rpt on cast(lp.ExportID as int) = rpt.ReportID
	where hf.DateDeleted is null
		and (hf.EndDate is null
			 or	(hf.EndDate >= rpt.ReportStart
				 and hf.EndDate > hf.StartDate)
			)
/*
	4.4 Get ProjectCoC Records for Export
		ProjectCoC.csv must have exactly one record for each ProjectID in Project.csv
			and the CoCCode must match ReportCoC
*/

	delete from lsa_ProjectCoC

	insert into lsa_ProjectCoC (
		  ProjectCoCID, ProjectID, CoCCode
		, Geocode
		, Address1, Address2, City, State
		, ZIP, GeographyType
		, DateCreated, DateUpdated, ExportID
		)
	select hcoc.ProjectCoCID, hcoc.ProjectID, hcoc.CoCCode
		, hcoc.Geocode
		, left(hcoc.Address1, 100), left(hcoc.Address2, 100), left(hcoc.City, 50), hcoc.State
		, left(hcoc.ZIP, 5), hcoc.GeographyType
		, format(hcoc.DateCreated, 'yyyy-MM-dd hh:mm:ss')
		, format(hcoc.DateUpdated, 'yyyy-MM-dd hh:mm:ss')
		, lp.ExportID
	from hmis_ProjectCoC hcoc
	inner join lsa_Project lp on lp.ProjectID = hcoc.ProjectID
	inner join lsa_Report rpt on cast(lp.ExportID as int) = rpt.ReportID
	where hcoc.DateDeleted is null
		and hcoc.CoCCode = rpt.ReportCoC
		and hcoc.ZIP is not null
		and hcoc.GeographyType is not null

/*
	4.5 Get Inventory Records for Export
		Inventory.csv must have at least one record for each ProjectID in Project.csv
			and the CoCCode must match ReportCoC.
*/

	delete from lsa_Inventory

	insert into lsa_Inventory (
		  InventoryID, ProjectID, CoCCode
		, HouseholdType, Availability
		, UnitInventory, BedInventory
		, CHVetBedInventory, YouthVetBedInventory, VetBedInventory
		, CHYouthBedInventory, YouthBedInventory
		, CHBedInventory, OtherBedInventory
		, ESBedType
		, InventoryStartDate, InventoryEndDate
		, DateCreated, DateUpdated, ExportID)
	select distinct hi.InventoryID, hi.ProjectID, hi.CoCCode
		, hi.HouseholdType
		, case when lp.ProjectType = 1 then hi.Availability else null end
		, hi.UnitInventory, hi.BedInventory
		, hi.CHVetBedInventory, hi.YouthVetBedInventory, hi.VetBedInventory
		, hi.CHYouthBedInventory, hi.YouthBedInventory
		, hi.CHBedInventory, hi.OtherBedInventory
		, case when lp.ProjectType = 1 then hi.ESBedType else null end
		, hi.InventoryStartDate, hi.InventoryEndDate
		, format(hi.DateCreated, 'yyyy-MM-dd hh:mm:ss')
		, format(hi.DateUpdated, 'yyyy-MM-dd hh:mm:ss')
		, lp.ExportID
	from hmis_Inventory hi
	inner join lsa_Project lp on lp.ProjectID = hi.ProjectID
	inner join lsa_Report rpt on cast(lp.ExportID as int) = rpt.ReportID
	where hi.DateDeleted is null
		and hi.CoCCode = rpt.ReportCoC
		and hi.InventoryStartDate <= rpt.ReportEnd
		and (hi.InventoryEndDate is null
			or (hi.InventoryEndDate >= rpt.ReportStart
				and hi.InventoryEndDate > hi.InventoryStartDate)
			)

