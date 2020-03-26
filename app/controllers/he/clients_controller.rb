###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module He
  class ClientsController < ApplicationController
    include ClientDependentControllers
    include HealthEmergency
    before_action :require_health_emergency!

    def boston_covid_19
    end
  end
end
