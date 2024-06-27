###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'
module GrdaWarehouse::CasProjectClientCalculator
  class Springfield < Default
    def value_for_cas_project_client(client:, column:)
      if column == :chronically_homeless_for_cas && GrdaWarehouse::Config.get(:chronic_adult_only_cohort)
        chronically_homeless_for_cas(client)
      else
        client.send(column)
      end
    end

    # All clients on the "Active Clients" tab of the adult only system cohort
    private def chronic_adult_chronic_cohort_client_ids
      @chronic_adult_chronic_cohort_client_ids ||= GrdaWarehouse::SystemCohorts::ChronicAdultOnly.first.search_clients(user: User.system_user).pluck(:client_id).to_set
    end

    def chronically_homeless_for_cas(client)
      # Count anyone who is either marked as chronically homeless, or part of the chronically homeless cohort
      # as chronic for CAS
      client.chronically_homeless_for_cas || on_chronic_system_cohort?(client)
    end

    def on_chronic_system_cohort?(client)
      chronic_adult_chronic_cohort_client_ids.include?(client.id)
    end
  end
end
