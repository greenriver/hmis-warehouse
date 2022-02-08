###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Censuses
  class ProjectTypeBase < Base
    include ArelHelper

    def detail_name(project_type)
      "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type.to_sym]} on"
    end

    def clients_for_date(date, project_type, population = :clients)
      known_sub_populations = GrdaWarehouse::ServiceHistoryEnrollment.known_standard_cohorts

      raise "Population #{population} not defined" unless known_sub_populations.include?(population.to_sym)

      columns = {
        'LastName' => c_t[:LastName].to_sql,
        'FirstName' => c_t[:FirstName].to_sql,
        'ProjectName' => she_t[:project_name].to_sql,
        'short_name' => ds_t[:short_name].to_sql,
        'client_id' => she_t[:client_id].to_sql,
        'project_id' => p_t[:id].to_sql,
      }
      GrdaWarehouse::ServiceHistoryService.where(date: date).
        where(project_type: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type]).
        joins(service_history_enrollment: [:client, :data_source, :project]).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.send(population)).
        order(c_t[:LastName].asc, c_t[:FirstName].asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end
    end

    def prior_year_averages(year, project_type, population, user: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        year: year,
        ave_client_count: census_values_scope(year).average(values_column_name(project_type, population)).round(2),
      }
    end

    private def values_column_name(project_type, population)
      GrdaWarehouse::Census::ByProjectType.arel_table["#{project_type}_#{population}"].to_sql
    end

    private def census_values_scope(year)
      start_date = Date.new(year).beginning_of_year
      end_date = Date.new(year).end_of_year

      GrdaWarehouse::Census::ByProjectType.for_date_range(start_date, end_date)
    end
  end
end
