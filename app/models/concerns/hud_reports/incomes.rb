###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required concerns:
#   HudReports:Households for HoH
#
# Required accessors:
#   a_t: Arel Type for the universe model
#   report_end_date: end date for report
#
# Required universe fields:
#   income_sources_at_*, income_total_at_* , income_from_any_source_at_*: Jsonb
#
# Collection points are start, exit, annual_assessment
#
#
module HudReports::Incomes
  extend ActiveSupport::Concern

  included do
    private def annual_assessment(enrollment)
      enrollment.income_benefits_annual_update.select do |i|
        i.InformationDate <= report_end_date
      end.max_by(&:InformationDate)
    end

    private def income_sources(income)
      sources = GrdaWarehouse::Hud::IncomeBenefit::SOURCES.keys.map(&:to_s)
      sources += GrdaWarehouse::Hud::IncomeBenefit::NON_CASH_BENEFIT_TYPES.map(&:to_s)
      sources += GrdaWarehouse::Hud::IncomeBenefit::INSURANCE_TYPES.map(&:to_s)
      amounts = GrdaWarehouse::Hud::IncomeBenefit::SOURCES.values.map(&:to_s)
      income&.attributes&.slice(*(sources + amounts)) || sources.map { |k| [k, 99] }.to_h.merge(amounts.map { |k| [k, nil] }.to_h)
    end
    private def earned_amount(universe_client, suffix)
      return unless universe_client["income_sources_at_#{suffix}"].present?

      universe_client["income_sources_at_#{suffix}"]['EarnedAmount'] || 0
    end

    private def other_amount(universe_client, suffix)
      total_amount = total_amount(universe_client, suffix)
      return 0 unless total_amount.present? && total_amount.positive?

      earned = earned_amount(universe_client, suffix).presence || 0
      total_amount.to_i - earned.to_i
    end

    private def total_amount(universe_client, suffix)
      universe_client["income_total_at_#{suffix}"]
    end

    # We have earned income if we said we had earned income and the amount is positive
    private def earned_income?(universe_client, suffix)
      return false unless universe_client["income_sources_at_#{suffix}"]['Earned'] == 1

      earned_amt = earned_amount(universe_client, suffix)
      earned_amt.present? && earned_amt.to_i.positive?
    end

    # We have other income if the total is positive and not equal to the earned amount
    private def other_income?(universe_client, suffix)
      total_amount = total_amount(universe_client, suffix)
      return false unless total_amount.present? && total_amount.positive?

      total_amount != earned_amount(universe_client, suffix).to_i
    end

    private def total_income?(universe_client, suffix)
      total_amount = total_amount(universe_client, suffix)
      total_amount.present? && total_amount.positive?
    end

    private def income_for_category?(universe_client, category:, suffix:)
      case category
      when :earned
        earned_income?(universe_client, suffix)
      when :other
        other_income?(universe_client, suffix)
      when :total
        total_income?(universe_client, suffix)
      end
    end

    private def both_income_types?(universe_client, suffix)
      earned_income?(universe_client, suffix) && other_income?(universe_client, suffix)
    end

    private def no_income?(universe_client, suffix)
      [
        earned_income?(universe_client, suffix),
        other_income?(universe_client, suffix),
      ].none?
    end

    private def income_change(universe_client, category:, initial:, subsequent:)
      case category
      when :total
        initial_amount = total_amount(universe_client, initial)
        subsequent_amount = total_amount(universe_client, subsequent)
      when :earned
        initial_amount = earned_amount(universe_client, initial)
        subsequent_amount = earned_amount(universe_client, subsequent)
      when :other
        initial_amount = other_amount(universe_client, initial)
        subsequent_amount = other_amount(universe_client, subsequent)
      end
      return unless initial_amount && subsequent_amount

      subsequent_amount.to_f - initial_amount.to_f
    end

    # Returns a sql query clause appropriate to see if a value exists or doesn't exist in a
    # jsonb hash
    # EX: 1 in (coalesce(data->>'a', '99'), coalesce(data->>'b', '99'))
    private def income_jsonb_clause(value, column, negation: false, coalesce_value: 99)
      if negation
        query = "'#{value}' not in ("
      else
        query = "'#{value}' in ("
      end
      measures = GrdaWarehouse::Hud::IncomeBenefit::SOURCES.keys.map do |income_measure|
        "coalesce(#{column}->>'#{income_measure}', '#{coalesce_value}')"
      end
      query += measures.join(', ') + ')'
      Arel.sql(query)
    end

    private def benefit_jsonb_clause(value, column, negation: false, coalesce_value: 99)
      if negation
        query = "'#{value}' not in ("
      else
        query = "'#{value}' in ("
      end
      measures = GrdaWarehouse::Hud::IncomeBenefit::NON_CASH_BENEFIT_TYPES.map do |measure|
        "coalesce(#{column}->>'#{measure}', '#{coalesce_value}')"
      end
      query += measures.join(', ') + ')'
      Arel.sql(query)
    end

    private def insurance_jsonb_clause(value, column, negation: false, coalesce_value: 99)
      if negation
        query = "'#{value}' not in ("
      else
        query = "'#{value}' in ("
      end
      measures = GrdaWarehouse::Hud::IncomeBenefit::INSURANCE_TYPES.map do |measure|
        "coalesce(#{column}->>'#{measure}', '#{coalesce_value}')"
      end
      query += measures.join(', ') + ')'
      Arel.sql(query)
    end

    private def income_responses(suffix)
      {
        'Adults with Only Earned Income (i.e., Employment Income)' => :earned,
        'Adults with Only Other Income' => :other,
        'Adults with Both Earned and Other Income' => :both,
        'Adults with No Income' => :none,
        'Adults with Client Doesn’t Know/Client Refused Income Information' => a_t["income_from_any_source_at_#{suffix}"].in([8, 9]),
        'Adults with Missing Income Information' => a_t["income_from_any_source_at_#{suffix}"].eq(99).
          or(a_t["income_from_any_source_at_#{suffix}"].eq(nil)).
          and(a_t["income_sources_at_#{suffix}"].not_eq(nil)),
        'Number of adult stayers not yet required to have an annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(false)),
        'Number of adult stayers without required annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(true)).
          and(a_t[:income_from_any_source_at_annual_assessment].eq(nil)),
        'Total Adults' => Arel.sql('1=1'),
        '1 or more source of income' => a_t["income_total_at_#{suffix}"].gt(0),
        'Adults with Income Information at Start and Annual Assessment/Exit' => a_t['income_from_any_source_at_start'].in([0, 1]).and(a_t["income_from_any_source_at_#{suffix}"].in([0, 1])),
      }
    end
  end
end
