###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module
  CoreDemographicsReport::RaceCalculations
  extend ActiveSupport::Concern
  included do
    # Generates a hash of detail reports for race data
    # @return [Hash] A hash containing report configurations for different race categories
    def race_detail_hash
      {}.tap do |hashes|
        race_buckets.each do |key, title|
          hashes["race_#{key}"] = {
            title: "Race - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_race(key)).distinct },
          }
        end
      end
    end

    # Defines the available race categories including special cases for unknown/missing data
    # @return [Hash] A hash mapping race keys to their display titles
    def race_buckets
      @race_buckets ||= ::HudUtility2024.races(multi_racial: true).merge(unknown_race_buckets).except('RaceNone')
    end

    # Defines special categories for unknown or missing race data
    # @return [Hash] A hash mapping special case keys to their display titles
    private def unknown_race_buckets
      {
        'Does Not Know' => 'Does Not Know',
        'Prefers not to answer' => 'Prefers not to answer',
        'Not Collected' => 'Data not collected',
      }
    end

    # Counts the number of clients with a specific race
    # @param type [String] The race type to count
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Integer] The count of clients with the specified race, masked if population is small
    def race_count(type, coc_code = base_count_sym)
      mask_small_population(client_ids_in_race(type, coc_code)&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific race
    # @param type [String] The race type to calculate percentage for
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Float] The percentage of clients with the specified race
    def race_percentage(type, coc_code = base_count_sym)
      total_count = mask_small_population(client_races[coc_code].count)
      return 0 if total_count.zero?

      of_type = race_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Prepares race data for export
    # @param rows [Hash] The hash to store the export data
    # @return [Hash] The updated rows hash with race data
    def race_data_for_export(rows)
      rows['_Race Break'] ||= []
      rows['*Race Overall'] ||= []
      rows['*Race Overall'] += ['Race Overall', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Race Overall'] += ["#{coc_code} Client"]
        rows['*Race Overall'] += ["#{coc_code} Percentage"]
      end
      rows['*Race Overall'] += [nil]
      race_buckets.each do |id, title|
        rows["_Race Overall_data_#{title}"] ||= []
        rows["_Race Overall_data_#{title}"] += [
          title,
          nil,
          race_count(id),
          race_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Race Overall_data_#{title}"] += [
            race_count(id, coc_code.to_sym),
            race_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    # Groups clients by their race for a specific CoC code
    # @param coc_code [Symbol] The CoC code to group by, defaults to base_count_sym
    # @return [Hash] A hash mapping race types to sets of client IDs
    private def race_breakdowns(coc_code = base_count_sym)
      client_races[coc_code].group_by do |_, v|
        v
      end
    end

    # Retrieves client IDs for a specific race and CoC code
    # @param key [String] The race type to filter by
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Array] Array of client IDs with the specified race
    private def client_ids_in_race(key, coc_code = base_count_sym)
      race_breakdowns(coc_code)[key]&.map(&:first)
    end

    # Retrieves and caches client race data
    # @return [Hash] A hash mapping CoC codes to client race data
    private def client_races
      @client_races ||= Rails.cache.fetch(races_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          clients[base_count_sym] ||= {}
          available_coc_codes.each do |id, _|
            clients[id.to_sym] = {}
          end
          # find any clients who fell within the scope
          client_scope = GrdaWarehouse::Hud::Client.where(id: distinct_client_ids)
          cache_client = GrdaWarehouse::Hud::Client.new
          distinct_client_ids.pluck(:client_id).each do |client_id|
            clients[base_count_sym][client_id] = cache_client.race_string(scope_limit: client_scope, include_none_reason: true, destination_id: client_id)
          end
          available_coc_codes.each do |coc_code|
            client_coc_scope = GrdaWarehouse::Hud::Client.in_coc(coc_code: coc_code).where(id: distinct_client_ids)
            cache_coc_client = GrdaWarehouse::Hud::Client.new
            distinct_client_ids.in_enrollment_coc(coc_code: coc_code).pluck(:client_id).each do |client_id|
              clients[coc_code.to_sym][client_id] = cache_coc_client.race_string(scope_limit: client_coc_scope, include_none_reason: true, destination_id: client_id)
            end
          end
        end
      end
    end

    # Generates the cache key for race data
    # @return [Array] An array containing the class name, cache slug, and 'client_races'
    private def races_cache_key
      [self.class.name, cache_slug, 'client_races']
    end
  end
end
