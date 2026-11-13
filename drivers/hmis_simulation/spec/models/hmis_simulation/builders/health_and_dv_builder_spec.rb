###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::HealthAndDvBuilder do
  include_context 'hmis simulation builder setup'

  let(:date) { Date.current - 1 }

  let(:hdv_config) do
    {
      'dv_survivor_probability' => 0.0,
      'currently_fleeing_probability' => 0.0,
      'general_health' => { 'poor' => 0.3, 'fair' => 0.4, 'good' => 0.25, 'excellent' => 0.05 },
    }
  end

  subject(:builder) do
    described_class.new(
      enrollment: enrollment,
      date: date,
      hdv_config: hdv_config,
      data_source: data_source,
      user_id: user_id,
      rng_seed: 42,
    )
  end

  describe '#build!' do
    it 'creates an Hmis::Hud::HealthAndDv record' do
      expect { builder.build! }.to change { Hmis::Hud::HealthAndDv.where(data_source: data_source).count }.by(1)
    end

    it 'uses a FAKE HealthAndDVID' do
      expect(builder.build!.HealthAndDVID).to start_with('FAKE')
    end

    it 'sets DataCollectionStage to 1 (entry)' do
      expect(builder.build!.DataCollectionStage).to eq(1)
    end

    it 'sets InformationDate to the given date' do
      expect(builder.build!.InformationDate).to eq(date)
    end

    it 'links to the correct enrollment and client' do
      result = builder.build!
      expect(result.EnrollmentID).to eq(enrollment.EnrollmentID)
      expect(result.PersonalID).to eq(client.PersonalID)
    end

    context 'with dv_survivor_probability: 1.0' do
      let(:hdv_config) { super().merge('dv_survivor_probability' => 1.0) }

      it 'sets DomesticViolenceSurvivor to 1' do
        expect(builder.build!.DomesticViolenceSurvivor).to eq(1)
      end
    end

    context 'with dv_survivor_probability: 0.0' do
      it 'sets DomesticViolenceSurvivor to 0' do
        expect(builder.build!.DomesticViolenceSurvivor).to eq(0)
      end
    end

    it 'sets GeneralHealthStatus to a value from the configured distribution' do
      result = builder.build!
      # 1=Excellent, 2=Good, 3=Fair, 4=Poor in HUD
      expect([1, 2, 3, 4]).to include(result.GeneralHealthStatus)
    end

    context 'with stage: :exit' do
      subject(:builder) do
        described_class.new(
          enrollment: enrollment,
          date: date,
          stage: :exit,
          hdv_config: hdv_config,
          data_source: data_source,
          user_id: user_id,
          rng_seed: 42,
        )
      end

      it 'sets DataCollectionStage to 3 (exit)' do
        expect(builder.build!.DataCollectionStage).to eq(3)
      end
    end
  end
end
