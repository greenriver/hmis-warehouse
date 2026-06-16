# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for GrdaWarehouse::Hud::Client fields
  # This class resolves fields that are columns on the `Client` table or one of its associations.
  class ClientFieldMap
    # Catalog of client fields usable in CE Match Rule expressions.
    module Fields
      DAYS_SINCE_LAST_EXIT = ClientField.new(
        key: :days_since_last_exit,
        value_type: ValueType::NUMERIC,
        description: 'Number of days since the client last exited an enrollment. If the client still has one ore more open enrollments, this field evaluates to 0.'
      )

      VETERAN_STATUS = ClientField.new(
        key: :veteran_status,
        value_type: ValueType::STRING, # isn't it numeric? not sure
        pick_list: 'NoYesReasonsForMissingData',
        # description: clients veteran status
      )

      CURRENT_AGE = ClientField.new(
        key: :current_age,
        value_type: ValueType::NUMERIC,
        # description: clients current age in years
      )

      # Expression engine only; not yet available in the structured expression builder.
      OPEN_ENROLLMENT_PROJECT_TYPES = ClientField.new(
        key: :open_enrollment_project_types,
        value_type: ValueType::NUMERIC, # integer array? or strings? unsure
        # description: project types for which the client currently has an open enrollment (including incomplete enrollments)
      )

      OPEN_ENROLLMENT_PROJECT_TYPES_EXCLUDING_INCOMPLETE = ClientField.new(
        key: :open_enrollment_project_types_excluding_incomplete,
        value_type: ValueType::NUMERIC, # integer array? or strings? unsure
        # description: project types for which the client currently has an open enrollment (excluding incomplete enrollments)
      )

      OPEN_REFERRAL_PROJECT_TYPES = ClientField.new(
        key: :open_referral_project_types,
        value_type: ValueType::NUMERIC, # integer array? or strings? unsure
        # description: project types for which the client currently has an open referral
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
      field.to_s.humanize
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

    # display helpers
    def helpers = ApplicationController.helpers
    def format_days(days) = days.nil? ? nil : helpers.pluralize(days, 'day')
    def format_project_types(project_type_ids) = project_type_ids.uniq.map { |t| HudHelper.util('2026').project_type(t) }
  end
end
