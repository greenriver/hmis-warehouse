###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Distribution do
  let(:seed) { 42 }

  def rng(context)
    Random.new(seed + HmisSimulation::Hashing.stable_hash(context))
  end

  describe '.sample' do
    context 'constant distribution' do
      let(:config) { { 'distribution' => 'constant', 'value' => 7 } }

      it 'always returns the configured value' do
        results = 10.times.map { described_class.sample(config, rng: rng('ctx')) }
        expect(results.uniq).to eq([7])
      end
    end

    context 'uniform distribution' do
      let(:config) { { 'distribution' => 'uniform', 'min' => 5, 'max' => 10 } }

      it 'returns values within [min, max]' do
        results = 100.times.map { |i| described_class.sample(config, rng: rng("ctx#{i}")) }
        expect(results.min).to be >= 5
        expect(results.max).to be <= 10
      end
    end

    context 'normal distribution' do
      let(:config) { { 'distribution' => 'normal', 'mean' => 50, 'stddev' => 10, 'min' => 20, 'max' => 80 } }

      it 'returns values within [min, max]' do
        results = 200.times.map { |i| described_class.sample(config, rng: rng("ctx#{i}")) }
        expect(results.min).to be >= 20
        expect(results.max).to be <= 80
      end

      it 'clusters around the mean' do
        results = 500.times.map { |i| described_class.sample(config, rng: rng("ctx#{i}")) }
        expect(results.sum.to_f / results.size).to be_within(5).of(50)
      end
    end

    context 'normal distribution without min/max' do
      let(:config) { { 'distribution' => 'normal', 'mean' => 30, 'stddev' => 5 } }

      it 'returns numeric values' do
        result = described_class.sample(config, rng: rng('ctx'))
        expect(result).to be_a(Numeric)
      end
    end

    context 'poisson distribution' do
      let(:config) { { 'distribution' => 'poisson', 'lambda' => 8 } }

      it 'returns non-negative integers' do
        results = 100.times.map { |i| described_class.sample(config, rng: rng("ctx#{i}")) }
        expect(results).to all(be_a(Integer))
        expect(results).to all(be >= 0)
      end

      it 'has mean approximately equal to lambda' do
        results = 500.times.map { |i| described_class.sample(config, rng: rng("ctx#{i}")) }
        expect(results.sum.to_f / results.size).to be_within(1.5).of(8)
      end
    end

    context 'weighted distribution' do
      let(:config) { { 'distribution' => 'weighted', 'weights' => { 'a' => 3, 'b' => 1 } } }

      it 'returns only defined keys' do
        results = 100.times.map { |i| described_class.sample(config, rng: rng("ctx#{i}")) }
        expect(results.uniq.sort).to eq(['a', 'b'])
      end

      it 'selects proportionally to weights' do
        results = 1000.times.map { |i| described_class.sample(config, rng: rng("ctx#{i}")) }
        ratio = results.count('a').to_f / results.count('b')
        expect(ratio).to be_within(0.5).of(3.0)
      end
    end

    context 'weighted distribution with numeric keys' do
      let(:config) { { 'distribution' => 'weighted', 'weights' => { '101' => 0.5, '116' => 0.3, '17' => 0.2 } } }

      it 'returns integer versions of numeric string keys' do
        results = 100.times.map { |i| described_class.sample(config, rng: rng("ctx#{i}")) }
        expect(results.uniq.sort).to eq([17, 101, 116])
      end
    end

    context 'unknown distribution type' do
      let(:config) { { 'distribution' => 'magic' } }

      it 'raises ArgumentError' do
        expect { described_class.sample(config, rng: rng('ctx')) }.to raise_error(ArgumentError, /unknown distribution/i)
      end
    end
  end

  describe '.normalize_weights' do
    it 'converts absolute values to probabilities summing to 1.0' do
      normalized = described_class.normalize_weights({ 'a' => 3, 'b' => 1 })
      expect(normalized['a']).to be_within(0.001).of(0.75)
      expect(normalized['b']).to be_within(0.001).of(0.25)
    end

    it 'handles already-normalized values' do
      normalized = described_class.normalize_weights({ 'x' => 0.6, 'y' => 0.4 })
      expect(normalized['x']).to be_within(0.001).of(0.6)
    end

    it 'raises ArgumentError when all weights are zero' do
      expect { described_class.normalize_weights({ 'a' => 0, 'b' => 0 }) }.to raise_error(ArgumentError, /weights/i)
    end
  end
end
