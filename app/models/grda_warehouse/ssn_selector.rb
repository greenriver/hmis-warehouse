###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  # Determines the preferred SSN and SSN data quality from a set of source
  # client records. This extraction allows consumers beyond the client cleanup
  # task to evaluate the impact of the enhanced selection algorithm without
  # mutating persisted records.
  class SSNSelector
    Candidate = Struct.new(:value, :quality, :tie_breakers, keyword_init: true)

    def self.call(dest_attr:, source_clients:, use_oldest: true)
      new(dest_attr: dest_attr, source_clients: source_clients, use_oldest: use_oldest).call
    end

    def initialize(dest_attr:, source_clients:, use_oldest: true)
      @dest_attr = dest_attr.with_indifferent_access
      @source_clients = Array.wrap(source_clients).map { |client| normalize_source(client) }
      @use_oldest = use_oldest
    end

    def call
      best = select_best_candidate
      if best
        @dest_attr[:SSN] = best.value
        @dest_attr[:SSNDataQuality] = best.quality
      else
        @dest_attr[:SSN] = nil
        @dest_attr[:SSNDataQuality] = 99
      end
      @dest_attr
    end

    private

    def select_best_candidate
      @source_clients.
        filter_map { |source| build_candidate_from_source(source) }.
        min_by(&:tie_breakers)
    end

    def build_candidate_from_source(source)
      raw_dq = source[:SSNDataQuality]
      initial_dq = coerce_dq(raw_dq)
      dq = initial_dq
      dq = 99 unless dq&.in?(ssn_dqs)

      value = source[:SSN]&.strip.presence
      numeric = value&.gsub(/\D/, '').presence

      if initial_dq.in?([1, 2])
        if numeric.nil?
          dq = 99
          value = nil
        elsif numeric.length != 9
          dq = 2
        elsif dq == 1 && !HudHelper.util.valid_social?(numeric)
          dq = 2
        end
      end

      return unless value

      date_key = timestamp_for(source[:DateCreated])

      tie_breakers = [dq, date_key, source_identifier_for(source)]

      Candidate.new(value: value, quality: dq, tie_breakers: tie_breakers)
    end

    def normalize_source(client)
      base =
        case client
        when ActiveSupport::HashWithIndifferentAccess
          client
        when Hash
          client.with_indifferent_access
        when ActiveRecord::Base
          client.attributes.with_indifferent_access
        else
          raise ArgumentError, "Unsupported source client: #{client.class.name}"
        end

      base[:SSNDataQuality] = base[:SSNDataQuality].presence || 99
      base
    end

    def timestamp_for(value)
      timestamp =
        case value
        when nil, ''
          nil
        when Time, DateTime, ActiveSupport::TimeWithZone
          value.to_i
        when Date
          value.to_time.to_i
        else
          raise ArgumentError, "invalid timestamp #{value.inspect}"
        end

      timestamp ||= default_date_key
      timestamp *= -1 unless use_oldest?
      timestamp
    end

    def use_oldest?
      @use_oldest
    end

    def default_date_key
      use_oldest? ? Float::INFINITY : -Float::INFINITY
    end

    def source_identifier_for(source)
      raw = source[:id]
      return Float::INFINITY if raw.blank?

      coerced = Integer(raw, exception: false)
      coerced || Float::INFINITY
    end

    def ssn_dqs
      @ssn_dqs ||= HudHelper.util.ssn_data_quality_options.keys.sort
    end

    def coerce_dq(value)
      return if value.blank?

      return value if value.is_a?(Integer)

      Integer(value, exception: false)
    end

    def candidate_preferred?(existing, candidate)
      return true unless existing

      # Compare the new candidate against the current best using the primary data
      # quality followed by our tie-breaker ordering (date, then id). We only
      # take the new candidate when it sorts ahead of the existing one.
      (candidate.tie_breakers <=> existing.tie_breakers).negative?
    end
  end
end
