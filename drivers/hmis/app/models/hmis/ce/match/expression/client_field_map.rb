# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for GrdaWarehouse::Hud::Client fields
  # This class resolves fields that are columns on the `Client` table or one of its associations.
  class ClientFieldMap
    attr_reader :current_date

    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    def client_query(clients, field)
      callback = all.dig(field.to_sym, :query)
      raise ArgumentError, "Field \"#{field}\" is not supported" unless callback

      callback.call(clients)
    end

    def arel_field(field)
      all.dig(field.to_sym, :arel_field)
    end

    def joins(field)
      all.dig(field.to_sym, :joins)
    end

    # Label for user-facing display of resolved field
    def label_for(field)
      all.dig(field.to_sym, :label) || field.to_s.humanize
    end

    # Value for user-facing display of resolved field
    def format_for_display(field, value)
      formatted = all.dig(field.to_sym, :format_for_display)&.call(value)
      return value if formatted.nil?

      formatted
    end

    private

    def arel
      Hmis::ArelHelper
    end

    def all
      @all ||= {
        days_since_last_exit: days_since_last_exit_field,
        veteran_status: veteran_status_field,
        current_age: current_age_field,
        open_enrollment_project_types: open_enrollment_project_types_field,
        open_enrollment_project_types_excluding_incomplete: open_enrollment_project_types_excluding_incomplete_field,
        open_referral_project_types: open_referral_project_types_field,
        cohorts: cohorts_field,
      }
    end

    def days_since_last_exit_field
      calculator = LastEnrolledDaysCalculator.new(@current_date)
      {
        query: ->(clients) { calculator.call(clients) },
        joins: [{ hmis_source_clients: { enrollments: :exit } }],
        arel_field: calculator.arel_expression,
        format_for_display: method(:format_days),
      }
    end

    def veteran_status_field
      {
        query: ->(clients) { clients.pluck(:id, :veteran_status).to_h },
        format_for_display: ->(v) { HudHelper.util.veteran_status(v) },
        arel_field: arel.c_t['VeteranStatus'],
      }
    end

    def current_age_field
      calculator = AgeCalculator.new(@current_date)
      {
        query: ->(clients) { calculator.call(clients) },
        arel_field: calculator.arel_expression,
      }
    end

    def open_enrollment_project_types_field
      {
        query: ->(clients) { project_types_query(clients, Hmis::Hud::Enrollment.open_including_wip, :project) },
        format_for_display: method(:format_project_types),
      }
    end

    def open_enrollment_project_types_excluding_incomplete_field
      {
        query: ->(clients) { project_types_query(clients, Hmis::Hud::Enrollment.open_excluding_wip, :project) },
        format_for_display: method(:format_project_types),
      }
    end

    # Active cohort memberships for each destination client (cohort primary keys).
    # Uses +CohortClient.active+ only so inactive rows on a cohort tab do not count.
    def cohorts_field
      {
        label: 'Cohort membership',
        query: ->(clients) { cohort_ids_query(clients) },
        format_for_display: method(:format_cohort_ids),
      }
    end

    def open_referral_project_types_field
      {
        query: ->(clients) do
          # Get project types from CE referrals
          ce_referrals_result = project_types_query(clients, Hmis::Ce::Referral.active, :target_project)

          # Get project types from legacy referrals
          legacy_referrals_scope = HmisExternalApis::AcHmis::ReferralHouseholdMember.joins(:postings).
            merge(HmisExternalApis::AcHmis::ReferralPosting.active)
          legacy_referrals_result = project_types_query(clients, legacy_referrals_scope, postings: :project)

          # Merge results from both referral types
          ce_referrals_result.merge(legacy_referrals_result) { |_key, values1, values2| (values1 + values2).uniq.sort }
        end,
        format_for_display: method(:format_project_types),
      }
    end

    # Returns a hash mapping client IDs to arrays of project type IDs
    # @return [Hash{Integer => Array<Integer>}] e.g. { 123 => [1, 3, 13], 456 => [2, 4], 789 => [] }
    def project_types_query(clients, scope, project_association)
      client_ids = clients.pluck(:id)
      values = scope.joins(client: :warehouse_client_source).
        where(warehouse_clients: { destination_id: client_ids }).
        joins(project_association).
        distinct.
        pluck(arel.wc_t[:destination_id], arel.p_t['ProjectType'])

      result = values.group_by(&:first).transform_values { |rows| rows.map(&:last) }
      client_ids.each { |client_id| result[client_id] ||= [] }
      result
    end

    # @return [Hash{Integer => Array<Integer>}] cohort ids per destination client id
    def cohort_ids_query(clients)
      client_ids = clients.pluck(:id)
      values = GrdaWarehouse::CohortClient.active.
        where(client_id: client_ids).
        distinct.
        pluck(:client_id, :cohort_id)

      result = values.group_by(&:first).transform_values { |pairs| pairs.map(&:last).uniq.sort }
      client_ids.each { |client_id| result[client_id] ||= [] }
      result
    end

    # display helpers
    def helpers = ApplicationController.helpers
    def format_days(days) = days.nil? ? nil : helpers.pluralize(days, 'day')
    def format_project_types(project_type_ids) = project_type_ids.uniq.map { |t| HudHelper.util('2026').project_type(t) }

    def format_cohort_ids(cohort_ids)
      ids = Array(cohort_ids).compact_blank.uniq.sort
      return [] if ids.empty?

      names_by_id = GrdaWarehouse::Cohort.where(id: ids).pluck(:id, :name).to_h
      ids.map { |id| names_by_id[id].presence || "Cohort ##{id}" }
    end
  end
end
