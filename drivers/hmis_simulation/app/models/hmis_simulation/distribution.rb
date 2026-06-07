###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Stateless probability distribution sampler.
#
# Uses a caller-supplied RNG so each draw is independent — avoids the
# butterfly-effect problem where a single extra draw shifts all future
# results for unrelated entities.
#
# Usage:
#   rng = Random.new(simulation_seed + HmisSimulation::Hashing.stable_hash(context_string))
#   HmisSimulation::Distribution.sample(config, rng: rng)
#
# Supported distribution types:
#   constant  { distribution: constant, value: N }
#   uniform   { distribution: uniform, min: N, max: N }
#   normal    { distribution: normal, mean: N, stddev: N, min: N (opt), max: N (opt) }
#   poisson   { distribution: poisson, lambda: N }
#   weighted  { distribution: weighted, weights: { key => weight, ... } }
#             Numeric string keys (e.g. "101") are returned as integers.
#             Weights are relative — they are normalized internally.
module HmisSimulation
  class Distribution
    # Sample a value from the distribution described by +config+.
    # +rng+ must be a Random instance.
    def self.sample(config, rng:)
      type = config.fetch('distribution')

      case type.to_s
      when 'constant'
        config.fetch('value')

      when 'uniform'
        min = config.fetch('min').to_f
        max = config.fetch('max').to_f
        min + rng.rand * (max - min)

      when 'normal'
        mean   = config.fetch('mean').to_f
        stddev = config.fetch('stddev').to_f
        min    = config['min']&.to_f
        max    = config['max']&.to_f
        sample_normal(mean: mean, stddev: stddev, min: min, max: max, rng: rng)

      when 'poisson'
        lambda_val = config.fetch('lambda').to_f
        sample_poisson(lambda: lambda_val, rng: rng)

      when 'weighted'
        weights = config.fetch('weights')
        normalized = normalize_weights(weights)
        threshold = rng.rand
        cumulative = 0.0
        normalized.each do |key, prob|
          cumulative += prob
          return coerce_key(key) if threshold < cumulative
        end
        coerce_key(normalized.keys.last)

      else
        raise ArgumentError, "Unknown distribution type: #{type.inspect}"
      end
    end

    # Normalize a weights hash so values sum to 1.0.
    # Raises ArgumentError if all weights are zero.
    def self.normalize_weights(weights)
      weights = weights.transform_keys(&:to_s).transform_values(&:to_f)
      total = weights.values.sum
      raise ArgumentError, "weights must have at least one positive value (got #{weights.inspect})" if total.zero?

      weights.transform_values { |w| w / total }
    end

    # -- private helpers --

    def self.sample_normal(mean:, stddev:, min:, max:, rng:)
      # Box-Muller transform
      100.times do
        u1 = rng.rand
        u2 = rng.rand
        z  = Math.sqrt(-2.0 * Math.log([u1, Float::EPSILON].max)) * Math.cos(2 * Math::PI * u2)
        v  = mean + stddev * z
        next if min && v < min
        next if max && v > max

        return v
      end
      # Fallback: return mean clipped to bounds
      [[mean, min].compact.max, max].compact.min
    end
    private_class_method :sample_normal

    def self.sample_poisson(lambda:, rng:)
      return 0 if lambda <= 0
      raise ArgumentError, "lambda too large for Knuth algorithm (#{lambda}; max 100)" if lambda > 100

      # Knuth algorithm
      l = Math.exp(-lambda)
      k = 0
      p = 1.0
      loop do
        k += 1
        p *= rng.rand
        break if p <= l
      end
      k - 1
    end
    private_class_method :sample_poisson

    def self.coerce_key(key)
      Integer(key)
    rescue ArgumentError, TypeError
      key
    end
    private_class_method :coerce_key
  end
end
