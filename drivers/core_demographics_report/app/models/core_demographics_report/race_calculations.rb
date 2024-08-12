###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::RaceCalculations
  extend ActiveSupport::Concern
  included do
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

    def race_buckets
      @race_buckets ||= ::HudUtility2024.races(multi_racial: true).merge(unknown_race_buckets).except('RaceNone')
    end

    private def unknown_race_buckets
      {
        'Does Not Know' => 'Does Not Know',
        'Prefers not to answer' => 'Prefers not to answer',
        'Not Collected' => 'Data not collected',
      }
    end

    def race_count(type, coc_code = base_count_sym)
      mask_small_population(race_breakdowns(coc_code)[type]&.count&.presence || 0)
    end

    def race_percentage(type, coc_code = base_count_sym)
      total_count = mask_small_population(client_races[coc_code].count)
      return 0 if total_count.zero?

      of_type = race_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

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

    private def race_breakdowns(coc_code = base_count_sym)
      client_races[coc_code].group_by do |_, v|
        v
      end
    end

    private def client_ids_in_race(key, coc_code = base_count_sym)
      race_breakdowns(coc_code)[key]&.map(&:first)
    end

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
            distinct_client_ids.in_coc(coc_code: coc_code).pluck(:client_id).each do |client_id|
              clients[coc_code.to_sym][client_id] = cache_coc_client.race_string(scope_limit: client_coc_scope, include_none_reason: true, destination_id: client_id)
            end
          end
        end
      end
    end

    private def races_cache_key
      [self.class.name, cache_slug, 'client_races']
    end
  end
end
