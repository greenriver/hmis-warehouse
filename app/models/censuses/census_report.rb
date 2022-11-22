###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Censuses
  class CensusReport
    include ArelHelper
    include Filter::ControlSections

    def initialize(filter)
      @filter = filter
    end

    # what projects should be included?
    def census_projects_scope
      scope = GrdaWarehouse::Hud::Project.residential.
        viewable_by(@filter.user).
        where(id: @filter.effective_project_ids)

      # Limit ES projects to Night-by-night only by filtering out Entry/Exit ES projects
      scope = scope.where.not(ProjectType: 1, TrackingMethod: 0) if @filter.limit_es_to_nbn
      scope
    end

    # what data should be included?
    def census_data_scope(project_scope)
      GrdaWarehouse::Census::ByProject.joins(:project).merge(project_scope)
    end

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

    def for_date_range
      user = @filter.user
      start_date = @filter.start
      end_date = @filter.end

      @shape ||= {}
      project_scope = census_projects_scope

      case @filter.aggregation_level.to_sym
      when :by_project
        project_scope.each do |project|
          for_project(start_date, end_date, project, user: user)
        end
      when :by_organization
        organizations = GrdaWarehouse::Hud::Organization.joins(:projects).merge(project_scope).uniq
        organizations.each do |organization|
          for_organization(start_date, end_date, organization, project_scope, user: user)
        end
      when :by_data_source
        data_sources = GrdaWarehouse::DataSource.joins(:projects).merge(project_scope).uniq
        data_sources.each do |ds|
          for_data_source(start_date, end_date, ds, project_scope)
        end
      when :by_project_type
        [:ph, :th, :es, :so, :sh].each do |project_type|
          for_project_type(start_date, end_date, project_type, project_scope)
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
      dimension_scope = census_data_scope(project_scope).by_data_source_id(data_source.id)
      project_count = dimension_scope.group_by(&:project_id).count
      dimension_label = "#{project_count_str(project_count)} from #{data_source.name}"
      compute_dimension(start_date, end_date, data_source.id, 'all', 'all', dimension_label, dimension_scope)
    end

    private def for_organization(start_date, end_date, organization, project_scope, user: nil)
      organization_name = organization.name(user, ignore_confidential_status: user.can_edit_organizations?)
      dimension_scope = census_data_scope(project_scope).by_organization_id(organization.id)
      project_count = dimension_scope.group_by(&:project_id).count
      dimension_label = "#{project_count_str(project_count)} from #{organization_name}"
      compute_dimension(start_date, end_date, organization.data_source_id, organization.id, 'all', dimension_label, dimension_scope)
    end

    private def for_project_type(start_date, end_date, project_type, project_scope)
      project_type_ids = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type]
      project_group_title = GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES[project_type]
      dimension_scope = census_data_scope(project_scope).by_project_type(project_type_ids)
      project_count = dimension_scope.group_by(&:project_id).count
      dimension_label = project_count_str(project_count, prefix: project_group_title)
      compute_dimension(start_date, end_date, project_type, 'all', 'all', dimension_label, dimension_scope)
    end

    private def project_count_str(count, prefix: nil)
      [count, prefix, 'Project'.pluralize(count)].compact.join(' ')
    end

    private def compute_dimension(start_date, end_date, data_source_or_project_type, organization_id, project_id, dimension_label, dimension_scope)
      # Move the start of the range to include "yesterday"
      yesterday = 0
      adjusted_start_date = start_date.to_date - 1.day

      labels = @filter.aggregation_type.to_sym == :veteran ? ['Veteran Count', 'Non-Veteran Count'] : ['Client Count', 'Bed Inventory Count']
      # FIXME: veterans and non_veterans don't add up to all_clients
      columns = @filter.aggregation_type.to_sym == :veteran ? ['sum(veterans)', 'sum(non_veterans)'] : ['sum(all_clients)', 'sum(beds)']

      bounded_scope = dimension_scope.for_date_range(adjusted_start_date, end_date).group(:date).pluck(:date, *columns)

      first_dataset = []
      second_dataset = []

      bounded_scope.each do |item|
        first_dataset << { x: item.first, y: item.second, yesterday: yesterday }
        second_dataset << { x: item.first, y: item.last }

        yesterday = item.second
      end

      datasets = [
        { label: labels[0], data: first_dataset },
        { label: labels[1], data: second_dataset },
      ]

      add_dimension(data_source_or_project_type, organization_id, project_id, datasets, dimension_label) unless first_dataset.empty?
    end

    private def add_dimension(data_source_or_project_type, organization_id, project_id, datasets, title)
      @shape[data_source_or_project_type] ||= {}
      @shape[data_source_or_project_type][organization_id] ||= {}
      @shape[data_source_or_project_type][organization_id][project_id] ||= {}
      @shape[data_source_or_project_type][organization_id][project_id][:datasets] = datasets
      @shape[data_source_or_project_type][organization_id][project_id][:title] = {}
      @shape[data_source_or_project_type][organization_id][project_id][:title][:display] = true
      @shape[data_source_or_project_type][organization_id][project_id][:title][:text] = title
      @shape
    end

    # Detail view

    def detail_name(project_count, project_type, data_source_id, organization_id, project_id)
      if project_type != 'all'
        ptype = GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES[project_type]
        return "#{project_count_str(project_count, prefix: ptype)} on"
      end

      projects = project_count_str(project_count)
      return "#{projects} from All Sources on" if data_source_id == 'all'

      if organization_id == 'all'
        data_source_name = GrdaWarehouse::DataSource.find(data_source_id.to_i).name
        return "#{projects} from #{data_source_name} on"
      end

      organization_name = GrdaWarehouse::Hud::Organization.find(organization_id.to_i).name(@filter.user)
      return "#{projects} from #{organization_name} on" if project_id == 'all'

      project_name = GrdaWarehouse::Hud::Project.find(project_id.to_i).name(@filter.user)
      "#{project_name} at #{organization_name} on"
    end

    def clients_for_date(date, project_type, data_source, organization, project, population)
      known_sub_populations = GrdaWarehouse::ServiceHistoryEnrollment.known_standard_cohorts

      raise "Population #{population} not defined" unless known_sub_populations.include?(population.to_sym)

      columns = {
        'LastName' => c_t[:LastName].to_sql,
        'FirstName' => c_t[:FirstName].to_sql,
        'ProjectName' => she_t[:project_name].to_sql,
        'short_name' => ds_t[:short_name].to_sql,
        'client_id' => she_t[:client_id].to_sql,
        'project_id' => p_t[:id].to_sql,
        'confidential' => bool_or(p_t[:confidential], o_t[:confidential]),
      }

      enrollments = GrdaWarehouse::ServiceHistoryEnrollment.residential.
        send(population).
        service_on_date(date).
        joins(:client, :data_source, :organization, :project).
        merge(census_projects_scope) # merge with project scope filtered by @filter params

      enrollments = enrollments.in_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type]) if project_type && project_type != 'all'
      enrollments = enrollments.where(data_source_id: data_source.to_i) if data_source && data_source != 'all'
      enrollments = enrollments.merge(GrdaWarehouse::Hud::Organization.where(id: organization.to_i)) if organization && organization != 'all'
      enrollments = enrollments.merge(GrdaWarehouse::Hud::Project.where(id: project.to_i)) if project && project != 'all'

      enrollments.distinct.
        order(c_t[:LastName].asc, c_t[:FirstName].asc).
        pluck(*columns.values).
        map do |row|
          h = Hash[columns.keys.zip(row)]
          h['ProjectName'] = GrdaWarehouse::Hud::Project.confidential_project_name if h['confidential'] && !@filter.user.can_view_confidential_project_names?
          h
        end
    end

    def prior_year_averages(year, project_type, data_source, organization, project, population)
      start_date = Date.new(year).beginning_of_year
      end_date = Date.new(year).end_of_year
      days = (end_date - start_date).to_i

      local_census_scope = census_data_scope(census_projects_scope).for_date_range(start_date, end_date)

      if project_type && project_type != 'all'
        project_type_ids = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type]
        local_census_scope = local_census_scope.by_project_type(project_type_ids)
      end
      local_census_scope = local_census_scope.by_data_source_id(data_source.to_i) if data_source && data_source != 'all'
      local_census_scope = local_census_scope.by_organization_id(organization.to_i) if organization && organization != 'all'
      local_census_scope = local_census_scope.by_project_id(project.to_i) if project && project != 'all'

      averages = { year: year }
      # sum and divide by total days to find the average. can't average columns directly since they're split by project.
      column = population == :clients ? :all_clients : population
      averages[:ave_client_count] = percentage(local_census_scope.sum(column), days)

      if population == :all_clients
        averages[:ave_bed_inventory] = percentage(local_census_scope.sum(:beds), days)
        averages[:ave_seasonal_inventory] = seasonal_inventory(year)&.round(2) || 0
      end

      averages
    end

    private def percentage(numerator, denominator)
      pct = numerator / denominator
      pct&.round(2) || 0
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

    private def build_control_sections
      []
    end
  end
end
