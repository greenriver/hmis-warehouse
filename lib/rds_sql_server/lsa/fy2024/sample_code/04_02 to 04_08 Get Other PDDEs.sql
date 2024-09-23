/*
LSA FY2024 Sample Code
Name:  04_02 to 04_08 Get Other PDDEs.sql

FY2024 Changes

	None

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

	4.2 Get Organization Records for Export
		Export organization records for all projects selected in 4.1.
		Organization.csv must have exactly one Organization record for each 
			OrganizationID in Project.csv 
*/	  	

	delete from lsa_Organization

	insert into lsa_Organization
		(OrganizationID, OrganizationName
		, VictimServiceProvider
		, DateCreated, DateUpdated, ExportID)
	select distinct ho.OrganizationID
		, left(ho.OrganizationName, 200)
		, ho.VictimServiceProvider	
		, format(ho.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(ho.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID
	from hmis_Organization ho
	inner join lsa_Project lp on lp.OrganizationID = ho.OrganizationID
	where ho.DateDeleted is null 

/*
	4.3 Get Funder Records for Export
		Get records for project funders with grants active in the report period.
		Funder.csv must have at least one Funder record for each ProjectID 
			in Project.csv where OperatingEndDate is NULL or > ReportStart. 
*/

	delete from lsa_Funder

	insert into lsa_Funder	
		 (FunderID, ProjectID, Funder, OtherFunder
		, StartDate, EndDate
		, DateCreated, DateUpdated, ExportID)
	select distinct hf.FunderID, hf.ProjectID, hf.Funder, hf.OtherFunder
		, format(hf.StartDate, 'yyyy-MM-dd')
		, case when hf.EndDate is not null then format(hf.EndDate, 'yyyy-MM-dd') else null end
		, format(hf.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hf.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
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
		, format(hcoc.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hcoc.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID
	from hmis_ProjectCoC hcoc
	inner join lsa_Project lp on lp.ProjectID = hcoc.ProjectID
	inner join lsa_Report rpt on cast(lp.ExportID as int) = rpt.ReportID
	where hcoc.DateDeleted is null
		and hcoc.CoCCode = rpt.ReportCoC

/*
	4.5 Get Inventory Records for Export
		Inventory.csv must have at least one record for each ProjectID 
			in Project.csv where OperatingEndDate is NULL or > ReportStart			
			and the CoCCode must match ReportCoC.
		Note that BedInventory is set up for lsa_Inventory in '2 Create Output Tables.sql' as a computed column --
		    the value MUST equal the sum of the other xBedInventory columns -- so this code 
			does not select it into lsa_Inventory.
*/

	delete from lsa_Inventory 

	insert into lsa_Inventory (
		  InventoryID, ProjectID, CoCCode
		, HouseholdType, Availability
		, UnitInventory 
		--, BedInventory
		, CHVetBedInventory, YouthVetBedInventory, VetBedInventory
		, CHYouthBedInventory, YouthBedInventory
		, CHBedInventory, OtherBedInventory
		, ESBedType
		, InventoryStartDate, InventoryEndDate
		, DateCreated, DateUpdated, ExportID)
	select distinct hi.InventoryID, hi.ProjectID, hi.CoCCode
		, hi.HouseholdType
		, case when lp.ProjectType in (0,1) then hi.Availability else null end 
		, hi.UnitInventory 
		--, hi.BedInventory
		, hi.CHVetBedInventory, hi.YouthVetBedInventory, hi.VetBedInventory
		, hi.CHYouthBedInventory, hi.YouthBedInventory
		, hi.CHBedInventory, hi.OtherBedInventory
		, case when lp.ProjectType in (0,1) then hi.ESBedType else null end
		, format(hi.InventoryStartDate, 'yyyy-MM-dd')
		, case when isdate(cast(hi.InventoryEndDate as datetime)) = 1 then format(hi.InventoryEndDate, 'yyyy-MM-dd') else null end
		, format(hi.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hi.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID	
	from hmis_Inventory hi
	inner join lsa_Project lp on lp.ProjectID = hi.ProjectID
	inner join lsa_Report rpt on cast(lp.ExportID as int) = rpt.ReportID
	where hi.DateDeleted is null 
		and hi.CoCCode = rpt.ReportCoC
		and (hi.InventoryEndDate is null 
			or (hi.InventoryEndDate >= rpt.ReportStart
				and hi.InventoryEndDate > hi.InventoryStartDate)
			)
		and (lp.ProjectType <> 13 or lp.RRHSubType = 2)

/*
	4.6 Get HMIS Participation Records for Export
		HMISParticipation.csv must have at least one record for each ProjectID 
			in Project.csv 
*/

	delete from lsa_HMISParticipation

	insert into lsa_HMISParticipation (
		HMISParticipationID, ProjectID, 
		HMISParticipationType, 
		HMISParticipationStatusStartDate, HMISParticipationStatusEndDate,
		DateCreated, DateUpdated, ExportID)
	select distinct hp.HMISParticipationID
		, hp.ProjectID
		, hp.HMISParticipationType
		, format(hp.HMISParticipationStatusStartDate, 'yyyy-MM-dd')
		, case when isdate(cast(hp.HMISParticipationStatusEndDate as datetime)) = 1 then format(hp.HMISParticipationStatusEndDate, 'yyyy-MM-dd') else null end
		, format(hp.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(hp.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID	
	from hmis_HMISParticipation hp
	inner join lsa_Project lp on lp.ProjectID = hp.ProjectID
	where hp.DateDeleted is null 
		and (lp.OperatingEndDate is null or lp.OperatingEndDate >= (select ReportStart from lsa_Report))

	
/*
	4.7 Get Affiliation Records for Export
		Affiliation.csv must have at least one record for each ProjectID 
			in Project.csv active during the report period where 
			RRHSubType = 1 and ResidentialAffiliation = 1 
*/

	delete from lsa_Affiliation

	insert into lsa_Affiliation (
		AffiliationID, ProjectID, 
		ResProjectID, 
		DateCreated, DateUpdated, ExportID)
	select distinct a.AffiliationID
		, a.ProjectID
		, a.ResProjectID
		, format(a.DateCreated, 'yyyy-MM-dd HH:mm:ss')
		, format(a.DateUpdated, 'yyyy-MM-dd HH:mm:ss')
		, lp.ExportID	
	from hmis_Affiliation a
	inner join lsa_Project lp on lp.ProjectID = a.ProjectID
	where a.DateDeleted is null
		and lp.ProjectType = 13 and lp.RRHSubType = 1 and lp.ResidentialAffiliation = 1
		and (lp.OperatingEndDate is null or lp.OperatingEndDate >= (select ReportStart from lsa_Report))