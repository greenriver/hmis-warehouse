###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Drives the simulation forward one calendar day at a time.
  #
  # See @docs/features/hmis-simulation.md
  #
  # Each call to #run(date:) processes exactly one simulated day:
  #   1. Spawn new clients (looped over all primary tracks)
  #   2. Process primary enrollment exits and entries (per primary track), plus NBN bed nights
  #   3. Housing move-in (defer MoveInDate onto open PH enrollments whose delay has elapsed)
  #   4. Periodic CLS records (SO: every ~30 days; CE: every ~90 days)
  #   5. Annual record collection (IncomeBenefits + EmploymentEducation, per client's track config)
  #   6. Concurrent enrollment tick (looped over all concurrent tracks)
  #   7. Lifecycle enrollment tick (looped over all lifecycle tracks)
  #   8. Write RunLog
  #
  # Idempotent: re-running the same date is a no-op (detected via RunLog).
  # Recoverable: a previously failed date's RunLog is overwritten on retry.
  #
  # Usage:
  #   config = HmisSimulation::ConfigLoader.from_app_config('hmis_simulation/demo-coc')
  #   engine = HmisSimulation::Engine.new(config)
  #   engine.run(date: Date.current)
  class Engine
    def initialize(config)
      @config = config.deep_stringify_keys
      @data_source_id = @config['data_source_id'].to_i
      @seed = @config['seed'].to_i
      record_miss_rate = (@config.dig('data_quality', 'record_miss_rate') || 0).to_f
      @schedule = Schedule.new(seed: @seed, record_miss_rate: record_miss_rate)
    end

    def run(date:)
      HmisSimulation.ensure_not_production!
      RunLog.with_advisory_lock("hmis_simulation:#{@data_source_id}", timeout_seconds: 0) do
        ensure_bootstrapped!
        run_locked(date: date)
      end
    end

    private

    # Lazily create the structural HUD scaffolding (orgs, projects, ProjectCoc,
    # Inventory, Funders, etc.) that the simulation writes into. Idempotent and
    # memoized so a multi-day run only checks once. Making this the Engine's
    # responsibility means no caller can advance the simulation without it.
    def ensure_bootstrapped!
      return if @bootstrapped

      unless Hmis::Hud::Project.where(
        data_source_id: @data_source_id,
        ExportID: Bootstrapper::EXPORT_ID,
      ).exists?
        Bootstrapper.new(@config).run!
      end
      @bootstrapped = true
    end

    def run_locked(date:)
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
          tick_housing_move_in(date: date)
          tick_cls_records(date: date)
          tick_annual_collections(date: date)
          tick_concurrent(date: date)
          tick_lifecycle(date: date)

          # Finalize inside the transaction so the success flag commits atomically
          # with the day's HUD/state writes.
          log.update!(
            clients_created: @clients_created,
            enrollments_opened: @enrollments_opened,
            enrollments_closed: @enrollments_closed,
            services_created: @services_created,
            finished_at: Time.current,
          )
        end
      rescue StandardError => e
        log.update!(error_message: e.message, finished_at: Time.current)
        raise
      end
    end

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
        spawn_clients_for_track(track, date: date)
      end
    end

    def spawn_clients_for_track(track, date:)
      count = @schedule.daily_new_client_count(
        monthly_cfg: track['new_clients_per_month'],
        context: "spawn_count:#{track['name']}:#{date}",
      )

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
          user_id: current_user_id,
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
        process_primary_exit(sim_client, date)
      end

      Client.pending_enrollment(date).where(data_source_id: @data_source_id).find_each do |sim_client|
        process_primary_entry(sim_client, date)
      end

      create_bed_nights(date)
    end

    def process_primary_exit(sim_client, date)
      enrollment = Hmis::Hud::Enrollment.find_by(id: sim_client.hud_enrollment_id)
      return unless enrollment

      # DateOfEngagement can be up to 7 days after entry; clamp so it never exceeds exit date.
      enrollment.update!(DateOfEngagement: date) if enrollment.DateOfEngagement.present? && enrollment.DateOfEngagement > date

      transition = find_transition(sim_client.current_population, sim_client.next_population)
      exit_dests = transition&.dig('exit_destinations') || { '17' => 1.0 }

      Builders::ExitBuilder.new(
        enrollment: enrollment,
        exit_date: date,
        exit_destinations: exit_dests,
        data_source: data_source,
        user_id: current_user_id,
        seed: @seed,
        context_prefix: "exit:#{date}:#{sim_client.id}",
      ).build!
      create_linked_exit_records(enrollment, date, sim_client: sim_client)

      @enrollments_closed += 1

      population_cfg = find_population(sim_client.current_population)
      if @schedule.exit_point?(probability: population_cfg&.dig('exit_point').to_f, context: "exit_point:#{sim_client.id}")
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
        gap = @schedule.sample_gap(gap_cfg: transition&.dig('gap_before_entry'), context: "gap:#{date}:#{sim_client.id}")
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

    def process_primary_entry(sim_client, date)
      population_cfg = find_population(sim_client.current_population)
      return unless population_cfg

      project_ref = population_cfg['project_ref']
      project = find_project_by_ref(project_ref)
      return unless project

      hoh_client = Hmis::Hud::Client.find_by(id: sim_client.hud_client_id)
      return unless hoh_client

      household_group = (HouseholdGroup.find_by(id: sim_client.household_group_id) if sim_client.household_group_id.present?)
      members = household_group&.member_relationships || []

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
        user_id: current_user_id,
        rng_seed: @schedule.seed_for("entry:#{date}:#{sim_client.id}"),
      ).build!

      @enrollments_opened += 1
      create_entry_records(
        result[:hoh_enrollment],
        date,
        sim_client: sim_client,
        project_type: project.ProjectType,
      )
      assign_concurrent_enrollments(sim_client, date)
      trigger_lifecycle_enrollments(sim_client, date)

      next_pop, timing = sample_enrollment_exit(sim_client.current_population, date, sim_client.id)

      sim_client.update!(
        hud_enrollment_id: result[:hoh_enrollment].id,
        pending_enrollment_on: nil,
        next_transition_on: date + timing,
        next_population: next_pop,
      )
    end

    def create_bed_nights(date)
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
          user_id: current_user_id,
        ).build_bed_night!
        @services_created += 1
      end
    end

    # -- Housing move-in tick --

    # Sets MoveInDate on open PH enrollments whose configured delay has elapsed.
    # MoveInDate is NOT set at enrollment entry — it is deferred here so that some
    # clients can exit PH without ever receiving a move-in date (they left before
    # being housed), which reflects real-world HMIS data.
    #
    # Config (under primary track enrollment_config.ph_move_in):
    #   probability  – share of clients who will ever receive a MoveInDate (0–1)
    #   delay_days   – distribution of days from EntryDate to MoveInDate
    #
    # Both rolls are stable per enrollment (seeded by EnrollmentID), so the move-in
    # date is determined at first tick and never changes.
    def tick_housing_move_in(date:)
      ph_project_pks = Hmis::Hud::Project.
        where(data_source_id: @data_source_id, ProjectType: Builders::EnrollmentBuilder::PH_PROJECT_TYPES).
        pluck(:id)
      return if ph_project_pks.empty?

      Hmis::Hud::Enrollment.
        where(data_source_id: @data_source_id, project_pk: ph_project_pks, MoveInDate: nil).
        open_on_date(date).
        find_each do |enrollment|
          sim_client = Client.find_by(data_source_id: @data_source_id, hud_enrollment_id: enrollment.id)
          next unless sim_client

          move_in_cfg = enrollment_config_for(sim_client)['ph_move_in'] || {}
          probability = move_in_cfg['probability'].to_f
          next if probability.zero?

          next unless @schedule.chance?(probability, context: "ph_move_in_prob:#{enrollment.EnrollmentID}")

          delay_cfg = (move_in_cfg['delay_days'] || { 'distribution' => 'constant', 'value' => 30 }).deep_stringify_keys
          delay_days = @schedule.sample(
            delay_cfg,
            context: "ph_move_in_days:#{enrollment.EnrollmentID}",
          ).ceil.clamp(0, 365)

          move_in_date = enrollment.EntryDate + delay_days
          next if move_in_date > date

          enrollment.update!(MoveInDate: move_in_date)
        end
    end

    # -- Linked record builders (called at enrollment entry/exit) --

    def create_entry_records(enrollment, date, sim_client:, project_type: nil)
      enrollment_cfg = enrollment_config_for(sim_client)
      disability_cfg = enrollment_cfg['disabilities'] || {}
      income_cfg     = enrollment_cfg['income_at_entry'] || {}
      hdv_cfg        = enrollment_cfg['health_and_dv'] || {}

      disability_result = Builders::DisabilityBuilder.new(
        enrollment: enrollment,
        date: date,
        disability_config: disability_cfg,
        data_source: data_source,
        user_id: current_user_id,
        rng_seed: @schedule.seed_for("disability_entry:#{enrollment.EnrollmentID}"),
      ).build!
      enrollment.update!(DisablingCondition: disability_result[:disabling_condition])

      Builders::IncomeBenefitBuilder.new(
        enrollment: enrollment,
        date: date,
        stage: :entry,
        income_config: income_cfg,
        data_source: data_source,
        user_id: current_user_id,
        rng_seed: @schedule.seed_for("income_entry:#{enrollment.EnrollmentID}"),
      ).build!

      Builders::HealthAndDvBuilder.new(
        enrollment: enrollment,
        date: date,
        hdv_config: hdv_cfg,
        data_source: data_source,
        user_id: current_user_id,
        rng_seed: @schedule.seed_for("hdv_entry:#{enrollment.EnrollmentID}"),
      ).build!

      cls_code = cls_situation_code_for(enrollment)
      if cls_code
        Builders::ClsBuilder.new(
          enrollment: enrollment,
          date: date,
          situation_code: cls_code,
          data_source: data_source,
          user_id: current_user_id,
        ).build!
      end

      pt = (project_type || enrollment.project&.ProjectType).to_i
      return unless ComplianceRules.employment_education_required?(pt)
      return if @schedule.record_miss?("ee_entry:#{enrollment.EnrollmentID}")

      Builders::EmploymentEducationBuilder.new(
        enrollment: enrollment,
        date: date,
        stage: :entry,
        data_source: data_source,
        user_id: current_user_id,
        rng_seed: @schedule.seed_for("ee_entry:#{enrollment.EnrollmentID}"),
      ).build!
    end

    def create_linked_exit_records(enrollment, exit_date, sim_client:, project_type: nil)
      enrollment_cfg = enrollment_config_for(sim_client)
      income_cfg = enrollment_cfg['income_at_entry'] || {}
      Builders::IncomeBenefitBuilder.new(
        enrollment: enrollment,
        date: exit_date,
        stage: :exit,
        income_config: income_cfg,
        data_source: data_source,
        user_id: current_user_id,
        rng_seed: @schedule.seed_for("exit_income:#{enrollment.EnrollmentID}"),
      ).build!

      pt = (project_type || enrollment.project&.ProjectType).to_i

      if ComplianceRules.health_and_dv_required?(pt) && !@schedule.record_miss?("hdv_exit:#{enrollment.EnrollmentID}")
        hdv_cfg = enrollment_cfg['health_and_dv'] || {}
        Builders::HealthAndDvBuilder.new(
          enrollment: enrollment,
          date: exit_date,
          stage: :exit,
          hdv_config: hdv_cfg,
          data_source: data_source,
          user_id: current_user_id,
          rng_seed: @schedule.seed_for("hdv_exit:#{enrollment.EnrollmentID}"),
        ).build!
      end

      return unless ComplianceRules.employment_education_required?(pt)
      return if @schedule.record_miss?("ee_exit:#{enrollment.EnrollmentID}")

      Builders::EmploymentEducationBuilder.new(
        enrollment: enrollment,
        date: exit_date,
        stage: :exit,
        data_source: data_source,
        user_id: current_user_id,
        rng_seed: @schedule.seed_for("ee_exit:#{enrollment.EnrollmentID}"),
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

            next unless @schedule.annual_collection_due?(
              entry_date: enrollment.EntryDate,
              on_date: date,
              enrollment_id: enrollment.EnrollmentID,
              jitter_cfg: jitter_cfg,
            )
            next if @schedule.chance?(miss_rate, context: "annual_miss:#{enrollment.EnrollmentID}:#{date}")

            Builders::IncomeBenefitBuilder.new(
              enrollment: enrollment,
              date: date,
              stage: :annual,
              income_config: income_cfg,
              data_source: data_source,
              user_id: current_user_id,
              rng_seed: @schedule.seed_for("annual:#{enrollment.EnrollmentID}:#{date}"),
            ).build!

            pt = project_type_by_pk[enrollment.project_pk].to_i
            next unless ComplianceRules.employment_education_required?(pt)
            next if @schedule.record_miss?("ee_annual:#{enrollment.EnrollmentID}:#{date}")

            Builders::EmploymentEducationBuilder.new(
              enrollment: enrollment,
              date: date,
              stage: :annual,
              data_source: data_source,
              user_id: current_user_id,
              rng_seed: @schedule.seed_for("ee_annual:#{enrollment.EnrollmentID}:#{date}"),
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

    def cls_situation_code_for(enrollment)
      return nil unless enrollment&.project

      case enrollment.project.ProjectType
      when *ComplianceRules::ES_PROJECT_TYPES then 101 # Emergency shelter
      when ComplianceRules::SO_PROJECT_TYPE then 116 # Street outreach — always place not meant for habitation
      when ComplianceRules::CE_PROJECT_TYPE # Coordinated Entry — use the client's actual living situation
        situation = enrollment.LivingSituation.to_i
        [8, 9, 99, 0].include?(situation) ? 116 : situation
      end
    end

    # -- Periodic CLS tick (SO and CE) --

    def tick_cls_records(date:)
      cls_project_types = [ComplianceRules::SO_PROJECT_TYPE, ComplianceRules::CE_PROJECT_TYPE]
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
        next unless @schedule.cls_due?(
          entry_date: enrollment.EntryDate,
          on_date: date,
          enrollment_id: enrollment.EnrollmentID,
          freq_config: freq_config,
        )
        next if @schedule.record_miss?("cls:#{enrollment.EnrollmentID}:#{date}")

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

    # -- CE record creation helpers --

    # Creates an opening Assessment + Event (code 3) for a newly opened lifecycle enrollment.
    def create_opening_ce_records(lc_enrollment, date)
      hud_enrollment = Hmis::Hud::Enrollment.find_by(id: lc_enrollment.hud_enrollment_id)
      return unless hud_enrollment

      unless @schedule.record_miss?("ce_assessment:#{hud_enrollment.EnrollmentID}")
        Builders::AssessmentBuilder.new(
          enrollment: hud_enrollment,
          date: date,
          data_source: data_source,
          user_id: current_user_id,
          rng_seed: @schedule.seed_for("ce_assessment:#{hud_enrollment.EnrollmentID}"),
        ).build!
      end

      return if @schedule.record_miss?("ce_open_event:#{hud_enrollment.EnrollmentID}")

      Builders::EventBuilder.new(
        enrollment: hud_enrollment,
        date: date,
        event_code: 3,
        data_source: data_source,
        user_id: current_user_id,
      ).build!
    end

    # Creates a mid-enrollment housing assessment Event (code 4) once per lifecycle enrollment,
    # after the enrollment has been open for at least 30 days.
    def create_midterm_ce_event(lc_enrollment, date)
      hud_enrollment = if @lc_hud_enrollment_by_pk
        @lc_hud_enrollment_by_pk[lc_enrollment.hud_enrollment_id]
      else
        Hmis::Hud::Enrollment.find_by(id: lc_enrollment.hud_enrollment_id)
      end
      return unless hud_enrollment

      days_open = (date - hud_enrollment.EntryDate).to_i
      return if days_open < 30

      already_created = if @lc_existing_event4_ids
        @lc_existing_event4_ids.include?(hud_enrollment.EnrollmentID)
      else
        Hmis::Hud::Event.where(
          data_source_id: @data_source_id,
          EnrollmentID: hud_enrollment.EnrollmentID,
          Event: 4,
        ).exists?
      end
      return if already_created

      return if @schedule.record_miss?("ce_midterm_event:#{hud_enrollment.EnrollmentID}")

      Builders::EventBuilder.new(
        enrollment: hud_enrollment,
        date: date,
        event_code: 4,
        data_source: data_source,
        user_id: current_user_id,
      ).build!
      @lc_existing_event4_ids&.add(hud_enrollment.EnrollmentID)
    end

    # Creates a closing Event for a lifecycle enrollment based on the close reason.
    #   housing_move_in  → code 14 (PSH referral), ReferralResult 1 (accepted)
    #   disengagement    → code 9 (no availability in continuum)
    #   pre_entry_exit   → code 2 (problem solving / diversion)
    def create_closing_ce_event(enrollment, date, reason:)
      return if @schedule.record_miss?("ce_close_event:#{enrollment.EnrollmentID}")

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
        user_id: current_user_id,
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
          concurrent_track: concurrent_track
        )
      end

      ConcurrentEnrollment.pending_reentry_on(date).where(data_source_id: @data_source_id).find_each do |concurrent_enrollment|
        concurrent_track = find_concurrent_track(concurrent_enrollment.track_name)
        open_concurrent_reentry(
          concurrent_enrollment, date,
          coc_code: coc_code, concurrent_track: concurrent_track
        )
      end
    end

    def assign_concurrent_enrollments(sim_client, date)
      applicable_tracks = secondary_tracks_for_client('concurrent', sim_client)
      return if applicable_tracks.empty?

      hud_client = Hmis::Hud::Client.find_by(id: sim_client.hud_client_id)
      return unless hud_client

      coc_code = primary_coc_code

      applicable_tracks.each_with_index do |concurrent_track, track_idx|
        count_dist_cfg  = concurrent_track['count_distribution'] || { '0' => 1 }
        data_error_rate = concurrent_track['data_error_rate'].to_f

        cfg   = { 'distribution' => 'weighted', 'weights' => count_dist_cfg.transform_values(&:to_f) }
        count = @schedule.sample(cfg, context: "concurrent_count:#{sim_client.id}:#{track_idx}").to_i
        next if count.zero?

        projects_config = build_concurrent_projects_config(concurrent_track, sim_client, data_error_rate)

        enrollments = Builders::ConcurrentEnrollmentBuilder.new(
          client: hud_client,
          date: date,
          projects_config: projects_config,
          count: count,
          coc_code: coc_code,
          data_source: data_source,
          user_id: current_user_id,
          track_name: concurrent_track['name'],
          rng_seed: @schedule.seed_for("concurrent:#{sim_client.id}:#{date}:#{track_idx}"),
        ).build!

        enrollments.each do |enrollment|
          create_entry_records(
            enrollment,
            date,
            sim_client: sim_client,
            project_type: enrollment.project&.ProjectType,
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

    def close_concurrent_enrollment(concurrent_enrollment, date, concurrent_track:)
      enrollment = Hmis::Hud::Enrollment.find_by(id: concurrent_enrollment.hud_enrollment_id)
      return unless enrollment

      Builders::ExitBuilder.new(
        enrollment: enrollment,
        exit_date: date,
        exit_destinations: { '116' => 1.0 },
        data_source: data_source,
        user_id: current_user_id,
        seed: @seed,
        context_prefix: "concurrent_exit:#{concurrent_enrollment.id}:#{date}",
      ).build!

      pt = enrollment.project&.ProjectType.to_i
      if ComplianceRules.health_and_dv_required?(pt) && !@schedule.record_miss?("hdv_exit:#{enrollment.EnrollmentID}")
        Builders::HealthAndDvBuilder.new(
          enrollment: enrollment,
          date: date,
          stage: :exit,
          hdv_config: {},
          data_source: data_source,
          user_id: current_user_id,
          rng_seed: @schedule.seed_for("hdv_exit:#{enrollment.EnrollmentID}"),
        ).build!
      end

      reentry = schedule_concurrent_reentry(concurrent_enrollment, date, concurrent_track)
      concurrent_enrollment.update!(hud_enrollment_id: nil, exit_on: nil, pending_reentry_on: reentry)
    end

    def open_concurrent_reentry(concurrent_enrollment, date, coc_code:, concurrent_track:)
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
        user_id: current_user_id,
        date_of_engagement: (date if project.ProjectType == 4),
      )

      sim_client = Client.find_by(hud_client_id: concurrent_enrollment.hud_client_id, data_source_id: @data_source_id)
      if sim_client
        create_entry_records(
          enrollment,
          date,
          sim_client: sim_client,
          project_type: project.ProjectType,
        )
      end

      duration_cfg = (concurrent_track&.dig('duration') || { 'distribution' => 'constant', 'value' => 30 }).deep_stringify_keys
      duration = @schedule.sample(
        duration_cfg,
        context: "concurrent_reentry_dur:#{concurrent_enrollment.id}:#{date}",
      ).ceil.clamp(1, 365)

      concurrent_enrollment.update!(hud_enrollment_id: enrollment.id, exit_on: date + duration, pending_reentry_on: nil)
    end

    def schedule_concurrent_reentry(concurrent_enrollment, exit_date, concurrent_track)
      return nil unless concurrent_track

      reentry_cfg = concurrent_track['reentry'] || {}
      prob = reentry_cfg['probability'].to_f
      return nil unless @schedule.chance?(prob, context: "reentry_prob:#{concurrent_enrollment.id}:#{exit_date}")

      gap_cfg  = (reentry_cfg['gap'] || { 'distribution' => 'constant', 'value' => 7 }).deep_stringify_keys
      gap_days = @schedule.sample(
        gap_cfg,
        context: "reentry_gap:#{concurrent_enrollment.id}:#{exit_date}",
      ).ceil.clamp(0, 365)
      exit_date + gap_days
    end

    def find_concurrent_track(track_name)
      secondary_tracks_of_type('concurrent').find { |t| t['name'] == track_name }
    end

    def apply_data_error_rate(projects_config, sim_client, data_error_rate, default_duration_cfg = nil)
      return projects_config if data_error_rate.zero?
      return projects_config unless @schedule.chance?(data_error_rate, context: "data_error:#{sim_client.id}")

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

      preload_lifecycle_tick_cache
      LifecycleEnrollment.
        where(data_source_id: @data_source_id, status: 'open').
        find_each do |lifecycle_enrollment|
          lc_cfg = secondary_tracks_of_type('lifecycle').find { |t| t['name'] == lifecycle_enrollment.lifecycle_name }
          process_lifecycle_close_conditions(
            lifecycle_enrollment, date,
            lc_cfg: lc_cfg
          )
        end
    ensure
      @lc_hud_enrollment_by_pk = nil
      @lc_existing_event4_ids = nil
    end

    def preload_lifecycle_tick_cache
      hud_enrollment_pks = LifecycleEnrollment.
        where(data_source_id: @data_source_id, status: 'open').
        pluck(:hud_enrollment_id).compact
      @lc_hud_enrollment_by_pk = Hmis::Hud::Enrollment.
        where(id: hud_enrollment_pks).
        index_by(&:id)
      enrollment_ids = @lc_hud_enrollment_by_pk.values.map(&:EnrollmentID)
      @lc_existing_event4_ids = Hmis::Hud::Event.
        where(data_source_id: @data_source_id, EnrollmentID: enrollment_ids, Event: 4).
        pluck(:EnrollmentID).
        to_set
    end

    def trigger_lifecycle_enrollments(sim_client, entry_date)
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

        next unless @schedule.chance?(lc_cfg['trigger_probability'].to_f, context: "lifecycle_trigger:#{lc_cfg['name']}:#{sim_client.id}:#{idx}")

        gap_cfg  = (lc_cfg['days_before_trigger'] || { 'distribution' => 'constant', 'value' => 0 }).deep_stringify_keys
        gap_days = @schedule.sample(
          gap_cfg,
          context: "lifecycle_gap:#{sim_client.id}:#{idx}",
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
          user_id: current_user_id,
          rng_seed: @schedule.seed_for("lc_living_situation:#{sim_client.id}:#{lc_cfg['name']}"),
        ).build!

        create_opening_ce_records(lc_enrollment, opens_on)

        hud_enrollment = Hmis::Hud::Enrollment.find_by(id: lc_enrollment.hud_enrollment_id)
        next unless hud_enrollment

        create_entry_records(
          hud_enrollment,
          opens_on,
          sim_client: sim_client,
          project_type: ce_project.ProjectType,
        )
      end
    end

    def process_lifecycle_close_conditions(lifecycle_enrollment, date, lc_cfg:)
      return unless lc_cfg

      create_midterm_ce_event(lifecycle_enrollment, date)

      close_conditions = lc_cfg['close_conditions'] || {}

      if check_housing_move_in?(lifecycle_enrollment, date, close_conditions)
        close_lifecycle_enrollment(lifecycle_enrollment, date, reason: 'housing_move_in')
        return
      end

      if check_disengagement?(lifecycle_enrollment, date, close_conditions)
        close_lifecycle_enrollment(lifecycle_enrollment, date, reason: 'disengagement')
        return
      end

      return unless check_pre_entry_exit?(lifecycle_enrollment, date, close_conditions)

      close_lifecycle_enrollment(lifecycle_enrollment, date, reason: 'pre_entry_exit')
    end

    def check_housing_move_in?(lifecycle_enrollment, date, close_conditions)
      return false unless close_conditions.key?('housing_move_in')
      return false unless @schedule.housing_move_in_cohort?(
        id: lifecycle_enrollment.id,
        probability: close_conditions['housing_move_in'].to_f,
      )

      personal_id_subquery = Hmis::Hud::Client.
        where(id: lifecycle_enrollment.hud_client_id).
        select(:PersonalID)

      # Only close the CE on housing if the person is *currently* in a housing
      # placement that belongs to this CE episode. Without these guards, the CE
      # would close on any stale, already-ended move-in from an earlier journey
      # segment (e.g. rrh -> street re-entry opens a new CE that instantly matches
      # the old rrh placement's MoveInDate).
      #   - open_on_date(date): the placement must still be open today. A stale
      #     placement is always exited (the client left it before re-entering the
      #     trigger population), so this excludes it regardless of how far
      #     days_before_trigger backdates opens_on.
      #   - MoveInDate >= opens_on: the housing must have begun on/after this CE
      #     opened. Defense-in-depth for configs where an active placement could
      #     predate the episode (e.g. overlapping multi-track populations).
      e_t = Hmis::Hud::Enrollment.arel_table
      Hmis::Hud::Enrollment.
        open_on_date(date).
        where(data_source_id: @data_source_id, PersonalID: personal_id_subquery).
        where.not(MoveInDate: nil).
        where(e_t[:MoveInDate].gteq(lifecycle_enrollment.opens_on)).
        exists?
    end

    def check_disengagement?(lifecycle_enrollment, date, close_conditions)
      @schedule.timed_close_due?(
        cfg: close_conditions['disengagement'],
        opens_on: lifecycle_enrollment.opens_on,
        on_date: date,
        rng_prefix: 'lc_disengage',
        id: lifecycle_enrollment.id,
        default_days: 365,
      )
    end

    def check_pre_entry_exit?(lifecycle_enrollment, date, close_conditions)
      @schedule.timed_close_due?(
        cfg: close_conditions['pre_entry_exit'],
        opens_on: lifecycle_enrollment.opens_on,
        on_date: date,
        rng_prefix: 'lc_pre_exit',
        id: lifecycle_enrollment.id,
        default_days: 30,
      )
    end

    def close_lifecycle_enrollment(lifecycle_enrollment, date, reason:)
      enrollment = Hmis::Hud::Enrollment.find_by(id: lifecycle_enrollment.hud_enrollment_id)
      if enrollment
        Builders::ExitBuilder.new(
          enrollment: enrollment,
          exit_date: date,
          exit_destinations: { '116' => 1.0 },
          data_source: data_source,
          user_id: current_user_id,
          seed: @seed,
          context_prefix: "lifecycle_exit:#{lifecycle_enrollment.id}:#{date}",
        ).build!

        create_closing_ce_event(enrollment, date, reason: reason)
      end

      lifecycle_enrollment.update!(status: 'closed', close_reason: reason)
    end

    # -- Transition helpers --

    # Resolves the outgoing transitions config for +population_name+ and delegates the
    # weighted draw + timing sample to Schedule.
    def sample_enrollment_exit(population_name, date, client_id)
      @schedule.sample_exit(
        population_name: population_name,
        transitions: outgoing_transitions(population_name),
        context_prefix: "#{date}:#{client_id}",
      )
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

    def find_project_by_ref(project_ref)
      return nil if project_ref.blank?

      Hmis::Hud::Project.find_by(data_source_id: data_source.id, ProjectName: project_ref)
    end

    # -- Population and household template draws (per primary track) --

    def draw_entry_population_for_track(track, date:, index:)
      populations = track['populations'] || []
      candidates  = populations.select { |p| p['entry_point'].to_f.positive? }
      return nil if candidates.empty?

      weights = candidates.each_with_object({}) { |p, h| h[p['name']] = p['entry_point'].to_f }
      cfg     = { 'distribution' => 'weighted', 'weights' => weights }
      name    = @schedule.sample(cfg, context: "population:#{track['name']}:#{date}:#{index}")
      populations.find { |p| p['name'] == name }
    end

    def draw_household_template(population:, date:, index:)
      templates = population['household_templates'] || { 'adult_only' => 1.0 }
      cfg = { 'distribution' => 'weighted', 'weights' => templates }
      @schedule.sample(cfg, context: "template:#{date}:#{index}")
    end
  end
end
