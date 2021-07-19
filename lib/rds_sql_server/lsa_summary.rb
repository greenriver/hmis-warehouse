require_relative 'sql_server_base'
module LsaSqlServer
  class LSAReportSummary
    def fetch_results
      SqlServerBase.connection.exec_query <<~SQL
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

    def fetch_demographics
      # Demographic summaries
      # dbo.sp_lsaPersonDemographics <popid>, <HHType>, <parameter>
      #
      # Available Parameters:
      #   Age, Gender, Race, Ethnicity, VetStatus, DVStatus
      #
      # popid popname           HHType
      # 1 Youth Household 18-21 HHType 1
      # 2 Youth Household 22-24 HHType 1
      # 3 Veteran Household HHType 1
      # 3 Veteran Household HHType 2
      # 4 Non-Veteran Household 25+ HHType 1
      # 5 Household with Disabled Adult/HoH HHType NULL,1,2, or 3
      # 6 Household with Chronically Homeless HHType NULL,1,2, or 3
      # 7 Household Fleeing Domestic Violence HHType NULL,1,2, or 3
      # 8 Senior Household 55+  HHType 1
      # 9 Parenting Youth Household 18-24 HHType 2
      # 10  Parenting Child Household HHType 3
      # 11  Household with 3+ Children  HHType 2
      demographic_summary = {}
      available_populations.each do |pop|
        pop[:hh_types].each do |hh_type|
          hh_type = 'NULL' if hh_type.nil?
          demographic_parameters.each do |param|
            pop_name = population_name(pop[:pop_id])
            hh_type_name = household_type_name(hh_type)
            demographic_summary[pop_name] ||= {}
            demographic_summary[pop_name][hh_type_name] ||= {}

            results = SqlServerBase.connection.exec_query("dbo.sp_lsaPersonDemographics #{pop[:pop_id]}, #{hh_type}, '#{param}'")
            demographic_summary[pop_name][hh_type_name][param] ||= { headers: results.columns, data: results.rows }
          end
        end
      end

      demographic_summary
    end

    def household_type_name(hh_id)
      available_household_types.try(:[], hh_id)
    end

    def available_household_types
      @available_household_types ||= ReportGenerators::Lsa::Fy2019::Base.new.household_types
    end

    def demographic_parameters
      @demographic_parameters ||= ['Age', 'Gender', 'Race', 'Ethnicity', 'VetStatus', 'DVStatus']
    end

    def population_name(pop_id)
      population_names.try(:[], pop_id)
    end

    def available_populations
      @available_populations ||= [
        { pop_id: 1, hh_types: [1] },
        { pop_id: 2, hh_types: [1] },
        { pop_id: 3, hh_types: [1, 2] },
        { pop_id: 4, hh_types: [1] },
        { pop_id: 5, hh_types: [nil, 1, 2, 3] },
        { pop_id: 6, hh_types: [nil, 1, 2, 3] },
        { pop_id: 7, hh_types: [nil, 1, 2, 3] },
        { pop_id: 8, hh_types: [1] },
        { pop_id: 9, hh_types: [2] },
        { pop_id: 10, hh_types: [3] },
        { pop_id: 11, hh_types: [2] },
      ]
    end

    def population_names
      @population_names ||= {
        1 => 'Youth Household 18-21',
        2 => 'Youth Household 22-24',
        3 => 'Veteran Household',
        4 => 'Non-Veteran Household 25+',
        5 => 'Household with Disabled Adult/HoH HHType',
        6 => 'Household with Chronically Homeless',
        7 => 'Household Fleeing Domestic Violence',
        8 => 'Senior Household 55+',
        9 => 'Parenting Youth Household 18-24',
        10 => 'Parenting Child Household',
        11 => 'Household with 3+ Children',
      }
    end
  end
end
