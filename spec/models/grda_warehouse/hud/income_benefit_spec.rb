###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::IncomeBenefit, type: :model do
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:client) { create(:hud_client, data_source: data_source) }
  let(:enrollment) { create(:hud_enrollment, data_source: data_source, PersonalID: client.PersonalID) }

  describe '#hud_total_monthly_income and #hud_income_from_any_source consistency' do
    context 'when hud_income_from_any_source returns 1 (has income)' do
      it 'hud_total_monthly_income never returns nil' do
        # Test various scenarios that should result in hud_income_from_any_source = 1
        scenarios = [
          # Scenario 1: TotalMonthlyIncome is positive
          { TotalMonthlyIncome: 1000.0, IncomeFromAnySource: 1 },
          { TotalMonthlyIncome: 500.50, IncomeFromAnySource: 0 }, # Should still result in income_from_any_source = 1

          # Scenario 2: Calculated income from sources is positive
          { TotalMonthlyIncome: nil, IncomeFromAnySource: nil, Earned: 1, EarnedAmount: 800.0 },
          { TotalMonthlyIncome: nil, IncomeFromAnySource: nil, SSDI: 1, SSDIAmount: 600.0 },
          { TotalMonthlyIncome: nil, IncomeFromAnySource: nil, Earned: 1, EarnedAmount: 400.0, SSDI: 1, SSDIAmount: 300.0 },
        ]

        scenarios.each_with_index do |attrs, index|
          income_benefit = create(
            :hud_income_benefit,
            data_source: data_source,
            enrollment: enrollment,
            **attrs,
          )

          expect(income_benefit.hud_income_from_any_source).to eq(1), "Scenario #{index + 1}: Expected hud_income_from_any_source to be 1 with attrs: #{attrs}"
          expect(income_benefit.hud_total_monthly_income).not_to be_nil, "Scenario #{index + 1}: Expected hud_total_monthly_income to not be nil when hud_income_from_any_source is 1 with attrs: #{attrs}"
        end
      end
    end

    context 'when hud_income_from_any_source returns 0 (no income)' do
      it 'hud_total_monthly_income never returns nil' do
        # Test scenarios that should result in hud_income_from_any_source = 0
        scenarios = [
          # Scenario 1: TotalMonthlyIncome is 0 and IncomeFromAnySource is 0
          { TotalMonthlyIncome: 0.0, IncomeFromAnySource: 0 },

          # Scenario 2: Calculated income from sources is 0 (sources indicated but amounts are 0)
          { TotalMonthlyIncome: nil, IncomeFromAnySource: nil, Earned: 1, EarnedAmount: 0.0 },
          { TotalMonthlyIncome: nil, IncomeFromAnySource: nil, SSDI: 1, SSDIAmount: 0.0 },

          # Scenario 3: IncomeFromAnySource is explicitly 0
          { TotalMonthlyIncome: nil, IncomeFromAnySource: 0 },

          # Scenario 4: TotalMonthlyIncome is 0 and IncomeFromAnySource is 1 or nil
          { TotalMonthlyIncome: 0.0, IncomeFromAnySource: 1 },
          { TotalMonthlyIncome: 0.0, IncomeFromAnySource: nil },
        ]

        scenarios.each_with_index do |attrs, index|
          income_benefit = create(
            :hud_income_benefit,
            data_source: data_source,
            enrollment: enrollment,
            **attrs,
          )

          expect(income_benefit.hud_income_from_any_source).to eq(0), "Scenario #{index + 1}: Expected hud_income_from_any_source to be 0 with attrs: #{attrs}"
          expect(income_benefit.hud_total_monthly_income).not_to be_nil, "Scenario #{index + 1}: Expected hud_total_monthly_income to not be nil when hud_income_from_any_source is 0 with attrs: #{attrs}"
          expect(income_benefit.hud_total_monthly_income).to eq(0.0), "Scenario #{index + 1}: Expected hud_total_monthly_income to be 0.0 when hud_income_from_any_source is 0 with attrs: #{attrs}"
        end
      end
    end

    context 'when hud_total_monthly_income is 0 or positive' do
      it 'hud_income_from_any_source never returns 99 (data not collected)' do
        # Test scenarios with 0 or positive income
        scenarios = [
          # Zero income scenarios
          { TotalMonthlyIncome: 0.0, IncomeFromAnySource: 0 },
          { TotalMonthlyIncome: 0.0, IncomeFromAnySource: 1 },
          { TotalMonthlyIncome: 0.0, IncomeFromAnySource: nil },
          { TotalMonthlyIncome: nil, IncomeFromAnySource: 0 },
          { TotalMonthlyIncome: nil, IncomeFromAnySource: nil, Earned: 1, EarnedAmount: 0.0 },

          # Positive income scenarios
          { TotalMonthlyIncome: 1000.0, IncomeFromAnySource: 1 },
          { TotalMonthlyIncome: 500.0, IncomeFromAnySource: 0 }, # Inconsistent but total is positive
          { TotalMonthlyIncome: nil, IncomeFromAnySource: nil, Earned: 1, EarnedAmount: 800.0 },
          { TotalMonthlyIncome: nil, IncomeFromAnySource: nil, SSDI: 1, SSDIAmount: 600.0 },
        ]

        scenarios.each_with_index do |attrs, index|
          income_benefit = create(
            :hud_income_benefit,
            data_source: data_source,
            enrollment: enrollment,
            **attrs,
          )

          total_income = income_benefit.hud_total_monthly_income
          next unless total_income&.>= 0 # Only test when total income is 0 or positive

          expect(income_benefit.hud_income_from_any_source).not_to eq(99), "Scenario #{index + 1}: Expected hud_income_from_any_source to not be 99 when hud_total_monthly_income is #{total_income} with attrs: #{attrs}"
          expect(income_benefit.hud_income_from_any_source).to be_in([0, 1]), "Scenario #{index + 1}: Expected hud_income_from_any_source to be 0 or 1 when hud_total_monthly_income is #{total_income} with attrs: #{attrs}"
        end
      end
    end

    context 'edge cases and data quality scenarios' do
      it 'handles refused/unknown responses appropriately' do
        # When IncomeFromAnySource is refused (9) or unknown (8), it should be preserved
        scenarios = [
          { IncomeFromAnySource: 8, TotalMonthlyIncome: nil }, # Client doesn't know
          { IncomeFromAnySource: 9, TotalMonthlyIncome: nil }, # Client refused
        ]

        scenarios.each_with_index do |attrs, index|
          income_benefit = create(
            :hud_income_benefit,
            data_source: data_source,
            enrollment: enrollment,
            **attrs,
          )

          expect(income_benefit.hud_income_from_any_source).to eq(attrs[:IncomeFromAnySource]), "Scenario #{index + 1}: Expected hud_income_from_any_source to preserve refused/unknown response with attrs: #{attrs}"
          expect(income_benefit.hud_total_monthly_income).to be_nil, "Scenario #{index + 1}: Expected hud_total_monthly_income to be nil for refused/unknown responses with attrs: #{attrs}"
        end
      end

      it 'handles data not collected scenarios' do
        # When all relevant fields are nil/empty, should default to 99 (data not collected)
        scenarios = [
          { IncomeFromAnySource: nil, TotalMonthlyIncome: nil },
          { IncomeFromAnySource: 99, TotalMonthlyIncome: nil },
          # IncomeFromAnySource is 1 but TotalMonthlyIncome is nil with no individual source amounts
          { IncomeFromAnySource: 1, TotalMonthlyIncome: nil },
        ]

        scenarios.each_with_index do |attrs, index|
          income_benefit = create(
            :hud_income_benefit,
            data_source: data_source,
            enrollment: enrollment,
            **attrs,
          )

          expect(income_benefit.hud_income_from_any_source).to eq(99), "Scenario #{index + 1}: Expected hud_income_from_any_source to be 99 for data not collected with attrs: #{attrs}"
          expect(income_benefit.hud_total_monthly_income).to be_nil, "Scenario #{index + 1}: Expected hud_total_monthly_income to be nil when data not collected with attrs: #{attrs}"
        end
      end
    end
  end
end
