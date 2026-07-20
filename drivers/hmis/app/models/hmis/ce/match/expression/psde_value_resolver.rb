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

    # @param clients [ActiveRecord::Relation, Array<GrdaWarehouse::Hud::Client>]
    # @param field [PsdeField]
    # @return [Hash{Integer => Numeric, nil}]
    def call(clients, field)
      case field.key
      when PsdeFieldRegistry::MONTHLY_TOTAL_INCOME.key
        resolve_monthly_total_income(clients)
      else
        raise ArgumentError, "Unknown PSDE field \"#{field.key}\""
      end
    end

    private

    # Unlike CAS +max_current_total_monthly_income+, which takes the max across open enrollments,
    # this resolver selects the single latest valid IncomeBenefits row across all scoped enrollments.
    def resolve_monthly_total_income(clients)
      client_ids = extract_client_ids(clients)
      return {} if client_ids.empty?

      result = client_ids.index_with { nil }
      rows = income_benefit_rows(clients)

      rows.group_by(&:first).each do |client_id, client_rows|
        selected = client_rows.find { |row| valid_income_from_any_source?(row[4]) }
        next unless selected

        result[client_id] = resolve_monthly_total_income_from_row(selected[4], selected[5])
      end

      result
    end

    def income_benefit_rows(clients)
      ib_t = Hmis::Hud::IncomeBenefit.arel_table

      Hmis::Hud::IncomeBenefit.
        joins(enrollment: { client: :warehouse_client_source }).
        merge(eligibility_scope.call(clients)).
        order(
          ib_t[:InformationDate].desc,
          ib_t[:DateUpdated].desc,
          ib_t[:id].desc,
        ).
        pluck(
          wc_t[:destination_id],
          ib_t[:InformationDate],
          ib_t[:DateUpdated],
          ib_t[:id],
          ib_t[:IncomeFromAnySource],
          ib_t[:TotalMonthlyIncome],
        )
    end

    def eligibility_scope
      @eligibility_scope ||= EnrollmentEligibilityScope.new(
        current_date: @current_date,
        configuration: @configuration,
      )
    end

    def valid_income_from_any_source?(value)
      return false if value.nil?

      !PsdeFieldRegistry::INVALID_INCOME_FROM_ANY_SOURCE.include?(value.to_i)
    end

    def resolve_monthly_total_income_from_row(income_from_any_source, monthly_total_income)
      case income_from_any_source.to_i
      when 0
        0
      when 1
        numeric_monthly_total_income(monthly_total_income)
      end
    end

    def numeric_monthly_total_income(value)
      return 0 if value.blank?

      value.to_f
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
