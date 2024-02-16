###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::DisabilityCalculations
  extend ActiveSupport::Concern
  included do
    def disability_detail_hash
      hash = {}.tap do |hashes|
        HudUtility2024.disability_types.each do |key, title|
          hashes["disability_#{key}"] = {
            title: "Disability #{title}",
            can_view_details: can_view_client_disability?(@filter.user, key),
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_disability(key)).distinct },
          }
        end
      end
      hash.merge!(
        'yes_disability' =>
          {
            title: 'At Least One Disability',
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_disabilities.keys).distinct },
          },
        'no_disability' =>
          {
            title: 'No Disability',
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: distinct_client_ids.pluck(:client_id).uniq - client_disabilities.keys).distinct },
          },
      )
    end

    def disability_count(type)
      mask_small_population(disability_breakdowns[type]&.count&.presence || 0)
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
      rows['*Indefinite and Impairing Disabilities'] += ['Disability', nil, 'Count', 'Percentage', nil]
      ::HudUtility2024.disability_types.each do |id, title|
        rows["_Disabilities_data_#{title}"] ||= []
        rows["_Disabilities_data_#{title}"] += [
          title,
          nil,
          disability_count(id),
          disability_percentage(id) / 100,
        ]
      end
      rows['_At Least One Disability_data_'] ||= []
      rows['_At Least One Disability_data_'] += [
        'At Least One Disability',
        nil,
        yes_disability_count,
        yes_disability_percentage / 100,
      ]
      rows['_No Disability_data_'] ||= []
      rows['_No Disability_data_'] += [
        'No Disability',
        nil,
        no_disability_count,
        no_disability_percentage / 100,
      ]
      rows
    end

    private def client_disabilities_count
      @client_disabilities_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(client_disabilities.count)
      end
    end

    def client_ids_in_disability(type)
      disability_breakdowns[type]
    end

    private def disability_breakdowns
      @disability_breakdowns ||= {}.tap do |disabilities|
        ::HudUtility2024.disability_types.keys.each do |d|
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
      ids = distinct_client_ids.pluck(:client_id)
      return [] unless ids.any?

      GrdaWarehouse::Hud::Client.disabled_client_scope(client_ids: ids).
        joins(:source_enrollment_disabilities).
        merge(
          GrdaWarehouse::Hud::Disability.
          where(GrdaWarehouse::Hud::Disability.indefinite_disability_arel),
        ).pluck(
          :id,
          d_t[:DisabilityType],
        )
    end

    private def disabilities_cache_key
      [self.class.name, cache_slug, 'client_disabilities']
    end
  end
end
