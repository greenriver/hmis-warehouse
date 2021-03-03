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
      projects = GrdaWarehouse::Hud::Project.
        preload(:organization).
        viewable_by(@filter.user).
        where(id: @filter.effective_project_ids)

      projects.map { |project| [HUD.project_type(project.computed_project_type), project.organization.name, project.safe_project_name, project.id] }.
        sort_by { |project| [project[0], project[1], project[2]] }
    end

    def clients_by_project(project_id, population_query)
      service_scope.
        in_project(project_id).
        where(population_query)
    end

    def clients_by_project_type(project_type, population_query)
      service_scope.
        in_project_type(HUD.project_type(project_type, true)).
        where(population_query)
    end

    def clients_by_population(population_query)
      service_scope.where(population_query)
    end

    def populations  # rubocop:disable Metrics/AbcSize
      @populations ||= {
        'Individual Males Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(1)),
        'Individual Trans Males Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(3)),
        'Individual Females Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(0)),
        'Individual Trans Females Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(2)),
        'Gender Non-conforming Individuals Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(4)),
        'Individual Adult Males Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(1)),
        'Individual Adult Trans Males Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(3)),
        'Individual Adult Females Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(0)),
        'Individual Adult Trans Females Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(2)),
        'Gender Non-conforming Individual Adults Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(4)),
        'Individual Adult Males Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(1)),
        'Individual Adult Trans Males Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(3)),
        'Individual Adult Females Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(0)),
        'Individual Adult Trans Females Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(2)),
        'Gender Non-conforming Individual Adults Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(4)),
        'Number of households with at least one adult age 18+ and at least one child under age 18' => she_t[:head_of_household].eq(true).and(shs_t[:age].gteq(18)).and(she_t[:other_clients_under_18].gt(0)),
        'Number of households with all members under age 18' => she_t[:head_of_household].eq(true).and(she_t[:children_only].eq(true)),
        'Number of clients under age 18 in all households served' => she_t[:presented_as_individual].eq(false).and(shs_t[:age].lt(18)),
        'Number of clients age 18-24 in all households served' => she_t[:presented_as_individual].eq(false).and(shs_t[:age].between(18..24)),
        'Number of clients age 25+ in all households served' => she_t[:presented_as_individual].eq(false).and(shs_t[:age].gteq(25)),
        'Total PIT (including clients of unknown gender)' => Arel.sql('1=1'),
      }
    end

    def headers
      ['Organization', 'Project'] + populations.keys
    end

    def footnote
      'Household counts are limited to households containing more than one client.'
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
