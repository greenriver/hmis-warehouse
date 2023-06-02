###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::UnshelteredCalculations
  extend ActiveSupport::Concern
  included do
    def unsheltered_detail_hash
      {}.tap do |hashes|
        hashes['unsheltered'] = {
          title: 'Unsheltered - Active in Street Outreach',
          headers: client_headers,
          columns: client_columns,
          scope: -> { report_scope.joins(:client, :enrollment).where(client_id: unsheltered_client_ids(:client)).distinct },
        }
      end
    end

    def unsheltered_count(type)
      unsheltered_clients[type]&.count&.presence || 0
    end

    def unsheltered_percentage(type)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = unsheltered_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def unsheltered_data_for_export(rows)
      rows['_Unsheltered'] ||= []
      rows['*Unsheltered'] ||= []
      rows['*Unsheltered'] += ['Unsheltered', 'Count', 'Percentage', nil, nil]
      rows['_Unsheltered_data_Active in Street Outreach'] ||= []
      rows['_Unsheltered_data_Active in Street Outreach'] += [
        'Active in Street Outreach',
        unsheltered_count(:client),
        unsheltered_percentage(:client) / 100,
        nil,
      ]
      rows
    end

    private def unsheltered_client_ids(key)
      unsheltered_clients[key]
    end

    private def unsheltered_clients
      @unsheltered_clients ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.distinct.
            in_project_type(HudUtility.project_type_number('Street Outreach')).
            # checks SHS which equates to CLS
            with_service_between(start_date: filter.start_date, end_date: filter.end_date).
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:client] ||= Set.new
              clients[:client] << client_id
            end
        end
      end
    end
  end
end
