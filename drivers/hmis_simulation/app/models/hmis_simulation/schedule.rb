###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Deterministic, seed-driven scheduling and probability decisions for the simulation.
  #
  # This is the simulation's source of randomness. It is pure: it depends only on the
  # seed, config fragments, and dates — never on the database or on orchestration state.
  # Every roll is stable for a given (seed, context) pair, so re-running a date reproduces
  # exactly the same decisions, and the same enrollment always rolls the same way.
  #
  # The Engine delegates here for three things:
  #   - "is X due / should X happen" decisions (#annual_collection_due?, #cls_due?, …)
  #   - seeded sampling and bernoulli rolls (#sample, #chance?)
  #   - integer seeds handed to builders that do their own sampling (#seed_for)
  #
  # Context strings are part of the reproducibility contract — changing one re-seeds that
  # roll and changes generated data. Treat them as you would a migration.
  class Schedule
    include HmisSimulation::Hashing

    def initialize(seed:, record_miss_rate: 0)
      @seed = seed
      @record_miss_rate = record_miss_rate.to_f
    end

    # -- Seeded primitives --

    # Deterministic integer seed for a context. Hand this to builders that take +rng_seed:+
    # and do their own sampling internally.
    def seed_for(context)
      @seed + stable_hash(context)
    end

    # Samples +cfg+ (a Distribution config hash) with a Random seeded from +context+.
    def sample(cfg, context:)
      Distribution.sample(cfg, rng: rng(context))
    end

    # Returns true with the given +probability+ (0–1), using a Random seeded from +context+.
    def chance?(probability, context:)
      rng(context).rand < probability
    end

    # -- Data quality --

    # Returns true with probability record_miss_rate (from global data_quality config).
    # Deterministic per context, so the same enrollment+stage always produces the same result.
    def record_miss?(context_suffix)
      return false if @record_miss_rate.zero?

      chance?(@record_miss_rate, context: "miss:#{context_suffix}")
    end

    # -- "Is it due?" decisions --

    # True when an annual record is due on +on_date+.
    # Uses floor (not ceil) so that positive jitter extending the year-1 window past day 365
    # is handled correctly — year_number stays at 1 until the second anniversary crosses.
    def annual_collection_due?(entry_date:, on_date:, enrollment_id:, jitter_cfg:)
      days_enrolled = (on_date - entry_date).to_i
      return false if days_enrolled < 300

      year_number = (days_enrolled / 365.0).floor
      return false if year_number < 1

      jitter = sample(jitter_cfg.deep_stringify_keys, context: "annual_jitter:#{enrollment_id}:#{year_number}").round
      expected_date = entry_date + (365 * year_number) + jitter
      on_date == expected_date
    end

    # True when a periodic CLS record is due on +on_date+ for the given frequency config
    # (a Hash with :days and :jitter_stddev, from ComplianceRules.cls_frequency).
    def cls_due?(entry_date:, on_date:, enrollment_id:, freq_config:)
      days_enrolled = (on_date - entry_date).to_i
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
      jitter = sample(jitter_cfg, context: "cls_jitter:#{enrollment_id}:#{n}").round
      expected = entry_date + (frequency * n) + jitter
      on_date == expected
    end

    # True when a timed lifecycle close condition (disengagement / pre-entry exit) fires:
    # the client is in the closing cohort (per-client probability roll) and enough days
    # have elapsed since +opens_on+. +rng_prefix+ and +id+ form the stable context.
    def timed_close_due?(cfg:, opens_on:, on_date:, rng_prefix:, id:, default_days:)
      return false unless cfg.present?
      return false unless chance?(cfg['probability'].to_f, context: "#{rng_prefix}_prob:#{id}")

      after_days_cfg = (cfg['after_days'] || { 'distribution' => 'constant', 'value' => default_days }).deep_stringify_keys
      after_days = sample(after_days_cfg, context: "#{rng_prefix}_days:#{id}").ceil
      on_date >= opens_on + after_days
    end

    # Stable per-client roll deciding whether a lifecycle enrollment is in the cohort that
    # closes via housing move-in. Seeded without a date so the result is the same every tick.
    def housing_move_in_cohort?(id:, probability:)
      chance?(probability, context: "lc_housing_move_in:#{id}")
    end

    # -- Sampling decisions --

    # Decides whether a client exits the system at a transition point. Returns false/true
    # immediately for the degenerate 0 / ≥1 probabilities (no roll consumed).
    def exit_point?(probability:, context:)
      return false if probability.zero?
      return true if probability >= 1.0

      chance?(probability, context: context)
    end

    # Picks the next population and the timing (days until transition) for an exit.
    # +transitions+ is the list of outgoing transitions for +population_name+; timing is
    # clamped to at least 1 day. Falls back to (population_name, 30) when there are none.
    def sample_exit(population_name:, transitions:, context_prefix:)
      return [population_name, 30] if transitions.empty?

      weights  = transitions.each_with_object({}) { |t, h| h[t['to']] = t['weight'].to_f }
      next_pop = sample({ 'distribution' => 'weighted', 'weights' => weights }, context: "next_pop:#{context_prefix}")
      transition = transitions.find { |t| t['to'] == next_pop }
      timing_days = if transition
        sample(transition['timing'].deep_stringify_keys, context: "timing:#{context_prefix}").ceil
      else
        30
      end
      [next_pop, [timing_days, 1].max]
    end

    # Days to wait before the next enrollment, drawn from a transition's gap config.
    def sample_gap(gap_cfg:, context:)
      return 0 unless gap_cfg.present?

      sample(gap_cfg.deep_stringify_keys, context: context).ceil.clamp(0, 365)
    end

    # Number of new clients to spawn on a given day, scaling a monthly rate down to daily.
    def daily_new_client_count(monthly_cfg:, context:)
      monthly_cfg ||= { 'distribution' => 'poisson', 'lambda' => 1 }
      daily_cfg = scale_to_daily(monthly_cfg.deep_stringify_keys)
      count = sample(daily_cfg, context: context).to_f
      [count.ceil, 0].max
    end

    private

    # Returns a deterministic Random seeded from the simulation seed + a stable context string.
    # Uses stable_hash (SHA-256-based) rather than String#hash to guarantee consistent seeds
    # across Ruby process restarts.
    def rng(context)
      Random.new(seed_for(context))
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
  end
end
