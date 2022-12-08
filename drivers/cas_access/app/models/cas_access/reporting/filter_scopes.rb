###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess::Reporting::FilterScopes
  extend ActiveSupport::Concern
  included do
    private def filter_for_range(scope)
      scope.open_between(range)
    end

    private def filter_for_match_routes(scope)
      return scope if @filter.match_routes.blank?

      scope.on_route(@filter.match_routes)
    end

    private def filter_for_program_types(scope)
      return scope if @filter.program_types.blank?

      scope.program_type(@filter.program_types)
    end

    private def filter_for_agencies(scope)
      return scope if @filter.agencies.blank?

      scope.associated_with_agency(@filter.agencies)
    end

    private def filter_for_household_types(scope)
      return scope if @filter.household_types.blank?

      scope.in_household_type(@filter.household_types)
    end

    private def filter_for_veteran_statuses(scope)
      return scope if @filter.veteran_statuses.blank?

      scope.veteran_status(@filter.veteran_statuses)
    end

    private def filter_for_age_ranges(scope)
      return scope if @filter.age_ranges.blank?

      scope.age_range(@filter.age_ranges)
    end

    private def filter_for_genders(scope)
      return scope if @filter.genders.blank?

      scope.gender(@filter.genders)
    end

    private def filter_for_races(scope)
      return scope if @filter.races.blank?

      scope.race(@filter.races)
    end

    private def filter_for_ethnicities(scope)
      return scope if @filter.ethnicities.blank?

      scope.ethnicity(@filter.ethnicities)
    end

    private def filter_for_disabilities(scope)
      return scope if @filter.disabilities.blank?

      scope.disability(@filter.disabilities)
    end
  end
end
