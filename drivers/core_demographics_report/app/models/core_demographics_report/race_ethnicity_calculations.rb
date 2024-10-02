###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::RaceEthnicityCalculations
  extend ActiveSupport::Concern
  included do
    def race_ethnicity_detail_hash
      {}.tap do |hashes|
        race_combination_buckets.each do |key, titles|
          hashes["race_combination_#{key}"] = {
            title: "Race by Ethnicity - #{titles.compact.join(' and ')}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_race_combination(key)).distinct },
          }
        end
      end
    end

    def race_combination_buckets
      @race_combination_buckets ||= {}.tap do |r|
        # from RaceCalculations
        race_buckets.each do |race, race_title|
          ::HudUtility2024.ethnicities.each do |ethnicity, ethnicity_title|
            # Skip these impossibilities
            next if race == 'HispanicLatinaeo' && ethnicity == :non_hispanic_latinaeo
            next if race.in?(unknown_race_buckets.keys) && ethnicity.in?([:hispanic_latinaeo, :non_hispanic_latinaeo])
            next if ! race.in?(unknown_race_buckets.keys) && ethnicity == :unknown

            # We already have a version of uknown from the race, no need to repeat it
            ethnicity_title = nil if ethnicity == :unknown
            r[[race, ethnicity]] = [race_title, ethnicity_title]
          end
        end
        # unknown_race_buckets.each do |race, race_title|
        #   r[[race, nil]] = [race_title, nil]
        # end
      end
    end

    def race_combination_count(type, coc_code = base_count_sym)
      mask_small_population(race_combination_breakdowns(coc_code)[type]&.count&.presence || 0)
    end

    def race_combination_percentage(type, coc_code = base_count_sym)
      total_count = mask_small_population(client_race_combinations[coc_code].count)
      return 0 if total_count.zero?

      of_type = race_combination_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def race_combination_data_for_export(rows)
      rows['_Race by Ethnicity Break'] ||= []
      rows['*Race by Ethnicity'] ||= []
      rows['*Race by Ethnicity'] += ['Race by Ethnicity', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Race by Ethnicity'] += ["#{coc_code} Client"]
        rows['*Race by Ethnicity'] += ["#{coc_code} Percentage"]
      end
      rows['*Race by Ethnicity'] += [nil]
      race_combination_buckets.each do |id, titles|
        title = titles.compact.join(' and ')
        rows["_Race by Ethnicity_data_#{title}"] ||= []
        rows["_Race by Ethnicity_data_#{title}"] += [
          title,
          nil,
          race_combination_count(id),
          race_combination_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Race by Ethnicity_data_#{title}"] += [
            race_combination_count(id, coc_code.to_sym),
            race_combination_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    private def race_combination_breakdowns(coc_code = base_count_sym)
      client_race_combinations[coc_code].group_by do |_, v|
        v
      end
    end

    private def client_ids_in_race_combination(key, coc_code = base_count_sym)
      race_combination_breakdowns(coc_code)[key]&.map(&:first)
    end

    private def client_race_combinations
      @client_race_combinations ||= Rails.cache.fetch(race_combinations_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          clients[base_count_sym] ||= {}
          available_coc_codes.each do |id, _|
            clients[id.to_sym] = {}
          end
          # find any clients who fell within the scope
          client_scope = GrdaWarehouse::Hud::Client.where(id: distinct_client_ids)
          cache_client = GrdaWarehouse::Hud::Client.new
          distinct_client_ids.pluck(:client_id).each do |client_id|
            race = cache_client.race_string(scope_limit: client_scope, include_none_reason: true, destination_id: client_id)
            ethnicity = cache_client.ethnicity_slug(scope_limit: client_scope, destination_id: client_id)
            clients[base_count_sym][client_id] = [race, ethnicity]
          end
          available_coc_codes.each do |coc_code|
            client_coc_scope = GrdaWarehouse::Hud::Client.in_coc(coc_code: coc_code).where(id: distinct_client_ids)
            cache_coc_client = GrdaWarehouse::Hud::Client.new
            distinct_client_ids.in_coc(coc_code: coc_code).pluck(:client_id).each do |client_id|
              race = cache_coc_client.race_string(scope_limit: client_coc_scope, include_none_reason: true, destination_id: client_id)
              ethnicity = cache_coc_client.ethnicity_slug(scope_limit: client_coc_scope, destination_id: client_id)
              clients[coc_code.to_sym][client_id] = [race, ethnicity]
            end
          end
        end
      end
    end

    private def race_combinations_cache_key
      [self.class.name, cache_slug, 'client_race_combinations']
    end
  end
end
