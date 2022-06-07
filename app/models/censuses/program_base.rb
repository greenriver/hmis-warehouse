###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Censuses
  class ProgramBase < Base
    include ArelHelper

    # JSON Shape:
    # { datasource_id: {
    #     organization_id: { // include "all" for totals if more than one project_id
    #       project_id: { // include "all" for totals if more than one project_id
    #         "datasets": [
    #           {
    #             "label": "Client Count",
    #             "data": [
    #               {
    #                 "x": date,
    #                 "y": value,
    #                 "yesterday": value // To allow change computation for the datum
    #               }
    #             ]
    #           },
    #           { "label": "Bed Inventory Count"
    #             "data": [
    #               {
    #                 "x": date,
    #                 "y": value
    #               }
    #             ]
    #           }
    #         ],
    #         "title": {
    #           "display": true,
    #           "text": string
    #         }
    #       }
    #     }
    #   }
    # }

    def for_date_range(start_date, end_date, data_source_id = 0, project_id = 0, user:)
      @shape ||= {}

      if data_source_id != 0 && project_id != 0
        for_project_id(start_date, end_date, data_source_id, project_id, user: user)
      else
        census_projects_scope(user: user).each do |project|
          for_project_id(start_date, end_date, project.data_source_id, project.id, user: user)
        end

        @shape.each_key do |ds_id|
          # only include data source summary if the source contains more than one organization
          for_data_source_id(start_date, end_date, ds_id, user: user) if @shape[ds_id].count > 1

          @shape[ds_id].each_key do |organization_id|
            if @shape[ds_id][organization_id].count > 1
              # only include the organization summary if the organization contains more than one project
              for_organization_id(start_date, end_date, ds_id, organization_id, user: user)
            end
          end
        end

        # only show the all sources summary if there is more than one source
        if @shape.count > 1
          compute_dimension(
            start_date, end_date, 'all', 'all', 'all',
            'All Programs from All Sources', GrdaWarehouse::Census::ByProject.night_by_night
          )
        end
      end
      @shape
    end

    private def for_project_id(start_date, end_date, data_source_id, project_id, user: nil)
      project = GrdaWarehouse::Hud::Project.find(project_id)
      project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.select { |_k, v| v.include?(project[:ProjectType]) }.keys.first&.upcase
      return if project_type.blank?

      dimension_scope = census_data_scope(user: user).by_project_id(project_id)
      organization_id = project.organization&.id
      name_and_type = project.name(ignore_confidential_status: true, include_project_type: true)
      dimension_label = "#{name_and_type} < #{project.organization&.name} < #{project.data_source&.short_name}"
      compute_dimension(start_date, end_date, data_source_id, organization_id, project_id, dimension_label, dimension_scope)
    end

    private def for_data_source_id(start_date, end_date, data_source_id, user: nil)
      data_source_name = GrdaWarehouse::DataSource.find(data_source_id).name
      dimension_label = "All programs from #{data_source_name}"
      dimension_scope = census_data_scope(user: user).by_data_source_id(data_source_id)
      compute_dimension(start_date, end_date, data_source_id, 'all', 'all', dimension_label, dimension_scope)
    end

    private def for_organization_id(start_date, end_date, data_source_id, organization_id, user: nil)
      organization_name = GrdaWarehouse::Hud::Organization.find(organization_id).name
      dimension_label = "All programs from #{organization_name}"
      dimension_scope = census_data_scope(user: user).by_organization_id(organization_id)
      compute_dimension(start_date, end_date, data_source_id, organization_id, 'all', dimension_label, dimension_scope)
    end

    private def compute_dimension(start_date, end_date, data_source_id, organization_id, project_id, dimension_label, dimension_scope)
      # Move the start of the range to include "yesterday"
      yesterday = 0
      adjusted_start_date = start_date.to_date - 1.day

      bounded_scope = dimension_scope.for_date_range(adjusted_start_date, end_date).group(:date).pluck(:date, 'sum(all_clients)', 'sum(beds)')

      client_data = []
      bed_data = []

      bounded_scope.each do |item|
        # item.first = date, item.second = clients, item.last = beds
        client_data << { x: item.first, y: item.second, yesterday: yesterday }
        bed_data << { x: item.first, y: item.last }

        yesterday = item.second
      end

      add_dimension(data_source_id, organization_id, project_id, client_data, bed_data, dimension_label) unless client_data.empty?
    end

    private def add_dimension(data_source_id, organization_id, project_id, clients, beds, title)
      @shape[data_source_id] ||= {}
      @shape[data_source_id][organization_id] ||= {}
      @shape[data_source_id][organization_id][project_id] ||= {}
      @shape[data_source_id][organization_id][project_id][:datasets] = []
      @shape[data_source_id][organization_id][project_id][:datasets][0] = { label: 'Client Count', data: clients }
      @shape[data_source_id][organization_id][project_id][:datasets][1] = { label: 'Bed Inventory Count', data: beds }
      @shape[data_source_id][organization_id][project_id][:title] = {}
      @shape[data_source_id][organization_id][project_id][:title][:display] = true
      @shape[data_source_id][organization_id][project_id][:title][:text] = title
      @shape
    end

    # Detail view

    def detail_name(project_code)
      data_source_id, organization_id, project_id = project_code.split('-')
      return 'All Programs from All Sources on' if data_source_id == 'all'

      data_source_name = GrdaWarehouse::DataSource.find(data_source_id.to_i).name
      return "All Programs from #{data_source_name} on" if organization_id == 'all'

      organization_name = GrdaWarehouse::Hud::Organization.find(organization_id.to_i).name
      return "All Projects from #{organization_name} on" if project_id == 'all'

      project_name = GrdaWarehouse::Hud::Project.find(project_id.to_i).name
      "#{project_name} at #{organization_name} on"
    end

    def clients_for_date(date, data_source = nil, organization = nil, project = nil)
      columns = {
        'LastName' => c_t[:LastName].to_sql,
        'FirstName' => c_t[:FirstName].to_sql,
        'ProjectName' => she_t[:project_name].to_sql,
        'short_name' => ds_t[:short_name].to_sql,
        'client_id' => she_t[:client_id].to_sql,
        'project_id' => p_t[:id].to_sql,
      }

      base_scope = GrdaWarehouse::ServiceHistoryService.where(date: date)
      if data_source && data_source != 'all'
        base_scope = base_scope.joins(:service_history_enrollment).
          merge(GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: data_source.to_i))
      end
      if organization && organization != 'all'
        base_scope = base_scope.joins(service_history_enrollment: :organization).
          merge(GrdaWarehouse::Hud::Organization.where(id: organization.to_i))
      end
      if project && project != 'all'
        base_scope = base_scope.joins(service_history_enrollment: :project).
          merge(GrdaWarehouse::Hud::Project.where(id: project.to_i))
      end

      base_scope.joins(:client, service_history_enrollment: [:data_source, :project]).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end
    end

    def prior_year_averages(year, data_source = nil, organization = nil, project = nil, user: nil)
      start_date = Date.new(year).beginning_of_year
      end_date = Date.new(year).end_of_year

      local_census_scope = census_data_scope(user: user).for_date_range(start_date, end_date)
      local_census_scope = local_census_scope.by_data_source_id(data_source.to_i) if data_source && data_source != 'all'
      local_census_scope = local_census_scope.by_organization_id(organization.to_i) if organization && organization != 'all'
      local_census_scope = local_census_scope.by_project_id(project.to_i) if project && project != 'all'

      {
        year: year,
        ave_client_count: local_census_scope.average(:all_clients)&.round(2) || 0,
        ave_bed_inventory: local_census_scope.average(:beds)&.round(2) || 0,
        ave_seasonal_inventory: seasonal_inventory(year)&.round(2) || 0,
      }
    end

    private def seasonal_inventory(year)
      start_date = Date.new(year).beginning_of_year
      end_date = Date.new(year).end_of_year

      counts = {}
      (start_date..end_date).each do |date|
        counts[date] = 0
        GrdaWarehouse::Hud::Inventory.within_range(date..date).each do |inventory|
          counts[date] += inventory.beds if inventory.Availability.present? && inventory.Availability != 1
        end
      end
      counts.values.sum.to_f / counts.values.count
    end
  end
end
