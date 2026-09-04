###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  # Determines the preferred DOB and DOB data quality from a set of source
  # client records. Parallels GrdaWarehouse::SSNSelector, but judges validity by
  # comparing the DOB against the source record's own DateCreated rather than by
  # inspecting the value's shape.
  #
  # Candidates are ranked on, in order:
  #   1. DOBDataQuality (lower is better)
  #   2. Validity (a possible DOB beats an impossible one at the same quality)
  #   3. Record timestamp (DateCreated), configurable to prefer oldest or newest
  #   4. Record ID (lower is better)
  #
  # A DOB is impossible when it falls after its record's DateCreated, or more
  # than MAX_AGE_IN_YEARS before it. An impossible DOB reported as full or
  # approximate is demoted to approximate; the value itself is always kept so a
  # mistyped date is not silently discarded.
  class DOBSelector
    MAX_AGE_IN_YEARS = 150

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
        @dest_attr[:DOB] = best.value
        @dest_attr[:DOBDataQuality] = best.quality
      else
        @dest_attr[:DOB] = nil
        @dest_attr[:DOBDataQuality] = 99
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
      value = source[:DOB]
      value = value.strip if value.is_a?(String)
      return if value.blank?

      initial_dq = coerce_dq(source[:DOBDataQuality])
      dq = initial_dq
      dq = 99 unless dq&.in?(dob_dqs)

      created_at = created_time_for(source[:DateCreated])
      invalid = invalid_dob?(value, created_at || Time.current)
      dq = 2 if invalid && dq.in?([1, 2])

      tie_breakers = [
        dq,
        invalid ? 1 : 0,
        date_key_for(created_at),
        source_identifier_for(source),
      ]

      Candidate.new(value: value, quality: dq, tie_breakers: tie_breakers)
    end

    def invalid_dob?(value, reference)
      dob = value.to_date
      reference_date = reference.to_date

      dob > reference_date || dob < reference_date - MAX_AGE_IN_YEARS.years
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

      base[:DOBDataQuality] = base[:DOBDataQuality].presence || 99
      base
    end

    def created_time_for(value)
      case value
      when nil, ''
        nil
      when Time, DateTime, ActiveSupport::TimeWithZone
        value
      when Date
        value.to_time
      else
        raise ArgumentError, "invalid timestamp #{value.inspect}"
      end
    end

    def date_key_for(created_at)
      timestamp = created_at&.to_i
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

    def dob_dqs
      @dob_dqs ||= HudHelper.util.dob_data_quality_options.keys.sort
    end

    def coerce_dq(value)
      return if value.blank?

      return value if value.is_a?(Integer)

      Integer(value, exception: false)
    end
  end
end
