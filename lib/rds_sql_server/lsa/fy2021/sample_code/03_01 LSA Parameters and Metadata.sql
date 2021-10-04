/*
LSA FY2021 Sample Code

	Name:	03_01 LSA Parameters and Metadata.sql 
	Date:	26 AUG 2021

	The hard-coded values here must be replaced with code to accept actual user-entered parameters 
	and info specific to the HMIS application.
*/
delete from lsa_Report 

insert into lsa_Report (
		  ReportID			--system-generated unique identifier for report process
		, ReportStart		--user-entered start of report period
		, ReportEnd			--user-entered end of report period 
		, ReportCoC			--user-insert into tlsa_Pops (PopID, Cohort, HoHID, HHType) selected HUD Continuum of Care Code
		, SoftwareVendor	--name of vendor  
		, SoftwareName		--name of HMIS application
		, VendorContact		--name of vendor contact
		, VendorEmail		--email address of vendor contact
		, LSAScope			--user-selected 1=systemwide, 2=project-focused
		)
	select
		  12345
		, '10/1/2020'
		, '9/30/2021'
		, 'XX-500'
		, 'Sample Code Inc.'
		, 'LSA Online'
		, 'Molly'			
		, 'molly@squarepegdata.com'
		, 1					

