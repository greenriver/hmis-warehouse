###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleServices
  class VprsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ArelHelper
    include ClientPathGenerator
    before_action :set_client
    before_action :set_hpc_patient

    def index
      @vprs = @patient.flexible_services
      @follow_ups = @patient.flexible_service_follow_ups
    end

    private def vpr_source
      HealthFlexibleServices::Vpr
    end

    private def vpr_scope
      vpr_source.order(created_at: :desc)
    end
  end
end
