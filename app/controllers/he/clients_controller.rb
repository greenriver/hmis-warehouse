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
      @triage = GrdaWarehouse::HealthEmergency::Triage.new(agency: current_user.agency)
      @test = GrdaWarehouse::HealthEmergency::Test.new(agency: current_user.agency)
      @isolation = GrdaWarehouse::HealthEmergency::Isolation.new(agency: current_user.agency)
      @quarantine = GrdaWarehouse::HealthEmergency::Quarantine.new(agency: current_user.agency)

      @triages = @client.health_emergency_triages.newest_first
      @tests = @client.health_emergency_test.newest_first
      @isolations = @client.health_emergency_isolations.newest_first
      @quarantines = @client.health_emergency_quarantines.newest_first
    end
  end
end
