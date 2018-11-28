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

    def census_scope (date)
      GrdaWarehouse::Census::ByProjectTypeClient.for_date_range(date, date)
    end

  end
end
