###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ClientsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    before_action :set_client, only: [:careplan]
    before_action :set_hpc_patient, only: [:careplan]

    def careplan
    end
  end
end
