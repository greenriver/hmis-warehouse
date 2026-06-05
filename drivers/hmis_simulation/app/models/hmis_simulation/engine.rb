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
  #   1. Spawn new clients (drawn from new_clients_per_month, scaled to daily)
  #   2. (Phase 4) Process primary enrollment exits and entries
  #   3. (Phase 5) Annual record collection (IncomeBenefits etc.)
  #   4. (Phase 6) Concurrent enrollment tick
  #   5. (Phase 7) Lifecycle enrollment tick
  #   6. Write RunLog
  #
  # Idempotent: re-running the same date is a no-op (detected via RunLog).
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
    end

    def run(date:)
      return if already_run?(date)

      log = RunLog.create!(
        data_source_id: @data_source_id,
        run_date: date,
        started_at: Time.current,
        clients_created: 0,
      )

      begin
        Hmis::Hud::Base.transaction do
          @clients_created     = 0
          @enrollments_opened  = 0
          @enrollments_closed  = 0
          @services_created    = 0

          spawn_clients(date: date)
          tick_primary(date: date)
          tick_annual_collections(date: date)

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

    private

    def already_run?(date)
      RunLog.exists?(data_source_id: @data_source_id, run_date: date, error_message: nil)
    end

    # -- Spawn --

    def spawn_clients(date:)
      count = daily_new_client_count(date: date)
      data_source = GrdaWarehouse::DataSource.find(@data_source_id)
      user_id     = Hmis::Hud::User.system_user(data_source_id: @data_source_id).user_id

      count.times do |i|
        population = draw_entry_population(date: date, index: i)
        next unless population

        template_name = draw_household_template(population: population, date: date, index: i)
        template_cfg  = @config.dig('household_templates', template_name) || {}

        result = Builders::HouseholdBuilder.new(
          household_template: template_cfg,
          household_template_name: template_name,
          data_quality_config: @config['data_quality'] || {},
          data_source: data_source,
          user_id: user_id,
          date: date,
          seed: @seed,
          context_prefix: "spawn:#{date}:#{i}",
        ).build!

        Client.create!(
          data_source_id: @data_source_id,
          hud_client_id: result[:hoh_id],
          household_group_id: result[:household_group_id],
          current_population: population['name'],
          entered_current_population_at: date,
          pending_enrollment_on: date,
          exited_system: false,
        )

        @clients_created += 1
      end
    end

    # -- Primary enrollment tick --

    def tick_primary(date:)
      data_source = GrdaWarehouse::DataSource.find(@data_source_id)
      user_id     = Hmis::Hud::User.system_user(data_source_id: @data_source_id).user_id

      # Process exits for clients whose enrollment ends today
      Client.pending_exit(date).where(data_source_id: @data_source_id).find_each do |sim_client|
        process_primary_exit(sim_client, date, data_source: data_source, user_id: user_id)
      end

      # Create enrollments for clients entering a program today
      Client.pending_enrollment(date).where(data_source_id: @data_source_id).find_each do |sim_client|
        process_primary_entry(sim_client, date, data_source: data_source, user_id: user_id)
      end

      # Generate bed nights for all active NBN enrollments
      create_bed_nights(date, data_source: data_source, user_id: user_id)
    end

    def process_primary_exit(sim_client, date, data_source:, user_id:)
      enrollment = Hmis::Hud::Enrollment.find(sim_client.hud_enrollment_id)
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
      create_linked_exit_records(enrollment, date, data_source: data_source, user_id: user_id)

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
        next_pop_name = sim_client.next_population || draw_next_population(sim_client.current_population, date, sim_client.id)
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
      cohesion = @config.dig('enrollment_config', 'household_cohesion_probability').to_f
      cohesion = 0.85 if cohesion.zero?

      hud_household_id = FakeIdentifier.uuid
      result = Builders::EnrollmentBuilder.new(
        project: project,
        hud_household_id: hud_household_id,
        entry_date: date,
        coc_code: @config.dig('coc_codes', 'primary') || 'XX-500',
        hoh_client: hoh_client,
        member_relationships: members,
        household_cohesion_probability: cohesion,
        data_source: data_source,
        user_id: user_id,
        rng_seed: @seed + "entry:#{date}:#{sim_client.id}".hash,
      ).build!

      @enrollments_opened += 1
      create_linked_entry_records(result[:hoh_enrollment], date, data_source: data_source, user_id: user_id, sim_client: sim_client)

      # Pre-select the outgoing transition and sample enrollment length
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

    def create_linked_entry_records(enrollment, date, data_source:, user_id:, sim_client:)
      rng_seed = @seed + "linked:#{enrollment.EnrollmentID}".hash
      disability_cfg = @config.dig('enrollment_config', 'disabilities') || {}
      income_cfg     = @config.dig('enrollment_config', 'income_at_entry') || {}
      hdv_cfg        = @config.dig('enrollment_config', 'health_and_dv') || {}

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

      # CLS at entry for street/shelter populations
      population_cfg = find_population(sim_client.current_population)
      return unless population_cfg&.dig('project_ref').present?

      project = find_project_by_ref(population_cfg['project_ref'], data_source: data_source)
      cls_code = cls_situation_code_for(project)
      return unless cls_code

      Builders::ClsBuilder.new(
        enrollment: enrollment,
        date: date,
        situation_code: cls_code,
        data_source: data_source,
        user_id: user_id,
      ).build!
    end

    def create_linked_exit_records(enrollment, exit_date, data_source:, user_id:)
      income_cfg = @config.dig('enrollment_config', 'income_at_entry') || {}
      Builders::IncomeBenefitBuilder.new(
        enrollment: enrollment,
        date: exit_date,
        stage: :exit,
        income_config: income_cfg,
        data_source: data_source,
        user_id: user_id,
        rng_seed: @seed + "exit_income:#{enrollment.EnrollmentID}".hash,
      ).build!
    end

    # -- Annual collection tick --

    def tick_annual_collections(date:)
      annual_cfg = @config.dig('enrollment_config', 'annual_collection') || {}
      miss_rate  = annual_cfg['miss_rate'].to_f
      jitter_cfg = annual_cfg['timing_jitter'] || { 'distribution' => 'normal', 'mean' => 0, 'stddev' => 30, 'min' => -90, 'max' => 90 }

      data_source = GrdaWarehouse::DataSource.find(@data_source_id)
      user_id     = Hmis::Hud::User.system_user(data_source_id: @data_source_id).user_id
      income_cfg  = @config.dig('enrollment_config', 'income_at_entry') || {}

      Hmis::Hud::Enrollment.
        where(data_source_id: @data_source_id).
        open_on_date(date).
        find_each do |enrollment|
          next unless annual_collection_due?(enrollment, date, jitter_cfg)
          next if Random.new(@seed + "annual_miss:#{enrollment.EnrollmentID}:#{date}".hash).rand < miss_rate

          Builders::IncomeBenefitBuilder.new(
            enrollment: enrollment,
            date: date,
            stage: :annual,
            income_config: income_cfg,
            data_source: data_source,
            user_id: user_id,
            rng_seed: @seed + "annual:#{enrollment.EnrollmentID}:#{date}".hash,
          ).build!
        end
    end

    def annual_collection_due?(enrollment, date, jitter_cfg)
      days_enrolled = (date - enrollment.EntryDate).to_i
      return false if days_enrolled < 300

      year_number = (days_enrolled / 365.0).ceil
      jitter = Distribution.sample(
        jitter_cfg.deep_stringify_keys,
        rng: Random.new(@seed + "annual_jitter:#{enrollment.EnrollmentID}:#{year_number}".hash),
      ).round
      expected_date = enrollment.EntryDate + (365 * year_number) + jitter
      date == expected_date
    end

    def cls_situation_code_for(project)
      return nil unless project

      case project.ProjectType
      when 1, 0 then 101  # Emergency shelter
      when 4    then 116  # Street outreach
      end
    end

    # -- Transition helpers --

    def sample_enrollment_exit(population_name, date, client_id)
      transitions = outgoing_transitions(population_name)
      return [population_name, 30] if transitions.empty?

      weights = transitions.each_with_object({}) { |t, h| h[t['to']] = t['weight'].to_f }
      cfg     = { 'distribution' => 'weighted', 'weights' => weights }
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

    def draw_next_population(from_population, date, client_id)
      transitions = outgoing_transitions(from_population)
      return from_population if transitions.empty?

      weights = transitions.each_with_object({}) { |t, h| h[t['to']] = t['weight'].to_f }
      cfg = { 'distribution' => 'weighted', 'weights' => weights }
      Distribution.sample(cfg, rng: rng("next_pop_fallback:#{date}:#{client_id}"))
    end

    def outgoing_transitions(population_name)
      (@config['transitions'] || []).select { |t| t['from'] == population_name }
    end

    def find_transition(from, to)
      return nil unless from.present? && to.present?

      (@config['transitions'] || []).find { |t| t['from'] == from && t['to'] == to }
    end

    def find_population(name)
      (@config['populations'] || []).find { |p| p['name'] == name }
    end

    def find_project_by_ref(project_ref, data_source:)
      return nil if project_ref.blank?

      Hmis::Hud::Project.find_by(data_source_id: data_source.id, ProjectName: project_ref)
    end

    # -- Daily count --

    def daily_new_client_count(date:)
      monthly_cfg = @config.dig('enrollment_config', 'new_clients_per_month') ||
                    { 'distribution' => 'poisson', 'lambda' => 1 }
      daily_cfg = scale_to_daily(monthly_cfg.deep_stringify_keys)
      count = Distribution.sample(daily_cfg, rng: rng("spawn_count:#{date}")).to_f
      [count.ceil, 0].max
    end

    def scale_to_daily(monthly_cfg)
      case monthly_cfg['distribution']
      when 'poisson'
        monthly_cfg.merge('lambda' => monthly_cfg['lambda'].to_f / 30.0)
      when 'constant'
        { 'distribution' => 'poisson', 'lambda' => monthly_cfg['value'].to_f / 30.0 }
      when 'uniform'
        monthly_cfg.merge(
          'min' => monthly_cfg['min'].to_f / 30.0,
          'max' => monthly_cfg['max'].to_f / 30.0,
        )
      else
        monthly_cfg
      end
    end

    def draw_entry_population(date:, index:)
      populations = @config['populations'] || []
      candidates  = populations.select { |p| p['entry_point'].to_f.positive? }
      return nil if candidates.empty?

      weights = candidates.each_with_object({}) { |p, h| h[p['name']] = p['entry_point'].to_f }
      cfg     = { 'distribution' => 'weighted', 'weights' => weights }
      name    = Distribution.sample(cfg, rng: rng("population:#{date}:#{index}"))
      populations.find { |p| p['name'] == name }
    end

    def draw_household_template(population:, date:, index:)
      templates = population['household_templates'] || { 'adult_only' => 1.0 }
      cfg = { 'distribution' => 'weighted', 'weights' => templates }
      Distribution.sample(cfg, rng: rng("template:#{date}:#{index}"))
    end

    def rng(context)
      Random.new(@seed + context.hash)
    end
  end
end
