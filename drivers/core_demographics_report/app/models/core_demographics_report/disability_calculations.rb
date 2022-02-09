###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::DisabilityCalculations
  extend ActiveSupport::Concern
  included do
    def disability_detail_hash
      {}.tap do |hashes|
        HUD.disability_types.each do |key, title|
          hashes["disability_#{key}"] = {
            title: "Disability #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_disability(key)).distinct },
          }
        end
      end
    end

    def disability_count(type)
      disability_breakdowns[type]&.count&.presence || 0
    end

    def disability_percentage(type)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = disability_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def no_disability_count
      @no_disability_count ||= total_client_count - client_disabilities_count
    end

    def no_disability_percentage
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = no_disability_count
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def yes_disability_count
      @yes_disability_count ||= client_disabilities_count
    end

    def yes_disability_percentage
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = yes_disability_count
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def disability_data_for_export(rows)
      rows['_Disability Break'] ||= []
      rows['*Indefinite and Impairing Disabilities'] ||= []
      rows['*Indefinite and Impairing Disabilities'] += ['Count', 'Percentage', nil, nil]
      ::HUD.disability_types.each do |id, title|
        rows["_Disabilities#{title}"] ||= []
        rows["_Disabilities#{title}"] += [
          title,
          disability_count(id),
          disability_percentage(id),
          nil,
        ]
      end
      rows['_At Least One Disability'] ||= []
      rows['_At Least One Disability'] += [
        'At Least One Disability',
        yes_disability_count,
        yes_disability_percentage,
        nil,
      ]
      rows['_No Disability'] ||= []
      rows['_No Disability'] += [
        'No Disability',
        no_disability_count,
        no_disability_percentage,
        nil,
      ]
      rows
    end

    private def client_disabilities_count
      @client_disabilities_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        client_disabilities.count
      end
    end

    def client_ids_in_disability(type)
      disability_breakdowns[type]
    end

    private def disability_breakdowns
      @disability_breakdowns ||= {}.tap do |disabilities|
        ::HUD.disability_types.keys.each do |d|
          disabilities[d] ||= Set.new
          client_disabilities.each do |id, ds|
            disabilities[d] << id if ds.include?(d)
          end
        end
      end
    end

    private def client_disabilities
      @client_disabilities ||= Rails.cache.fetch(disabilities_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          disabled_client_disability_types.each do |client_id, disability|
            clients[client_id] ||= Set.new
            clients[client_id] << disability
          end
        end
      end
    end

    private def disabled_client_disability_types
      GrdaWarehouse::Hud::Client.disabled_client_scope.where(id: distinct_client_ids).
        joins(:source_enrollment_disabilities).
        merge(
          GrdaWarehouse::Hud::Disability.
          where(
            DisabilityType: ::HUD.disability_types.keys,
            DisabilityResponse: [1, 2, 3],
            IndefiniteAndImpairs: 1,
          ),
        ).pluck(:id, d_t[:DisabilityType])
    end

    private def disabilities_cache_key
      [self.class.name, cache_slug, 'client_disabilities']
    end
  end
end
