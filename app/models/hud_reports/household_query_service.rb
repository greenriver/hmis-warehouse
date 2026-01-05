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

      # We need to ensure that the semantic scopes use the correct arel table (e.g. AprClient)
      # rather than the base UniverseMember table. We define a dynamic module that captures
      # our instance's @a_t and overrides the default universe_arel_table in the Filters module.
      context_a_t = @a_t
      extension = Module.new do
        include Filters
        define_method(:universe_arel_table) { context_a_t }
      end

      scope.joins(join.join_sources).extending(extension)
    end

    module Filters
      def hh_ctx
        @hh_ctx ||= Arel::Table.new(:hh_ctx)
      end

      def universe_arel_table
        arel_table
      end

      def hh_column(name)
        if universe_arel_table.name == 'hud_report_apr_clients'
          case name
          when :household_type then universe_arel_table[:household_type]
          when :inherited_chronic_status then universe_arel_table[:chronically_homeless]
          when :is_hoh then universe_arel_table[:head_of_household]
          when :relationship_to_hoh then universe_arel_table[:relationship_to_hoh]
          when :age then universe_arel_table[:age]
          when :is_parenting_youth then universe_arel_table[:parenting_youth]
          when :has_other_clients_over_25 then universe_arel_table[:other_clients_over_25]
          when :household_id then universe_arel_table[:household_id]
          when :hoh_id then universe_arel_table[:head_of_household_id]
          when :inherited_move_in_date then universe_arel_table[:adjusted_move_in_date]
          when :hoh_move_in_date then universe_arel_table[:hoh_move_in_date]
          when :inherited_chronic_detail then universe_arel_table[:chronically_homeless_detail]
          else hh_ctx[name]
          end
        else
          hh_ctx[name]
        end
      end

      def for_household_type(type)
        where(hh_column(:household_type).eq(type))
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
        where(hh_column(:inherited_chronic_status).eq(true))
      end

      def chronically_homeless_pit
        where(hh_column(:inherited_pit_chronic_status).eq(true))
      end

      def heads_of_household
        where(hh_column(:is_hoh).eq(true))
      end

      def hoh_or_spouses
        where(hh_column(:relationship_to_hoh).in([1, 3]))
      end

      def adults_or_hohs
        where(hh_column(:age).gteq(18).or(hh_column(:is_hoh).eq(true)))
      end

      def parenting_youth
        where(hh_column(:is_parenting_youth).eq(true))
      end

      def youth_only_households
        where(hh_column(:has_other_clients_over_25).eq(false))
      end

      def youth_adults_or_youth_hohs
        youth_only_households.where(
          hh_column(:is_hoh).eq(true).and(hh_column(:age).in(12..24)).
            or(hh_column(:age).in(18..24)),
        )
      end

      def between_ages(range)
        where(hh_column(:age).in(range))
      end

      def strict_leavers(report_end_date)
        where(
          universe_arel_table[:last_date_in_program].lteq(report_end_date).and(
            hh_column(:is_hoh).eq(true).or(
              hh_column(:hoh_exit_date).eq(universe_arel_table[:last_date_in_program]),
            ),
          ),
        )
      end

      def chronic_households
        where(hh_column(:inherited_chronic_status).eq(true).and(hh_column(:is_hoh).eq(true)))
      end
    end

    def hh_column(name)
      if @a_t.name == 'hud_report_apr_clients'
        case name
        when :household_type then @a_t[:household_type]
        when :inherited_chronic_status then @a_t[:chronically_homeless]
        when :is_hoh then @a_t[:head_of_household]
        when :relationship_to_hoh then @a_t[:relationship_to_hoh]
        when :age then @a_t[:age]
        when :is_parenting_youth then @a_t[:parenting_youth]
        when :has_other_clients_over_25 then @a_t[:other_clients_over_25]
        when :household_id then @a_t[:household_id]
        when :hoh_id then @a_t[:head_of_household_id]
        when :inherited_move_in_date then @a_t[:adjusted_move_in_date]
        when :hoh_move_in_date then @a_t[:hoh_move_in_date]
        when :inherited_chronic_detail then @a_t[:chronically_homeless_detail]
        else hh_ctx[name]
        end
      else
        hh_ctx[name]
      end
    end

    def hoh_clause
      hh_column(:is_hoh).eq(true)
    end

    def hoh_or_spouse_clause
      hh_column(:relationship_to_hoh).in([1, 3])
    end

    def adult_or_hoh_clause
      hh_column(:age).gteq(18).or(hoh_clause)
    end

    def strict_leavers_clause(report_end_date)
      @a_t[:last_date_in_program].lteq(report_end_date).and(
        hoh_clause.or(
          hh_column(:hoh_exit_date).eq(@a_t[:last_date_in_program]),
        ),
      )
    end

    def chronic_household_clause
      hh_column(:inherited_chronic_status).eq(true).and(hoh_clause)
    end

    def chronic_pit_household_clause
      hh_column(:inherited_pit_chronic_status).eq(true).and(hoh_clause)
    end

    def parenting_youth_clause
      hh_column(:is_parenting_youth).eq(true)
    end

    def sub_populations
      {
        'Total' => Arel.sql('1=1'),
        'Without Children' => hh_column(:household_type).eq('adults_only'),
        'With Children and Adults' => hh_column(:household_type).eq('adults_and_children'),
        'With Only Children' => hh_column(:household_type).eq('children_only'),
        'Unknown Household Type' => hh_column(:household_type).eq('unknown'),
        'Chronically Homeless' => hh_column(:inherited_chronic_status).eq(true),
        'Chronically Homeless (PIT)' => hh_column(:inherited_pit_chronic_status).eq(true),
      }
    end

    def youth_only_clause
      hh_column(:has_other_clients_over_25).eq(false)
    end

    def between_ages_clause(range)
      hh_column(:age).in(range)
    end

    def youth_adults_or_youth_hohs_clause
      hh_column(:has_other_clients_over_25).eq(false).and(
        hh_column(:is_hoh).eq(true).and(hh_column(:age).in(12..24)).
          or(hh_column(:age).in(18..24)),
      )
    end

    def hoh_exit_dates(members_scope)
      members_scope.where(hoh_clause).pluck(hh_column(:household_id), @a_t[:last_date_in_program]).to_h
    end
  end
end
