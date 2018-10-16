CREATE proc [dbo].[sp_lsaPersonDemographics] 
	  @popID int  --value in ref_Populations where popType = 1
	, @hhtype int
	, @rptTable varchar(12)

/*
	This will produce the following demographic report tables,
	depending on the @rptTable parameter:
		  Age, Gender, Race, Ethnicity, VetStatus, DVStatus

	It will generate results for these HHTypes / Populations:

popid	popname								HHType
	1	Youth Household 18-21				1
	2	Youth Household 22-24				1
	3	Veteran Household					1
	3	Veteran Household					2
	4	Non-Veteran Household 25+			1
	5	Household with Disabled Adult/HoH	NULL,1,2, or 3
	6	Household with Chronically Homeless NULL,1,2, or 3
	7	Household Fleeing Domestic Violence	NULL,1,2, or 3
	8	Senior Household 55+				1
	9	Parenting Youth Household 18-24		2
	10	Parenting Child Household			3
	11	Household with 3+ Children			2

	5/30/2018 - First version
	9/21/2018 - Update to use table ref_Populations to produce results for 
				a wider variety of populations.
	10/11/2018 - Uploaded to github

*/
AS
BEGIN
select t.Category, t.EST, t.RRH, t.PSH
from (select distinct top 1000 val.intvalue, val.textValue as Category
	, EST = coalesce((select sum(RowTotal)
			from lsa_Person est
			where (est.HHTypeEST <> -1
				and @hhtype is null or @hhtype = 0
					or cast(est.HHTypeEST as varchar) like '%' + cast(@hhtype as varchar) + '%')
				and (est.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
				and (cast(est.HHVet as varchar) like '%' + cast(pop.HHVet as varchar) + '%' or pop.HHVet is null)
				and (cast(est.HHDisability as varchar) like '%' + cast(pop.HHDisability as varchar) + '%' or pop.HHDisability is null)
				and (cast(est.HHChronic as varchar) like '%' + cast(pop.HHChronic as varchar) + '%' or pop.HHChronic is null)
				and (cast(est.HHFleeingDV as varchar) like '%' + cast(pop.HHFleeingDV as varchar) + '%' or pop.HHFleeingDV is null)
				and (cast(est.HHParent as varchar) like '%' + cast(pop.HHParent as varchar) + '%' or pop.HHParent is null)
				and (est.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
				and val.intValue = case when @rptTable = 'Age' then est.Age 
						when @rptTable = 'Gender' then est.Gender
						when @rptTable = 'Race' then est.Race
						when @rptTable = 'Ethnicity' then est.Ethnicity
						when @rptTable = 'VeteranStatus' then est.VetStatus
						when @rptTable = 'DVStatus' then est.DVStatus
						else null end
			), 0)

	, RRH = coalesce((select sum(RowTotal)
			from lsa_Person rrh
			where (rrh.HHTypeRRH <> -1
				and @hhtype is null or @hhtype = 0
					or cast(rrh.HHTypeRRH as varchar) like '%' + cast(@hhtype as varchar) + '%')
				and (rrh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
				and (cast(rrh.HHVet as varchar) like '%' + cast(pop.HHVet as varchar) + '%' or pop.HHVet is null)
				and (cast(rrh.HHDisability as varchar) like '%' + cast(pop.HHDisability as varchar) + '%' or pop.HHDisability is null)
				and (cast(rrh.HHChronic as varchar) like '%' + cast(pop.HHChronic as varchar) + '%' or pop.HHChronic is null)
				and (cast(rrh.HHFleeingDV as varchar) like '%' + cast(pop.HHFleeingDV as varchar) + '%' or pop.HHFleeingDV is null)
				and (cast(rrh.HHParent as varchar) like '%' + cast(pop.HHParent as varchar) + '%' or pop.HHParent is null)
				and (rrh.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
				and val.intValue = case when @rptTable = 'Age' then rrh.Age 
						when @rptTable = 'Gender' then rrh.Gender
						when @rptTable = 'Race' then rrh.Race
						when @rptTable = 'Ethnicity' then rrh.Ethnicity
						when @rptTable = 'VeteranStatus' then rrh.VetStatus
						when @rptTable = 'DVStatus' then rrh.DVStatus
						else null end
			), 0)
		, PSH = coalesce((select sum(RowTotal)
			from lsa_Person psh
			where (psh.HHTypePSH <> -1
				and @hhtype is null or @hhtype = 0
					or cast(psh.HHTypePSH as varchar) like '%' + cast(@hhtype as varchar) + '%')
				and (psh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
				and (cast(psh.HHVet as varchar) like '%' + cast(pop.HHVet as varchar) + '%' or pop.HHVet is null)
				and (cast(psh.HHDisability as varchar) like '%' + cast(pop.HHDisability as varchar) + '%' or pop.HHDisability is null)
				and (cast(psh.HHChronic as varchar) like '%' + cast(pop.HHChronic as varchar) + '%' or pop.HHChronic is null)
				and (cast(psh.HHFleeingDV as varchar) like '%' + cast(pop.HHFleeingDV as varchar) + '%' or pop.HHFleeingDV is null)
				and (cast(psh.HHParent as varchar) like '%' + cast(pop.HHParent as varchar) + '%' or pop.HHParent is null)
				and (psh.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
				and val.intValue = case when @rptTable = 'Age' then psh.Age 
						when @rptTable = 'Gender' then psh.Gender
						when @rptTable = 'Race' then psh.Race
						when @rptTable = 'Ethnicity' then psh.Ethnicity
						when @rptTable = 'VeteranStatus' then psh.VetStatus
						when @rptTable = 'DVStatus' then psh.DVStatus
						else null end
			), 0)from ref_lsaValues val

inner join ref_lsaColumns col on col.ColumnNumber = val.ColumnNumber
	and col.FileNumber = val.FileNumber
inner join ref_lsaFiles f on f.FileNumber = val.FileNumber
inner join ref_Populations pop on pop.PopID = @popID and pop.PopType = 1
	and pop.PopID between 1 and 11 and pop.SystemPath is null
where col.ColumnName = @rptTable
	and f.FileName = 'LSAPerson'
	and val.intValue <> -1
order by val.intValue) t


END
