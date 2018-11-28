module Censuses
  class ProjectTypeBase < Base
    include ArelHelper

    def detail_name (project_type)
      "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type.to_sym]} on"
    end

    def project_for_date (date, project_type, population = 'all_clients')
      columns = {
          'LastName' => c_t[:LastName].to_sql,
          'FirstName' => c_t[:FirstName].to_sql,
          'ProjectName' => she_t[:project_name].to_sql,
          'short_name' => ds_t[:short_name].to_sql,
          'client_id' => she_t[:client_id].to_sql,
      }

      enrollment_scope(date, project_type, population).
          where(client_id: census_scope(date).pluck("#{project_type}_#{population}").flatten).
          joins(:client, :data_source).
          pluck(*columns.values).
          #order(:LastName, :FirstName).
          map do | row |
        Hash[columns.keys.zip( row )]
      end
    end

    def prior_year_averages (year, project_type, population)
      {
          year: year,
          ave_client_count: census_data_scope(year).average("#{project_type}_#{population}").round(2),
      }
    end

    def census_scope (date)
      GrdaWarehouse::Census::ByProjectTypeClient.for_date_range(date, date)
    end

    def census_data_scope (year)
      start_date = Date.new(year).beginning_of_year
      end_date = Date.new(year).end_of_year

      GrdaWarehouse::Census::ByProjectType.for_date_range(start_date, end_date)
    end

  end
end
