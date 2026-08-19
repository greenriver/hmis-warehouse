###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::DataIntegrity::MissingTotalMonthlyIncomeFixer, type: :model do
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

  describe '.for_data_source!' do
    it 'fills in the missing total by summing income sources' do
      expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
        change { Hmis::Hud::IncomeBenefit.find(missing.id).total_monthly_income.to_i }.from(0).to(expected_total),
      )
    end

    it 'returns the number of updated records' do
      expect(described_class.for_data_source!(data_source_id: hmis_ds.id)).to eq(1)
    end

    context 'with a record whose income sources sum to zero (no change to make)' do
      let!(:zero_income) do
        create(:hmis_income_benefit, :skip_validate, income_from_any_source: 1, total_monthly_income: nil, enrollment: e1, client: e1.client, **default_attrs)
      end

      it 'leaves the null total untouched' do
        expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
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
        expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
          not_change { Hmis::Hud::IncomeBenefit.find(mismatched_total.id).total_monthly_income.to_i },
        )
      end
    end

    context 'with a record that indicates no income' do
      let!(:no_income) do
        create(:hmis_income_benefit, :skip_validate, income_from_any_source: 0, total_monthly_income: nil, enrollment: e1, client: e1.client, **default_attrs)
      end

      it 'leaves it unchanged' do
        expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
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
        expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
          not_change { GrdaWarehouse::Hud::IncomeBenefit.find(other_income.id).attributes },
        )
      end
    end
  end

  describe '.run! with an explicit scope' do
    let!(:e2) { create :hmis_hud_enrollment, data_source: hmis_ds, project: p1 }
    let!(:missing_e2) do
      create(:hmis_income_benefit, :skip_validate, income_from_any_source: 1, total_monthly_income: nil, earned: 1, earned_amount: 42, enrollment: e2, client: e2.client, **default_attrs)
    end

    it 'only processes records within the provided scope' do
      scope = Hmis::Hud::IncomeBenefit.hmis.where(EnrollmentID: e1.enrollment_id)

      expect { described_class.run!(scope: scope) }.to(
        change { Hmis::Hud::IncomeBenefit.find(missing.id).total_monthly_income.to_i }.to(expected_total).
          and(not_change { Hmis::Hud::IncomeBenefit.find(missing_e2.id).total_monthly_income }),
      )
    end
  end
end
