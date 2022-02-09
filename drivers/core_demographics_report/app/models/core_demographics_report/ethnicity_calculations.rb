###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::EthnicityCalculations
  extend ActiveSupport::Concern
  included do
    def ethnicity_detail_hash
      {}.tap do |hashes|
        HUD.ethnicities.each do |key, title|
          hashes["ethnicity_#{key}"] = {
            title: "Ethnicity - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_ethnicity(key)).distinct },
          }
        end
      end
    end

    def ethnicity_count(type)
      ethnicity_breakdowns[type]&.count&.presence || 0
    end

    def ethnicity_percentage(type)
      total_count = client_ethnicities.count
      return 0 if total_count.zero?

      of_type = ethnicity_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def ethnicity_data_for_export(rows)
      rows['_Ethnicity Break'] ||= []
      rows['*Ethnicity'] ||= []
      rows['*Ethnicity'] += ['Count', 'Percentage', nil, nil]
      ::HUD.ethnicities.each do |id, title|
        rows["_Ethnicity#{title}"] ||= []
        rows["_Ethnicity#{title}"] += [
          title,
          ethnicity_count(id),
          ethnicity_percentage(id),
          nil,
        ]
      end
      rows
    end

    def client_ids_in_ethnicity(key)
      ethnicity_breakdowns[key]&.map(&:first)
    end

    private def ethnicity_breakdowns
      @ethnicity_breakdowns ||= client_ethnicities.group_by do |_, v|
        v
      end
    end

    private def client_ethnicities
      @client_ethnicities ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.joins(:client).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, c_t[:Ethnicity], :first_date_in_program).
            each do |client_id, ethnicity, _|
              clients[client_id] ||= ethnicity
            end
        end
      end
    end
  end
end
