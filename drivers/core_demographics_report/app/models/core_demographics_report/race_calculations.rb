###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_race(key)).distinct },
          }
        end
      end
    end

    def race_buckets
      ::HUD.races.merge('MultiRacial' => 'Multi-racial')
    end

    def race_count(type)
      race_breakdowns[type]&.count&.presence || 0
    end

    def race_percentage(type)
      total_count = client_races.count
      return 0 if total_count.zero?

      of_type = race_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def race_data_for_export(rows)
      rows['_Race Break'] ||= []
      rows['*Race'] ||= []
      rows['*Race'] += ['Race', 'Count', 'Percentage', nil, nil]
      race_buckets.each do |id, title|
        rows["_Race_data_#{title}"] ||= []
        rows["_Race_data_#{title}"] += [
          title,
          race_count(id),
          race_percentage(id) / 100,
          nil,
        ]
      end
      rows
    end

    private def race_breakdowns
      @race_breakdowns ||= client_races.group_by do |_, v|
        v
      end
    end

    private def client_ids_in_race(key)
      race_breakdowns[key]&.map(&:first)
    end

    private def client_races
      @client_races ||= Rails.cache.fetch(races_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          # find any clients who fell within the scope
          client_scope = GrdaWarehouse::Hud::Client.where(id: distinct_client_ids)
          cache_client = GrdaWarehouse::Hud::Client.new
          distinct_client_ids.pluck(:client_id).each do |client_id|
            clients[client_id] = cache_client.race_string(scope_limit: client_scope, destination_id: client_id)
          end
        end
      end
    end

    private def races_cache_key
      [self.class.name, cache_slug, 'client_races']
    end
  end
end
