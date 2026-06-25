###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
