###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::DisabilityBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) do
    User.setup_system_user
    Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
  end
  let(:date)       { Date.current - 1 }
  let(:client)     { create(:hmis_hud_client, data_source: data_source) }
  let(:project)    { create(:hmis_hud_project, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, client: client, project: project, EntryDate: date - 30) }

  let(:disability_config) do
    {
      'disabling_condition_probability' => 0.8,
      'types' => { 'mental_health' => 0.6, 'substance_use' => 0.4, 'physical' => 0.3 },
    }
  end

  subject(:builder) do
    described_class.new(
      enrollment: enrollment,
      date: date,
      disability_config: disability_config,
      data_source: data_source,
      user_id: user_id,
      rng_seed: 42,
    )
  end

  describe '#build!' do
    it 'creates one Disability record per configured type' do
      expect { builder.build! }.
        to change { Hmis::Hud::Disability.where(data_source: data_source).count }.
        by(disability_config['types'].size)
    end

    it 'uses FAKE DisabilitiesID on each record' do
      builder.build!
      Hmis::Hud::Disability.where(data_source: data_source).each do |d|
        expect(d.DisabilitiesID).to start_with('FAKE')
      end
    end

    it 'sets DataCollectionStage to 1 (entry)' do
      builder.build!
      Hmis::Hud::Disability.where(data_source: data_source).each do |d|
        expect(d.DataCollectionStage).to eq(1)
      end
    end

    it 'sets IndefiniteAndImpairs to nil for developmental (type 6) and HIV/AIDS (type 8)' do
      config = disability_config.merge('types' => { 'developmental' => 1.0, 'hiv_aids' => 1.0 })
      described_class.new(
        enrollment: enrollment, date: date, disability_config: config,
        data_source: data_source, user_id: user_id, rng_seed: 42
      ).build!
      Hmis::Hud::Disability.where(data_source: data_source).each do |d|
        expect(d.IndefiniteAndImpairs).to be_nil
      end
    end

    it 'sets IndefiniteAndImpairs to 0 or 1 for non-exempt types (mental_health = type 9)' do
      config = disability_config.merge('types' => { 'mental_health' => 1.0 })
      described_class.new(
        enrollment: enrollment, date: date, disability_config: config,
        data_source: data_source, user_id: user_id, rng_seed: 42
      ).build!
      d = Hmis::Hud::Disability.where(data_source: data_source).first
      expect([0, 1]).to include(d.IndefiniteAndImpairs)
    end

    it 'returns the DisablingCondition value (0 or 1)' do
      result = builder.build!
      expect([0, 1]).to include(result[:disabling_condition])
    end

    it 'links records to the correct enrollment' do
      builder.build!
      Hmis::Hud::Disability.where(data_source: data_source).each do |d|
        expect(d.EnrollmentID).to eq(enrollment.EnrollmentID)
      end
    end
  end
end
