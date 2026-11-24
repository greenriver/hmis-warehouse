###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Performance Metrics takes its RRH and PSH lengths of stay from the outcomes reports,
# which read Reporting::Housed and only understand their own sub-population keys. The
# report's filter carries a registered sub-population (AvailableSubPopulations), so this
# restricts the housed stays to it, matching each *_sub_pop driver's definition against
# the household and client columns Reporting::Housed copies from the stay's enrollment.
#
# A sub-population with no faithful equivalent in Reporting::Housed gets no stays rather
# than every client's stays; see #supported?.
module PerformanceMetrics
  class OutcomesSubPopulation
    # Reporting::Housed has no household ID or head-of-household age, so the
    # head-of-household age sub-populations (e.g. :adults_with_children_youth_hoh)
    # cannot be matched to a stay.
    SUPPORTED_SUB_POPULATIONS = [
      :clients,
      :veterans,
      :non_veterans,
      :adult_only_households,
      :adults_with_children,
      :child_only_households,
    ].freeze

    def initialize(sub_population)
      @sub_population = sub_population&.to_sym
    end

    def supported?
      @sub_population.in?(SUPPORTED_SUB_POPULATIONS)
    end

    # @param housed_scope [ActiveRecord::Relation<Reporting::Housed>]
    def restrict(housed_scope)
      case @sub_population
      when :clients
        housed_scope
      when :veterans
        housed_scope.where(veteran_status: veteran_yes)
      when :non_veterans
        not_veteran = housed_t[:veteran_status].not_eq(veteran_yes).
          or(housed_t[:veteran_status].eq(nil))
        housed_scope.where(not_veteran)
      when :adult_only_households
        # Same rule as ServiceHistoryEnrollment.adult_only_households: an adult with
        # nobody under 18 in the household.
        housed_scope.where(individual_adult: true)
      when :child_only_households
        # Same rule as ServiceHistoryEnrollment.child_only_households: a child with no
        # adults in the household.
        housed_scope.where(children_only: true)
      when :adults_with_children
        # An adult who is not an individual adult has a child in the household, and a
        # child who is not in a children-only household has an adult in it. Both flags
        # are false for a client of unknown age, so require a DOB.
        housed_scope.
          where(individual_adult: false, children_only: false).
          where.not(dob: nil)
      else
        housed_scope.none
      end
    end

    private def veteran_yes
      HudHelper.util.no_yes_reasons_for_missing_data_options.key('Yes')
    end

    private def housed_t
      Reporting::Housed.arel_table
    end
  end
end
