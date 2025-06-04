# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Reconciles total monthly income discrepancies that may occur despite front-end validations.
# Calculates expected total from individual income sources and auto-corrects mismatches.
#
class Hmis::Hud::DataIntegrity::TotalIncomeReconciler
  # [[:Alimony, :AlimonyAmount], ...]
  INCOME_SOURCES = GrdaWarehouse::Hud::IncomeBenefit::SOURCES.to_a.freeze

  # convenience class method
  def self.call(...) = new.call(...)

  # @param [Hmis::Hud::IncomeBenefit] record
  def call(record)
    # note, we only perform reconciliation if the record indicates income_from_any_source. Otherwise we leave any
    # issues to be flagged by DQ
    @messages = []
    if record.income_from_any_source&.to_i == 1
      reconcile_total_income(record)
    else
      check_no_income_fields(record)
    end

    # report activity
    @messages
  end

  protected

  def check_no_income_fields(record)
    total = record.total_monthly_income
    report(record, "Expected total_monthly_income to be zero or nil, was #{total}") if total.to_f > 0
  end

  def reconcile_total_income(record)
    calculated_income = calculate_total_income(record)
    # Normalize nil total_monthly_income to 0 for comparison
    total_income = record.total_monthly_income.to_f
    # do nothing if total income matches calculated
    return if calculated_income.round(2) == total_income.round(2)

    # report and correct value
    report(record, "Total monthly income does not match calculated income. Expected #{record.total_monthly_income&.to_f.inspect} to equal calculated: #{calculated_income.inspect} (auto-corrected)")
    record.total_monthly_income = calculated_income
  end

  def calculate_total_income(record)
    result = 0
    INCOME_SOURCES.each do |source_field, amount_field|
      source = record.public_send(source_field)&.to_i
      amount = record.public_send(amount_field)&.to_f

      # we ignore the source field when calculating total value
      result += amount if amount&.positive?

      # report inconsistencies if the source was set to true
      if source == 1
        report(record, "Expected #{amount_field} to be provided but was #{amount.inspect}") if amount.nil? || amount&.negative? || amount&.zero?
      end
    end
    result
  end

  def report(record, message)
    tag = "#{record.class.name}##{record.id}"
    @messages << "#{tag}: #{message}"
  end
end
