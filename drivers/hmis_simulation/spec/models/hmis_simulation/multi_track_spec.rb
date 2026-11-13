###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Tests for N-track configuration: multiple primary tracks, applies_to_tracks
# filtering on secondary tracks, and per-track data_quality / enrollment_config overrides.
RSpec.describe 'HmisSimulation N-track behavior' do
  let!(:data_source) { create(:hmis_data_source) }
  let(:run_date)     { Date.new(2026, 1, 15) }

  let(:base_orgs) do
    [
      {
        'name' => 'Test Org_',
        'projects' => [
          { 'name' => 'General ES_',   'project_type' => 1, 'capacity' => 50 },
          { 'name' => 'Veteran ES_',   'project_type' => 1, 'capacity' => 20 },
          { 'name' => 'General SO_',   'project_type' => 4 },
          { 'name' => 'Track2 ES_',    'project_type' => 1, 'capacity' => 50 },
        ],
      },
    ]
  end

  def general_primary_track(project_ref: 'General ES_', overrides: {})
    {
      'name' => 'general',
      'type' => 'primary',
      'new_clients_per_month' => { 'distribution' => 'poisson', 'lambda' => 300 },
      'household_templates' => {
        'adult_only' => {
          'hoh' => {
            'age' => { 'distribution' => 'uniform', 'min' => 25, 'max' => 55 },
            'gender' => { 'man' => 0.5, 'woman' => 0.5 },
            'veteran_probability' => 0.0,
            'race' => { 'white' => 1.0 },
          },
        },
      },
      'populations' => [
        { 'name' => 'street', 'project_ref' => project_ref,
          'household_templates' => { 'adult_only' => 1 },
          'entry_point' => 1, 'exit_point' => 0.1 },
      ],
      'transitions' => [],
    }.deep_merge(overrides)
  end

  def veteran_primary_track
    {
      'name' => 'veterans',
      'type' => 'primary',
      'new_clients_per_month' => { 'distribution' => 'poisson', 'lambda' => 300 },
      'household_templates' => {
        'adult_only' => {
          'hoh' => {
            'age' => { 'distribution' => 'uniform', 'min' => 30, 'max' => 65 },
            'gender' => { 'man' => 0.85, 'woman' => 0.15 },
            'veteran_probability' => 1.0,
            'race' => { 'white' => 0.6, 'black_af_american' => 0.4 },
          },
        },
      },
      'populations' => [
        { 'name' => 'vet_street', 'project_ref' => 'Veteran ES_',
          'household_templates' => { 'adult_only' => 1 },
          'entry_point' => 1, 'exit_point' => 0.1 },
      ],
      'transitions' => [],
    }
  end

  def build_config(tracks:, data_quality: {})
    {
      'name' => 'Multi-Track Test CoC',
      'data_source_id' => data_source.id,
      'seed' => 100,
      'coc_codes' => { 'primary' => 'XX-500' },
      'organizations' => base_orgs,
      'data_quality' => data_quality,
      'tracks' => tracks,
    }
  end

  def run_engine(config, date: run_date)
    engine = HmisSimulation::Engine.new(config)
    engine.run(date: date)
    engine
  end

  def sim_clients_for(track_name)
    HmisSimulation::Client.where(data_source_id: data_source.id, track_name: track_name)
  end

  before { User.setup_system_user }

  # -----------------------------------------------------------------------
  # Multiple primary tracks: both spawn clients with correct track_names
  # -----------------------------------------------------------------------
  describe 'multiple primary tracks' do
    let(:config) do
      HmisSimulation::ConfigLoader.send(
        :normalize,
        build_config(tracks: [general_primary_track, veteran_primary_track]),
      )
    end

    before do
      HmisSimulation::Bootstrapper.new(config).run!
      run_engine(config)
    end

    it 'spawns clients for both primary tracks' do
      track_names = HmisSimulation::Client.where(data_source_id: data_source.id).pluck(:track_name).uniq.sort
      expect(track_names).to contain_exactly('general', 'veterans')
    end

    it 'creates HUD enrollments for clients in each track independently' do
      general_ids = sim_clients_for('general').pluck(:hud_client_id)
      veteran_ids = sim_clients_for('veterans').pluck(:hud_client_id)

      expect(general_ids).not_to be_empty
      expect(veteran_ids).not_to be_empty
      expect(general_ids & veteran_ids).to be_empty
    end

    it 'writes a single RunLog for the day (not one per track)' do
      logs = HmisSimulation::RunLog.where(data_source_id: data_source.id, run_date: run_date)
      expect(logs.count).to eq(1)
      expect(logs.first.error_message).to be_nil
    end

    it 'reports combined clients_created across all primary tracks' do
      log = HmisSimulation::RunLog.find_by!(data_source_id: data_source.id, run_date: run_date)
      general_count = sim_clients_for('general').count
      veteran_count = sim_clients_for('veterans').count
      expect(log.clients_created).to eq(general_count + veteran_count)
    end
  end

  # -----------------------------------------------------------------------
  # applies_to_tracks: concurrent track scoped to one primary track only
  # -----------------------------------------------------------------------
  describe 'applies_to_tracks filtering' do
    let(:config) do
      HmisSimulation::ConfigLoader.send(
        :normalize,
        build_config(
          tracks: [
            general_primary_track,
            veteran_primary_track,
            {
              'name' => 'general_outreach',
              'type' => 'concurrent',
              'applies_to_tracks' => ['general'], # only for general clients
              'projects' => ['General SO_'],
              'count_distribution' => { '1' => 1 }, # always 1 concurrent enrollment
              'data_error_rate' => 0.0,
              'duration' => { 'distribution' => 'constant', 'value' => 30 },
            },
          ],
        ),
      )
    end

    before do
      HmisSimulation::Bootstrapper.new(config).run!
      run_engine(config)
    end

    it 'creates concurrent enrollments only for general track clients' do
      concurrent_hud_ids = HmisSimulation::ConcurrentEnrollment.
        where(data_source_id: data_source.id).
        pluck(:hud_client_id).to_set

      general_hud_ids = sim_clients_for('general').pluck(:hud_client_id).to_set
      veteran_hud_ids = sim_clients_for('veterans').pluck(:hud_client_id).to_set

      expect(general_hud_ids).not_to be_empty
      expect(veteran_hud_ids).not_to be_empty

      expect(concurrent_hud_ids & general_hud_ids).not_to be_empty, 'general clients should have concurrent enrollments'
      expect(concurrent_hud_ids & veteran_hud_ids).to be_empty, 'veteran clients should NOT have concurrent enrollments'
    end

    it 'stores the concurrent track name on ConcurrentEnrollment records' do
      track_names = HmisSimulation::ConcurrentEnrollment.
        where(data_source_id: data_source.id).
        pluck(:track_name).uniq
      expect(track_names).to eq(['general_outreach'])
    end
  end

  # -----------------------------------------------------------------------
  # Per-track data_quality override
  # -----------------------------------------------------------------------
  describe 'per-track data_quality override' do
    let(:config) do
      HmisSimulation::ConfigLoader.send(
        :normalize,
        build_config(
          data_quality: { 'missing_dob_rate' => 0.0 },
          tracks: [
            general_primary_track, # inherits global: missing_dob_rate = 0.0
            general_primary_track(
              project_ref: 'Track2 ES_',
              overrides: {
                'name' => 'high_dq_issues',
                'data_quality' => { 'missing_dob_rate' => 1.0 },
              },
            ),
          ],
        ),
      )
    end

    before do
      HmisSimulation::Bootstrapper.new(config).run!
      run_engine(config)
    end

    it 'general track clients have DOB (missing_dob_rate = 0.0)' do
      hud_ids = sim_clients_for('general').pluck(:hud_client_id)
      expect(hud_ids).not_to be_empty
      missing = Hmis::Hud::Client.where(id: hud_ids, DOB: nil).count
      expect(missing).to eq(0)
    end

    it 'high_dq_issues track clients all have missing DOB (missing_dob_rate = 1.0)' do
      hud_ids = sim_clients_for('high_dq_issues').pluck(:hud_client_id)
      expect(hud_ids).not_to be_empty
      present = Hmis::Hud::Client.where(id: hud_ids).where.not(DOB: nil).count
      expect(present).to eq(0)
    end
  end

  # -----------------------------------------------------------------------
  # Per-track enrollment_config override
  # -----------------------------------------------------------------------
  describe 'per-track enrollment_config override' do
    let(:config) do
      HmisSimulation::ConfigLoader.send(
        :normalize,
        build_config(
          tracks: [
            general_primary_track(overrides: {
                                    'enrollment_config' => {
                                      'disabilities' => { 'disabling_condition_probability' => 0.0, 'types' => {} },
                                      'income_at_entry' => { 'no_income_probability' => 1.0, 'sources' => {} },
                                      'health_and_dv' => { 'dv_survivor_probability' => 0.0, 'general_health' => { 'good' => 1.0 } },
                                    },
                                  }),
            general_primary_track(
              project_ref: 'Track2 ES_',
              overrides: {
                'name' => 'all_disabled',
                'enrollment_config' => {
                  'disabilities' => { 'disabling_condition_probability' => 1.0, 'types' => { 'mental_health' => 1.0 } },
                  'income_at_entry' => { 'no_income_probability' => 1.0, 'sources' => {} },
                  'health_and_dv' => { 'dv_survivor_probability' => 0.0, 'general_health' => { 'good' => 1.0 } },
                },
              },
            ),
          ],
        ),
      )
    end

    before do
      HmisSimulation::Bootstrapper.new(config).run!
      run_engine(config)
    end

    it 'general track enrollments have DisablingCondition = 0 (probability = 0.0)' do
      enrollment_ids = HmisSimulation::Client.
        where(data_source_id: data_source.id, track_name: 'general').
        where.not(hud_enrollment_id: nil).
        pluck(:hud_enrollment_id)
      expect(enrollment_ids).not_to be_empty
      expect(Hmis::Hud::Enrollment.where(id: enrollment_ids, DisablingCondition: 1).count).to eq(0)
    end

    it 'all_disabled track enrollments have DisablingCondition = 1 (probability = 1.0)' do
      enrollment_ids = HmisSimulation::Client.
        where(data_source_id: data_source.id, track_name: 'all_disabled').
        where.not(hud_enrollment_id: nil).
        pluck(:hud_enrollment_id)
      expect(enrollment_ids).not_to be_empty
      expect(Hmis::Hud::Enrollment.where(id: enrollment_ids, DisablingCondition: 0).count).to eq(0)
    end
  end
end
