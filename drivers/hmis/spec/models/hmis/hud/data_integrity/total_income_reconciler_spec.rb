###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::DataIntegrity::TotalIncomeReconciler, type: :model do
  let(:income_benefit) do
    build(
      :hmis_income_benefit,
      income_from_any_source: 1,
      earned: 1,
      earned_amount: 100.00,
      ssi: 1,
      ssi_amount: 200.00,
      alimony: 0,
      alimony_amount: nil,
      total_monthly_income: 300.00,
    )
  end

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
      before do
        income_benefit.alimony = 1
        income_benefit.alimony_amount = nil
        income_benefit.total_monthly_income = 350.00 # Incorrect total; base calc is 300 (Earned 100 + SSI 200)
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
      before do
        income_benefit.earned_amount = -50.0
        income_benefit.ssdi = 1
        income_benefit.ssdi_amount = 0.0
        income_benefit.total_monthly_income = 300.0 # Incorrect total
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
      before do
        income_benefit.earned = 0 # Base has EarnedAmount: 100. Now Earned is 0.
        # SSI: 1, SSIAmount: 200 (from base)
        # Total calculation should still be EarnedAmount (100) + SSIAmount (200) = 300
        income_benefit.total_monthly_income = 250.00 # Incorrect total to trigger correction message
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

    context 'when income_from_any_source is not 1 and total_monthly_income is non-zero' do
      before do
        income_benefit.income_from_any_source = 0 # No income from any source
        income_benefit.total_monthly_income = 300.00 # Incorrectly has a total
      end

      it 'reports the discrepancy but does not correct the total monthly income' do
        messages = described_class.call(income_benefit)
        expect(messages.first).to match(/Expected total_monthly_income to be zero or nil, was 300.0/)
        expect(income_benefit.total_monthly_income).to eq(300) # Not corrected
      end
    end
  end

  describe '.fill_missing_totals!' do
    let!(:hmis_ds) { create :hmis_data_source }
    let(:yesterday) { Date.current - 1.day }
    let(:default_attrs) { { data_source: hmis_ds, date_created: yesterday, date_updated: yesterday } }
    let!(:p1) { create :hmis_hud_project, data_source: hmis_ds }
    let!(:e1) { create :hmis_hud_enrollment, data_source: hmis_ds, project: p1 }

    let(:income_attrs) do
      # distinct values for each source, summing to a known non-zero total
      {
        EarnedAmount: 1,
        UnemploymentAmount: 2,
        SSIAmount: 3,
        SSDIAmount: 4,
        VADisabilityServiceAmount: 5,
        VADisabilityNonServiceAmount: 6,
        PrivateDisabilityAmount: 7,
        WorkersCompAmount: 8,
        TANFAmount: 9,
        GAAmount: 10,
        SocSecRetirementAmount: 11,
        PensionAmount: 12,
        ChildSupportAmount: 13,
        AlimonyAmount: 14,
        OtherIncomeAmount: 15,
      }
    end
    let(:expected_total) { 120 } # sum of income_attrs values

    let!(:missing) do
      create(:hmis_income_benefit, :skip_validate, income_from_any_source: 1, total_monthly_income: nil, enrollment: e1, client: e1.client, **income_attrs, **default_attrs)
    end

    describe 'with a data source id' do
      it 'fills in the missing total by summing income sources' do
        expect { described_class.fill_missing_totals!(data_source_id: hmis_ds.id) }.to(
          change { Hmis::Hud::IncomeBenefit.find(missing.id).total_monthly_income.to_i }.from(0).to(expected_total),
        )
      end

      it 'returns the number of updated records' do
        expect(described_class.fill_missing_totals!(data_source_id: hmis_ds.id)).to eq(1)
      end

      context 'with a record whose income sources sum to zero (no change to make)' do
        let!(:zero_income) do
          create(:hmis_income_benefit, :skip_validate, income_from_any_source: 1, total_monthly_income: nil, enrollment: e1, client: e1.client, **default_attrs)
        end

        it 'leaves the null total untouched' do
          expect { described_class.fill_missing_totals!(data_source_id: hmis_ds.id) }.to(
            not_change { Hmis::Hud::IncomeBenefit.find(zero_income.id).total_monthly_income },
          )
          expect(Hmis::Hud::IncomeBenefit.find(zero_income.id).total_monthly_income).to be_nil
        end
      end

      context 'with a record that already has a (mismatched) non-null total' do
        let!(:mismatched_total) do
          create(:hmis_income_benefit, :skip_validate, income_from_any_source: 1, earned: 1, earned_amount: 100, total_monthly_income: 5, enrollment: e1, client: e1.client, **default_attrs)
        end

        it 'does not touch it, since it is not missing' do
          expect { described_class.fill_missing_totals!(data_source_id: hmis_ds.id) }.to(
            not_change { Hmis::Hud::IncomeBenefit.find(mismatched_total.id).total_monthly_income.to_i },
          )
        end
      end

      context 'with a record that indicates no income' do
        let!(:no_income) do
          create(:hmis_income_benefit, :skip_validate, income_from_any_source: 0, total_monthly_income: nil, enrollment: e1, client: e1.client, **default_attrs)
        end

        it 'leaves it unchanged' do
          expect { described_class.fill_missing_totals!(data_source_id: hmis_ds.id) }.to(
            not_change { Hmis::Hud::IncomeBenefit.find(no_income.id).total_monthly_income },
          )
        end
      end

      context 'with income records in a different data source' do
        let!(:other_ds) { create(:hmis_data_source) }
        let!(:other_income) do
          create(:hud_income_benefit, data_source_id: other_ds.id, IncomeFromAnySource: 1, EarnedAmount: 100, TotalMonthlyIncome: nil)
        end

        it 'does not touch them' do
          expect { described_class.fill_missing_totals!(data_source_id: hmis_ds.id) }.to(
            not_change { GrdaWarehouse::Hud::IncomeBenefit.find(other_income.id).attributes },
          )
        end
      end
    end

    describe 'with an explicit scope (instance entrypoint)' do
      let!(:e2) { create :hmis_hud_enrollment, data_source: hmis_ds, project: p1 }
      let!(:missing_e2) do
        create(:hmis_income_benefit, :skip_validate, income_from_any_source: 1, total_monthly_income: nil, earned: 1, earned_amount: 42, enrollment: e2, client: e2.client, **default_attrs)
      end

      it 'only processes records within the provided scope' do
        scope = Hmis::Hud::IncomeBenefit.hmis.where(EnrollmentID: e1.enrollment_id)

        expect { described_class.new.fill_missing_totals!(scope: scope) }.to(
          change { Hmis::Hud::IncomeBenefit.find(missing.id).total_monthly_income.to_i }.to(expected_total).
            and(not_change { Hmis::Hud::IncomeBenefit.find(missing_e2.id).total_monthly_income }),
        )
      end
    end
  end
end
