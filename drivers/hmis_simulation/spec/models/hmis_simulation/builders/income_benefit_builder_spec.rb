###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::IncomeBenefitBuilder do
  include_context 'hmis simulation builder setup'

  let(:date) { Date.current - 1 }

  let(:income_config) do
    {
      'no_income_probability' => 0.0,
      'sources' => { 'ssi' => 0.5, 'earned' => 0.5 },
    }
  end

  def build(stage:, config: income_config, rng_seed: 42)
    described_class.new(
      enrollment: enrollment,
      date: date,
      stage: stage,
      income_config: config,
      data_source: data_source,
      user_id: user_id,
      rng_seed: rng_seed,
    ).build!
  end

  describe '#build!' do
    it 'creates an Hmis::Hud::IncomeBenefit record' do
      expect { build(stage: :entry) }.to change { Hmis::Hud::IncomeBenefit.where(data_source: data_source).count }.by(1)
    end

    it 'uses a FAKE IncomeBenefitsID' do
      result = build(stage: :entry)
      expect(result.IncomeBenefitsID).to start_with('FAKE')
    end

    it 'sets DataCollectionStage to 1 for entry' do
      expect(build(stage: :entry).DataCollectionStage).to eq(1)
    end

    it 'sets DataCollectionStage to 5 for annual' do
      expect(build(stage: :annual).DataCollectionStage).to eq(5)
    end

    it 'sets DataCollectionStage to 3 for exit' do
      expect(build(stage: :exit).DataCollectionStage).to eq(3)
    end

    it 'sets InformationDate to the given date' do
      expect(build(stage: :entry).InformationDate).to eq(date)
    end

    context 'with no_income_probability: 1.0' do
      let(:income_config) { { 'no_income_probability' => 1.0, 'sources' => {} } }

      it 'sets IncomeFromAnySource to 0' do
        expect(build(stage: :entry).IncomeFromAnySource).to eq(0)
      end
    end

    context 'with no_income_probability: 0.0 and sources configured' do
      let(:income_config) { { 'no_income_probability' => 0.0, 'sources' => { 'ssi' => 1.0 } } }

      it 'sets IncomeFromAnySource to 1' do
        expect(build(stage: :entry).IncomeFromAnySource).to eq(1)
      end

      it 'sets SSI to 1 when ssi is the only source' do
        expect(build(stage: :entry).SSI).to eq(1)
      end

      it 'sets a positive TotalMonthlyIncome' do
        expect(build(stage: :entry).TotalMonthlyIncome.to_f).to be > 0
      end
    end

    it 'links to the correct enrollment and client' do
      result = build(stage: :entry)
      expect(result.EnrollmentID).to eq(enrollment.EnrollmentID)
      expect(result.PersonalID).to eq(client.PersonalID)
    end

    it 'is deterministic — same rng_seed produces same IncomeFromAnySource' do
      r1 = build(stage: :entry, rng_seed: 99)
      r2 = build(stage: :entry, rng_seed: 99)
      expect(r1.IncomeFromAnySource).to eq(r2.IncomeFromAnySource)
    end
  end
end
