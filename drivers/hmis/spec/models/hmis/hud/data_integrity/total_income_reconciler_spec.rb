# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Hud::DataIntegrity::TotalIncomeReconciler, type: :model do
  let(:income_benefit_attributes) do
    {
      income_from_any_source: 1,
      earned: 1,
      earned_amount: 100.00,
      ssi: 1,
      ssi_amount: 200.00,
      alimony: 0,
      alimony_amount: nil,
      total_monthly_income: 300.00,
    }
  end
  let(:income_benefit) { build(:hmis_income_benefit, **income_benefit_attributes) }

  describe '.call' do
    it 'corrects total monthly income when it does not match sum of income fields' do
      income_benefit.total_monthly_income = 250 # Incorrect total
      # Base attributes: earned_amount (100) + ssi_amount (200) = 300

      messages = described_class.call(income_benefit)
      expect(messages.first).to match(/Total monthly income does not match calculated income. Expected 250.0 to equal calculated: 300.0 \(auto-corrected\)/)
      expect(income_benefit.total_monthly_income).to eq(300)
    end

    it 'does not modify total monthly income when it matches sum' do
      # income_benefit is already set up with correct total (300)
      messages = described_class.call(income_benefit)
      expect(messages).to be_empty
      expect(income_benefit.total_monthly_income).to eq(300)
    end

    context 'when an income source is indicated (1) but its amount is nil' do
      let(:income_benefit_attributes) do
        super().merge(
          alimony: 1,
          alimony_amount: nil,
          total_monthly_income: 350.00, # Incorrect total; base calc is 300 (Earned 100 + SSI 200)
        )
      end

      it 'reports the missing amount, calculates total correctly, and corrects total_monthly_income' do
        messages = described_class.call(income_benefit)
        # Calculated income should be 100 (Earned) + 200 (SSI) = 300. AlimonyAmount is nil.
        expect(messages).to include(match(/Expected AlimonyAmount to be provided but was nil/))
        expect(messages).to include(match(/Total monthly income does not match calculated income. Expected 350.0 to equal calculated: 300.0 \(auto-corrected\)/))
        expect(income_benefit.total_monthly_income).to eq(300)
      end
    end

    context 'when an income source amount is zero or negative' do
      let(:income_benefit_attributes) do
        super().merge(
          earned_amount: -50.0,
          ssdi: 1,
          ssdi_amount: 0.0,
          total_monthly_income: 300.0, # Incorrect total
        )
      end

      it 'reports the invalid amounts, excludes them from the sum, and corrects total_monthly_income' do
        messages = described_class.call(income_benefit)
        # Base: Earned (100), SSI (200). Merged: EarnedAmount (-50), SSDI (1), SSDIAmount (0)
        # Valid amounts for sum: SSIAmount (200). Calculated total = 200.
        expect(messages).to include(match(/Expected EarnedAmount to be provided but was -50.0/))
        expect(messages).to include(match(/Expected SSDIAmount to be provided but was 0.0/))
        expect(messages).to include(match(/Total monthly income does not match calculated income. Expected 300.0 to equal calculated: 200.0 \(auto-corrected\)/))
        expect(income_benefit.total_monthly_income).to eq(200)
      end
    end

    context 'when an income source is not indicated (e.g., 0) but has a positive amount' do
      let(:income_benefit_attributes) do
        super().merge(
          earned: 0, # Base has EarnedAmount: 100. Now Earned is 0.
          # SSI: 1, SSIAmount: 200 (from base)
          # Total calculation should still be EarnedAmount (100) + SSIAmount (200) = 300
          total_monthly_income: 250.00, # Incorrect total to trigger correction message
        )
      end

      it 'includes the amount in sum, does not report for that specific field, and corrects total' do
        messages = described_class.call(income_benefit)
        # No message for EarnedAmount specifically because earned source is 0
        expect(messages.none? { |m| m.include?('EarnedAmount to be provided') }).to be true

        # Calculated income: EarnedAmount (100) + SSIAmount (200) = 300
        expect(messages).to include(match(/Total monthly income does not match calculated income. Expected 250.0 to equal calculated: 300.0 \(auto-corrected\)/))
        expect(income_benefit.total_monthly_income).to eq(300.00)
      end
    end
  end

  context 'when income_from_any_source is not 1' do
    context 'and total_monthly_income is non-zero' do
      let(:income_benefit_attributes) do
        super().merge(
          income_from_any_source: 0, # No income from any source
          total_monthly_income: 300.00, # Incorrectly has a total
        )
      end

      it 'reports the discrepancy but does not correct the total monthly income' do
        messages = described_class.call(income_benefit)
        expect(messages.first).to match(/Expected total_monthly_income to be zero or nil, was 300.0/)
        expect(income_benefit.total_monthly_income).to eq(300) # Not corrected
      end
    end
  end
end
