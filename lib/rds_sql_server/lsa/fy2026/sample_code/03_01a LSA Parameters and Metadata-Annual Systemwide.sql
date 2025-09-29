/*
LSA Sample Code
03_01a LSA Parameters and Metadata - Annual Systemwide.sql 
https://github.com/HMIS/LSASampleCode

Author: Molly McEvilley
Last update: 7/31/2025

Source: Source: LSA Programming Specifications v7
Relevant Sections:
	3.1 Report Parameters and Metadata
	
	Using August 1-July 31 for testing instead of the standard fiscal year to avoid issues
	with import/export of sample HMIS data with future dates.

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
		, LSAScope			--user-selected 1=systemwide, 2=project-focused 3=HIC
		, LookbackDate		--ReportStart - 7 years
		)
	select
		  right(year(getdate()), 1)*100000000 + cast(format (getdate(),'MMddHHmm') as int)
		, '8/1/2024'
		, '7/31/2025'
		, 'XX-501'
		, 'Sample Code Inc.'
		, 'LSA Online'
		, 'Molly'			
		, 'molly@squarepegdata.com'
		, 1					
		, dateadd(yyyy, -7, '8/1/2024')
