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

      join_condition = hh_ctx_table[:service_history_enrollment_id].eq(@a_t[:id]).
        and(hh_ctx_table[:report_instance_id].eq(@report.id))

      join = @a_t.join(hh_ctx_table, Arel::Nodes::OuterJoin).on(join_condition)

      scope.joins(join.join_sources)
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
      @a_t[:age].gteq(18).or(hoh_clause)
    end

    def chronic_household_clause
      hh_ctx[:inherited_chronic_status].eq(true).and(hoh_clause)
    end

    def parenting_youth_clause
      hh_ctx[:is_parenting_youth].eq(true)
    end
  end
end
