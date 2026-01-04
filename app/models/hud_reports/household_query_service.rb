# frozen_string_literal: true

module HudReports
  # Provides a standardized interface for accessing pre-computed household attributes within HUD reports.
  #
  # This service joins the `hud_report_household_contexts` table into report queries, allowing
  # complex population filtering (e.g., household types, chronic status inheritance) to be
  # performed via SQL rather than expensive runtime Ruby calculations or memory-intensive global caches.
  class HouseholdQueryService
    attr_reader :hh_ctx

    def initialize(report, universe_arel_table)
      @report = report
      @a_t = universe_arel_table
      @hh_ctx = Arel::Table.new(:hh_ctx)
    end

    def with_household_context(scope)
      hh_ctx_table = Arel::Table.new(:hud_report_household_contexts).alias(:hh_ctx)

      # Determine the join condition based on the table we're joining to.
      # ServiceHistoryEnrollment joins on its primary key (id).
      # Report-specific clients (like AprClient) join on source_enrollment_id.
      join_condition = if @a_t.name == 'service_history_enrollments'
        hh_ctx_table[:service_history_enrollment_id].eq(@a_t[:id])
      else
        hh_ctx_table[:source_enrollment_id].eq(@a_t[:source_enrollment_id])
      end

      join_condition = join_condition.and(hh_ctx_table[:report_instance_id].eq(@report.id))

      join = @a_t.join(hh_ctx_table, Arel::Nodes::OuterJoin).on(join_condition)

      scope.joins(join.join_sources).extending(Filters)
    end

    module Filters
      def hh_ctx
        @hh_ctx ||= Arel::Table.new(:hh_ctx)
      end

      def a_t
        @a_t ||= arel_table
      end

      def for_household_type(type)
        where(hh_ctx[:household_type].eq(type))
      end

      def without_children
        for_household_type('adults_only')
      end

      def with_children_and_adults
        for_household_type('adults_and_children')
      end

      def with_only_children
        for_household_type('children_only')
      end

      def unknown_household_type
        for_household_type('unknown')
      end

      def chronically_homeless
        where(hh_ctx[:inherited_chronic_status].eq(true))
      end

      def heads_of_household
        where(hh_ctx[:is_hoh].eq(true))
      end

      def hoh_or_spouses
        where(hh_ctx[:relationship_to_hoh].in([1, 3]))
      end

      def adults_or_hohs
        where(hh_ctx[:age].gteq(18).or(hh_ctx[:is_hoh].eq(true)))
      end

      def parenting_youth
        where(hh_ctx[:is_parenting_youth].eq(true))
      end

      def youth_only_households
        where(hh_ctx[:has_other_clients_over_25].eq(false))
      end

      def youth_adults_or_youth_hohs
        youth_only_households.where(
          hh_ctx[:is_hoh].eq(true).and(hh_ctx[:age].in(12..24)).
            or(hh_ctx[:age].in(18..24)),
        )
      end

      def between_ages(range)
        where(hh_ctx[:age].in(range))
      end

      def strict_leavers(report_end_date)
        where(
          a_t[:last_date_in_program].lteq(report_end_date).and(
            hh_ctx[:is_hoh].eq(true).or(
              hh_ctx[:hoh_exit_date].eq(a_t[:last_date_in_program]),
            ),
          ),
        )
      end

      def chronic_households
        where(hh_ctx[:inherited_chronic_status].eq(true).and(hh_ctx[:is_hoh].eq(true)))
      end
    end

    def hoh_clause
      hh_ctx[:is_hoh].eq(true)
    end

    def hoh_or_spouse_clause
      hh_ctx[:relationship_to_hoh].in([1, 3])
    end

    def adult_or_hoh_clause
      hh_ctx[:age].gteq(18).or(hh_ctx[:is_hoh].eq(true))
    end

    def strict_leavers_clause(report_end_date)
      @a_t[:last_date_in_program].lteq(report_end_date).and(
        hh_ctx[:is_hoh].eq(true).or(
          hh_ctx[:hoh_exit_date].eq(@a_t[:last_date_in_program]),
        ),
      )
    end

    def chronic_household_clause
      hh_ctx[:inherited_chronic_status].eq(true).and(hh_ctx[:is_hoh].eq(true))
    end

    def parenting_youth_clause
      hh_ctx[:is_parenting_youth].eq(true)
    end

    def sub_populations
      {
        'Total' => Arel.sql('1=1'),
        'Without Children' => hh_ctx[:household_type].eq('adults_only'),
        'With Children and Adults' => hh_ctx[:household_type].eq('adults_and_children'),
        'With Only Children' => hh_ctx[:household_type].eq('children_only'),
        'Unknown Household Type' => hh_ctx[:household_type].eq('unknown'),
        'Chronically Homeless' => hh_ctx[:inherited_chronic_status].eq(true),
      }
    end

    def hoh_clause
      hh_ctx[:is_hoh].eq(true)
    end

    def hoh_or_spouse_clause
      hh_ctx[:relationship_to_hoh].in([1, 3])
    end

    def adult_or_hoh_clause
      hh_ctx[:age].gteq(18).or(hoh_clause)
    end

    def strict_leavers_clause(report_end_date)
      @a_t[:last_date_in_program].lteq(report_end_date).and(
        hoh_clause.or(
          hh_ctx[:hoh_exit_date].eq(@a_t[:last_date_in_program]),
        ),
      )
    end

    def chronic_household_clause
      hh_ctx[:inherited_chronic_status].eq(true).and(hoh_clause)
    end

    def parenting_youth_clause
      hh_ctx[:is_parenting_youth].eq(true)
    end

    def youth_only_clause
      hh_ctx[:has_other_clients_over_25].eq(false)
    end

    def between_ages_clause(range)
      hh_ctx[:age].in(range)
    end

    def youth_adults_or_youth_hohs_clause
      hh_ctx[:has_other_clients_over_25].eq(false).and(
        hh_ctx[:is_hoh].eq(true).and(hh_ctx[:age].in(12..24)).
          or(hh_ctx[:age].in(18..24)),
      )
    end

    def hoh_exit_dates(members_scope)
      members_scope.where(hoh_clause).pluck(hh_ctx[:household_id], @a_t[:last_date_in_program]).to_h
    end
  end
end
