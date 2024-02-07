###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CensusTracking
  class Worksheet
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(filter)
      @filter = filter
      @project_type_sum = populations.keys.zip(Array.new(populations.keys.size, 0)).to_h
      @population_sum = populations.keys.zip(Array.new(populations.keys.size, 0)).to_h
    end

    def projects
      @projects ||= GrdaWarehouse::Hud::Project.
        preload(:organization).
        viewable_by(@filter.user).
        where(id: @filter.effective_project_ids).
        map do |project|
          [
            HudUtility2024.project_type(project.computed_project_type) || 'Unknown Project Type',
            project.organization.name(@filter.user),
            project.name(@filter.user),
            project.id,
          ]
        end.
        sort_by { |project| [project[0], project[1], project[2]] }
    end

    def clients_by_project(project_id, population)
      population_query = populations[population]
      clients = filter_by_population(service_data_by_project(project_id), population_query)
      @project_type_sum[population] += clients.count
      @population_sum[population] += clients.count

      clients
    end

    def client_count_by_project_type(_project_type_name, population, reset: true)
      result = @project_type_sum[population]
      @project_type_sum[population] = 0 if reset

      result
    end

    def client_count_by_population(population)
      return @population_sum[population]
    end

    def populations # rubocop:disable Metrics/AbcSize
      @populations ||= {
        'Individual Men Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age < 18 },
            ->(client) { client.gender_multi == [1] },
          ],
        'Individual Trans Men Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age < 18 },
            ->(client) { client.gender_multi == [1, 5] },
          ],
        'Individual Women Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age < 18 },
            ->(client) { client.gender_multi == [0] },
          ],
        'Individual Trans Women Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age < 18 },
            ->(client) { client.gender_multi == [0, 5] },
          ],
        'Gender Non-conforming Individuals Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age < 18 },
            ->(client) { client.gender_multi.include?(4) },
          ],
        'Individual Adult Men Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender_multi == [1] },
          ],
        'Individual Adult Trans Men Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender_multi == [1, 5] },
          ],
        'Individual Adult Women Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender_multi == [0] },
          ],
        'Individual Adult Trans Women Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender_multi == [0, 5] },
          ],
        'Gender Non-conforming Individual Adults Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender_multi.include?(4) },
          ],
        'Individual Adult Men Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 25 },
            ->(client) { client.gender_multi == [1] },
          ],
        'Individual Adult Trans Men Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 25 },
            ->(client) { client.gender_multi == [1, 5] },
          ],
        'Individual Adult Women Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 25 },
            ->(client) { client.gender_multi == [0] },
          ],
        'Individual Adult Trans Women Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 25 },
            ->(client) { client.gender_multi == [0, 5] },
          ],
        'Gender Non-conforming Individual Adults Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age.present? && client.age >= 25 },
            ->(client) { client.gender_multi.include?(4) },
          ],
        'Number of households with at least one adult age 18+ and at least one child under age 18' =>
          [
            ->(client) { client.head_of_household == true },
            ->(client) { client.age.present? && client.age >= 18 },
            ->(client) { client.other_clients_under_18.positive? },
          ],
        'Number of households with all members under age 18' =>
          [
            ->(client) { client.head_of_household == true },
            ->(client) { client.children_only == true },
          ],
        'Number of clients under age 18 in all households served' =>
          [
            ->(client) { client.presented_as_individual == false },
            ->(client) { client.age.present? && client.age < 18 },
          ],
        'Number of clients age 18-24 in all households served' =>
          [
            ->(client) { client.presented_as_individual == false },
            ->(client) { client.age.present? && client.age >= 18 && client.age <= 24 },
          ],
        'Number of clients age 25+ in all households served' =>
          [
            ->(client) { client.presented_as_individual == false },
            ->(client) { client.age.present? && client.age >= 25 },
          ],
        'Total PIT (including clients of unknown gender)' =>
          [],
      }
    end

    def headers
      ['Organization', 'Project'] + populations.keys
    end

    def footnote
      'Household counts are limited to households containing more than one client.'
    end

    private def filter_by_population(clients, population_queries)
      population_queries.each do |query|
        clients = clients.select { |client| query.call(client) }
      end
      clients
    end

    private def service_columns
      {
        project_id: p_t[:id],
        project_type: she_t[:project_type],
        presented_as_individual: she_t[:presented_as_individual],
        age: shs_t[:age],
        woman: c_t[:Woman],
        man: c_t[:man],
        transgender: c_t[:Transgender],
        non_binary: c_t[:NonBinary],
        culturally_specific: c_t[:CulturallySpecific],
        different_identity: c_t[:DifferentIdentity],
        head_of_household: she_t[:head_of_household],
        household_id: she_t[:household_id],
        # For details view
        client_id: she_t[:client_id],
        first_name: c_t[:FirstName],
        last_name: c_t[:LastName],
        project_name: she_t[:project_name],
      }
    end

    private def service_data_by_project(project_id)
      if @last_project_id != project_id
        @all_data ||= service_scope.pluck(*service_columns.values).group_by(&:first)
        @data = transform(@all_data[project_id] || [])
        @last_project_id = project_id
      end
      @data
    end

    private def transform(data)
      rows = data.
        map do |row|
          client = ::OpenStruct.new(service_columns.keys.zip(row).to_h)
          client.gender_multi = []
          client.gender_multi << 0 if client.woman == 1
          client.gender_multi << 1 if client.man == 1
          client.gender_multi << 2 if client.culturally_specific == 1
          client.gender_multi << 3 if client.different_identity == 1
          client.gender_multi << 5 if client.transgender == 1
          client.gender_multi << 4 if client.non_binary == 1
          client.gender_multi&.sort!
          client
        end

      rows = rows.map do |row|
        row.other_clients_under_18 = rows.select do |candidate|
          candidate.household_id.present? &&
          candidate.household_id == row.household_id &&
            candidate.client_id != row.client_id &&
            candidate.age.present? && candidate.age < 18
        end.count
        row.only_children = rows.select do |candidate|
          candidate.household_id.present? &&
          candidate.household_id == row.household_id &&
            candidate.age.present? && candidate.age >= 18
        end.empty?

        row
      end

      rows
    end

    private def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    private def service_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:service_history_services, :client).
        service_on_date(@filter.on).
        in_project(projects.map(&:last))

      scope = filter_for_user_access(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_race(scope)
      scope = filter_for_gender(scope)

      scope
    end
  end
end
