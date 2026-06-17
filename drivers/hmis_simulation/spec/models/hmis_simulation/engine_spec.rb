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
      'tracks' => [
        {
          'name' => 'general',
          'type' => 'primary',
          'new_clients_per_month' => { 'distribution' => 'poisson', 'lambda' => 300 },
          'household_cohesion_probability' => 0.85,
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
            'disabilities' => {
              'disabling_condition_probability' => 0.8,
              'types' => { 'mental_health' => 0.7, 'substance_use' => 0.5 },
            },
            'income_at_entry' => { 'no_income_probability' => 0.3, 'sources' => { 'ssi' => 1.0 } },
            'health_and_dv' => { 'dv_survivor_probability' => 0.2, 'general_health' => { 'fair' => 1.0 } },
          },
        },
      ],
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

  def primary_populations
    config['tracks'].find { |t| t['type'] == 'primary' }['populations']
  end

  describe '#run' do
    it 'creates HmisSimulation::Client state records' do
      expect { engine.run(date: run_date) }.to change { sim_clients.count }.by_at_least(1)
    end

    it 'sets pending_enrollment_on to the run date for all spawned clients' do
      engine.run(date: run_date)
      expect(sim_clients.where.not(pending_enrollment_on: run_date).count).to eq(0)
    end

    it 'only assigns entry_point populations (street has entry_point > 0, psh does not)' do
      engine.run(date: run_date)
      populations = sim_clients.pluck(:current_population).uniq
      expect(populations).to include('street')
      expect(populations).not_to include('psh')
    end

    it 'assigns track_name to spawned clients' do
      engine.run(date: run_date)
      expect(sim_clients.pluck(:track_name).uniq).to eq(['general'])
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
        enrolled.each do |sim_client|
          expect(sim_client.next_transition_on).to be_present
          expect(sim_client.next_transition_on).to be > run_date
        end
      end

      it 'stores next_population on enrolled clients' do
        engine.run(date: run_date)
        enrolled = sim_clients.where.not(hud_enrollment_id: nil)
        population_names = primary_populations.map { |p| p['name'] }
        enrolled.each do |sim_client|
          expect(population_names).to include(sim_client.next_population)
        end
      end

      it 'creates Exit records when next_transition_on fires' do
        fast_config = base_config.deep_dup
        fast_config['tracks'].first['transitions'].each { |t| t['timing'] = { 'distribution' => 'constant', 'value' => 1 } }
        fast_config['tracks'].first['transitions'].each { |t| t['gap_before_entry'] = { 'distribution' => 'constant', 'value' => 0 } }
        cfg = HmisSimulation::ConfigLoader.send(:normalize, fast_config)
        HmisSimulation::Bootstrapper.new(cfg).run!
        fast_engine = described_class.new(cfg)

        fast_engine.run(date: run_date)
        fast_engine.run(date: run_date + 1)
        exit_count = Hmis::Hud::Exit.where(data_source: data_source).count
        expect(exit_count).to be > 0
      end

      it 'creates HealthAndDv records at exit stage (DataCollectionStage 3) for enrollments that exit' do
        fast_config = base_config.deep_dup
        fast_config['tracks'].first['transitions'].each { |t| t['timing'] = { 'distribution' => 'constant', 'value' => 1 } }
        fast_config['tracks'].first['transitions'].each { |t| t['gap_before_entry'] = { 'distribution' => 'constant', 'value' => 0 } }
        cfg = HmisSimulation::ConfigLoader.send(:normalize, fast_config)
        HmisSimulation::Bootstrapper.new(cfg).run!
        fast_engine = described_class.new(cfg)

        fast_engine.run(date: run_date)
        fast_engine.run(date: run_date + 1)

        exit_enrollment_ids = Hmis::Hud::Exit.where(data_source: data_source).pluck(:EnrollmentID)
        expect(exit_enrollment_ids).not_to be_empty, 'expected at least one exit to have occurred — check engine config'

        hdv_exit_count = Hmis::Hud::HealthAndDv.where(
          data_source: data_source,
          DataCollectionStage: 3,
          EnrollmentID: exit_enrollment_ids,
        ).count
        expect(hdv_exit_count).to be > 0
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

      it 'creates EmploymentEducation records at entry for residential project types' do
        # base_config has ES-NBN (type 1) which is residential
        count = Hmis::Hud::EmploymentEducation.where(data_source: data_source, DataCollectionStage: 1).count
        expect(count).to be > 0
      end

      it 'sets LivingSituation to a valid HUD code on enrollments' do
        valid = HudHelper.util.valid_prior_living_situations.to_set
        enrollments = Hmis::Hud::Enrollment.where(data_source: data_source)
        enrollments.each do |e|
          expect(valid).to include(e.LivingSituation), "Expected #{e.LivingSituation} to be valid"
        end
      end
    end

    context 'periodic CLS records for SO enrollments' do
      let(:so_config) do
        base_config.deep_dup.tap do |cfg|
          # Add an SO project (not linked to any population so engine won't auto-spawn into it)
          cfg['organizations'].first['projects'] << { 'name' => 'Test SO_', 'project_type' => 4 }
        end
      end
      let(:so_normalized) { HmisSimulation::ConfigLoader.send(:normalize, so_config) }

      before do
        HmisSimulation::Bootstrapper.new(so_normalized).run!
      end

      it 'creates CLS records for SO enrollments at the frequency interval' do
        so_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test SO_')
        client = create(:hmis_hud_client, data_source: data_source)
        # Entry 1 day ago; CLS window is days 15-45 (30 ± 2*stddev)
        create(
          :hmis_hud_enrollment,
          data_source: data_source,
          project: so_project,
          client: client,
          EntryDate: run_date - 1,
        )

        engine_instance = described_class.new(so_normalized)
        # Run days 1 through 50 relative to entry to cover the first CLS window
        (1..50).each { |i| engine_instance.run(date: run_date + i) }

        cls_count = Hmis::Hud::CurrentLivingSituation.where(data_source: data_source).count
        expect(cls_count).to be >= 1
      end
    end

    context 'concurrent enrollments' do
      let(:base_config_with_concurrent) do
        base_config.deep_dup.tap do |cfg|
          cfg['organizations'].first['projects'] << { 'name' => 'Concurrent SO_', 'project_type' => 4 }
          cfg['tracks'] << {
            'name' => 'so_contacts',
            'type' => 'concurrent',
            'applies_to_tracks' => [],
            'projects' => ['Concurrent SO_'],
            'count_distribution' => { '1' => 1 },
            'data_error_rate' => 0.0,
            'duration' => { 'distribution' => 'constant', 'value' => 2 },
            'reentry' => {
              'gap' => { 'distribution' => 'constant', 'value' => 1 },
              'probability' => 1.0,
            },
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

      it 'sets track_name on concurrent enrollments' do
        described_class.new(concurrent_config).run(date: run_date)
        expect(HmisSimulation::ConcurrentEnrollment.where(data_source_id: data_source.id).pluck(:track_name).uniq).to eq(['so_contacts'])
      end

      it 'closes concurrent enrollments when exit_on fires' do
        engine_instance = described_class.new(concurrent_config)
        engine_instance.run(date: run_date)

        engine_instance.run(date: run_date + 1)
        engine_instance.run(date: run_date + 2)

        exits = Hmis::Hud::Exit.where(data_source: data_source)
        expect(exits.count).to be > 0
      end

      it 'schedules reentry when reentry probability = 1.0' do
        engine_instance = described_class.new(concurrent_config)
        engine_instance.run(date: run_date)

        engine_instance.run(date: run_date + 1)
        engine_instance.run(date: run_date + 2)

        expired = HmisSimulation::ConcurrentEnrollment.
          where(data_source_id: data_source.id).
          where.not(pending_reentry_on: nil)
        expect(expired.count).to be > 0
      end

      it 'opens reentry enrollments when pending_reentry_on fires' do
        engine_instance = described_class.new(concurrent_config)
        engine_instance.run(date: run_date)
        engine_instance.run(date: run_date + 2)
        enrollment_count = Hmis::Hud::Enrollment.where(data_source: data_source).count

        engine_instance.run(date: run_date + 3)
        expect(Hmis::Hud::Enrollment.where(data_source: data_source).count).to be > enrollment_count
      end
    end

    context 'lifecycle enrollments (CE)' do
      let(:base_config_with_lifecycle) do
        base_config.deep_dup.tap do |cfg|
          cfg['organizations'].first['projects'] << { 'name' => 'CE Program_', 'project_type' => 14 }
          cfg['tracks'] << {
            'name' => 'coordinated_entry',
            'type' => 'lifecycle',
            'applies_to_tracks' => [],
            'project_ref' => 'CE Program_',
            'trigger_populations' => ['street'],
            'trigger_probability' => 1.0,
            'days_before_trigger' => { 'distribution' => 'constant', 'value' => 0 },
            'close_conditions' => {
              'housing_move_in' => 0.5,
              'disengagement' => {
                'probability' => 0.5,
                'after_days' => { 'distribution' => 'constant', 'value' => 1 },
              },
            },
          }
        end
      end
      let(:lifecycle_config) { HmisSimulation::ConfigLoader.send(:normalize, base_config_with_lifecycle) }

      before do
        HmisSimulation::Bootstrapper.new(lifecycle_config).run!
      end

      it 'creates a CE LifecycleEnrollment when client enters a trigger population' do
        described_class.new(lifecycle_config).run(date: run_date)
        expect(HmisSimulation::LifecycleEnrollment.where(data_source_id: data_source.id, status: 'open').count).to be > 0
      end

      it 'does NOT create CE for populations not in trigger_populations' do
        config = lifecycle_config.deep_dup
        config['tracks'].find { |t| t['type'] == 'primary' }['populations'].each do |pop|
          pop['entry_point'] = pop['name'] == 'psh' ? 1 : 0
        end
        described_class.new(config).run(date: run_date)
        expect(HmisSimulation::LifecycleEnrollment.where(data_source_id: data_source.id).count).to eq(0)
      end

      it 'creates a CE HUD Enrollment linked to the CE project' do
        described_class.new(lifecycle_config).run(date: run_date)
        ce_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'CE Program_')
        ce_enrollments = Hmis::Hud::Enrollment.where(data_source: data_source, project_pk: ce_project.id)
        expect(ce_enrollments.count).to be > 0
      end

      it 'closes CE enrollment and emits a closing Event once MoveInDate is set on primary PH enrollment (housing_move_in condition)' do
        config = lifecycle_config.deep_dup
        config['tracks'].find { |t| t['name'] == 'coordinated_entry' }['close_conditions'] = { 'housing_move_in' => 1.0 }
        config['tracks'].find { |t| t['type'] == 'primary' }.tap do |track|
          track['transitions'] = [
            { 'from' => 'street', 'to' => 'psh', 'weight' => 1,
              'timing' => { 'distribution' => 'constant', 'value' => 1 },
              'gap_before_entry' => { 'distribution' => 'constant', 'value' => 0 },
              'exit_destinations' => { '435' => 1 } },
          ]
          track['enrollment_config']['ph_move_in'] = {
            'probability' => 1.0,
            'delay_days' => { 'distribution' => 'constant', 'value' => 0 },
          }
        end
        cfg = HmisSimulation::ConfigLoader.send(:normalize, config)
        HmisSimulation::Bootstrapper.new(cfg).run!
        engine_instance = described_class.new(cfg)

        engine_instance.run(date: run_date)
        engine_instance.run(date: run_date + 1)

        closed = HmisSimulation::LifecycleEnrollment.where(
          data_source_id: data_source.id, status: 'closed', close_reason: 'housing_move_in',
        )
        expect(closed.count).to be > 0

        # housing_move_in close → closing Event code 14 (PSH referral), ReferralResult 1 (successful)
        closing_events = Hmis::Hud::Event.where(data_source: data_source, Event: 14, ReferralResult: 1)
        expect(closing_events.count).to be > 0
      end

      it 'closes CE enrollment after disengagement timeout' do
        config = lifecycle_config.deep_dup
        config['tracks'].find { |t| t['name'] == 'coordinated_entry' }['close_conditions'] = {
          'disengagement' => {
            'probability' => 1.0,
            'after_days' => { 'distribution' => 'constant', 'value' => 1 },
          },
        }
        cfg = HmisSimulation::ConfigLoader.send(:normalize, config)
        HmisSimulation::Bootstrapper.new(cfg).run!
        engine_instance = described_class.new(cfg)

        engine_instance.run(date: run_date)
        engine_instance.run(date: run_date + 1)

        closed = HmisSimulation::LifecycleEnrollment.where(
          data_source_id: data_source.id, status: 'closed', close_reason: 'disengagement',
        )
        expect(closed.count).to be > 0
      end

      it 'creates an opening Event (code 3) for CE enrollments' do
        described_class.new(lifecycle_config).run(date: run_date)
        opening_events = Hmis::Hud::Event.where(data_source: data_source, Event: 3)
        expect(opening_events.count).to be > 0
      end

      it 'creates an Assessment for each CE enrollment' do
        described_class.new(lifecycle_config).run(date: run_date)
        ce_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'CE Program_')
        ce_enrollment_ids = Hmis::Hud::Enrollment.
          where(data_source: data_source, project_pk: ce_project.id).
          pluck(:EnrollmentID)

        assessments = Hmis::Hud::Assessment.where(data_source: data_source, EnrollmentID: ce_enrollment_ids)
        expect(assessments.count).to be > 0
      end

      it 'creates 3-5 AssessmentResults per Assessment' do
        described_class.new(lifecycle_config).run(date: run_date)
        Hmis::Hud::Assessment.where(data_source: data_source).each do |assessment|
          result_count = Hmis::Hud::AssessmentResult.where(
            data_source: data_source,
            AssessmentID: assessment.AssessmentID,
          ).count
          expect(result_count).to be_between(3, 5)
        end
      end
    end

    context 'tick_housing_move_in' do
      # Base config variant with 1-day ES→PSH transition and configurable ph_move_in.
      def psh_config_with_move_in(probability:, delay_days:)
        base_config.deep_dup.tap do |cfg|
          cfg['tracks'].find { |t| t['type'] == 'primary' }.tap do |track|
            track['transitions'] = [
              { 'from' => 'street', 'to' => 'psh', 'weight' => 1,
                'timing' => { 'distribution' => 'constant', 'value' => 1 },
                'gap_before_entry' => { 'distribution' => 'constant', 'value' => 0 },
                'exit_destinations' => { '435' => 1 } },
            ]
            track['enrollment_config']['ph_move_in'] = {
              'probability' => probability,
              'delay_days' => { 'distribution' => 'constant', 'value' => delay_days },
            }
          end
        end
      end

      it 'does not set MoveInDate before delay_days have passed' do
        cfg = HmisSimulation::ConfigLoader.send(:normalize, psh_config_with_move_in(probability: 1.0, delay_days: 5))
        HmisSimulation::Bootstrapper.new(cfg).run!
        engine_instance = described_class.new(cfg)

        # Day 0: clients spawn into ES. Day 1: clients exit ES, enter PSH (gap=0, same tick).
        # Days 2..5: delay_days=5 not yet reached (entry+5 > current date).
        engine_instance.run(date: run_date)
        engine_instance.run(date: run_date + 1)
        engine_instance.run(date: run_date + 2)

        psh_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test PSH_')
        psh_enrollments = Hmis::Hud::Enrollment.where(data_source: data_source, project_pk: psh_project.id)
        expect(psh_enrollments.where.not(MoveInDate: nil).count).to eq(0)
      end

      it 'sets MoveInDate on PH enrollments after delay_days have passed' do
        cfg = HmisSimulation::ConfigLoader.send(:normalize, psh_config_with_move_in(probability: 1.0, delay_days: 5))
        HmisSimulation::Bootstrapper.new(cfg).run!
        engine_instance = described_class.new(cfg)

        # Enter PSH on day 1 (entry_date = run_date + 1). Move-in fires when date >= entry + 5.
        7.times { |d| engine_instance.run(date: run_date + d) }

        psh_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test PSH_')
        psh_enrollments = Hmis::Hud::Enrollment.where(data_source: data_source, project_pk: psh_project.id)
        expect(psh_enrollments.where.not(MoveInDate: nil).count).to be > 0
      end

      it 'sets MoveInDate to entry_date + delay_days, not the tick date' do
        cfg = HmisSimulation::ConfigLoader.send(:normalize, psh_config_with_move_in(probability: 1.0, delay_days: 5))
        HmisSimulation::Bootstrapper.new(cfg).run!
        engine_instance = described_class.new(cfg)

        7.times { |d| engine_instance.run(date: run_date + d) }

        psh_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test PSH_')
        Hmis::Hud::Enrollment.
          where(data_source: data_source, project_pk: psh_project.id).
          where.not(MoveInDate: nil).
          each do |enrollment|
            expect(enrollment.MoveInDate).to eq(enrollment.EntryDate + 5)
          end
      end

      it 'never sets MoveInDate when ph_move_in probability is 0' do
        cfg = HmisSimulation::ConfigLoader.send(:normalize, psh_config_with_move_in(probability: 0.0, delay_days: 1))
        HmisSimulation::Bootstrapper.new(cfg).run!
        engine_instance = described_class.new(cfg)

        10.times { |d| engine_instance.run(date: run_date + d) }

        psh_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test PSH_')
        psh_enrollments = Hmis::Hud::Enrollment.where(data_source: data_source, project_pk: psh_project.id)
        expect(psh_enrollments.where.not(MoveInDate: nil).count).to eq(0)
      end

      it 'does not set MoveInDate again on enrollments that already have one' do
        cfg = HmisSimulation::ConfigLoader.send(:normalize, psh_config_with_move_in(probability: 1.0, delay_days: 1))
        HmisSimulation::Bootstrapper.new(cfg).run!
        engine_instance = described_class.new(cfg)

        5.times { |d| engine_instance.run(date: run_date + d) }

        psh_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test PSH_')
        move_in_dates = Hmis::Hud::Enrollment.
          where(data_source: data_source, project_pk: psh_project.id).
          where.not(MoveInDate: nil).
          pluck(:id, :MoveInDate).
          to_h

        # Run more ticks — MoveInDate should remain unchanged.
        5.times { |d| engine_instance.run(date: run_date + 5 + d) }

        move_in_dates.each do |enrollment_id, original_date|
          current = Hmis::Hud::Enrollment.find(enrollment_id).MoveInDate
          expect(current).to eq(original_date)
        end
      end
    end

    context 'annual collection' do
      it 'creates annual IncomeBenefit records for enrollments near their anniversary' do
        old_entry = run_date - 365
        hoh = create(:hmis_hud_client, data_source: data_source)
        project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test ES_')
        enrollment = create(
          :hmis_hud_enrollment,
          data_source: data_source, client: hoh, project: project,
          EntryDate: old_entry
        )

        zero_jitter_config = base_config.deep_dup
        zero_jitter_config['tracks'].find { |t| t['type'] == 'primary' }.tap do |track|
          track['enrollment_config'] ||= {}
          track['enrollment_config']['annual_collection'] = {
            'miss_rate' => 0.0,
            'timing_jitter' => { 'distribution' => 'constant', 'value' => 0 },
          }
        end
        cfg = HmisSimulation::ConfigLoader.send(:normalize, zero_jitter_config)
        described_class.new(cfg).run(date: run_date)

        annual = Hmis::Hud::IncomeBenefit.where(
          data_source: data_source,
          EnrollmentID: enrollment.EnrollmentID,
          DataCollectionStage: 5,
        )
        expect(annual.count).to eq(1)
      end

      # Regression: with ceil(), days_enrolled=375, year_number=ceil(375/365)=2,
      # and the annual for year 1 is never fired.
      it 'fires year-1 annual when positive jitter pushes expected date past day 365' do
        # entry 375 days before run_date; jitter=+10 → expected = entry + 365 + 10 = run_date
        entry_date = run_date - 375
        hoh = create(:hmis_hud_client, data_source: data_source)
        project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Test ES_')
        enrollment = create(
          :hmis_hud_enrollment,
          data_source: data_source, client: hoh, project: project,
          EntryDate: entry_date
        )

        cfg = base_config.deep_dup
        cfg['tracks'].find { |t| t['type'] == 'primary' }.tap do |track|
          track['enrollment_config'] ||= {}
          track['enrollment_config']['annual_collection'] = {
            'miss_rate' => 0.0,
            'timing_jitter' => { 'distribution' => 'constant', 'value' => 10 },
          }
        end
        described_class.new(HmisSimulation::ConfigLoader.send(:normalize, cfg)).run(date: run_date)

        annual = Hmis::Hud::IncomeBenefit.where(
          data_source: data_source,
          EnrollmentID: enrollment.EnrollmentID,
          DataCollectionStage: 5,
        )
        expect(annual.count).to eq(1)
      end
    end

    context 'RunLog behavior' do
      it 'retries a previously-failed date without raising RecordNotUnique' do
        # Simulate a prior failed run that left an errored RunLog
        HmisSimulation::RunLog.create!(
          data_source_id: data_source.id,
          run_date: run_date,
          started_at: 1.hour.ago,
          finished_at: 1.hour.ago,
          error_message: 'Previous failure',
        )

        expect { engine.run(date: run_date) }.not_to raise_error

        log = HmisSimulation::RunLog.find_by(data_source_id: data_source.id, run_date: run_date)
        expect(log.error_message).to be_nil
        expect(log.finished_at).to be_present
      end

      describe 'RunLog.successful scope' do
        it 'excludes in-progress logs (nil finished_at)' do
          log = HmisSimulation::RunLog.create!(
            data_source_id: data_source.id,
            run_date: run_date + 200,
            started_at: Time.current,
            clients_created: 0,
          )
          expect(HmisSimulation::RunLog.successful.pluck(:id)).not_to include(log.id)
        end

        it 'includes completed successful logs' do
          log = HmisSimulation::RunLog.create!(
            data_source_id: data_source.id,
            run_date: run_date + 200,
            started_at: Time.current,
            finished_at: Time.current,
            clients_created: 0,
          )
          expect(HmisSimulation::RunLog.successful.pluck(:id)).to include(log.id)
        end

        it 'excludes logs with error_message even when finished_at is set' do
          log = HmisSimulation::RunLog.create!(
            data_source_id: data_source.id,
            run_date: run_date + 200,
            started_at: Time.current,
            finished_at: Time.current,
            error_message: 'failed',
            clients_created: 0,
          )
          expect(HmisSimulation::RunLog.successful.pluck(:id)).not_to include(log.id)
        end
      end
    end

    context 'when a sim_client has an orphaned hud_enrollment_id' do
      it 'does not raise when processing an exit for a deleted enrollment' do
        engine.run(date: run_date)

        sim_client_with_enrollment = HmisSimulation::Client.
          where(data_source_id: data_source.id).
          find { |c| c.hud_enrollment_id && c.next_transition_on }
        skip 'no enrolled sim_client with transition found' unless sim_client_with_enrollment

        # Orphan the enrollment by deleting it directly
        Hmis::Hud::Enrollment.where(id: sim_client_with_enrollment.hud_enrollment_id).delete_all
        sim_client_with_enrollment.update!(next_transition_on: run_date + 1)

        expect { engine.run(date: run_date + 1) }.not_to raise_error
      end
    end

    context 'when sim_client has nil next_population at exit (defensive re-sample path)' do
      it 'logs a warning and re-samples the transition without raising' do
        engine.run(date: run_date)

        sim_client = HmisSimulation::Client.where(data_source_id: data_source.id).
          find { |c| c.hud_enrollment_id.present? && c.next_transition_on.present? }
        skip 'no enrolled sim_client with transition found' unless sim_client

        sim_client.update!(next_population: nil, next_transition_on: run_date + 1)

        # Force the transition branch rather than the system-exit branch by stubbing the
        # real seam. process_primary_exit branches on Schedule#exit_point?; the engine has
        # no #roll_exit_point, so the previous stub was a silent no-op and the branch was
        # actually decided by the seeded RNG.
        allow(engine.instance_variable_get(:@schedule)).to receive(:exit_point?).and_return(false)

        expect { engine.run(date: run_date + 1) }.not_to raise_error

        sim_client.reload
        expect(sim_client.current_population).to eq('psh')
      end
    end

    context 'when LifecycleEnrollment has nil hud_enrollment_id' do
      it 'marks the record closed without raising' do
        hud_client = create(:hmis_hud_client, data_source: data_source)
        lifecycle_enrollment = HmisSimulation::LifecycleEnrollment.create!(
          data_source_id: data_source.id,
          hud_client_id: hud_client.id,
          hud_enrollment_id: nil,
          lifecycle_name: 'coordinated_entry',
          status: 'open',
          opens_on: run_date,
        )

        expect do
          engine.send(
            :close_lifecycle_enrollment,
            lifecycle_enrollment,
            run_date,
            reason: 'disengagement',
          )
        end.not_to raise_error

        lifecycle_enrollment.reload
        expect(lifecycle_enrollment.status).to eq('closed')
        expect(lifecycle_enrollment.close_reason).to eq('disengagement')
      end
    end

    context 'household_cohesion_probability: 0 is respected, not overridden to 0.85' do
      it 'never includes household members when cohesion is explicitly set to 0' do
        hoh = create(:hmis_hud_client, data_source: data_source)
        member = create(:hmis_hud_client, data_source: data_source)
        group = HmisSimulation::HouseholdGroup.create!(
          data_source_id: data_source.id,
          hoh_client_id: hoh.id,
          member_relationships: [{ 'hud_client_id' => member.id, 'relationship_to_hoh' => 2 }],
          household_template_name: 'adult_and_child',
        )

        zero_cohesion_config = base_config.deep_dup.tap do |cfg|
          cfg['tracks'].first['household_cohesion_probability'] = 0
        end
        cfg = HmisSimulation::ConfigLoader.send(:normalize, zero_cohesion_config)
        engine_instance = described_class.new(cfg)

        HmisSimulation::Client.create!(
          data_source_id: data_source.id,
          hud_client_id: hoh.id,
          household_group_id: group.id,
          current_population: 'street',
          entered_current_population_at: run_date,
          pending_enrollment_on: run_date,
          track_name: 'general',
          exited_system: false,
        )

        engine_instance.run(date: run_date)

        member_enrollments = Hmis::Hud::Enrollment.where(
          data_source: data_source,
          PersonalID: member.PersonalID,
        )
        expect(member_enrollments.count).to eq(0)
      end
    end
  end
end
