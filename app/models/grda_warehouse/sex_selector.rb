###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  # Determines the preferred Sex value from a set of source client records.
  # This service object encapsulates the business rules for selecting the best
  # available Sex value based on a multi-level sorting algorithm.
  #
  # The selection process prioritizes candidates based on the following criteria
  # in order:
  #   1. Sex value preference (0 or 1 preferred over 8, 9, 99)
  #   2. Record timestamp (DateUpdated), preferring most recent
  #   3. Record ID (lower is better)
  #
  # Valid Sex values:
  #   0 => Female
  #   1 => Male
  #   8 => Client doesn't know
  #   9 => Client prefers not to answer
  #   99 => Data not collected
  #
  # This class handles data normalization for various source data formats
  # (e.g., Hashes, ActiveRecord objects). The goal is to provide a consistent
  # and reliable way to determine the most trustworthy Sex value from potentially
  # conflicting source data.
  class SexSelector
    Candidate = Struct.new(:value, :tie_breakers, keyword_init: true)

    def self.call(dest_attr:, source_clients:, use_oldest: false)
      new(dest_attr: dest_attr, source_clients: source_clients, use_oldest: use_oldest).call
    end

    def initialize(dest_attr:, source_clients:, use_oldest: false)
      @dest_attr = dest_attr.with_indifferent_access
      @source_clients = Array.wrap(source_clients).map { |client| normalize_source(client) }
      @use_oldest = use_oldest
    end

    def call
      best = select_best_candidate
      @dest_attr[:Sex] = best.value if best
      @dest_attr
    end

    private

    def select_best_candidate
      @source_clients.
        filter_map { |source| build_candidate_from_source(source) }.
        min_by(&:tie_breakers)
    end

    def build_candidate_from_source(source)
      value = source[:Sex]
      return unless value.present?

      coerced_value = coerce_value(value)
      return unless coerced_value
      return unless coerced_value.in?(valid_sex_values)

      date_key = timestamp_for(source[:DateUpdated])

      # Prefer 0 or 1 (Female/Male) over 8, 9, 99
      # Lower priority number = higher preference
      priority = if coerced_value.in?([0, 1])
        0
      else
        1
      end

      tie_breakers = [priority, date_key, source_identifier_for(source)]

      Candidate.new(value: coerced_value, tie_breakers: tie_breakers)
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

    def valid_sex_values
      @valid_sex_values ||= HudHelper.util('2026').sexes.keys.sort
    end

    def coerce_value(value)
      return if value.blank?

      return value if value.is_a?(Integer)

      Integer(value, exception: false)
    end
  end
end
