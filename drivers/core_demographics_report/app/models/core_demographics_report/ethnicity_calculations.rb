###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::EthnicityCalculations
  extend ActiveSupport::Concern
  included do
    def ethnicity_detail_hash
      {}.tap do |hashes|
        ethnicity_buckets.each do |key, title|
          hashes["ethnicity_#{key}"] = {
            title: "Ethnicity - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_ethnicity(key)).distinct },
          }
        end
      end
    end

    def ethnicity_buckets
      @ethnicity_buckets ||= ::HudUtility2024.ethnicities.merge(dont_know: "Don't know", prefers_not_to_answer: 'Prefers not to answer', not_collected: 'Data not collected').except(:unknown)
    end

    def ethnicity_count(type, coc_code = base_count_sym)
      mask_small_population(ethnicity_breakdowns(coc_code)[type]&.count&.presence || 0)
    end

    def ethnicity_percentage(type, coc_code = base_count_sym)
      total_count = mask_small_population(client_ethnicities[coc_code].count)
      return 0 if total_count.zero?

      of_type = ethnicity_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def ethnicity_data_for_export(rows)
      rows['_Ethnicity Break'] ||= []
      rows['*Ethnicity Overall'] ||= []
      rows['*Ethnicity Overall'] += ['Ethnicity Overall', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Ethnicity Overall'] += ["#{coc_code} Client"]
        rows['*Ethnicity Overall'] += ["#{coc_code} Percentage"]
      end
      rows['*Ethnicity Overall'] += [nil]
      ethnicity_buckets.each do |id, title|
        rows["_Ethnicity Overall_data_#{title}"] ||= []
        rows["_Ethnicity Overall_data_#{title}"] += [
          title,
          nil,
          ethnicity_count(id),
          ethnicity_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Ethnicity Overall_data_#{title}"] += [
            ethnicity_count(id, coc_code.to_sym),
            ethnicity_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    private def ethnicity_breakdowns(coc_code = base_count_sym)
      client_ethnicities[coc_code].group_by do |_, v|
        v
      end
    end

    private def client_ids_in_ethnicity(key, coc_code = base_count_sym)
      ethnicity_breakdowns(coc_code)[key]&.map(&:first)
    end

    private def client_ethnicities
      @client_ethnicities ||= Rails.cache.fetch(ethnicities_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          clients[base_count_sym] ||= {}
          available_coc_codes.each do |id, _|
            clients[id.to_sym] = {}
          end
          # find any clients who fell within the scope
          client_scope = GrdaWarehouse::Hud::Client.where(id: distinct_client_ids)
          cache_client = GrdaWarehouse::Hud::Client.new
          distinct_client_ids.pluck(:client_id).each do |client_id|
            clients[base_count_sym][client_id] = cache_client.ethnicity_slug(scope_limit: client_scope, include_none_reason: true, destination_id: client_id)
          end
          available_coc_codes.each do |coc_code|
            client_coc_scope = GrdaWarehouse::Hud::Client.in_coc(coc_code: coc_code).where(id: distinct_client_ids)
            cache_coc_client = GrdaWarehouse::Hud::Client.new
            distinct_client_ids.in_coc(coc_code: coc_code).pluck(:client_id).each do |client_id|
              clients[coc_code.to_sym][client_id] = cache_coc_client.ethnicity_slug(scope_limit: client_coc_scope, include_none_reason: true, destination_id: client_id)
            end
          end
        end
      end
    end

    private def ethnicities_cache_key
      [self.class.name, cache_slug, 'client_ethnicities']
    end
  end
end
