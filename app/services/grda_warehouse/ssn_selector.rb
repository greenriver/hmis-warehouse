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
    def self.call(dest_attr:, source_clients:, use_oldest: true)
      new(dest_attr: dest_attr, source_clients: source_clients, use_oldest: use_oldest).call
    end

    def initialize(dest_attr:, source_clients:, use_oldest: true)
      @dest_attr = dest_attr.with_indifferent_access
      @source_clients = Array.wrap(source_clients).map { |client| normalize_source(client) }
      @use_oldest = use_oldest
    end

    def call
      best_by_dq = {}

      @source_clients.each do |source|
        dq = source[:SSNDataQuality]
        dq = 99 unless dq&.in?(ssn_dqs)

        value = source[:SSN]&.strip.presence
        numeric = value&.gsub(/\D/, '').presence

        if dq.between?(1, 2)
          if numeric.nil?
            dq = 99
            value = nil
          elsif numeric.length != 9
            dq = 2
          end
        elsif numeric
          dq = 2
        end

        next unless value

        date_key = timestamp_for(source[:DateCreated]) || default_date_key
        date_key *= -1 unless use_oldest?

        tie_breakers = [source[:SSNDataQuality] || 99, date_key, source[:id].to_i]
        existing = best_by_dq[dq]
        best_by_dq[dq] = { value: value, keys: tie_breakers } if existing.nil? || (tie_breakers <=> existing[:keys]).negative?
      end

      ssn_dqs.each do |dq|
        candidate = best_by_dq[dq]
        next unless candidate

        @dest_attr[:SSN] = candidate[:value]
        @dest_attr[:SSNDataQuality] = dq
        return @dest_attr
      end

      @dest_attr[:SSN] = nil
      @dest_attr[:SSNDataQuality] = 99
      @dest_attr
    end

    private

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
      base[:DateCreated] ||= default_date_fallback
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

    def default_date_fallback
      @default_date_fallback ||= 10.years.ago
    end
  end
end
