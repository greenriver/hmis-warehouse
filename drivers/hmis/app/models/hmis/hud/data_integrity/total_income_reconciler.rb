# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Reconciles total monthly income discrepancies that may occur despite front-end validations.
# Calculates expected total from individual income sources and auto-corrects mismatches.
#
class Hmis::Hud::DataIntegrity::TotalIncomeReconciler < Hmis::Hud::DataIntegrity::BaseReconciler
  # [[:Alimony, :AlimonyAmount], ...]
  INCOME_SOURCES = GrdaWarehouse::Hud::IncomeBenefit::SOURCES

  # @param [Hmis::Hud::IncomeBenefit] record
  def call(record)
    messages = []

    calculated_income = 0
    INCOME_SOURCES.each_pair do |source_field, amount_field|
      next unless record.public_send(source_field)&.to_i == 1 # 1 = yes

      amount = record.public_send(amount_field).presence
      if amount.nil?
        messages << "Expected #{amount_field} to have a numeric value but was null"
      elsif amount.negative? || amount.zero?
        messages << "Expected #{amount_field} to be positive but was #{amount}. Excluding from total"
      else
        calculated_income += amount
      end
    end

    if calculated_income.round(2) != record.total_monthly_income&.round(2)
      messages << "Total monthly income does not match calculated income. Expected #{record.total_monthly_income} to equal calculated: #{calculated_income} (auto-corrected)"
      # auto correction
      record.total_monthly_income = calculated_income
    end

    format_messages(record, messages)
  end
end
