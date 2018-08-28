require_relative 'sql_server_base'
module LsaSqlServer

  class LSAReportSummary

    def self.fetch_results
      SqlServerBase.connection.exec_query (<<~SQL);
      /**********************************************************************
      5.2 Select LSA Summary
      (Optional; no display of LSA summary data is required in HMIS applications at this time.)
      **********************************************************************/
      --active cohort
      select 'All' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID)
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID)
      from lsa_Report rpt
      union all
      select 'AO households' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and (cast(HHTypeEST as varchar) like '1%'
              or cast(HHTypeRRH as varchar) like '1%'
              or cast(HHTypePSH as varchar) like '1%'))
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 1)
      from lsa_Report rpt
      union all
      select 'AC households' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and (cast(HHTypeEST as varchar) like '%2%'
              or cast(HHTypeRRH as varchar) like '%2%'
              or cast(HHTypePSH as varchar) like '%2%'))
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 2)
      from lsa_Report rpt
      union all
      select 'CO households' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and (cast(HHTypeEST as varchar) like '%3%'
              or cast(HHTypeRRH as varchar) like '%3%'
              or cast(HHTypePSH as varchar) like '%3%'))
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 3)
      from lsa_Report rpt
      union all
      select 'All in ES/SH/TH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and lp.HHTypeEST <> -1)
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.ESTDays > 0)
      from lsa_Report rpt
      union all
      select 'AO households in ES/SH/TH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and cast(lp.HHTypeEST as varchar) like '1%')
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 1
            and lh.ESTStatus > 2)
      from lsa_Report rpt
      union all
      select 'AC households in ES/SH/TH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and cast(lp.HHTypeEST as varchar) like '%2%')
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 2
            and lh.ESTStatus > 2)
      from lsa_Report rpt
      union all
      select 'CO households in ES/SH/TH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and cast(lp.HHTypeEST as varchar) like '%3%')
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 3
            and lh.ESTStatus > 2)
      from lsa_Report rpt
      union all
      select 'All in RRH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and lp.HHTypeRRH <> -1)
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.RRHStatus > 2)
      from lsa_Report rpt
      union all
      select 'AO households in RRH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and cast(lp.HHTypeRRH as varchar) like '1%')
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 1
            and lh.RRHStatus > 2)
      from lsa_Report rpt
      union all
      select 'AC households in RRH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and cast(lp.HHTypeRRH as varchar) like '%2%')
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 2
            and lh.RRHStatus > 2)
      from lsa_Report rpt
      union all
      select 'CO households in RRH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and cast(lp.HHTypeRRH as varchar) like '%3%')
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 3
            and lh.RRHStatus > 2)
      from lsa_Report rpt
      union all
      select 'All in PSH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and lp.HHTypePSH <> -1)
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.PSHStatus > 2)
      from lsa_Report rpt
      union all
      select 'AO households in PSH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and cast(lp.HHTypePSH as varchar) like '1%')
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 1
            and lh.PSHStatus > 2)
      from lsa_Report rpt
      union all
      select 'AC households in PSH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and cast(lp.HHTypePSH as varchar) like '%2%')
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 2
            and lh.PSHStatus > 2)
      from lsa_Report rpt
      union all
      select 'CO households in PSH' as Category
      , People = (select coalesce (sum(lp.RowTotal), 0)
          from lsa_Person lp
          where lp.ReportID = rpt.ReportID
            and cast(lp.HHTypePSH as varchar) like '%3%')
      , Households = (select coalesce (sum(lh.RowTotal), 0)
          from lsa_Household lh
          where lh.ReportID = rpt.ReportID
            and lh.HHType = 3
            and lh.PSHStatus > 2)
      from lsa_Report rpt

      --exit cohorts
      select 'All - Report Period - 2 years' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = -2)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -2)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -2
            and lx.ReturnTime <> -1)
      from lsa_Report rpt
      union all
      select 'AO households - Report Period - 2 years' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = -2
            and lx.HHType = 1)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -2
            and lx.HHType = 1)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -2
            and lx.ReturnTime <> -1
            and lx.HHType = 1)
      from lsa_Report rpt
      union all
      select 'AC households - Report Period - 2 years' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = -2
            and lx.HHType = 2)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -2
            and lx.HHType = 2)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -2
            and lx.ReturnTime <> -1
            and lx.HHType = 2)
      from lsa_Report rpt
      union all
      select 'CO households - Report Period - 2 years' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = -2
            and lx.HHType = 3)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -2
            and lx.HHType = 3)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -2
            and lx.ReturnTime <> -1
            and lx.HHType = 3)
      from lsa_Report rpt
      union all
      select 'All - Report Period - 1 year' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = -1)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -1)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -1
            and lx.ReturnTime <> -1)
      from lsa_Report rpt
      union all
      select 'AO households - Report Period - 1 year' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = -1
            and lx.HHType = 1)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -1
            and lx.HHType = 1)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -1
            and lx.ReturnTime <> -1
            and lx.HHType = 1)
      from lsa_Report rpt
      union all
      select 'AC households - Report Period - 1 year' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = -1
            and lx.HHType = 2)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -1
            and lx.HHType = 2)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -1
            and lx.ReturnTime <> -1
            and lx.HHType = 2)
      from lsa_Report rpt
      union all
      select 'CO households - Report Period - 1 year' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = -1
            and lx.HHType = 3)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -1
            and lx.HHType = 3)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = -1
            and lx.ReturnTime <> -1
            and lx.HHType = 3)
      from lsa_Report rpt
      union all
      select 'All - Report Period First Six Months' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = 0)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = 0)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = 0
            and lx.ReturnTime <> -1)
      from lsa_Report rpt
      union all
      select 'AO households - Report Period First Six Months' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = 0
            and lx.HHType = 1)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = 0
            and lx.HHType = 1)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = 0
            and lx.ReturnTime <> -1
            and lx.HHType = 1)
      from lsa_Report rpt
      union all
      select 'AC households - Report Period First Six Months' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = 0
            and lx.HHType = 2)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = 0
            and lx.HHType = 2)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = 0
            and lx.ReturnTime <> -1
            and lx.HHType = 2)
      from lsa_Report rpt
      union all
      select 'CO households - Report Period - 1 year' as Category
      , Exits = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.Cohort = 0
            and lx.HHType = 3)
      , ExitsToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = 0
            and lx.HHType = 3)
      , ReturnAfterExitToPH = (select coalesce (sum(lx.RowTotal), 0)
          from lsa_Exit lx
          where lx.ReportID = rpt.ReportID
            and lx.ExitTo between 1 and 6
            and lx.Cohort = 0
            and lx.ReturnTime <> -1
            and lx.HHType = 3)
      from lsa_Report rpt
      SQL

    end
  end
end
