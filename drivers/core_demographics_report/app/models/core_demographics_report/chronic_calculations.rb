###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::ChronicCalculations
  extend ActiveSupport::Concern
  included do
    def chronic_detail_hash
      {}.tap do |hashes|
        available_chronic_types.invert.each do |key, title|
          hashes["chronic_#{key}"] = {
            title: "Chronic - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: chronic_client_ids(key)).distinct },
          }
        end
      end
    end

    def chronic_count(type)
      chronic_clients[type]&.count&.presence || 0
    end

    def chronic_percentage(type)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = chronic_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def chronic_data_for_export(rows)
      rows['_Chronic Type'] ||= []
      rows['*Chronic Type'] ||= []
      rows['*Chronic Type'] += ['Chronic Type', nil, 'Count', 'Percentage', nil]
      available_chronic_types.invert.each do |id, title|
        rows["_Chronic Type_data_#{title}"] ||= []
        rows["_Chronic Type_data_#{title}"] += [
          title,
          nil,
          chronic_count(id),
          chronic_percentage(id) / 100,
        ]
      end
      rows
    end

    private def chronic_client_ids(key)
      chronic_clients[key]
    end

    def available_chronic_types
      {
        'Client' => :client,
        'Household' => :household,
      }
    end

    private def chronic_clients
      @chronic_clients ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.distinct.
            joins(enrollment: :ch_enrollment).
            merge(GrdaWarehouse::ChEnrollment.chronically_homeless).
            order(first_date_in_program: :asc). # NOTE: this differs from other calculations, we might want to go back to desc
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:client] ||= Set.new
              clients[:client] << client_id
            end
          hoh_scope.distinct.
            joins(enrollment: :ch_enrollment).
            merge(GrdaWarehouse::ChEnrollment.chronically_homeless).
            order(first_date_in_program: :asc). # NOTE: this differs from other calculations, we might want to go back to desc
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:household] ||= Set.new
              clients[:household] << client_id
            end
        end
      end
    end
  end
end
