/*
LSA Sample Code
Name:	03_01c LSA Parameters and Metadata-HIC.sql 
https://github.com/HMIS/LSASampleCode

Last update: 9/28/2025

Source: Source: LSA Programming Specifications v7
Relevant Sections:

	3.1 Report Parameters and Metadata
	
	Using 9/26/2025 for testing instead of a January date to avoid issues
	with import/export of sample HMIS data with future dates.

	The hard-coded values here must be replaced with code to accept actual user-entered parameters 
	and info specific to the HMIS application.

	If LSAScope=3 (HIC), ReportStart and ReportEnd must be identical.   
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
		, LSAScope			--user-selected 1=systemwide, 2=project-focused 3=HIC
		, LookbackDate		--ReportStart - 7 years
		, ReportDate		
		)
	select
		  right(year(getdate()), 1)*100000000 + cast(format (getdate(),'MMddHHmm') as int)
		, '9/26/2025'
		, '9/26/2025'
		, 'XX-501'
		, 'Sample Code Inc.'
		, 'HIC Online'
		, 'Molly'			
		, 'molly@squarepegdata.com'
		, 3					
		, dateadd(yyyy, -7, '9/26/2025')
		, getdate()
