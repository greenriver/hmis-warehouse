###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::EmploymentEducationBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) do
    User.setup_system_user
    Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
  end
  let(:date)       { Date.new(2026, 3, 1) }
  let(:project)    { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
  let(:client)     { create(:hmis_hud_client, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: project, client: client) }

  def build(stage: :entry, rng_seed: 42)
    described_class.new(
      enrollment: enrollment,
      date: date,
      stage: stage,
      data_source: data_source,
      user_id: user_id,
      rng_seed: rng_seed,
    ).build!
  end

  describe '#build!' do
    it 'creates one EmploymentEducation record' do
      expect { build }.to change { Hmis::Hud::EmploymentEducation.where(data_source: data_source).count }.by(1)
    end

    it 'sets DataCollectionStage to 1 for entry stage' do
      record = build(stage: :entry)
      expect(record.DataCollectionStage).to eq(1)
    end

    it 'sets DataCollectionStage to 3 for exit stage' do
      record = build(stage: :exit)
      expect(record.DataCollectionStage).to eq(3)
    end

    it 'sets DataCollectionStage to 5 for annual stage' do
      record = build(stage: :annual)
      expect(record.DataCollectionStage).to eq(5)
    end

    it 'sets InformationDate to the provided date' do
      expect(build.InformationDate).to eq(date)
    end

    it 'uses a FAKE EmploymentEducationID' do
      expect(build.EmploymentEducationID).to start_with('FAKE')
    end

    it 'sets Employed to a valid HUD code (0, 1, or 99)' do
      expect([0, 1, 99]).to include(build.Employed)
    end

    it 'sets LastGradeCompleted to a valid HUD code' do
      valid = HudHelper.util.last_grade_completeds.keys
      expect(valid).to include(build.LastGradeCompleted)
    end

    it 'sets SchoolStatus to a valid HUD code' do
      valid = HudHelper.util.school_statuses.keys
      expect(valid).to include(build.SchoolStatus)
    end

    it 'sets EmploymentType when Employed is 1' do
      # With different seeds one will produce Employed=1
      records = 20.times.map { |i| build(rng_seed: i) }
      employed_records = records.select { |r| r.Employed == 1 }
      next if employed_records.empty?

      valid = HudHelper.util.employment_types.keys
      employed_records.each { |r| expect(valid).to include(r.EmploymentType) }
    end

    it 'sets NotEmployedReason when Employed is 0' do
      records = 20.times.map { |i| build(rng_seed: i) }
      unemployed = records.select { |r| r.Employed == 0 }
      next if unemployed.empty?

      valid = HudHelper.util.not_employed_reasons.keys
      unemployed.each { |r| expect(valid).to include(r.NotEmployedReason) }
    end

    it 'leaves EmploymentType nil when Employed is not 1' do
      records = 20.times.map { |i| build(rng_seed: i) }
      not_employed = records.reject { |r| r.Employed == 1 }
      not_employed.each { |r| expect(r.EmploymentType).to be_nil }
    end

    it 'produces varied results across different seeds' do
      employed_values = 20.times.map { |i| build(rng_seed: i).Employed }
      expect(employed_values.uniq.length).to be > 1
    end
  end
end
