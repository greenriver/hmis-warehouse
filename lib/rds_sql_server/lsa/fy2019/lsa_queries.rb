# require_relative 'sql_server_base'
require_relative '../../sql_server_base' unless ENV['NO_LSA_RDS'].present?
require_relative 'lsa_sql_server' unless ENV['NO_LSA_RDS'].present?
module LsaSqlServer
  class LSAQueries
    attr_accessor :project_ids

    def steps
      @steps ||= [
        'lib/rds_sql_server/lsa/fy2019/sample_code/3_1 to 3_6 Parameters Households and Enrollments.sql',
        'lib/rds_sql_server/lsa/fy2019/sample_code/4_1 to 4_6 PDDEs for Export.sql',
        'lib/rds_sql_server/lsa/fy2019/sample_code/5_1 to 5_19 LSAPerson.sql',
        'lib/rds_sql_server/lsa/fy2019/sample_code/6_1 to 6_19 LSAHousehold.sql',
        'lib/rds_sql_server/lsa/fy2019/sample_code/7_1 to 7_8 LSAExit.sql',
        'lib/rds_sql_server/lsa/fy2019/sample_code/8_1 to 8_8 lsa_Calculated Averages from LSAHousehold and LSAExit.sql',
        'lib/rds_sql_server/lsa/fy2019/sample_code/8_9 to 8_21 lsa_Calculated Counts.sql',
        'lib/rds_sql_server/lsa/fy2019/sample_code/9_1 to 9_3 LSAReport DQ and ReportDate.sql',
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
          , DateCreated, DateUpdated, ExportID)
        select distinct
          hp.ProjectID, hp.OrganizationID, left(hp.ProjectName, 50)
          , format(hp.OperatingStartDate, 'yyyy-MM-dd')
          , case when hp.OperatingEndDate is not null then format(hp.OperatingEndDate, 'yyyy-MM-dd') else null end
          , hp.ContinuumProject, hp.ProjectType, hp.HousingType
          , hp.TrackingMethod, hp.HMISParticipatingProject
          , hp.TargetPopulation
          , format(hp.DateCreated, 'yyyy-MM-dd hh:mm:ss')
          , format(hp.DateUpdated, 'yyyy-MM-dd hh:mm:ss')
          , rpt.ReportID
        from hmis_Project hp
        inner join lsa_Report rpt on hp.OperatingStartDate <= rpt.ReportEnd
        inner join hmis_ProjectCoC coc on coc.CoCCode = rpt.ReportCoC
        where hp.DateDeleted is null
          and hp.ContinuumProject = 1
          and hp.ProjectType in (1,2,3,8,9,10,13)
          and hp.OperatingStartDate <= rpt.ReportEnd
          and (hp.OperatingEndDate is null
            or	(hp.OperatingEndDate >= rpt.ReportStart
              and hp.OperatingEndDate > hp.OperatingStartDate)
            )
      SQL
      query += "and hp.ProjectID in(#{project_ids.join(',')})" if project_ids.present? && ! test?
      SqlServerBase.connection.execute(query)
    end
  end
end
