# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Hud::DataIntegrity::TotalIncomeReconciler, type: :model do
  let(:base_attributes) do
    {
      Earned: 1,
      EarnedAmount: 100.00,
      SSI: 1,
      SSIAmount: 200.00,
      TotalMonthlyIncome: 300.00,
    }
  end
  let!(:income_benefit) { build(:hmis_income_benefit, **base_attributes) }

  describe '.call' do
    it 'corrects total monthly income when it does not match sum of income fields' do
      income_benefit.total_monthly_income = 250 # Incorrect total

      messages = described_class.call(income_benefit)
      expect(messages.first).to match(/Total monthly income does not match calculated income. Expected 250.0 to equal calculated: 300.0/)
      expect(income_benefit.total_monthly_income).to eq(300)
    end

    it 'does not modify total monthly income when it matches sum' do
      # income_benefit is already set up with correct total
      messages = described_class.call(income_benefit)
      expect(messages).to be_empty
      expect(income_benefit.total_monthly_income).to eq(300)
    end

    context 'when an income source amount is nil' do
      let!(:income_benefit_with_nil_amount) { build(:hmis_income_benefit, Earned: 1, EarnedAmount: nil, SSI: 1, SSIAmount: 200) }

      it 'reports the missing amount and calculates total without it' do
        income_benefit_with_nil_amount.total_monthly_income = 250 # Incorrect total to trigger auto-correction message as well

        messages = described_class.call(income_benefit_with_nil_amount)
        expect(messages).to include(match(/Expected EarnedAmount to have a numeric value but was null/))
        expect(messages).to include(match(/Total monthly income does not match calculated income. Expected 250.0 to equal calculated: 200.0/))
        expect(income_benefit_with_nil_amount.total_monthly_income).to eq(200)
      end
    end

    context 'when an income source amount is zero or negative' do
      let!(:income_benefit_with_invalid_amount) { build(:hmis_income_benefit, Earned: 1, EarnedAmount: -50, SSI: 1, SSIAmount: 200, SSDI: 1, SSDIAmount: 0) }

      it 'reports the invalid amounts and excludes them from the total' do
        income_benefit_with_invalid_amount.total_monthly_income = 300 # Incorrect total

        messages = described_class.call(income_benefit_with_invalid_amount)
        expect(messages).to include(match(/Expected EarnedAmount to be positive but was -50.0. Excluding from total/))
        expect(messages).to include(match(/Expected SSDIAmount to be positive but was 0.0. Excluding from total/))
        expect(messages).to include(match(/Total monthly income does not match calculated income. Expected 300.0 to equal calculated: 200.0/))
        expect(income_benefit_with_invalid_amount.total_monthly_income).to eq(200)
      end
    end
  end
end
