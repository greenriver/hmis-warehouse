###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for GrdaWarehouse::Hud::Client fields.
  # The Fields module defines expression-field metadata; the methods below resolve
  # client values and provide SQL/engine details for those fields.
  class ClientFieldMap
    module Fields
      DAYS_SINCE_LAST_EXIT = ClientField.new(
        key: :days_since_last_exit,
        value_type: ValueType::NUMERIC,
        multiple: false,
        description: 'Number of days since the client last exited an enrollment.',
      )

      VETERAN_STATUS = ClientField.new(
        key: :veteran_status,
        value_type: ValueType::NUMERIC,
        multiple: false,
        description: "The client's veteran status.",
      )

      CURRENT_AGE = ClientField.new(
        key: :current_age,
        value_type: ValueType::NUMERIC,
        multiple: false,
        description: "The client's current age in years.",
      )

      OPEN_ENROLLMENT_PROJECT_TYPES = ClientField.new(
        key: :open_enrollment_project_types,
        value_type: ValueType::NUMERIC,
        multiple: true,
        description: 'Project types for which the client currently has an open enrollment (including incomplete enrollments).',
      )

      OPEN_ENROLLMENT_PROJECT_TYPES_EXCLUDING_INCOMPLETE = ClientField.new(
        key: :open_enrollment_project_types_excluding_incomplete,
        value_type: ValueType::NUMERIC,
        multiple: true,
        description: 'Project types for which the client currently has an open enrollment (excluding incomplete enrollments).',
      )

      OPEN_REFERRAL_PROJECT_TYPES = ClientField.new(
        key: :open_referral_project_types,
        value_type: ValueType::NUMERIC,
        multiple: true,
        description: 'Project types for which the client currently has an open referral.',
      )

      ALL = [
        DAYS_SINCE_LAST_EXIT,
        VETERAN_STATUS,
        CURRENT_AGE,
        OPEN_ENROLLMENT_PROJECT_TYPES,
        OPEN_ENROLLMENT_PROJECT_TYPES_EXCLUDING_INCOMPLETE,
        OPEN_REFERRAL_PROJECT_TYPES,
      ].freeze
    end

    attr_reader :current_date

    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    def client_query(clients, field)
      field_config = field_config_by_key[field.to_sym]
      raise ArgumentError, "Field \"#{field}\" is not supported" unless field_config

      field_config.fetch(:query).call(clients)
    end

    def arel_field(field)
      field_config_by_key.dig(field.to_sym, :arel_field)
    end

    def joins(field)
      field_config_by_key.dig(field.to_sym, :joins)
    end

    # Label for user-facing display of resolved field
    def label_for(field)
      field.to_s.humanize
    end

    # Value for user-facing display of resolved field
    def format_for_display(field, value)
      formatted = field_config_by_key.dig(field.to_sym, :format_for_display)&.call(value)
      return value if formatted.nil?

      formatted
    end

    def fields
      Fields::ALL
    end

    private

    def arel
      Hmis::ArelHelper
    end

    def field_config_by_key
      @field_config_by_key ||= {
        Fields::DAYS_SINCE_LAST_EXIT.key => days_since_last_exit_field,
        Fields::VETERAN_STATUS.key => veteran_status_field,
        Fields::CURRENT_AGE.key => current_age_field,
        Fields::OPEN_ENROLLMENT_PROJECT_TYPES.key => open_enrollment_project_types_field,
        Fields::OPEN_ENROLLMENT_PROJECT_TYPES_EXCLUDING_INCOMPLETE.key => open_enrollment_project_types_excluding_incomplete_field,
        Fields::OPEN_REFERRAL_PROJECT_TYPES.key => open_referral_project_types_field,
      }
    end

    def days_since_last_exit_field
      calculator = LastEnrolledDaysCalculator.new(@current_date)
      {
        label: 'Days since last exit',
        query: ->(clients) { calculator.call(clients) },
        joins: [{ hmis_source_clients: { enrollments: :exit } }],
        arel_field: calculator.arel_expression,
        format_for_display: method(:format_days),
      }
    end

    def veteran_status_field
      {
        label: 'Veteran status',
        query: ->(clients) { clients.pluck(:id, :veteran_status).to_h },
        format_for_display: ->(v) { HudHelper.util.veteran_status(v) },
        arel_field: arel.c_t['VeteranStatus'],
        joins: nil,
      }
    end

    def current_age_field
      calculator = AgeCalculator.new(@current_date)
      {
        label: 'Current age',
        query: ->(clients) { calculator.call(clients) },
        arel_field: calculator.arel_expression,
        joins: nil,
        format_for_display: nil,
      }
    end

    def open_enrollment_project_types_field
      {
        label: 'Open enrollment project types',
        query: ->(clients) { project_types_query(clients, Hmis::Hud::Enrollment.open_including_wip, :project) },
        format_for_display: method(:format_project_types),
        arel_field: nil,
        joins: nil,
      }
    end

    def open_enrollment_project_types_excluding_incomplete_field
      {
        label: 'Open enrollment project types excluding incomplete enrollments',
        query: ->(clients) { project_types_query(clients, Hmis::Hud::Enrollment.open_excluding_wip, :project) },
        format_for_display: method(:format_project_types),
        arel_field: nil,
        joins: nil,
      }
    end

    def open_referral_project_types_field
      {
        label: 'Open referral project types',
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

    # display helpers
    def helpers = ApplicationController.helpers
    def format_days(days) = days.nil? ? nil : helpers.pluralize(days, 'day')
    def format_project_types(project_type_ids) = project_type_ids.uniq.map { |t| HudHelper.util('2026').project_type(t) }
  end
end
