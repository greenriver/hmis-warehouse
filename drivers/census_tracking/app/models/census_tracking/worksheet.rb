###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CensusTracking
  class Worksheet
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(filter)
      @filter = filter
    end

    def projects
      @projects ||= GrdaWarehouse::Hud::Project.
        preload(:organization).
        viewable_by(@filter.user).
        where(id: @filter.effective_project_ids).
        map do |project|
          [HUD.project_type(project.computed_project_type), project.organization.name, project.safe_project_name, project.id]
        end.
        sort_by { |project| [project[0], project[1], project[2]] }
    end

    def clients_by_project(project_id, population_query)
      filter_by_population(service_data_by_project[project_id], population_query)
    end

    def clients_by_project_type(project_type_name, population_query)
      project_type = HUD.project_type(project_type_name, true)
      filter_by_population(service_data_by_project_type[project_type], population_query)
    end

    def clients_by_population(population_query)
      filter_by_population(service_data, population_query)
    end

    def populations
      @populations ||= {
        'Individual Males Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age < 18 },
            ->(client) { client.gender == 1 },
          ],
        'Individual Trans Males Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age < 18 },
            ->(client) { client.gender == 3 },
          ],
        'Individual Females Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age < 18 },
            ->(client) { client.gender == 0 }, # rubocop:disable Style/NumericPredicate
          ],
        'Individual Trans Females Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age < 18 },
            ->(client) { client.gender == 2 },
          ],
        'Gender Non-conforming Individuals Under Age 18' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age < 18 },
            ->(client) { client.gender == 4 },
          ],
        'Individual Adult Males Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender == 1 },
          ],
        'Individual Adult Trans Males Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender == 3 },
          ],
        'Individual Adult Females Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender == 0 }, # rubocop:disable Style/NumericPredicate
          ],
        'Individual Adult Trans Females Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender == 2 },
          ],
        'Gender Non-conforming Individual Adults Age 18-24' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 18 && client.age <= 24 },
            ->(client) { client.gender == 4 },
          ],
        'Individual Adult Males Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 25 },
            ->(client) { client.gender == 1 },
          ],
        'Individual Adult Trans Males Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 25 },
            ->(client) { client.gender == 3 },
          ],
        'Individual Adult Females Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 25 },
            ->(client) { client.gender == 0 }, # rubocop:disable Style/NumericPredicate
          ],
        'Individual Adult Trans Females Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 25 },
            ->(client) { client.gender == 2 },
          ],
        'Gender Non-conforming Individual Adults Age 25+' =>
          [
            ->(client) { client.presented_as_individual == true },
            ->(client) { client.age >= 25 },
            ->(client) { client.gender == 4 },
          ],
        'Number of households with at least one adult age 18+ and at least one child under age 18' =>
          [
            ->(client) { client.head_of_household == true },
            ->(client) { client.age >= 18 },
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
            ->(client) { client.age < 18 },
          ],
        'Number of clients age 18-24 in all households served' =>
          [
            ->(client) { client.presented_as_individual == false },
            ->(client) { client.age >= 18 && client.age <= 24 },
          ],
        'Number of clients age 25+ in all households served' =>
          [
            ->(client) { client.presented_as_individual == false },
            ->(client) { client.age >= 25 },
          ],
        'Total PIT (including clients of unknown gender)' =>
          [],
      }
    end

    private def filter_by_population(clients, population_queries)
      population_queries.each do |query|
        clients = clients.select { |client| query.call(client) }
      end
      clients
    end

    def headers
      ['Organization', 'Project'] + populations.keys
    end

    def footnote
      'Household counts are limited to households containing more than one client.'
    end

    private def service_columns
      {
        project_id: p_t[:id],
        project_type: she_t[:project_type],
        presented_as_individual: she_t[:presented_as_individual],
        age: shs_t[:age],
        gender: c_t[:Gender],
        head_of_household: she_t[:head_of_household],
        household_id: she_t[:household_id],
        # For details view
        client_id: she_t[:client_id],
        first_name: c_t[:FirstName],
        last_name: c_t[:LastName],
        project_name: she_t[:project_name],
      }
    end

    private def service_data
      @service_data ||= begin
        rows = service_scope.
          pluck(*service_columns.values).
          map do |row|
            ::OpenStruct.new(service_columns.keys.zip(row).to_h)
          end

        rows = rows.map do |row|
          row.other_clients_under_18 = rows.select do |candidate|
            candidate.household_id == row.household_id &&
              candidate.client_id != row.client_id &&
              candidate.age < 18
          end.count
          row.only_children = rows.select do |candidate|
            candidate.household_id == row.household_id &&
              candidate.age >= 18
          end.empty?

          row
        end

        rows
      end
    end

    private def service_data_by_project_type
      @service_data_by_project_type ||= begin
        data = {}

        projects.map { |project| HUD.project_type(project[0], true) }.each do |project_type|
          data[project_type] = service_data.select { |row| row.project_type == project_type }
        end

        data
      end
    end

    private def service_data_by_project
      @service_data_by_project ||= begin
        data = {}

        projects.map { |project| project[3] }.each do |project_id|
          data[project_id] = service_data.select { |row| row.project_id.to_i == project_id }
        end

        data
      end
    end

    private def service_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:service_history_services, :client).
        service_on_date(@filter.on).
        in_project(@filter.effective_project_ids)

      scope = filter_for_cocs(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_race(scope)
      scope = filter_for_gender(scope)

      scope
    end
  end
end
