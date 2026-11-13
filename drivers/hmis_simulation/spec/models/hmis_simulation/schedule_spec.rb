###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Schedule do
  let(:seed) { 12_345 }
  subject(:schedule) { described_class.new(seed: seed, record_miss_rate: 0.5) }

  describe '#seed_for' do
    it 'is the simulation seed plus the stable hash of the context' do
      expect(schedule.seed_for('entry:1')).to eq(seed + HmisSimulation::Hashing.stable_hash('entry:1'))
    end

    it 'is deterministic and context-specific' do
      expect(schedule.seed_for('a')).to eq(schedule.seed_for('a'))
      expect(schedule.seed_for('a')).not_to eq(schedule.seed_for('b'))
    end
  end

  describe '#chance?' do
    it 'never fires at probability 0 and always fires at probability 1' do
      expect(schedule.chance?(0.0, context: 'x')).to be(false)
      expect(schedule.chance?(1.0, context: 'x')).to be(true)
    end

    it 'is stable for a given (seed, context)' do
      expect(schedule.chance?(0.5, context: 'x')).to eq(schedule.chance?(0.5, context: 'x'))
    end

    it 'is independent across contexts and seeds' do
      other = described_class.new(seed: seed + 1)
      rolls = (1..200).map { |i| schedule.chance?(0.5, context: "ctx:#{i}") }
      expect(rolls.uniq).to contain_exactly(true, false) # both outcomes occur

      # A different seed produces a different roll for at least some contexts.
      differs = (1..50).any? { |i| schedule.chance?(0.5, context: "ctx:#{i}") != other.chance?(0.5, context: "ctx:#{i}") }
      expect(differs).to be(true)
    end
  end

  describe '#record_miss?' do
    it 'never misses when the rate is zero' do
      no_miss = described_class.new(seed: seed, record_miss_rate: 0)
      expect((1..100).map { |i| no_miss.record_miss?("ctx:#{i}") }).to all(be(false))
    end

    it 'always misses when the rate is one' do
      always = described_class.new(seed: seed, record_miss_rate: 1.0)
      expect((1..100).map { |i| always.record_miss?("ctx:#{i}") }).to all(be(true))
    end
  end

  describe '#annual_collection_due?' do
    let(:entry_date) { Date.new(2024, 1, 1) }
    let(:no_jitter) { { 'distribution' => 'constant', 'value' => 0 } }

    def due_on(on_date)
      schedule.annual_collection_due?(entry_date: entry_date, on_date: on_date, enrollment_id: 'E1', jitter_cfg: no_jitter)
    end

    it 'is not due before the first anniversary' do
      expect(due_on(entry_date + 300)).to be(false)
      expect(due_on(entry_date + 364)).to be(false)
    end

    it 'is due on the (jitter-free) first anniversary and not the days around it' do
      expect(due_on(entry_date + 365)).to be(true)
      expect(due_on(entry_date + 366)).to be(false)
    end

    it 'applies positive jitter, shifting the due date past the un-jittered anniversary' do
      jitter = { 'distribution' => 'constant', 'value' => 3 }
      due = ->(on) { schedule.annual_collection_due?(entry_date: entry_date, on_date: on, enrollment_id: 'E1', jitter_cfg: jitter) }

      # The un-jittered anniversary is no longer the due date...
      expect(due.call(entry_date + 365)).to be(false)
      # ...it has moved by the jitter amount. Day 368 also pins the floor (not ceil) of
      # year_number: under ceil this day would be treated as year 2 and never match.
      expect(due.call(entry_date + 368)).to be(true)
    end
  end

  describe '#cls_due?' do
    let(:entry_date) { Date.new(2024, 1, 1) }
    let(:freq_config) { { days: 90, jitter_stddev: 0 } }

    def due_on(on_date)
      schedule.cls_due?(entry_date: entry_date, on_date: on_date, enrollment_id: 'E1', freq_config: freq_config)
    end

    it 'is not due before half the frequency has elapsed' do
      expect(due_on(entry_date + 44)).to be(false)
    end

    it 'is due on the (jitter-free) frequency boundary' do
      expect(due_on(entry_date + 90)).to be(true)
      expect(due_on(entry_date + 89)).to be(false)
    end

    it 'applies jitter, moving some due dates off the un-jittered boundary' do
      jittered = { days: 90, jitter_stddev: 10 }
      offsets = (1..20).map do |eid|
        due_day = (entry_date + 60..entry_date + 120).find do |on|
          schedule.cls_due?(entry_date: entry_date, on_date: on, enrollment_id: "E#{eid}", freq_config: jittered)
        end
        due_day && (due_day - entry_date).to_i
      end.compact

      expect(offsets).not_to be_empty
      # With zero jitter every enrollment would be due exactly on day 90; non-zero stddev perturbs it.
      expect(offsets.uniq).not_to eq([90])
    end
  end

  describe '#timed_close_due?' do
    let(:cfg) { { 'probability' => 1.0, 'after_days' => { 'distribution' => 'constant', 'value' => 30 } } }
    let(:opens_on) { Date.new(2024, 1, 1) }

    it 'returns false when the condition is not configured' do
      expect(schedule.timed_close_due?(cfg: nil, opens_on: opens_on, on_date: opens_on, rng_prefix: 'lc_x', id: 1, default_days: 30)).to be(false)
    end

    it 'fires only once the configured delay has elapsed' do
      expect(schedule.timed_close_due?(cfg: cfg, opens_on: opens_on, on_date: opens_on + 29, rng_prefix: 'lc_x', id: 1, default_days: 30)).to be(false)
      expect(schedule.timed_close_due?(cfg: cfg, opens_on: opens_on, on_date: opens_on + 30, rng_prefix: 'lc_x', id: 1, default_days: 30)).to be(true)
    end
  end

  describe '#housing_move_in_cohort?' do
    it 'respects the degenerate probabilities' do
      expect(schedule.housing_move_in_cohort?(id: 1, probability: 0.0)).to be(false)
      expect(schedule.housing_move_in_cohort?(id: 1, probability: 1.0)).to be(true)
    end
  end

  describe '#exit_point?' do
    it 'short-circuits the degenerate probabilities' do
      expect(schedule.exit_point?(probability: 0.0, context: 'x')).to be(false)
      expect(schedule.exit_point?(probability: 1.0, context: 'x')).to be(true)
    end
  end

  describe '#sample_gap' do
    it 'is zero when no gap is configured' do
      expect(schedule.sample_gap(gap_cfg: nil, context: 'x')).to eq(0)
    end

    it 'samples and clamps a configured gap' do
      gap = schedule.sample_gap(gap_cfg: { 'distribution' => 'constant', 'value' => 5 }, context: 'x')
      expect(gap).to eq(5)
    end
  end

  describe '#sample_exit' do
    it 'falls back to (population, 30) with no transitions' do
      expect(schedule.sample_exit(population_name: 'A', transitions: [], context_prefix: '2024-01-01:1')).to eq(['A', 30])
    end

    it 'returns a configured destination and a timing of at least one day' do
      transitions = [{ 'to' => 'B', 'weight' => 1.0, 'timing' => { 'distribution' => 'constant', 'value' => 10 } }]
      next_pop, timing = schedule.sample_exit(population_name: 'A', transitions: transitions, context_prefix: '2024-01-01:1')
      expect(next_pop).to eq('B')
      expect(timing).to eq(10)
    end
  end

  describe '#daily_new_client_count' do
    def total_over(days, value)
      cfg = { 'distribution' => 'constant', 'value' => value }
      (1..days).sum { |i| schedule.daily_new_client_count(monthly_cfg: cfg, context: "spawn:#{i}") }
    end

    it 'returns a non-negative integer and is deterministic' do
      cfg = { 'distribution' => 'constant', 'value' => 30 }
      count = schedule.daily_new_client_count(monthly_cfg: cfg, context: 'spawn:2024-01-01')
      expect(count).to be_a(Integer)
      expect(count).to be >= 0
      expect(schedule.daily_new_client_count(monthly_cfg: cfg, context: 'spawn:2024-01-01')).to eq(count)
    end

    it 'scales a monthly rate down to a daily rate' do
      # 30/month ≈ 1/day → roughly 300 over 300 days. Skipping the /30 scaling would yield ~9000.
      expect(total_over(300, 30)).to be_between(200, 450)
    end

    it 'produces proportionally more clients for a larger monthly rate' do
      # 10x the monthly rate → roughly 10x the daily count; ignoring the config entirely would tie them.
      expect(total_over(300, 300)).to be > total_over(300, 30) * 5
    end
  end
end
