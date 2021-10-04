# require_relative 'sql_server_base'
require_relative '../../sql_server_base' unless ENV['NO_LSA_RDS'].present?
require_relative 'lsa_sql_server' unless ENV['NO_LSA_RDS'].present?
module LsaSqlServer
  class LSAQueries
    attr_accessor :project_ids, :test_run

    def steps
      @steps ||= [
        'lib/rds_sql_server/lsa/fy2021/sample_code/03_02 to 03_06 HMIS Households and Enrollments.sql',
        'lib/rds_sql_server/lsa/fy2021/sample_code/04_02 to 04_06 Get Other PDDEs.sql',
        'lib/rds_sql_server/lsa/fy2021/sample_code/05_01 to 05_11 LSAPerson Records and Demographics.sql',
        'lib/rds_sql_server/lsa/fy2021/sample_code/05_12 to 05_15 LSAPerson Project Group and Population Household Types.sql',
        'lib/rds_sql_server/lsa/fy2021/sample_code/06 LSAHousehold.sql',
        'lib/rds_sql_server/lsa/fy2021/sample_code/07 LSAExit.sql',
        'lib/rds_sql_server/lsa/fy2021/sample_code/08 LSACalculated Averages for LSAHousehold and LSAExit.sql',
        'lib/rds_sql_server/lsa/fy2021/sample_code/09 LSACalculated AHAR Counts.sql',
        'lib/rds_sql_server/lsa/fy2021/sample_code/10 LSACalculated Data Quality.sql',
        'lib/rds_sql_server/lsa/fy2021/sample_code/11 LSAReport DQ and ReportDate.sql',
      ]
    end

    def run_query(step)
      SqlServerBase.connection.execute <<~SQL
        #{File.read(step)}
      SQL
      GrdaWarehouseBase.connection.reconnect!
      ApplicationRecord.connection.reconnect!
      ReportingBase.connection.reconnect!
    end

    def setup_test_report
      step = 'lib/rds_sql_server/lsa/fy2021/sample_code/03_01 LSA Parameters and Metadata.sql'
      run_query(step)
    end

    def setup_test_projects
      step = 'lib/rds_sql_server/lsa/fy2021/sample_code/04_01 Get Project Records.sql'
      run_query(step)
    end

    def insert_projects
      # Limit the projects that are reported to those selected
      query = <<~SQL
        -- 4.1 Get Project Records for Export
        delete from lsa_Project

        insert into lsa_Project
          (ProjectID, OrganizationID, ProjectName
          , OperatingStartDate, OperatingEndDate
          , ContinuumProject, ProjectType, HousingType
          , TrackingMethod, HMISParticipatingProject
          , TargetPopulation
          , HOPWAMedAssistedLivingFac
          , DateCreated, DateUpdated, ExportID)
        select distinct
          hp.ProjectID, hp.OrganizationID, left(hp.ProjectName, 100)
          , format(hp.OperatingStartDate, 'yyyy-MM-dd')
          , case when hp.OperatingEndDate is not null then format(hp.OperatingEndDate, 'yyyy-MM-dd') else null end
          , hp.ContinuumProject, hp.ProjectType, hp.HousingType
          , hp.TrackingMethod, hp.HMISParticipatingProject
          , hp.TargetPopulation
          , hp.HOPWAMedAssistedLivingFac
          , format(hp.DateCreated, 'yyyy-MM-dd hh:mm:ss')
          , format(hp.DateUpdated, 'yyyy-MM-dd hh:mm:ss')
          , rpt.ReportID
        from hmis_Project hp
        inner join lsa_Report rpt on hp.OperatingStartDate <= rpt.ReportEnd
        inner join hmis_ProjectCoC coc on coc.CoCCode = rpt.ReportCoC
          and coc.ProjectID = hp.ProjectID
          and coc.DateDeleted is null
        where hp.DateDeleted is null
          and hp.ContinuumProject = 1
          and hp.ProjectType in (1,2,3,8,9,10,13)
          and hp.OperatingStartDate <= rpt.ReportEnd
          and (hp.OperatingEndDate is null
            or	(hp.OperatingEndDate >= '10/1/2012'
              and hp.OperatingEndDate > hp.OperatingStartDate)
            )
      SQL
      query += "and hp.ProjectID in(#{project_ids.join(',')})" if project_ids.present? && ! test_run
      SqlServerBase.connection.execute(query)
    end
  end
end
