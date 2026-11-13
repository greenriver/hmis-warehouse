###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::ConcurrentEnrollmentBuilder do
  include_context 'hmis simulation builder setup'

  let(:date)       { Date.current - 5 }
  let(:so_project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 4) }

  let(:concurrent_projects_config) do
    [
      {
        'name' => so_project.ProjectName,
        'project_type' => 4,
        'selection_weight' => 1.0,
        'duration' => { 'distribution' => 'constant', 'value' => 30 },
        'gap_before_reentry' => { 'distribution' => 'constant', 'value' => 7 },
        'reentry_probability' => 0.8,
      },
    ]
  end

  def build(rng_seed: 42)
    described_class.new(
      client: client,
      date: date,
      projects_config: concurrent_projects_config,
      count: 1,
      coc_code: 'XX-500',
      data_source: data_source,
      user_id: user_id,
      rng_seed: rng_seed,
    ).build!
  end

  describe '#build!' do
    it 'creates an Hmis::Hud::Enrollment for the concurrent project' do
      expect { build }.to change { Hmis::Hud::Enrollment.where(data_source: data_source).count }.by(1)
    end

    it 'creates an HmisSimulation::ConcurrentEnrollment state record' do
      expect { build }.to change { HmisSimulation::ConcurrentEnrollment.where(data_source_id: data_source.id).count }.by(1)
    end

    it 'uses a FAKE EnrollmentID' do
      build
      enrollment = Hmis::Hud::Enrollment.where(data_source: data_source).last
      expect(enrollment.EnrollmentID).to start_with('FAKE')
    end

    it 'sets EntryDate to the given date' do
      build
      enrollment = Hmis::Hud::Enrollment.where(data_source: data_source).last
      expect(enrollment.EntryDate).to eq(date)
    end

    it 'links the state record to the correct client' do
      build
      state = HmisSimulation::ConcurrentEnrollment.find_by(
        data_source_id: data_source.id,
        hud_client_id: client.id,
      )
      expect(state).to be_present
    end

    it 'sets exit_on based on the duration distribution' do
      build
      state = HmisSimulation::ConcurrentEnrollment.where(data_source_id: data_source.id).last
      expect(state.exit_on).to eq(date + 30)
    end

    it 'stores the project name on the state record' do
      build
      state = HmisSimulation::ConcurrentEnrollment.where(data_source_id: data_source.id).last
      expect(state.project_name).to eq(so_project.ProjectName)
    end

    context 'when count is 0' do
      it 'creates no records' do
        described_class.new(
          client: client, date: date, projects_config: concurrent_projects_config,
          count: 0, coc_code: 'XX-500', data_source: data_source, user_id: user_id, rng_seed: 42
        ).build!
        expect(HmisSimulation::ConcurrentEnrollment.where(data_source_id: data_source.id).count).to eq(0)
      end
    end
  end
end
