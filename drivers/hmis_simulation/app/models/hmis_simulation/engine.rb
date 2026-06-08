###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Drives the simulation forward one calendar day at a time.
  #
  # Each call to #run(date:) processes exactly one simulated day:
  #   1. Spawn new clients (looped over all primary tracks)
  #   2. Process primary enrollment exits and entries (per primary track)
  #   3. Periodic CLS records (SO: every ~30 days; CE: every ~90 days)
  #   4. Annual record collection (IncomeBenefits, per client's track config)
  #   5. Concurrent enrollment tick (looped over all concurrent tracks)
  #   6. Lifecycle enrollment tick (looped over all lifecycle tracks)
  #   7. Write RunLog
  #
  # Idempotent: re-running the same date is a no-op (detected via RunLog).
  # Recoverable: a previously failed date's RunLog is overwritten on retry.
  #
  # Usage:
  #   config = HmisSimulation::ConfigLoader.from_app_config('hmis_simulation/demo-coc')
  #   engine = HmisSimulation::Engine.new(config)
  #   engine.run(date: Date.current)
  class Engine
    include HmisSimulation::Hashing

    def initialize(config)
      @config = config.deep_stringify_keys
      @data_source_id = @config['data_source_id'].to_i
      @seed = @config['seed'].to_i
    end

    def run(date:)
      return if already_run?(date)

      log = RunLog.find_or_initialize_by(
        data_source_id: @data_source_id,
        run_date: date,
      )
      log.assign_attributes(
        started_at: Time.current,
        clients_created: 0,
        error_message: nil,
        finished_at: nil,
      )
      log.save!

      begin
        Hmis::Hud::Base.transaction do
          @clients_created     = 0
          @enrollments_opened  = 0
          @enrollments_closed  = 0
          @services_created    = 0

          spawn_clients(date: date)
          tick_primary(date: date)
          tick_cls_records(date: date)
          tick_annual_collections(date: date)
          tick_concurrent(date: date)
          tick_lifecycle(date: date)
        end

        log.update!(
          clients_created: @clients_created,
          enrollments_opened: @enrollments_opened,
          enrollments_closed: @enrollments_closed,
          services_created: @services_created,
          finished_at: Time.current,
        )
      rescue StandardError => e
        log.update!(error_message: e.message, finished_at: Time.current)
        raise
      end
    end

    private

    def already_run?(date)
      RunLog.where(data_source_id: @data_source_id, run_date: date, error_message: nil).
        where.not(finished_at: nil).
        exists?
    end

    # -- Memoized infrastructure --

    def data_source
      @data_source ||= GrdaWarehouse::DataSource.find(@data_source_id)
    end

    def current_user_id
      @current_user_id ||= Hmis::Hud::User.system_user(data_source_id: @data_source_id).user_id
    end

    def primary_coc_code
      @primary_coc_code ||= @config.dig('coc_codes', 'primary') || 'XX-500'
    end

    # -- Track helpers --

    def primary_tracks
      @primary_tracks ||= (@config['tracks'] || []).select { |t| t['type'] == 'primary' }
    end

    def secondary_tracks_of_type(type)
      (@config['tracks'] || []).select { |t| t['type'] == type }
    end

    def secondary_tracks_for_client(type, sim_client)
      secondary_tracks_of_type(type).select do |track|
        track['applies_to_tracks'].blank? ||
          track['applies_to_tracks'].include?(sim_client.track_name)
      end
    end

    def track_for_population(population_name)
      primary_tracks.find do |track|
        (track['populations'] || []).any? { |p| p['name'] == population_name }
      end
    end

    def find_population(name)
      primary_tracks.flat_map { |t| t['populations'] || [] }.find { |p| p['name'] == name }
    end

    def enrollment_config_for(sim_client)
      track = primary_tracks.find { |t| t['name'] == sim_client.track_name }
      track&.fetch('enrollment_config', {}) || {}
    end

    # -- Spawn --

    def spawn_clients(date:)
      primary_tracks.each do |track|
        spawn_clients_for_track(track, date: date, data_source: data_source, user_id: current_user_id)
      end
    end

    def spawn_clients_for_track(track, date:, data_source:, user_id:)
      count = daily_new_client_count_for_track(track, date: date)

      count.times do |i|
        population = draw_entry_population_for_track(track, date: date, index: i)
        next unless population

        template_name = draw_household_template(population: population, date: date, index: i)
        template_cfg  = track.dig('household_templates', template_name) || {}
        data_quality  = data_quality_for_track(track)

        result = Builders::HouseholdBuilder.new(
          household_template: template_cfg,
          household_template_name: template_name,
          data_quality_config: data_quality,
          data_source: data_source,
          user_id: user_id,
          date: date,
          seed: @seed,
          context_prefix: "spawn:#{track['name']}:#{date}:#{i}",
        ).build!

        Client.create!(
          data_source_id: @data_source_id,
          hud_client_id: result[:hoh_id],
          household_group_id: result[:household_group_id],
          current_population: population['name'],
          entered_current_population_at: date,
          pending_enrollment_on: date,
          track_name: track['name'],
          exited_system: false,
        )

        @clients_created += 1
      end
    end

    def data_quality_for_track(track)
      global_dq = @config['data_quality'] || {}
      global_dq.deep_merge(track.fetch('data_quality', {}) || {})
    end

    # -- Primary enrollment tick --

    def tick_primary(date:)
      Client.pending_exit(date).where(data_source_id: @data_source_id).find_each do |sim_client|
        process_primary_exit(sim_client, date, data_source: data_source, user_id: current_user_id)
      end

      Client.pending_enrollment(date).where(data_source_id: @data_source_id).find_each do |sim_client|
        process_primary_entry(sim_client, date, data_source: data_source, user_id: current_user_id)
      end

      create_bed_nights(date, data_source: data_source, user_id: current_user_id)
    end

    def process_primary_exit(sim_client, date, data_source:, user_id:)
      enrollment = Hmis::Hud::Enrollment.find_by(id: sim_client.hud_enrollment_id)
      return unless enrollment

      transition = find_transition(sim_client.current_population, sim_client.next_population)
      exit_dests = transition&.dig('exit_destinations') || { '17' => 1.0 }

      Builders::ExitBuilder.new(
        enrollment: enrollment,
        exit_date: date,
        exit_destinations: exit_dests,
        data_source: data_source,
        user_id: user_id,
        seed: @seed,
        context_prefix: "exit:#{date}:#{sim_client.id}",
      ).build!
      create_linked_exit_records(enrollment, date, data_source: data_source, user_id: user_id, sim_client: sim_client)

      @enrollments_closed += 1

      population_cfg = find_population(sim_client.current_population)
      if roll_exit_point(population_cfg, sim_client)
        sim_client.update!(
          exited_system: true,
          hud_enrollment_id: nil,
          next_transition_on: nil,
          next_population: nil,
        )
      else
        next_pop_name = sim_client.next_population
        if next_pop_name.nil?
          Rails.logger.warn { "HmisSimulation: nil next_population for sim_client #{sim_client.id} at exit; re-sampling transition" }
          next_pop_name, _timing = sample_enrollment_exit(sim_client.current_population, date, sim_client.id)
          transition = find_transition(sim_client.current_population, next_pop_name)
        end
        gap = sample_gap(transition, date, sim_client.id)
        sim_client.update!(
          current_population: next_pop_name,
          entered_current_population_at: date,
          hud_enrollment_id: nil,
          next_transition_on: nil,
          next_population: nil,
          pending_enrollment_on: date + gap,
        )
      end
    end

    def process_primary_entry(sim_client, date, data_source:, user_id:)
      population_cfg = find_population(sim_client.current_population)
      return unless population_cfg

      project_ref = population_cfg['project_ref']
      project = find_project_by_ref(project_ref, data_source: data_source)
      return unless project

      hoh_client = Hmis::Hud::Client.find_by(id: sim_client.hud_client_id)
      return unless hoh_client

      household_group = (HouseholdGroup.find_by(id: sim_client.household_group_id) if sim_client.household_group_id.present?)
      members = household_group&.member_client_ids || []

      track = primary_tracks.find { |t| t['name'] == sim_client.track_name }
      cohesion = track&.fetch('household_cohesion_probability', nil)
      cohesion ||= 0.85
      cohesion = cohesion.to_f

      hud_household_id = FakeIdentifier.uuid
      result = Builders::EnrollmentBuilder.new(
        project: project,
        hud_household_id: hud_household_id,
        entry_date: date,
        coc_code: primary_coc_code,
        hoh_client: hoh_client,
        member_relationships: members,
        household_cohesion_probability: cohesion,
        population_config: population_cfg,
        data_source: data_source,
        user_id: user_id,
        rng_seed: @seed + stable_hash("entry:#{date}:#{sim_client.id}"),
      ).build!

      @enrollments_opened += 1
      create_entry_records(result[:hoh_enrollment], date, data_source: data_source, user_id: user_id, sim_client: sim_client)
      assign_concurrent_enrollments(sim_client, date, data_source: data_source, user_id: user_id)
      trigger_lifecycle_enrollments(sim_client, date, data_source: data_source, user_id: user_id)

      next_pop, timing = sample_enrollment_exit(sim_client.current_population, date, sim_client.id)

      sim_client.update!(
        hud_enrollment_id: result[:hoh_enrollment].id,
        pending_enrollment_on: nil,
        next_transition_on: date + timing,
        next_population: next_pop,
      )
    end

    def create_bed_nights(date, data_source:, user_id:)
      nbn_project_pks = Hmis::Hud::Project.
        where(data_source_id: @data_source_id, ProjectType: 1).
        pluck(:id)
      return if nbn_project_pks.empty?

      active_nbn_enrollments = Hmis::Hud::Enrollment.
        where(data_source_id: @data_source_id, project_pk: nbn_project_pks).
        open_on_date(date)

      active_nbn_enrollments.find_each do |enrollment|
        Builders::ServiceBuilder.new(
          enrollment: enrollment,
          date: date,
          data_source: data_source,
          user_id: user_id,
        ).build_bed_night!
        @services_created += 1
      end
    end

    # -- Linked record builders (called at enrollment entry/exit) --

    def create_entry_records(enrollment, date, data_source:, user_id:, sim_client:)
      rng_seed       = @seed + stable_hash("linked:#{enrollment.EnrollmentID}")
      enrollment_cfg = enrollment_config_for(sim_client)
      disability_cfg = enrollment_cfg['disabilities'] || {}
      income_cfg     = enrollment_cfg['income_at_entry'] || {}
      hdv_cfg        = enrollment_cfg['health_and_dv'] || {}

      disability_result = Builders::DisabilityBuilder.new(
        enrollment: enrollment,
        date: date,
        disability_config: disability_cfg,
        data_source: data_source,
        user_id: user_id,
        rng_seed: rng_seed,
      ).build!
      enrollment.update!(DisablingCondition: disability_result[:disabling_condition])

      Builders::IncomeBenefitBuilder.new(
        enrollment: enrollment,
        date: date,
        stage: :entry,
        income_config: income_cfg,
        data_source: data_source,
        user_id: user_id,
        rng_seed: rng_seed + 1,
      ).build!

      Builders::HealthAndDvBuilder.new(
        enrollment: enrollment,
        date: date,
        hdv_config: hdv_cfg,
        data_source: data_source,
        user_id: user_id,
        rng_seed: rng_seed + 2,
      ).build!

      cls_code = cls_situation_code_for(enrollment)
      if cls_code
        Builders::ClsBuilder.new(
          enrollment: enrollment,
          date: date,
          situation_code: cls_code,
          data_source: data_source,
          user_id: user_id,
        ).build!
      end

      pt = enrollment.project&.ProjectType.to_i
      return unless ComplianceRules.employment_education_required?(pt)
      return if record_miss?("ee_entry:#{enrollment.EnrollmentID}")

      Builders::EmploymentEducationBuilder.new(
        enrollment: enrollment,
        date: date,
        stage: :entry,
        data_source: data_source,
        user_id: user_id,
        rng_seed: rng_seed + 10,
      ).build!
    end

    def create_linked_exit_records(enrollment, exit_date, data_source:, user_id:, sim_client:)
      enrollment_cfg = enrollment_config_for(sim_client)
      income_cfg = enrollment_cfg['income_at_entry'] || {}
      Builders::IncomeBenefitBuilder.new(
        enrollment: enrollment,
        date: exit_date,
        stage: :exit,
        income_config: income_cfg,
        data_source: data_source,
        user_id: user_id,
        rng_seed: @seed + stable_hash("exit_income:#{enrollment.EnrollmentID}"),
      ).build!

      pt = enrollment.project&.ProjectType.to_i
      return unless ComplianceRules.employment_education_required?(pt)
      return if record_miss?("ee_exit:#{enrollment.EnrollmentID}")

      Builders::EmploymentEducationBuilder.new(
        enrollment: enrollment,
        date: exit_date,
        stage: :exit,
        data_source: data_source,
        user_id: user_id,
        rng_seed: @seed + stable_hash("ee_exit:#{enrollment.EnrollmentID}"),
      ).build!
    end

    # -- Annual collection tick --

    def tick_annual_collections(date:)
      project_type_by_pk = Hmis::Hud::Project.
        where(data_source_id: @data_source_id).
        pluck(:id, :ProjectType).
        to_h

      Hmis::Hud::Enrollment.
        where(data_source_id: @data_source_id).
        open_on_date(date).
        in_batches do |batch|
          enrollment_ids = batch.pluck(:id)
          sim_clients_by_enrollment = Client.
            where(data_source_id: @data_source_id, hud_enrollment_id: enrollment_ids).
            index_by(&:hud_enrollment_id)

          batch.each do |enrollment|
            sim_client = sim_clients_by_enrollment[enrollment.id]
            enrollment_cfg = sim_client ? enrollment_config_for(sim_client) : default_enrollment_config
            annual_cfg    = enrollment_cfg['annual_collection'] || {}
            miss_rate     = annual_cfg['miss_rate'].to_f
            jitter_cfg    = annual_cfg['timing_jitter'] || default_jitter_cfg
            income_cfg    = enrollment_cfg['income_at_entry'] || {}

            next unless annual_collection_due?(enrollment, date, jitter_cfg)
            next if Random.new(@seed + stable_hash("annual_miss:#{enrollment.EnrollmentID}:#{date}")).rand < miss_rate

            Builders::IncomeBenefitBuilder.new(
              enrollment: enrollment,
              date: date,
              stage: :annual,
              income_config: income_cfg,
              data_source: data_source,
              user_id: current_user_id,
              rng_seed: @seed + stable_hash("annual:#{enrollment.EnrollmentID}:#{date}"),
            ).build!

            pt = project_type_by_pk[enrollment.project_pk].to_i
            next unless ComplianceRules.employment_education_required?(pt)
            next if record_miss?("ee_annual:#{enrollment.EnrollmentID}:#{date}")

            Builders::EmploymentEducationBuilder.new(
              enrollment: enrollment,
              date: date,
              stage: :annual,
              data_source: data_source,
              user_id: current_user_id,
              rng_seed: @seed + stable_hash("ee_annual:#{enrollment.EnrollmentID}:#{date}"),
            ).build!
          end
        end
    end

    def default_jitter_cfg
      { 'distribution' => 'normal', 'mean' => 0, 'stddev' => 30, 'min' => -90, 'max' => 90 }
    end

    def default_enrollment_config
      primary_tracks.first&.fetch('enrollment_config', {}) || {}
    end

    # Returns true when an annual record is due for +enrollment+ on +date+.
    # Uses floor (not ceil) so that positive jitter extending the year-1 window
    # past day 365 is handled correctly — year_number stays at 1 until the second
    # anniversary crosses.
    def annual_collection_due?(enrollment, date, jitter_cfg)
      days_enrolled = (date - enrollment.EntryDate).to_i
      return false if days_enrolled < 300

      year_number = (days_enrolled / 365.0).floor
      return false if year_number < 1

      jitter = Distribution.sample(
        jitter_cfg.deep_stringify_keys,
        rng: Random.new(@seed + stable_hash("annual_jitter:#{enrollment.EnrollmentID}:#{year_number}")),
      ).round
      expected_date = enrollment.EntryDate + (365 * year_number) + jitter
      date == expected_date
    end

    def cls_situation_code_for(enrollment)
      return nil unless enrollment&.project

      case enrollment.project.ProjectType
      when 1, 0 then 101  # Emergency shelter
      when 4    then 116  # Street outreach — always place not meant for habitation
      when 14             # Coordinated Entry — use the client's actual living situation
        situation = enrollment.LivingSituation.to_i
        [8, 9, 99, 0].include?(situation) ? 116 : situation
      end
    end

    # -- Periodic CLS tick (SO and CE) --

    def tick_cls_records(date:)
      cls_project_types = [4, 14]
      project_type_by_pk = Hmis::Hud::Project.
        where(data_source_id: @data_source_id, ProjectType: cls_project_types).
        pluck(:id, :ProjectType).
        to_h
      return if project_type_by_pk.empty?

      cls_project_pks = project_type_by_pk.keys

      open_enrollments = Hmis::Hud::Enrollment.
        where(data_source_id: @data_source_id, project_pk: cls_project_pks).
        open_on_date(date)

      open_enrollments.find_each do |enrollment|
        pt = project_type_by_pk[enrollment.project_pk].to_i
        freq_config = ComplianceRules.cls_frequency(pt)
        next unless freq_config
        next unless cls_due?(enrollment, date, freq_config)
        next if record_miss?("cls:#{enrollment.EnrollmentID}:#{date}")

        situation = enrollment.LivingSituation.to_i
        situation = 116 if [8, 9, 99, 0].include?(situation)

        Builders::ClsBuilder.new(
          enrollment: enrollment,
          date: date,
          situation_code: situation,
          data_source: data_source,
          user_id: current_user_id,
        ).build!
      end
    end

    def cls_due?(enrollment, date, freq_config)
      days_enrolled = (date - enrollment.EntryDate).to_i
      frequency     = freq_config[:days]
      return false if days_enrolled < frequency / 2

      n = (days_enrolled.to_f / frequency).ceil
      return false if n < 1

      jitter_cfg = {
        'distribution' => 'normal',
        'mean' => 0,
        'stddev' => freq_config[:jitter_stddev].to_f,
        'min' => -(freq_config[:jitter_stddev] * 2),
        'max' => freq_config[:jitter_stddev] * 2,
      }
      jitter = Distribution.sample(
        jitter_cfg,
        rng: Random.new(@seed + stable_hash("cls_jitter:#{enrollment.EnrollmentID}:#{n}")),
      ).round
      expected = enrollment.EntryDate + (frequency * n) + jitter
      date == expected
    end

    # Returns true with probability record_miss_rate (from global data_quality config).
    # Uses a deterministic seeded roll so the same enrollment+date always produces the same result.
    def record_miss?(context_suffix)
      miss_rate = (@config.dig('data_quality', 'record_miss_rate') || 0).to_f
      return false if miss_rate.zero?

      Random.new(@seed + stable_hash("miss:#{context_suffix}")).rand < miss_rate
    end

    # -- CE record creation helpers --

    # Creates an opening Assessment + Event (code 3) for a newly opened lifecycle enrollment.
    def create_opening_ce_records(lc_enrollment, date, data_source:, user_id:)
      hud_enrollment = Hmis::Hud::Enrollment.find_by(id: lc_enrollment.hud_enrollment_id)
      return unless hud_enrollment

      unless record_miss?("ce_assessment:#{hud_enrollment.EnrollmentID}")
        Builders::AssessmentBuilder.new(
          enrollment: hud_enrollment,
          date: date,
          data_source: data_source,
          user_id: user_id,
          rng_seed: @seed + stable_hash("ce_assessment:#{hud_enrollment.EnrollmentID}"),
        ).build!
      end

      return if record_miss?("ce_open_event:#{hud_enrollment.EnrollmentID}")

      Builders::EventBuilder.new(
        enrollment: hud_enrollment,
        date: date,
        event_code: 3,
        data_source: data_source,
        user_id: user_id,
      ).build!
    end

    # Creates a mid-enrollment housing assessment Event (code 4) once per lifecycle enrollment,
    # after the enrollment has been open for at least 30 days.
    def create_midterm_ce_event(lc_enrollment, date, data_source:, user_id:)
      hud_enrollment = Hmis::Hud::Enrollment.find_by(id: lc_enrollment.hud_enrollment_id)
      return unless hud_enrollment

      days_open = (date - hud_enrollment.EntryDate).to_i
      return if days_open < 30

      already_created = Hmis::Hud::Event.where(
        data_source_id: @data_source_id,
        EnrollmentID: hud_enrollment.EnrollmentID,
        Event: 4,
      ).exists?
      return if already_created

      return if record_miss?("ce_midterm_event:#{hud_enrollment.EnrollmentID}")

      Builders::EventBuilder.new(
        enrollment: hud_enrollment,
        date: date,
        event_code: 4,
        data_source: data_source,
        user_id: user_id,
      ).build!
    end

    # Creates a closing Event for a lifecycle enrollment based on the close reason.
    #   housing_move_in  → code 14 (PSH referral), ReferralResult 1 (accepted)
    #   disengagement    → code 9 (no availability in continuum)
    #   pre_entry_exit   → code 2 (problem solving / diversion)
    def create_closing_ce_event(enrollment, date, reason:, data_source:, user_id:)
      return if record_miss?("ce_close_event:#{enrollment.EnrollmentID}")

      event_code, referral_result = case reason
      when 'housing_move_in' then [14, 1]
      when 'disengagement'   then [9,  nil]
      else                        [2,  nil]
      end

      Builders::EventBuilder.new(
        enrollment: enrollment,
        date: date,
        event_code: event_code,
        referral_result: referral_result,
        result_date: (date if referral_result),
        data_source: data_source,
        user_id: user_id,
      ).build!
    end

    # -- Concurrent enrollment tick --

    def tick_concurrent(date:)
      return if secondary_tracks_of_type('concurrent').empty?

      coc_code = primary_coc_code

      ConcurrentEnrollment.expiring_on(date).where(data_source_id: @data_source_id).find_each do |concurrent_enrollment|
        concurrent_track = find_concurrent_track(concurrent_enrollment.track_name)
        close_concurrent_enrollment(
          concurrent_enrollment, date,
          data_source: data_source, user_id: current_user_id, concurrent_track: concurrent_track
        )
      end

      ConcurrentEnrollment.pending_reentry_on(date).where(data_source_id: @data_source_id).find_each do |concurrent_enrollment|
        concurrent_track = find_concurrent_track(concurrent_enrollment.track_name)
        open_concurrent_reentry(
          concurrent_enrollment, date,
          user_id: current_user_id, coc_code: coc_code, concurrent_track: concurrent_track
        )
      end
    end

    def assign_concurrent_enrollments(sim_client, date, data_source:, user_id:)
      applicable_tracks = secondary_tracks_for_client('concurrent', sim_client)
      return if applicable_tracks.empty?

      hud_client = Hmis::Hud::Client.find_by(id: sim_client.hud_client_id)
      return unless hud_client

      coc_code = primary_coc_code

      applicable_tracks.each_with_index do |concurrent_track, track_idx|
        count_dist_cfg  = concurrent_track['count_distribution'] || { '0' => 1 }
        data_error_rate = concurrent_track['data_error_rate'].to_f

        cfg   = { 'distribution' => 'weighted', 'weights' => count_dist_cfg.transform_values(&:to_f) }
        rng   = Random.new(@seed + stable_hash("concurrent_count:#{sim_client.id}:#{track_idx}"))
        count = Distribution.sample(cfg, rng: rng).to_i
        next if count.zero?

        projects_config = build_concurrent_projects_config(concurrent_track, sim_client, data_error_rate)

        enrollments = Builders::ConcurrentEnrollmentBuilder.new(
          client: hud_client,
          date: date,
          projects_config: projects_config,
          count: count,
          coc_code: coc_code,
          data_source: data_source,
          user_id: user_id,
          track_name: concurrent_track['name'],
          rng_seed: @seed + stable_hash("concurrent:#{sim_client.id}:#{date}:#{track_idx}"),
        ).build!

        enrollments.each do |enrollment|
          create_entry_records(
            enrollment, date,
            data_source: data_source, user_id: user_id, sim_client: sim_client
          )
        end
      end
    end

    def build_concurrent_projects_config(concurrent_track, sim_client, data_error_rate)
      project_names = concurrent_track['projects'] || []
      duration_cfg  = concurrent_track['duration'] || { 'distribution' => 'constant', 'value' => 30 }

      projects_config = project_names.map do |name|
        { 'name' => name, 'selection_weight' => 1.0, 'duration' => duration_cfg }
      end

      apply_data_error_rate(projects_config, sim_client, data_error_rate, duration_cfg)
    end

    def close_concurrent_enrollment(concurrent_enrollment, date, data_source:, user_id:, concurrent_track:)
      enrollment = Hmis::Hud::Enrollment.find_by(id: concurrent_enrollment.hud_enrollment_id)
      return unless enrollment

      Builders::ExitBuilder.new(
        enrollment: enrollment,
        exit_date: date,
        exit_destinations: { '116' => 1.0 },
        data_source: data_source,
        user_id: user_id,
        seed: @seed,
        context_prefix: "concurrent_exit:#{concurrent_enrollment.id}:#{date}",
      ).build!

      reentry = schedule_concurrent_reentry(concurrent_enrollment, date, concurrent_track)
      concurrent_enrollment.update!(hud_enrollment_id: nil, exit_on: nil, pending_reentry_on: reentry)
    end

    def open_concurrent_reentry(concurrent_enrollment, date, user_id:, coc_code:, concurrent_track:)
      return unless concurrent_track

      project = Hmis::Hud::Project.find_by(
        data_source_id: @data_source_id,
        ProjectName: concurrent_enrollment.project_name,
      )
      return unless project

      client = Hmis::Hud::Client.find_by(id: concurrent_enrollment.hud_client_id)
      return unless client

      enrollment = Builders::BaseBuilder.create_solo_enrollment(
        client: client,
        project: project,
        date: date,
        coc_code: coc_code,
        data_source: data_source,
        user_id: user_id,
        date_of_engagement: (date if project.ProjectType == 4),
      )

      sim_client = Client.find_by(hud_client_id: concurrent_enrollment.hud_client_id, data_source_id: @data_source_id)
      create_entry_records(enrollment, date, data_source: data_source, user_id: user_id, sim_client: sim_client) if sim_client

      duration_cfg = (concurrent_track&.dig('duration') || { 'distribution' => 'constant', 'value' => 30 }).deep_stringify_keys
      duration = Distribution.sample(
        duration_cfg,
        rng: Random.new(@seed + stable_hash("concurrent_reentry_dur:#{concurrent_enrollment.id}:#{date}")),
      ).ceil.clamp(1, 365)

      concurrent_enrollment.update!(hud_enrollment_id: enrollment.id, exit_on: date + duration, pending_reentry_on: nil)
    end

    def schedule_concurrent_reentry(concurrent_enrollment, exit_date, concurrent_track)
      return nil unless concurrent_track

      reentry_cfg = concurrent_track['reentry'] || {}
      prob = reentry_cfg['probability'].to_f
      return nil if Random.new(@seed + stable_hash("reentry_prob:#{concurrent_enrollment.id}:#{exit_date}")).rand >= prob

      gap_cfg  = (reentry_cfg['gap'] || { 'distribution' => 'constant', 'value' => 7 }).deep_stringify_keys
      gap_days = Distribution.sample(
        gap_cfg,
        rng: Random.new(@seed + stable_hash("reentry_gap:#{concurrent_enrollment.id}:#{exit_date}")),
      ).ceil.clamp(0, 365)
      exit_date + gap_days
    end

    def find_concurrent_track(track_name)
      secondary_tracks_of_type('concurrent').find { |t| t['name'] == track_name }
    end

    def apply_data_error_rate(projects_config, sim_client, data_error_rate, default_duration_cfg = nil)
      return projects_config if data_error_rate.zero?
      return projects_config unless Random.new(@seed + stable_hash("data_error:#{sim_client.id}")).rand < data_error_rate

      primary_enrollment = Hmis::Hud::Enrollment.find_by(id: sim_client.hud_enrollment_id)
      return projects_config unless primary_enrollment

      same_type_project = Hmis::Hud::Project.
        where(data_source_id: @data_source_id, ProjectType: primary_enrollment.project&.ProjectType).
        where.not(id: primary_enrollment.project_pk).
        first
      return projects_config unless same_type_project

      error_duration = default_duration_cfg || { 'distribution' => 'constant', 'value' => 30 }
      error_entry = {
        'name' => same_type_project.ProjectName,
        'selection_weight' => 1.0,
        'duration' => error_duration,
      }
      [error_entry]
    end

    # -- Lifecycle enrollment tick (CE) --

    def tick_lifecycle(date:)
      return if secondary_tracks_of_type('lifecycle').empty?

      LifecycleEnrollment.
        where(data_source_id: @data_source_id, status: 'open').
        find_each do |lifecycle_enrollment|
          lc_cfg = secondary_tracks_of_type('lifecycle').find { |t| t['name'] == lifecycle_enrollment.lifecycle_name }
          process_lifecycle_close_conditions(
            lifecycle_enrollment, date,
            data_source: data_source, user_id: current_user_id, lc_cfg: lc_cfg
          )
        end
    end

    def trigger_lifecycle_enrollments(sim_client, entry_date, data_source:, user_id:)
      applicable_tracks = secondary_tracks_for_client('lifecycle', sim_client)
      return if applicable_tracks.empty?

      coc_code = primary_coc_code

      applicable_tracks.each_with_index do |lc_cfg, idx|
        trigger_populations = lc_cfg['trigger_populations'] || []
        next unless trigger_populations.include?(sim_client.current_population)

        next if LifecycleEnrollment.where(
          data_source_id: @data_source_id,
          hud_client_id: sim_client.hud_client_id,
          lifecycle_name: lc_cfg['name'],
          status: 'open',
        ).exists?

        rng = Random.new(@seed + stable_hash("lifecycle_trigger:#{lc_cfg['name']}:#{sim_client.id}:#{idx}"))
        next if rng.rand >= lc_cfg['trigger_probability'].to_f

        gap_cfg  = (lc_cfg['days_before_trigger'] || { 'distribution' => 'constant', 'value' => 0 }).deep_stringify_keys
        gap_days = Distribution.sample(
          gap_cfg,
          rng: Random.new(@seed + stable_hash("lifecycle_gap:#{sim_client.id}:#{idx}")),
        ).ceil.clamp(0, 365)
        opens_on = entry_date - gap_days

        project_ref = lc_cfg['project_ref']
        ce_project  = Hmis::Hud::Project.find_by(data_source_id: @data_source_id, ProjectName: project_ref)
        next unless ce_project

        client = Hmis::Hud::Client.find_by(id: sim_client.hud_client_id)
        next unless client

        lc_enrollment = Builders::LifecycleEnrollmentBuilder.new(
          client: client,
          lifecycle_name: lc_cfg['name'],
          ce_project: ce_project,
          opens_on: opens_on,
          coc_code: coc_code,
          data_source: data_source,
          user_id: user_id,
          rng_seed: @seed + stable_hash("lc_living_situation:#{sim_client.id}:#{lc_cfg['name']}"),
        ).build!

        create_opening_ce_records(lc_enrollment, opens_on, data_source: data_source, user_id: user_id)

        hud_enrollment = Hmis::Hud::Enrollment.find_by(id: lc_enrollment.hud_enrollment_id)
        create_entry_records(hud_enrollment, opens_on, data_source: data_source, user_id: user_id, sim_client: sim_client) if hud_enrollment
      end
    end

    def process_lifecycle_close_conditions(lifecycle_enrollment, date, data_source:, user_id:, lc_cfg:)
      return unless lc_cfg

      create_midterm_ce_event(lifecycle_enrollment, date, data_source: data_source, user_id: user_id)

      close_conditions = lc_cfg['close_conditions'] || {}

      if check_housing_move_in?(lifecycle_enrollment, close_conditions)
        close_lifecycle_enrollment(lifecycle_enrollment, date, reason: 'housing_move_in', data_source: data_source, user_id: user_id)
        return
      end

      if check_disengagement?(lifecycle_enrollment, date, close_conditions)
        close_lifecycle_enrollment(lifecycle_enrollment, date, reason: 'disengagement', data_source: data_source, user_id: user_id)
        return
      end

      return unless check_pre_entry_exit?(lifecycle_enrollment, date, close_conditions)

      close_lifecycle_enrollment(lifecycle_enrollment, date, reason: 'pre_entry_exit', data_source: data_source, user_id: user_id)
    end

    def check_housing_move_in?(lifecycle_enrollment, close_conditions)
      return false unless close_conditions.key?('housing_move_in')

      rng = Random.new(@seed + stable_hash("lc_housing_move_in:#{lifecycle_enrollment.id}"))
      return false if rng.rand >= close_conditions['housing_move_in'].to_f

      Hmis::Hud::Enrollment.
        where(data_source_id: @data_source_id, PersonalID: hmis_personal_id_for(lifecycle_enrollment)).
        where.not(MoveInDate: nil).
        exists?
    end

    def check_disengagement?(lifecycle_enrollment, date, close_conditions)
      check_timed_close_condition?(lifecycle_enrollment, date, close_conditions, 'disengagement', 'lc_disengage')
    end

    def check_pre_entry_exit?(lifecycle_enrollment, date, close_conditions)
      check_timed_close_condition?(lifecycle_enrollment, date, close_conditions, 'pre_entry_exit', 'lc_pre_exit', default_days: 30)
    end

    def check_timed_close_condition?(lifecycle_enrollment, date, close_conditions, config_key, rng_prefix, default_days: 365)
      cfg = close_conditions[config_key]
      return false unless cfg.present?

      rng = Random.new(@seed + stable_hash("#{rng_prefix}_prob:#{lifecycle_enrollment.id}"))
      return false if rng.rand >= cfg['probability'].to_f

      after_days_cfg = (cfg['after_days'] || { 'distribution' => 'constant', 'value' => default_days }).deep_stringify_keys
      after_days = Distribution.sample(
        after_days_cfg,
        rng: Random.new(@seed + stable_hash("#{rng_prefix}_days:#{lifecycle_enrollment.id}")),
      ).ceil
      date >= lifecycle_enrollment.opens_on + after_days
    end

    def close_lifecycle_enrollment(lifecycle_enrollment, date, reason:, data_source:, user_id:)
      enrollment = Hmis::Hud::Enrollment.find_by(id: lifecycle_enrollment.hud_enrollment_id)
      if enrollment
        Builders::ExitBuilder.new(
          enrollment: enrollment,
          exit_date: date,
          exit_destinations: { '116' => 1.0 },
          data_source: data_source,
          user_id: user_id,
          seed: @seed,
          context_prefix: "lifecycle_exit:#{lifecycle_enrollment.id}:#{date}",
        ).build!

        create_closing_ce_event(enrollment, date, reason: reason, data_source: data_source, user_id: user_id)
      end

      lifecycle_enrollment.update!(status: 'closed', close_reason: reason)
    end

    def hmis_personal_id_for(lifecycle_enrollment)
      Hmis::Hud::Client.find_by(id: lifecycle_enrollment.hud_client_id)&.PersonalID
    end

    # -- Transition helpers --

    def sample_enrollment_exit(population_name, date, client_id)
      transitions = outgoing_transitions(population_name)
      return [population_name, 30] if transitions.empty?

      weights  = transitions.each_with_object({}) { |t, h| h[t['to']] = t['weight'].to_f }
      cfg      = { 'distribution' => 'weighted', 'weights' => weights }
      next_pop = Distribution.sample(cfg, rng: rng("next_pop:#{date}:#{client_id}"))
      transition = find_transition(population_name, next_pop)
      timing_days = if transition
        Distribution.sample(transition['timing'].deep_stringify_keys, rng: rng("timing:#{date}:#{client_id}")).ceil
      else
        30
      end
      [next_pop, [timing_days, 1].max]
    end

    def roll_exit_point(population_cfg, sim_client)
      prob = population_cfg&.dig('exit_point').to_f
      return false if prob.zero?
      return true if prob >= 1.0

      rng("exit_point:#{sim_client.id}").rand < prob
    end

    def sample_gap(transition, date, client_id)
      gap_cfg = transition&.dig('gap_before_entry')
      return 0 unless gap_cfg.present?

      Distribution.sample(gap_cfg.deep_stringify_keys, rng: rng("gap:#{date}:#{client_id}")).ceil.clamp(0, 365)
    end

    def outgoing_transitions(population_name)
      track = track_for_population(population_name)
      return [] unless track

      (track['transitions'] || []).select { |t| t['from'] == population_name }
    end

    def find_transition(from, to)
      return nil unless from.present? && to.present?

      track = track_for_population(from)
      return nil unless track

      (track['transitions'] || []).find { |t| t['from'] == from && t['to'] == to }
    end

    def find_project_by_ref(project_ref, data_source:)
      return nil if project_ref.blank?

      Hmis::Hud::Project.find_by(data_source_id: data_source.id, ProjectName: project_ref)
    end

    # -- Daily count and population draw (per primary track) --

    def daily_new_client_count_for_track(track, date:)
      monthly_cfg = track['new_clients_per_month'] || { 'distribution' => 'poisson', 'lambda' => 1 }
      daily_cfg   = scale_to_daily(monthly_cfg.deep_stringify_keys)
      count       = Distribution.sample(daily_cfg, rng: rng("spawn_count:#{track['name']}:#{date}")).to_f
      [count.ceil, 0].max
    end

    def scale_to_daily(monthly_cfg)
      case monthly_cfg['distribution']
      when 'poisson'
        monthly_cfg.merge('lambda' => monthly_cfg['lambda'].to_f / 30.0)
      when 'constant'
        { 'distribution' => 'poisson', 'lambda' => monthly_cfg['value'].to_f / 30.0 }
      when 'uniform'
        avg_monthly = (monthly_cfg['min'].to_f + monthly_cfg['max'].to_f) / 2.0
        { 'distribution' => 'poisson', 'lambda' => avg_monthly / 30.0 }
      else
        monthly_cfg
      end
    end

    def draw_entry_population_for_track(track, date:, index:)
      populations = track['populations'] || []
      candidates  = populations.select { |p| p['entry_point'].to_f.positive? }
      return nil if candidates.empty?

      weights = candidates.each_with_object({}) { |p, h| h[p['name']] = p['entry_point'].to_f }
      cfg     = { 'distribution' => 'weighted', 'weights' => weights }
      name    = Distribution.sample(cfg, rng: rng("population:#{track['name']}:#{date}:#{index}"))
      populations.find { |p| p['name'] == name }
    end

    def draw_household_template(population:, date:, index:)
      templates = population['household_templates'] || { 'adult_only' => 1.0 }
      cfg = { 'distribution' => 'weighted', 'weights' => templates }
      Distribution.sample(cfg, rng: rng("template:#{date}:#{index}"))
    end

    # Returns a deterministic Random seeded from the simulation seed + a stable context string.
    # Uses stable_hash (SHA-256-based) rather than String#hash to guarantee consistent
    # seeds across Ruby process restarts.
    def rng(context)
      Random.new(@seed + stable_hash(context))
    end
  end
end
