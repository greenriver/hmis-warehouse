###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Integration tests that exercise the full simulation lifecycle:
#   bootstrap → multi-day run → verify all record types
#
# These tests are slower than unit specs (~2-3s per simulated day) but
# provide end-to-end confidence that the engine produces valid HMIS data.
RSpec.describe 'HmisSimulation end-to-end', :integration do
  let!(:data_source) { create(:hmis_data_source) }
  let(:start_date)   { Date.new(2026, 1, 1) }
  let(:end_date)     { Date.new(2026, 1, 14) }

  let(:full_config) do
    {
      'name' => 'Integration Test CoC',
      'data_source_id' => data_source.id,
      'seed' => 55,
      'coc_codes' => { 'primary' => 'XX-500' },
      'organizations' => [
        {
          'name' => 'Integration Org_',
          'projects' => [
            { 'name' => 'Integration ES NBN_', 'project_type' => 1, 'capacity' => 50 },
            { 'name' => 'Integration PSH_',    'project_type' => 3, 'capacity' => 20 },
            { 'name' => 'Integration SO_',     'project_type' => 4 },
            { 'name' => 'Integration CE_',     'project_type' => 14 },
          ],
        },
      ],
      'data_quality' => {
        'missing_dob_rate' => 0.02,
        'missing_ssn_rate' => 0.05,
        'missing_name_rate' => 0.01,
        'approximate_dob_rate' => 0.02,
      },
      'tracks' => [
        {
          'name' => 'general_population',
          'type' => 'primary',
          'new_clients_per_month' => { 'distribution' => 'poisson', 'lambda' => 60 },
          'household_cohesion_probability' => 0.9,
          'household_templates' => {
            'adult_only' => {
              'hoh' => {
                'age' => { 'distribution' => 'uniform', 'min' => 25, 'max' => 55 },
                'gender' => { 'woman' => 0.5, 'man' => 0.5 },
                'veteran_probability' => 0.1,
                'race' => { 'white' => 0.5, 'black_af_american' => 0.5 },
              },
            },
          },
          'populations' => [
            { 'name' => 'street', 'label' => 'Street',
              'project_ref' => 'Integration SO_',
              'household_templates' => { 'adult_only' => 1 },
              'entry_point' => 1, 'exit_point' => 0.05 },
            { 'name' => 'es', 'label' => 'ES',
              'project_ref' => 'Integration ES NBN_',
              'household_templates' => { 'adult_only' => 1 },
              'entry_point' => 0, 'exit_point' => 0.05 },
            { 'name' => 'psh', 'label' => 'PSH',
              'project_ref' => 'Integration PSH_',
              'household_templates' => { 'adult_only' => 1 },
              'entry_point' => 0, 'exit_point' => 0.5 },
          ],
          'transitions' => [
            { 'from' => 'street', 'to' => 'es', 'weight' => 1,
              'timing' => { 'distribution' => 'uniform', 'min' => 2, 'max' => 5 },
              'gap_before_entry' => { 'distribution' => 'constant', 'value' => 0 },
              'exit_destinations' => { '101' => 1 } },
            { 'from' => 'es', 'to' => 'psh', 'weight' => 1,
              'timing' => { 'distribution' => 'uniform', 'min' => 3, 'max' => 7 },
              'gap_before_entry' => { 'distribution' => 'constant', 'value' => 0 },
              'exit_destinations' => { '435' => 1 } },
          ],
          'enrollment_config' => {
            'disabilities' => {
              'disabling_condition_probability' => 0.7,
              'types' => { 'mental_health' => 0.6, 'substance_use' => 0.4 },
            },
            'income_at_entry' => {
              'no_income_probability' => 0.35,
              'sources' => { 'ssi' => 0.4, 'earned' => 0.3, 'ga' => 0.3 },
            },
            'health_and_dv' => {
              'dv_survivor_probability' => 0.2,
              'general_health' => { 'poor' => 0.3, 'fair' => 0.4, 'good' => 0.3 },
            },
            'annual_collection' => {
              'miss_rate' => 0.0,
              'timing_jitter' => { 'distribution' => 'constant', 'value' => 0 },
            },
          },
        },
        {
          'name' => 'so_contacts',
          'type' => 'concurrent',
          'applies_to_tracks' => [],
          'projects' => ['Integration SO_'],
          'count_distribution' => { '0' => 3, '1' => 1 },
          'data_error_rate' => 0.0,
          'duration' => { 'distribution' => 'constant', 'value' => 5 },
          'reentry' => {
            'gap' => { 'distribution' => 'constant', 'value' => 2 },
            'probability' => 0.5,
          },
        },
        {
          'name' => 'coordinated_entry',
          'type' => 'lifecycle',
          'applies_to_tracks' => [],
          'project_ref' => 'Integration CE_',
          'trigger_populations' => ['street', 'es'],
          'trigger_probability' => 0.5,
          'days_before_trigger' => { 'distribution' => 'constant', 'value' => 0 },
          'close_conditions' => {
            'housing_move_in' => 0.7,
            'disengagement' => {
              'probability' => 0.3,
              'after_days' => { 'distribution' => 'constant', 'value' => 30 },
            },
          },
        },
      ],
    }
  end

  let(:config) { HmisSimulation::ConfigLoader.send(:normalize, full_config) }

  before do
    User.setup_system_user
    HmisSimulation::Bootstrapper.new(config).run!
  end

  def ds_scope(klass)
    klass.where(data_source_id: data_source.id)
  end

  def run_engine(days)
    engine = HmisSimulation::Engine.new(config)
    days.each { |d| engine.run(date: d) }
    engine
  end

  # -----------------------------------------------------------------------
  # End-to-end: 14 days produces all expected record types
  # -----------------------------------------------------------------------
  describe '14-day run' do
    before { run_engine(start_date..end_date) }

    it 'creates HmisSimulation::Client state records' do
      expect(HmisSimulation::Client.where(data_source_id: data_source.id).count).to be > 0
    end

    it 'creates RunLog entries for all 14 days' do
      logs = HmisSimulation::RunLog.where(data_source_id: data_source.id)
      expect(logs.count).to eq(14)
      expect(logs.where(error_message: nil).count).to eq(14)
    end

    it 'creates Hmis::Hud::Client records with FAKE PersonalIDs' do
      clients = ds_scope(Hmis::Hud::Client)
      expect(clients.count).to be > 0
      expect(clients.pluck(:PersonalID)).to all(start_with('FAKE'))
    end

    it 'creates Client records with 999-prefixed SSNs (or nil for missing)' do
      clients = ds_scope(Hmis::Hud::Client).where.not(SSN: nil)
      expect(clients.pluck(:SSN)).to all(start_with('999'))
    end

    it 'creates Hmis::Hud::Enrollment records' do
      expect(ds_scope(Hmis::Hud::Enrollment).count).to be > 0
    end

    it 'creates Hmis::Hud::Exit records as clients transition' do
      expect(ds_scope(Hmis::Hud::Exit).count).to be > 0
    end

    it 'creates bed-night Service records for NBN enrollments' do
      expect(ds_scope(Hmis::Hud::Service).where(RecordType: 200).count).to be > 0
    end

    it 'creates Disability records at enrollment entry' do
      expect(ds_scope(Hmis::Hud::Disability).count).to be > 0
    end

    it 'creates IncomeBenefit records at enrollment entry' do
      expect(ds_scope(Hmis::Hud::IncomeBenefit).where(DataCollectionStage: 1).count).to be > 0
    end

    it 'creates HealthAndDv records at enrollment entry' do
      expect(ds_scope(Hmis::Hud::HealthAndDv).count).to be > 0
    end

    it 'creates CustomClientName records for all clients' do
      client_count = ds_scope(Hmis::Hud::Client).count
      name_count   = Hmis::Hud::CustomClientName.where(data_source_id: data_source.id).count
      expect(name_count).to eq(client_count)
    end

    it 'updates DisablingCondition on enrollments (not stuck at 99)' do
      updated = ds_scope(Hmis::Hud::Enrollment).where(RelationshipToHoH: 1).where.not(DisablingCondition: 99)
      expect(updated.count).to be > 0
    end

    it 'only produces enrollments with fake identifiers' do
      personal_ids = ds_scope(Hmis::Hud::Enrollment).pluck(:PersonalID)
      expect(personal_ids).to all(start_with('FAKE'))
    end

    it 'produces CE lifecycle enrollments for trigger population clients' do
      ce_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Integration CE_')
      expect(ds_scope(Hmis::Hud::Enrollment).where(project_pk: ce_project.id).count).to be > 0
    end

    it 'produces HmisSimulation::HouseholdGroup records' do
      expect(HmisSimulation::HouseholdGroup.where(data_source_id: data_source.id).count).to be > 0
    end
  end

  # -----------------------------------------------------------------------
  # Idempotency: re-running the same date range produces no new records
  # -----------------------------------------------------------------------
  describe 'idempotency' do
    it 're-running the same 14 days creates no duplicate records' do
      run_engine(start_date..end_date)

      snapshot = {
        clients: HmisSimulation::Client.where(data_source_id: data_source.id).count,
        enrollments: ds_scope(Hmis::Hud::Enrollment).count,
        exits: ds_scope(Hmis::Hud::Exit).count,
        run_logs: HmisSimulation::RunLog.where(data_source_id: data_source.id).count,
      }

      run_engine(start_date..end_date)

      expect(HmisSimulation::Client.where(data_source_id: data_source.id).count).to eq(snapshot[:clients])
      expect(ds_scope(Hmis::Hud::Enrollment).count).to eq(snapshot[:enrollments])
      expect(ds_scope(Hmis::Hud::Exit).count).to eq(snapshot[:exits])
      expect(HmisSimulation::RunLog.where(data_source_id: data_source.id).count).to eq(snapshot[:run_logs])
    end
  end

  # -----------------------------------------------------------------------
  # Resumability: days 1-7 then 8-14 = same RunLog as days 1-14 in one shot
  # -----------------------------------------------------------------------
  describe 'resumability' do
    let(:mid_date) { Date.new(2026, 1, 7) }

    it 'produces 14 successful RunLog entries when run in two 7-day chunks' do
      run_engine(start_date..mid_date)
      run_engine((mid_date + 1)..end_date)

      logs = HmisSimulation::RunLog.where(data_source_id: data_source.id)
      expect(logs.count).to eq(14)
      expect(logs.where(error_message: nil).count).to eq(14)
    end

    it 'accumulates clients across chunks — more after second chunk' do
      run_engine(start_date..mid_date)
      count_after_first_half = HmisSimulation::Client.where(data_source_id: data_source.id).count

      run_engine((mid_date + 1)..end_date)
      count_after_second_half = HmisSimulation::Client.where(data_source_id: data_source.id).count

      expect(count_after_second_half).to be > count_after_first_half
    end

    it 'has no RunLog gaps — all dates from start to end are present' do
      run_engine(start_date..mid_date)
      run_engine((mid_date + 1)..end_date)

      run_dates = HmisSimulation::RunLog.
        where(data_source_id: data_source.id).
        pluck(:run_date).
        sort

      expected = (start_date..end_date).to_a
      expect(run_dates).to eq(expected)
    end
  end

  # -----------------------------------------------------------------------
  # Determinism: same seed + same date produces same daily client count
  # -----------------------------------------------------------------------
  describe 'daily client count determinism' do
    it 'produces the same number of new clients on a given day for the same seed' do
      # Run day 1 on data_source
      run_engine([start_date])
      count_a = HmisSimulation::Client.where(data_source_id: data_source.id).count

      # Reset state and run day 1 on a fresh data source with same seed
      ds2 = create(:hmis_data_source)
      User.setup_system_user
      config2 = HmisSimulation::ConfigLoader.send(:normalize, full_config.merge('data_source_id' => ds2.id))
      HmisSimulation::Bootstrapper.new(config2).run!
      HmisSimulation::Engine.new(config2).run(date: start_date)
      count_b = HmisSimulation::Client.where(data_source_id: ds2.id).count

      expect(count_a).to eq(count_b)
    end

    it 'produces the same FirstName for clients spawned with the same seed + context' do
      run_engine([start_date])
      ds2 = create(:hmis_data_source)
      User.setup_system_user
      config2 = HmisSimulation::ConfigLoader.send(:normalize, full_config.merge('data_source_id' => ds2.id))
      HmisSimulation::Bootstrapper.new(config2).run!
      HmisSimulation::Engine.new(config2).run(date: start_date)

      names_a = Hmis::Hud::Client.where(data_source: data_source).pluck(:FirstName).compact.sort
      names_b = Hmis::Hud::Client.where(data_source: ds2).pluck(:FirstName).compact.sort

      expect(names_a).to eq(names_b)
    end
  end

  # -----------------------------------------------------------------------
  # Compliance: 30-day run satisfies HUD spec requirements
  # -----------------------------------------------------------------------
  describe '30-day compliance run' do
    let(:compliance_start) { Date.new(2026, 2, 1) }
    let(:compliance_end)   { Date.new(2026, 3, 2) }

    before { run_engine(compliance_start..compliance_end) }

    it 'creates HmisParticipation for every project' do
      project_count       = ds_scope(Hmis::Hud::Project).count
      participation_count = ds_scope(Hmis::Hud::HmisParticipation).count
      expect(participation_count).to eq(project_count)
    end

    it 'creates CeParticipation for the CE project' do
      ce_projects = ds_scope(Hmis::Hud::Project).where(ProjectType: 14)
      ce_participation_count = ds_scope(Hmis::Hud::CeParticipation).count
      expect(ce_participation_count).to eq(ce_projects.count)
    end

    it 'sets LivingSituation to a non-nil value on all enrollments' do
      missing = ds_scope(Hmis::Hud::Enrollment).where(LivingSituation: nil)
      expect(missing.count).to eq(0)
    end

    it 'sets DateOfEngagement on all SO project enrollments' do
      so_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Integration SO_')
      so_enrollments = ds_scope(Hmis::Hud::Enrollment).where(project_pk: so_project.id)
      missing_engagement = so_enrollments.where(DateOfEngagement: nil)
      expect(missing_engagement.count).to eq(0)
    end

    it 'creates EmploymentEducation for residential project enrollments' do
      expect(ds_scope(Hmis::Hud::EmploymentEducation).count).to be > 0
    end

    it 'creates EmploymentEducation only for residential project types' do
      non_residential_pks = ds_scope(Hmis::Hud::Project).
        where(ProjectType: [4, 6, 7, 11, 12, 14]).
        pluck(:id)
      non_residential_enrollment_ids = ds_scope(Hmis::Hud::Enrollment).
        where(project_pk: non_residential_pks).
        pluck(:EnrollmentID)

      if non_residential_enrollment_ids.any?
        ee_for_non_residential = ds_scope(Hmis::Hud::EmploymentEducation).
          where(EnrollmentID: non_residential_enrollment_ids)
        expect(ee_for_non_residential.count).to eq(0)
      end
    end

    it 'creates Assessment records for CE enrollments' do
      ce_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Integration CE_')
      ce_enrollment_ids = ds_scope(Hmis::Hud::Enrollment).
        where(project_pk: ce_project.id).
        pluck(:EnrollmentID)

      expect(ds_scope(Hmis::Hud::Assessment).where(EnrollmentID: ce_enrollment_ids).count).to be > 0 if ce_enrollment_ids.any?
    end

    it 'creates Event records for CE enrollments' do
      ce_project = Hmis::Hud::Project.find_by(data_source: data_source, ProjectName: 'Integration CE_')
      ce_enrollment_ids = ds_scope(Hmis::Hud::Enrollment).
        where(project_pk: ce_project.id).
        pluck(:EnrollmentID)

      expect(ds_scope(Hmis::Hud::Event).where(EnrollmentID: ce_enrollment_ids).count).to be > 0 if ce_enrollment_ids.any?
    end

    it 'reports zero ComplianceValidator violations' do
      validator  = HmisSimulation::ComplianceValidator.new(data_source_id: data_source.id)
      violations = validator.validate!
      expect(violations).to be_empty, "Expected 0 violations, got #{violations.size}:\n" \
        "#{violations.map { |v| "  #{v[:type]}: #{v[:message]}" }.first(10).join("\n")}"
    end
  end

  # -----------------------------------------------------------------------
  # Warehouse sync: IdentifyDuplicates creates WarehouseClient records
  # -----------------------------------------------------------------------
  describe 'warehouse sync' do
    # IdentifyDuplicates requires a destination data source (source_type: nil,
    # authoritative: false) to create destination clients and WarehouseClient links.
    let!(:destination_data_source) { create(:destination_data_source) }

    before { run_engine(start_date..end_date) }

    it 'links simulated clients to warehouse destination records via IdentifyDuplicates' do
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      source_client_ids = Hmis::Hud::Client.where(data_source_id: data_source.id).pluck(:id)
      expect(GrdaWarehouse::WarehouseClient.where(source_id: source_client_ids).count).to be > 0
    end

    # batch_process_unprocessed! enqueues service history via Delayed::Worker, which
    # opens a new DB connection and cannot see uncommitted test-transaction data.
    # The full ServiceHistoryEnrollment pipeline is verified manually or in a
    # non-transactional integration environment.
    it 'ServiceHistoryEnrollment assertions require non-transactional test setup' do
      skip 'batch_process_unprocessed! uses a new DB connection — cannot see transactional test data'
    end
  end

  # -----------------------------------------------------------------------
  # Config validation: sample config passes validator
  # -----------------------------------------------------------------------
  describe 'sample config validity' do
    it 'validates the small_coc.json sample without errors' do
      raw = HmisSimulation::ConfigLoader.from_file(
        Rails.root.join('drivers', 'hmis_simulation', 'config', 'sample', 'small_coc.json').to_s,
      )
      # Override data_source_id for validation (sample has 0 which is intentionally invalid)
      raw['data_source_id'] = data_source.id
      validator = HmisSimulation::ConfigValidator.new(raw)
      expect(validator).to be_valid, validator.errors.join("\n")
    end
  end
end
