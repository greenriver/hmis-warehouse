/*
LSA FY2023 Sample Code
Name:	03_01 LSA Parameters and Metadata.sql 

FY2023 Changes
		-Update report start and end dates

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode)

	The hard-coded values here must be replaced with code to accept actual user-entered parameters 
	and info specific to the HMIS application.
*/
delete from lsa_Report 

insert into lsa_Report (
		  ReportID			--system-generated unique identifier for report process
		, ReportStart		--user-entered start of report period
		, ReportEnd			--user-entered end of report period 
		, ReportCoC			--user-selected HUD Continuum of Care Code
		, SoftwareVendor	--name of vendor  
		, SoftwareName		--name of HMIS application
		, VendorContact		--name of vendor contact
		, VendorEmail		--email address of vendor contact
		, LSAScope			--user-selected 1=systemwide, 2=project-focused
		, LookbackDate		--ReportStart - 7 years
		)
	select
		  cast(format (getdate(),'3MMddHHmm') as int)
		, '10/1/2022'
		, '9/30/2023'
		, 'XX-501'
		, 'Sample Code Inc.'
		, 'LSA Online'
		, 'Molly'			
		, 'molly@squarepegdata.com'
		, 1					
		, dateadd(yyyy, -7, '10/1/2022')
