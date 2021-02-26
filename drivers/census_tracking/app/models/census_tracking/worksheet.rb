###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CensusTracking
  class Worksheet
    include ArelHelper

    def initialize(filter)
      @filter = filter
    end

    def projects
      projects = GrdaWarehouse::Hud::Project.
        preload(:organization).
        viewable_by(@filter.user).
        where(id: @filter.effective_project_ids)

      projects.map { |project| [HUD.project_type(project.compute_project_type), project.organization.name, project.safe_project_name, project.id] }.
        sort_by { |project| [project[0], project[1], project[2]] }
    end

    def clients_by_project(project_id, query)
      scope = service_scope.in_project(project_id)
      clients_by_population(query, scope: scope)
    end

    def clients_by_project_type(project_type, query)
      scope = service_scope.in_project_type(HUD.project_type(project_type, true))
      clients_by_population(query, scope: scope)
    end

    def clients_by_population(query, scope: service_scope)
      scope.where(query)
    end

    def populations  # rubocop:disable Metrics/AbcSize
      @populations ||= {
        'Unaccompanied Males Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(1)),
        'Unaccompanied Trans Males Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(3)),
        'Unaccompanied Females Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(0)),
        'Unaccompanied Trans Females Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(2)),
        'Unaccompanied Gender Non-conforming Under Age 18' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].lt(18)).and(c_t[:Gender].eq(4)),
        'Single Adult Males Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(1)),
        'Single Adult Trans Males Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(3)),
        'Single Adult Females Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(0)),
        'Single Adult Trans Females Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(2)),
        'Single Adult Gender Non-conforming Age 18-24' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].between(18..24)).and(c_t[:Gender].eq(4)),
        'Single Adult Males Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(1)),
        'Single Adult Trans Males Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(3)),
        'Single Adult Females Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(0)),
        'Single Adult Trans Females Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(2)),
        'Single Adult Gender Non-conforming Age 25+' => she_t[:presented_as_individual].eq(true).and(shs_t[:age].gteq(25)).and(c_t[:Gender].eq(4)),
        'Number of households with at least one adult age 18+ and at least one child under age 18' => she_t[:head_of_household].eq(true).and(shs_t[:age].gteq(18)).and(she_t[:other_clients_under_18].gt(0)),
        'Number of households with all members under age 18' => she_t[:head_of_household].eq(true).and(she_t[:children_only].eq(true)),
        'Number of clients under age 18 in all households served' => she_t[:presented_as_individual].eq(false).and(shs_t[:age].lt(18)),
        'Number of clients age 18-24 in all households served' => she_t[:presented_as_individual].eq(false).and(shs_t[:age].between(18..24)),
        'Number of clients age 25+ in all households served' => she_t[:presented_as_individual].eq(false).and(shs_t[:age].gteq(25)),
        'Total PIT (including clients of unknown gender)' => Arel.sql('1=1'),
      }
    end

    private def service_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:service_history_services, :client).
        service_on_date(@filter.on).
        in_project(@filter.effective_project_ids)

      scope = scope.in_coc(coc_code: @filter.coc_codes) if @filter.coc_codes.present?
      scope = scope.in_data_source(@filter.data_source_ids) if @filter.data_source_ids.present?
      scope = scope.in_organization(@filter.organization_ids) if @filter.organization_ids.present?
      scope = scope.where(c_t[:Ethnicity].in(@filter.ethnicities)) if @filter.ethnicities.present?

      race_filter = nil
      @filter.races.each do |race|
        if race_filter
          race_filter = race_filter.or(c_t[race].eq(1))
        else
          race_filter = c_t[race].eq(1)
        end
      end
      scope = scope.where(race_filter) if race_filter.present?
      scope = scope.where(c_t[:Gender].in(@filter.genders)) if @filter.genders.present?

      scope
    end
  end
end
