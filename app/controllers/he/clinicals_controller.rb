###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module He
  class ClinicalsController < ApplicationController
    include ClientDependentControllers
    include HealthEmergency
    before_action :require_health_emergency!
    before_action :can_edit_health_emergency_clinical!
  end
end
