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
      candidates = build_candidates
      best_by_dq = {}

      candidates.each do |candidate|
        existing = best_by_dq[candidate.quality]
        best_by_dq[candidate.quality] = candidate if candidate_preferred?(existing, candidate)
      end

      ssn_dqs.each do |dq|
        return best_by_dq[dq] if best_by_dq[dq]
      end

      nil
    end

    def build_candidates
      @source_clients.filter_map { |source| build_candidate_from_source(source) }
    end

    def build_candidate_from_source(source)
      raw_dq = source[:SSNDataQuality]
      normalized_dq = coerce_dq(raw_dq)
      dq = normalized_dq
      dq = 99 unless dq&.in?(ssn_dqs)

      value = source[:SSN]&.strip.presence
      numeric = value&.gsub(/\D/, '').presence

      if normalized_dq.in?([1, 2])
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

      date = timestamp_for(source[:DateCreated])
      date_key =
        if date
          date
        else
          use_oldest? ? Float::INFINITY : -Float::INFINITY
        end
      date_key *= -1 unless use_oldest?

      tie_breakers = [dq, date_key, source[:id].to_i]

      byebug
      Candidate.new(value: value, quality: dq, tie_breakers: tie_breakers)
    end

    def normalize_source(client)
      base =
        if client.respond_to?(:with_indifferent_access)
          client.with_indifferent_access
        elsif client.respond_to?(:attributes)
          client.attributes.with_indifferent_access
        else
          client.to_h.with_indifferent_access
        end

      base[:SSNDataQuality] = base[:SSNDataQuality].presence || 99
      base
    end

    def timestamp_for(value)
      return unless value

      value = value.to_time if value.respond_to?(:to_time)
      value.to_i if value.respond_to?(:to_i)
    end

    def use_oldest?
      @use_oldest
    end

    def default_date_key
      use_oldest? ? Float::INFINITY : -Float::INFINITY
    end

    def ssn_dqs
      @ssn_dqs ||= HudHelper.util.ssn_data_quality_options.keys.sort
    end

    def coerce_dq(value)
      raw = value
      raw = raw.presence if raw.respond_to?(:presence)
      return unless raw

      return raw if raw.is_a?(Integer)

      Integer(raw, exception: false)
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
