# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for GrdaWarehouse::Hud::Client fields
  # This class resolves fields that are columns on the `Client` table or one of its associations.
  class ClientFieldMap
    # todo @martha - maybe get this to match Gig's implementation a bit more closely, or revert many of the changes to reduce the diff/churn.
    attr_reader :current_date

    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    # todo @martha - labels in this file should get replaced with using label_for, see gig's comment: https://github.com/greenriver/hmis-warehouse/pull/6590#discussion_r3415657883
    def client_query(clients, field)
      client_field = field_by_key[field.to_sym]
      raise ArgumentError, "Field \"#{field}\" is not supported" unless client_field

      client_field.query.call(clients)
    end

    def arel_field(field)
      field_by_key.dig(field.to_sym)&.arel_field
    end

    def joins(field)
      field_by_key.dig(field.to_sym)&.joins
    end

    # Label for user-facing display of resolved field
    def label_for(field)
      field_by_key.dig(field.to_sym)&.label || field.humanize
    end

    # Value for user-facing display of resolved field
    def format_for_display(field, value)
      formatted = field_by_key.dig(field.to_sym)&.format_for_display&.call(value)
      return value if formatted.nil?

      formatted
    end

    def fields
      @fields ||= [
        days_since_last_exit_field,
        veteran_status_field,
        current_age_field,
        open_enrollment_project_types_field,
        open_enrollment_project_types_excluding_incomplete_field,
        open_referral_project_types_field,
      ].freeze
    end

    private

    def arel
      Hmis::ArelHelper
    end

    def field_by_key
      @field_by_key ||= fields.index_by(&:key).freeze
    end

    def days_since_last_exit_field
      calculator = LastEnrolledDaysCalculator.new(@current_date)
      ClientField.new(
        key: :days_since_last_exit,
        value_type: ValueType::NUMERIC,
        label: 'Days since last exit',
        description: nil,
        pick_list: nil,
        query: ->(clients) { calculator.call(clients) },
        joins: [{ hmis_source_clients: { enrollments: :exit } }],
        arel_field: calculator.arel_expression,
        format_for_display: method(:format_days),
      )
    end

    def veteran_status_field
      ClientField.new(
        key: :veteran_status,
        value_type: ValueType::NUMERIC,
        label: 'Veteran status',
        description: nil,
        pick_list: 'NoYesReasonsForMissingData',
        query: ->(clients) { clients.pluck(:id, :veteran_status).to_h },
        format_for_display: ->(v) { HudHelper.util.veteran_status(v) },
        arel_field: arel.c_t['VeteranStatus'],
        joins: nil,
      )
    end

    def current_age_field
      calculator = AgeCalculator.new(@current_date)
      ClientField.new(
        key: :current_age,
        value_type: ValueType::NUMERIC,
        label: 'Current age',
        description: nil,
        pick_list: nil,
        query: ->(clients) { calculator.call(clients) },
        arel_field: calculator.arel_expression,
        joins: nil,
        format_for_display: nil,
      )
    end

    def open_enrollment_project_types_field
      ClientField.new(
        key: :open_enrollment_project_types,
        value_type: ValueType::NUMERIC_ARRAY,
        label: 'Open enrollment project types',
        description: nil,
        pick_list: 'ProjectType',
        query: ->(clients) { project_types_query(clients, Hmis::Hud::Enrollment.open_including_wip, :project) },
        format_for_display: method(:format_project_types),
        arel_field: nil,
        joins: nil,
      )
    end

    def open_enrollment_project_types_excluding_incomplete_field
      ClientField.new(
        key: :open_enrollment_project_types_excluding_incomplete,
        value_type: ValueType::NUMERIC_ARRAY,
        label: 'Open enrollment project types excluding incomplete enrollments',
        description: nil,
        pick_list: 'ProjectType',
        query: ->(clients) { project_types_query(clients, Hmis::Hud::Enrollment.open_excluding_wip, :project) },
        format_for_display: method(:format_project_types),
        arel_field: nil,
        joins: nil,
      )
    end

    def open_referral_project_types_field
      ClientField.new(
        key: :open_referral_project_types,
        value_type: ValueType::NUMERIC_ARRAY,
        label: 'Open referral project types',
        description: nil,
        pick_list: 'ProjectType',
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
        arel_field: nil,
        joins: nil,
      )
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

    # display helpers
    def helpers = ApplicationController.helpers
    def format_days(days) = days.nil? ? nil : helpers.pluralize(days, 'day')
    def format_project_types(project_type_ids) = project_type_ids.uniq.map { |t| HudHelper.util('2026').project_type(t) }
  end
end
