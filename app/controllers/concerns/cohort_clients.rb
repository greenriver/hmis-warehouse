###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortClients
  extend ActiveSupport::Concern

  included do
    def set_cohort_clients
      @cohort_clients = @cohort.search_clients(
        page: params[:page].to_i,
        per: params[:per].to_i,
        population: params[:population],
        user: current_user,
      )
    end
  end
end
