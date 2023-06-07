###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::HighAcuityCalculations
  extend ActiveSupport::Concern
  included do
    def high_acuity_detail_hash
      {}.tap do |hashes|
        available_high_acuity_types.invert.each do |key, title|
          hashes["high_acuity_#{key}"] = {
            title: "High Acuity - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: high_acuity_client_ids(key)).distinct },
          }
        end
      end
    end

    def high_acuity_count(type)
      high_acuity_clients[type]&.count&.presence || 0
    end

    def high_acuity_percentage(type)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = high_acuity_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def high_acuity_data_for_export(rows)
      rows['_High Acuity Type'] ||= []
      rows['*High Acuity Type'] ||= []
      rows['*High Acuity Type'] += ['High Acuity Type', nil, 'Count', 'Percentage', nil]
      available_high_acuity_types.invert.each do |id, title|
        rows["_High Acuity Type_data_#{title}"] ||= []
        rows["_High Acuity Type_data_#{title}"] += [
          title,
          nil,
          high_acuity_count(id),
          high_acuity_percentage(id) / 100,
        ]
      end
      rows
    end

    private def high_acuity_client_ids(key)
      high_acuity_clients[key]
    end

    def available_high_acuity_types
      {
        'Client' => :client,
        'Household' => :household,
      }
    end

    private def high_acuity_clients
      @high_acuity_clients ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.distinct.
            joins(client: :source_enrollment_disabilities).
            merge(GrdaWarehouse::Hud::Disability.chronically_disabled).
            pluck(:client_id, d_t[:DisabilityType]).
            group_by(&:shift).
            each do |client_id, disabilities|
              # Don't count anyone with only one disabling condition
              next unless disabilities.count > 1
              # Don't count anyone we've already counted in the chronic counts
              next if chronic_clients[:client].include?(client_id)

              clients[:client] ||= Set.new
              clients[:client] << client_id
            end
          hoh_scope.distinct.
            joins(client: :source_enrollment_disabilities).
            merge(GrdaWarehouse::Hud::Disability.chronically_disabled).
            pluck(:client_id, d_t[:DisabilityType]).
            group_by(&:shift).
            each do |client_id, disabilities|
              # Don't count anyone with only one disabling condition
              next unless disabilities.count > 1
              # Don't count anyone we've already counted in the chronic counts
              next if chronic_clients[:household].include?(client_id)

              clients[:household] ||= Set.new
              clients[:household] << client_id
            end
        end
      end
    end
  end
end
