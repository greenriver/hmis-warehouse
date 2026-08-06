###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Resolves PSDE field values for destination clients in batch.
  class PsdeValueResolver
    include Hmis::Concerns::HmisArelHelper

    # HUD DisabilityType codes, keyed by the names used across the warehouse (:physical, :substance, etc.)
    DISABILITY_TYPE_CODES = GrdaWarehouse::Hud::Disability.disability_types.invert.freeze

    # Maps NoYes-disability field keys to their HUD DisabilityType code. Substance use is deliberately
    # excluded here — it is dispatched separately in boolean_field_source because its meaningful-value set differs.
    NO_YES_DISABILITY_TYPES = {
      PsdeFieldRegistry::PHYSICAL_DISABILITY.key => DISABILITY_TYPE_CODES.fetch(:physical),
      PsdeFieldRegistry::DEVELOPMENTAL_DISABILITY.key => DISABILITY_TYPE_CODES.fetch(:developmental),
      PsdeFieldRegistry::CHRONIC_HEALTH_CONDITION.key => DISABILITY_TYPE_CODES.fetch(:chronic),
      PsdeFieldRegistry::HIV_AIDS.key => DISABILITY_TYPE_CODES.fetch(:hiv),
      PsdeFieldRegistry::MENTAL_HEALTH_DISORDER.key => DISABILITY_TYPE_CODES.fetch(:mental),
    }.freeze

    SUBSTANCE_USE_DISABILITY_TYPE = DISABILITY_TYPE_CODES.fetch(:substance)

    # Meaningful raw HUD response codes from NoYesReasonsForMissingData.
    # Anything else — 8/9/99/nil — is skipped as "not meaningful".
    NO_YES_RESPONSES = [0, 1].freeze
    SUBSTANCE_RESPONSES = [0, 1, 2, 3].freeze # 1=Alcohol, 2=Drug, 3=Both; all collapse to true

    def initialize(current_date: Date.current, configuration: Hmis::Ce.configuration)
      @current_date = current_date.to_date
      @configuration = configuration
    end

    # Resolves the value for a PSDE field for a given set of destination clients.
    def call(clients, field)
      return resolve_total_monthly_income(clients) if field.key == PsdeFieldRegistry::TOTAL_MONTHLY_INCOME.key

      values_in_window = field.key.end_with?(PsdeFieldRegistry::VALUES_IN_WINDOW_SUFFIX)
      base_key = field.key.delete_suffix(PsdeFieldRegistry::VALUES_IN_WINDOW_SUFFIX)
      source = boolean_field_source(base_key)

      if values_in_window
        resolve_boolean_values_in_window(clients, **source)
      else
        resolve_latest_boolean_response(clients, **source)
      end
    end

    private

    # Unlike CAS +max_current_total_monthly_income+, which takes the max across open enrollments,
    # this resolver selects the single latest valid IncomeBenefits row across all scoped enrollments.
    # (Ignoring 8/9/99/nil responses to IncomeFromAnySource.)
    #
    # @return [Hash{Integer => Numeric, nil}]
    def resolve_total_monthly_income(clients)
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      # Ensure all destination clients are in the hash. Clients with no valid IncomeBenefits rows will have a nil value.
      result = client_ids.index_with { nil }

      rows = scoped_rows(client_ids, Hmis::Hud::IncomeBenefit.all).pluck(
        wc_t[:destination_id],
        ib_t[:IncomeFromAnySource],
        ib_t[:TotalMonthlyIncome],
      )

      rows.group_by(&:first).each do |client_id, client_rows|
        selected = client_rows.find { |row| valid_total_monthly_income_row?(income_from_any_source: row[1], total_monthly_income: row[2]) }
        next unless selected

        income_from_any_source = selected[1]
        total_monthly_income = selected[2]
        total_monthly_income = 0 if income_from_any_source.zero? # "No Income From Any Source" = $0 income

        result[client_id] = total_monthly_income
      end

      result
    end

    # Describes where a boolean PSDE field's response lives in HUD data, keyed by its base
    # (suffix-stripped) key. Returns { scope:, column:, meaningful_values: } which both the
    # "latest" and "all enrollment" resolvers splat straight into their keyword args.
    def boolean_field_source(base_key)
      case base_key
      when PsdeFieldRegistry::DOMESTIC_VIOLENCE_SURVIVOR.key
        { scope: Hmis::Hud::HealthAndDv.all, column: hdv_t[:DomesticViolenceSurvivor], meaningful_values: NO_YES_RESPONSES }
      when PsdeFieldRegistry::SUBSTANCE_USE_DISORDER.key
        # Substance use collapses Alcohol/Drug/Both (1/2/3) to true, No (0) to false.
        { scope: disability_scope(SUBSTANCE_USE_DISABILITY_TYPE), column: d_t[:DisabilityResponse], meaningful_values: SUBSTANCE_RESPONSES }
      when *NO_YES_DISABILITY_TYPES.keys
        { scope: disability_scope(NO_YES_DISABILITY_TYPES.fetch(base_key)), column: d_t[:DisabilityResponse], meaningful_values: NO_YES_RESPONSES }
      else
        raise ArgumentError, "Unknown boolean PSDE field \"#{base_key}\""
      end
    end

    # Picks the single latest row with a meaningful response per client, and converts the raw HUD
    # response code of that row to a real Ruby boolean (0 => false; any other meaningful code => true).
    # Returns nil when no row has a meaningful response in scope.
    #
    # @return [Hash{Integer => Boolean, nil}]
    def resolve_latest_boolean_response(clients, scope:, column:, meaningful_values:)
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      # Ensure all destination clients are in the hash. Clients with no meaningful rows will have a nil value.
      result = client_ids.index_with { nil }
      rows = scoped_rows(client_ids, scope).pluck(wc_t[:destination_id], column)
      rows.group_by(&:first).each do |client_id, client_rows|
        response = client_rows.find { |row| meaningful_values.include?(row.last) }&.last
        result[client_id] = response_to_boolean(response) unless response.nil?
      end
      result
    end

    # Collects every meaningful response recorded within the configured eligibility scope
    # (lookback window + optional project group) and converts each to a boolean.
    # Clients with no meaningful values get []. Shape: Hash{Integer => Array<Boolean>}.
    def resolve_boolean_values_in_window(clients, scope:, column:, meaningful_values:)
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      # Ensure all destination clients are in the hash. Clients with no meaningful rows will have an empty array.
      result = client_ids.index_with { [] }

      # scoped_rows already orders rows newest-first
      rows = scoped_rows(client_ids, scope).pluck(wc_t[:destination_id], column)
      rows.group_by(&:first).each do |client_id, client_rows|
        result[client_id] = client_rows.map(&:last).
          select { |code| meaningful_values.include?(code) }.
          map { |code| response_to_boolean(code) }.uniq
      end
      result
    end

    # Scoped, ordered relation for a HUD table restricted to eligible enrollments.
    # Ordered so the first row is the most recent.
    # Callers pluck the specific columns they need.
    def scoped_rows(client_ids, scope)
      scope.
        joins(:enrollment).
        merge(eligibility_scope.call(client_ids)).
        order(information_date: :desc, date_updated: :desc, id: :desc)
    end

    # HUD NoYes code -> boolean (0 => false; any other meaningful code => true)
    def response_to_boolean(code)
      !code.zero?
    end

    def disability_scope(disability_type)
      Hmis::Hud::Disability.where(d_t[:DisabilityType].eq(disability_type))
    end

    def eligibility_scope
      @eligibility_scope ||= EnrollmentEligibilityScope.new(
        current_date: @current_date,
        configuration: @configuration,
      )
    end

    # Used to evaluate HUD 1.7 NoYesReasonsForMissingData response code (0/1/8/9/99/nil)
    # Returns true if the response is meaningful (0/1)
    def meaningful_yes_no_response?(value)
      value.in?(NO_YES_RESPONSES)
    end

    # Yes (1) with a blank MonthlyTotalIncome is invalid data and is skipped, same as 8/9/99/nil on IncomeFromAnySource.
    def valid_total_monthly_income_row?(income_from_any_source:, total_monthly_income:)
      # 8/9/99/nil on IncomeFromAnySource = skip
      return false unless meaningful_yes_no_response?(income_from_any_source)
      # 1(Yes) on IncomeFromAnySource with no MonthlyTotalIncome = skip, invalid
      return false if income_from_any_source == 1 && total_monthly_income.nil?

      true
    end

    def extract_client_ids(clients)
      case clients
      when ActiveRecord::Relation
        clients.pluck(:id)
      else
        Array(clients).map(&:id)
      end
    end
  end
end
