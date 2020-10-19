module
  CoreDemographicsReport::RaceCalculations
  extend ActiveSupport::Concern
  included do
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
      rows['*Race'] += ['Count', 'Percentage', nil, nil]
      race_buckets.each do |id, title|
        rows["_Race#{title}"] ||= []
        rows["_Race#{title}"] += [
          title,
          race_count(id),
          race_percentage(id),
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

    private def client_races
      @client_races ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
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
  end
end
