###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module He
  class ClientsController < ApplicationController
    include ClientDependentControllers
    include HealthEmergencyController

    def boston_covid_19
      @triages = GrdaWarehouse::HealthEmergency::Triage.where(client_id: params[:client_id].to_i).newest_first
      @tests = GrdaWarehouse::HealthEmergency::Test.where(client_id: params[:client_id]).newest_first
      @isolations = GrdaWarehouse::HealthEmergency::IsolationBase.where(client_id: params[:client_id]).newest_first
    end
  end
end
