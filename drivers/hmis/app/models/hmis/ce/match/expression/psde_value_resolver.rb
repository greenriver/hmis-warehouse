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

    def initialize(current_date: Date.current, configuration: Hmis::Ce.configuration)
      @current_date = current_date.to_date
      @configuration = configuration
    end

    # Resolves the value for a PSDE field for a given set of destination clients.
    def call(clients, field)
      case field.key
      when PsdeFieldRegistry::TOTAL_MONTHLY_INCOME.key
        resolve_total_monthly_income(clients)
      else
        raise ArgumentError, "Unknown PSDE field \"#{field.key}\""
      end
    end

    private

    IGNORED_RESPONSE_CODES = [8, 9, 99].freeze

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

      rows = Hmis::Hud::IncomeBenefit.
        joins(enrollment: { client: :warehouse_client_source }).
        merge(eligibility_scope.call(clients)).
        order(information_date: :desc, date_updated: :desc, id: :desc).
        pluck(
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

    def eligibility_scope
      @eligibility_scope ||= EnrollmentEligibilityScope.new(
        current_date: @current_date,
        configuration: @configuration,
      )
    end

    # Accepts HUD 1.7 NoYesReasonsForMissingData response code (0/1/8/9/99/nil)
    # Returns true if the response is meaningful (0/1)
    def meaningful_yes_no_response?(value)
      return false if value.nil?

      !IGNORED_RESPONSE_CODES.include?(value)
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
