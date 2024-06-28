###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'
module GrdaWarehouse::CasProjectClientCalculator
  class Default
    # Used for limiting queries when displaying the CAS Readiness page
    attr_accessor :client_id
    # A hook/wrapper to enable easily overriding how we get data for a given project client column
    # To use this efficiently, you'll probably want to preload a handful of data, see push_clients_to_cas.rb
    def value_for_cas_project_client(client:, column:)
      client.send(column)
    end

    def description_for_column(column)
      custom_descriptions[column].presence || GrdaWarehouse::Hud::Client.cas_columns_data.dig(column, :description)
    end

    private def custom_descriptions
      {}
    end

    def unrelated_columns
      []
    end

    def most_recent_assessment_for_destination(_)
      nil
    end

    def chronically_homeless_for_cas(client)
      client.chronically_homeless_for_cas?
    end
  end
end
