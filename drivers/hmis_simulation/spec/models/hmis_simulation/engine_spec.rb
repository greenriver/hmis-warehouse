###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Engine do
  let!(:data_source) { create(:hmis_data_source) }
  let(:run_date)     { Date.new(2026, 1, 15) }

  # High lambda so we reliably get clients on every test day.
  # 300/month = ~10/day via Poisson — virtually never 0 in practice.
  let(:base_config) do
    {
      'name' => 'Engine Test CoC',
      'data_source_id' => data_source.id,
      'seed' => 42,
      'coc_codes' => { 'primary' => 'XX-500' },
      'organizations' => [
        {
          'name' => 'Test Org_',
          'projects' => [
            { 'name' => 'Test ES_', 'project_type' => 1, 'capacity' => 50 },
            { 'name' => 'Test PSH_', 'project_type' => 3, 'capacity' => 30 },
          ],
        },
      ],
      'household_templates' => {
        'adult_only' => {
          'hoh' => {
            'age' => { 'distribution' => 'uniform', 'min' => 25, 'max' => 55 },
            'gender' => { 'woman' => 0.5, 'man' => 0.5 },
            'veteran_probability' => 0.0,
            'race' => { 'white' => 1.0 },
          },
        },
      },
      'populations' => [
        { 'name' => 'street', 'label' => 'Street', 'project_ref' => 'Test ES_',
          'household_templates' => { 'adult_only' => 1 },
          'entry_point' => 6, 'exit_point' => 0.1 },
        { 'name' => 'psh', 'label' => 'PSH', 'project_ref' => 'Test PSH_',
          'household_templates' => { 'adult_only' => 1 },
          'entry_point' => 0, 'exit_point' => 0.5 },
      ],
      'transitions' => [
        { 'from' => 'street', 'to' => 'psh', 'weight' => 1,
          'timing' => { 'distribution' => 'constant', 'value' => 30 },
          'exit_destinations' => { '435' => 1 } },
      ],
      'enrollment_config' => {
        'new_clients_per_month' => { 'distribution' => 'poisson', 'lambda' => 300 },
        'disabilities' => {
          'disabling_condition_probability' => 0.8,
          'types' => { 'mental_health' => 0.7, 'substance_use' => 0.5 },
        },
        'income_at_entry' => { 'no_income_probability' => 0.3, 'sources' => { 'ssi' => 1.0 } },
        'health_and_dv' => { 'dv_survivor_probability' => 0.2, 'general_health' => { 'fair' => 1.0 } },
      },
    }
  end

  let(:config) { HmisSimulation::ConfigLoader.send(:normalize, base_config) }

  before do
    User.setup_system_user
    HmisSimulation::Bootstrapper.new(config).run!
  end

  subject(:engine) { described_class.new(config) }

  def sim_clients
    HmisSimulation::Client.where(data_source_id: data_source.id)
  end

  describe '#run' do
    it 'creates HmisSimulation::Client state records' do
      expect { engine.run(date: run_date) }.to change { sim_clients.count }.by_at_least(1)
    end

    it 'sets pending_enrollment_on to the run date for all spawned clients' do
      engine.run(date: run_date)
      expect(sim_clients.where.not(pending_enrollment_on: run_date).count).to eq(0)
    end

    it 'assigns each spawned client a current_population matching a defined population' do
      engine.run(date: run_date)
      population_names = config['populations'].map { |p| p['name'] }
      sim_clients.pluck(:current_population).each do |pop|
        expect(population_names).to include(pop)
      end
    end

    it 'only assigns entry_point populations (street has entry_point > 0, psh does not)' do
      engine.run(date: run_date)
      populations = sim_clients.pluck(:current_population).uniq
      expect(populations).to include('street')
      expect(populations).not_to include('psh')
    end

    it 'sets exited_system: false for all spawned clients' do
      engine.run(date: run_date)
      expect(sim_clients.where(exited_system: true).count).to eq(0)
    end

    it 'writes a RunLog record for the run date' do
      engine.run(date: run_date)
      log = HmisSimulation::RunLog.find_by(data_source_id: data_source.id, run_date: run_date)
      expect(log).to be_present
      expect(log.error_message).to be_nil
      expect(log.clients_created).to be > 0
    end

    context 'when run twice on the same date' do
      it 'is idempotent — no duplicate clients or log entries' do
        engine.run(date: run_date)
        first_count = sim_clients.count

        engine.run(date: run_date)
        expect(sim_clients.count).to eq(first_count)
        expect(HmisSimulation::RunLog.where(data_source_id: data_source.id, run_date: run_date).count).to eq(1)
      end
    end

    context 'when run across multiple dates' do
      it 'accumulates clients across days' do
        engine.run(date: run_date)
        count_day1 = sim_clients.count

        engine.run(date: run_date + 1)
        expect(sim_clients.count).to be > count_day1
      end

      it 'creates separate RunLog records per date' do
        engine.run(date: run_date)
        engine.run(date: run_date + 1)

        logs = HmisSimulation::RunLog.where(data_source_id: data_source.id)
        expect(logs.pluck(:run_date)).to include(run_date, run_date + 1)
      end
    end

    context 'primary enrollment tick' do
      it 'creates Enrollment records for spawned clients on the same day' do
        engine.run(date: run_date)
        enrolled = sim_clients.where.not(hud_enrollment_id: nil)
        expect(enrolled.count).to be > 0
      end

      it 'sets next_transition_on for enrolled clients' do
        engine.run(date: run_date)
        enrolled = sim_clients.where.not(hud_enrollment_id: nil)
        enrolled.each do |sc|
          expect(sc.next_transition_on).to be_present
          expect(sc.next_transition_on).to be > run_date
        end
      end

      it 'stores next_population on enrolled clients' do
        engine.run(date: run_date)
        enrolled = sim_clients.where.not(hud_enrollment_id: nil)
        population_names = config['populations'].map { |p| p['name'] }
        enrolled.each do |sc|
          expect(population_names).to include(sc.next_population)
        end
      end

      it 'creates Exit records when next_transition_on fires' do
        # Use config with 1-day timing so transitions fire the next day
        fast_config = base_config.deep_dup
        fast_config['transitions'].each { |t| t['timing'] = { 'distribution' => 'constant', 'value' => 1 } }
        fast_config['transitions'].each { |t| t['gap_before_entry'] = { 'distribution' => 'constant', 'value' => 0 } }
        cfg = HmisSimulation::ConfigLoader.send(:normalize, fast_config)
        HmisSimulation::Bootstrapper.new(cfg).run!
        e = described_class.new(cfg)

        e.run(date: run_date)
        Hmis::Hud::Enrollment.where(data_source: data_source).count

        e.run(date: run_date + 1)
        exit_count = Hmis::Hud::Exit.where(data_source: data_source).count
        expect(exit_count).to be > 0
      end

      it 'creates bed-night Service records for NBN project enrollments' do
        engine.run(date: run_date)

        nbn_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test ES_')
        nbn_enrollments = Hmis::Hud::Enrollment.where(
          data_source: data_source, project_pk: nbn_project.id,
        )

        if nbn_enrollments.any?
          services = Hmis::Hud::Service.where(data_source: data_source, RecordType: 200)
          expect(services.count).to be > 0
        end
      end

      it 'clears pending_enrollment_on after creating an enrollment' do
        engine.run(date: run_date)
        enrolled = sim_clients.where.not(hud_enrollment_id: nil)
        expect(enrolled.where.not(pending_enrollment_on: nil).count).to eq(0)
      end

      it 'updates enrollments_opened in RunLog' do
        engine.run(date: run_date)
        log = HmisSimulation::RunLog.find_by(data_source_id: data_source.id, run_date: run_date)
        expect(log.enrollments_opened).to be > 0
      end
    end

    context 'linked records at entry' do
      before { engine.run(date: run_date) }

      it 'creates Disability records for enrolled clients' do
        expect(Hmis::Hud::Disability.where(data_source: data_source).count).to be > 0
      end

      it 'creates IncomeBenefit records at entry stage' do
        count = Hmis::Hud::IncomeBenefit.where(data_source: data_source, DataCollectionStage: 1).count
        expect(count).to be > 0
      end

      it 'creates HealthAndDv records for enrolled clients' do
        expect(Hmis::Hud::HealthAndDv.where(data_source: data_source).count).to be > 0
      end

      it 'sets DisablingCondition on enrollments to 0 or 1 (updated from 99 default)' do
        updated = Hmis::Hud::Enrollment.
          where(data_source: data_source).
          where.not(DisablingCondition: 99)
        expect(updated.count).to be > 0
      end
    end

    context 'concurrent enrollments' do
      # Config with concurrent enrollments guaranteed on every client (count=1 always)
      let(:base_config_with_concurrent) do
        base_config.deep_dup.tap do |c|
          c['organizations'].first['projects'] << {
            'name' => 'Concurrent SO_', 'project_type' => 4
          }
          c['concurrent_enrollments'] = {
            'count_distribution' => { '1' => 1 },
            'data_error_rate' => 0.0,
            'projects' => [
              {
                'name' => 'Concurrent SO_',
                'project_type' => 4,
                'selection_weight' => 1,
                'duration' => { 'distribution' => 'constant', 'value' => 2 },
                'gap_before_reentry' => { 'distribution' => 'constant', 'value' => 1 },
                'reentry_probability' => 1.0,
              },
            ],
          }
        end
      end
      let(:concurrent_config) { HmisSimulation::ConfigLoader.send(:normalize, base_config_with_concurrent) }

      before do
        HmisSimulation::Bootstrapper.new(concurrent_config).run!
      end

      it 'assigns concurrent enrollments when a primary enrollment opens' do
        described_class.new(concurrent_config).run(date: run_date)
        expect(HmisSimulation::ConcurrentEnrollment.where(data_source_id: data_source.id).count).to be > 0
      end

      it 'closes concurrent enrollments when exit_on fires' do
        e = described_class.new(concurrent_config)
        e.run(date: run_date)

        # concurrent enrollment duration = 2 days, so it expires on run_date + 2
        e.run(date: run_date + 1)
        e.run(date: run_date + 2)

        exits = Hmis::Hud::Exit.where(data_source: data_source)
        # At least some concurrent exits should have been created
        expect(exits.count).to be > 0
      end

      it 'schedules reentry when reentry_probability = 1.0' do
        e = described_class.new(concurrent_config)
        e.run(date: run_date)

        # Duration=2, so expires on run_date+2
        e.run(date: run_date + 1)
        e.run(date: run_date + 2)

        # With reentry_probability=1.0, all expired concurrent enrollments should have pending_reentry_on set
        expired = HmisSimulation::ConcurrentEnrollment.
          where(data_source_id: data_source.id).
          where.not(pending_reentry_on: nil)
        expect(expired.count).to be > 0
      end

      it 'opens reentry enrollments when pending_reentry_on fires' do
        e = described_class.new(concurrent_config)
        e.run(date: run_date)       # spawns clients, creates concurrent enrollments (exit_on = run_date+2)
        e.run(date: run_date + 2)   # expires concurrent, schedules reentry on run_date+3
        enrollment_count = Hmis::Hud::Enrollment.where(data_source: data_source).count

        e.run(date: run_date + 3)   # reentry fires, opens new concurrent enrollment
        expect(Hmis::Hud::Enrollment.where(data_source: data_source).count).to be > enrollment_count
      end
    end

    context 'annual collection' do
      it 'creates annual IncomeBenefit records for enrollments near their anniversary' do
        # Create an enrollment that is exactly 365 days old so annual collection fires today
        old_entry = run_date - 365
        hoh = create(:hmis_hud_client, data_source: data_source)
        project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test ES_')
        enrollment = create(
          :hmis_hud_enrollment,
          data_source: data_source, client: hoh, project: project,
          EntryDate: old_entry
        )

        # Use a config with zero jitter so the anniversary date is deterministic
        zero_jitter_config = base_config.deep_dup
        zero_jitter_config['enrollment_config'] ||= {}
        zero_jitter_config['enrollment_config']['annual_collection'] = {
          'miss_rate' => 0.0,
          'timing_jitter' => { 'distribution' => 'constant', 'value' => 0 },
        }
        cfg = HmisSimulation::ConfigLoader.send(:normalize, zero_jitter_config)
        e = described_class.new(cfg)
        e.run(date: run_date)

        annual = Hmis::Hud::IncomeBenefit.where(
          data_source: data_source,
          EnrollmentID: enrollment.EnrollmentID,
          DataCollectionStage: 5,
        )
        expect(annual.count).to eq(1)
      end
    end
  end
end
