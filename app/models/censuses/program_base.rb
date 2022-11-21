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

    def for_date_range(filter)
      user = filter.user
      start_date = filter.start
      end_date = filter.end

      Rails.logger.info(">>> calculating #{filter.aggregation_level}")
      # Rails.logger.info(">>> start_date #{start_date}")
      # Rails.logger.info(">>> end_date #{end_date}")
      # Rails.logger.info(">>> user #{user}")
      @shape ||= {}
      projects = census_projects_scope(filter)
      Rails.logger.info(">>> #{projects.count} projects")

      case filter.aggregation_level.to_sym
      when :by_project
        projects.each do |project|
          for_project(start_date, end_date, project, user: user)
        end
      when :by_organization
        organizations = GrdaWarehouse::Hud::Organization.joins(:projects).merge(projects).uniq
        Rails.logger.info(">>>  #{organizations.count} orgs")
        organizations.each do |organization|
          for_organization(start_date, end_date, organization, projects, user: user)
        end
      when :by_data_source
        data_sources = GrdaWarehouse::DataSource.joins(:projects).merge(projects).uniq
        Rails.logger.info(">>>  #{data_sources.count} sources")
        data_sources.each do |ds|
          for_data_source(start_date, end_date, ds, projects)
        end
      else
        raise NotImplementedError
      end

      @shape
    end

    private def for_project(start_date, end_date, project, user: nil)
      dimension_scope = GrdaWarehouse::Census::ByProject.by_project_id(project.id)
      organization_id = project.organization&.id
      data_source_id = project.data_source_id
      name_and_type = project.name(user, include_project_type: true, ignore_confidential_status: user.can_edit_projects?)
      organization_name = project.organization&.name(user, ignore_confidential_status: user.can_edit_organizations?)
      dimension_label = "#{name_and_type} < #{organization_name} < #{project.data_source&.short_name}"
      compute_dimension(start_date, end_date, data_source_id, organization_id, project.id, dimension_label, dimension_scope)
    end

    private def for_data_source(start_date, end_date, data_source, project_scope)
      project_count = project_scope.where(data_source_id: data_source.id).count
      dimension_label = "#{project_count_str(project_count)} from #{data_source.name}"

      # pass project scope
      dimension_scope = census_data_scope(project_scope).by_data_source_id(data_source.id)
      compute_dimension(start_date, end_date, data_source.id, 'all', 'all', dimension_label, dimension_scope)
    end

    private def for_organization(start_date, end_date, organization, project_scope, user: nil)
      organization_name = organization.name(user, ignore_confidential_status: user.can_edit_organizations?)
      project_count = project_scope.where(data_source_id: organization.data_source_id, OrganizationID: organization.OrganizationID).count
      dimension_label = "#{project_count_str(project_count)} from #{organization_name}"
      dimension_scope = census_data_scope(project_scope).by_organization_id(organization.id)
      compute_dimension(start_date, end_date, organization.data_source_id, organization.id, 'all', dimension_label, dimension_scope)
    end

    private def project_count_str(count)
      "#{count} #{'Project'.pluralize(count)}"
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

    def detail_name(project_code, user: nil)
      data_source_id, organization_id, project_id = project_code.split('-')
      return 'All Programs from All Sources on' if data_source_id == 'all'

      data_source_name = GrdaWarehouse::DataSource.find(data_source_id.to_i).name
      return "All Programs from #{data_source_name} on" if organization_id == 'all'

      organization_name = GrdaWarehouse::Hud::Organization.find(organization_id.to_i).name(user)
      return "All Projects from #{organization_name} on" if project_id == 'all'

      project_name = GrdaWarehouse::Hud::Project.find(project_id.to_i).name(user)
      "#{project_name} at #{organization_name} on"
    end

    def clients_for_date(user, date, data_source = nil, organization = nil, project = nil)
      columns = {
        'LastName' => c_t[:LastName].to_sql,
        'FirstName' => c_t[:FirstName].to_sql,
        'ProjectName' => she_t[:project_name].to_sql,
        'short_name' => ds_t[:short_name].to_sql,
        'client_id' => she_t[:client_id].to_sql,
        'project_id' => p_t[:id].to_sql,
        'confidential' => bool_or(p_t[:confidential], o_t[:confidential]),
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

      base_scope.joins(:client, service_history_enrollment: [:data_source, project: :organization]).
        pluck(*columns.values).
        map do |row|
          h = Hash[columns.keys.zip(row)]
          h['ProjectName'] = GrdaWarehouse::Hud::Project.confidential_project_name if h['confidential'] && !user.can_view_confidential_project_names?
          h
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
