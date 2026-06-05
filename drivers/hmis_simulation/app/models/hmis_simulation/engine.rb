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
          @clients_created = 0

          spawn_clients(date: date)

          log.update!(
            clients_created: @clients_created,
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
