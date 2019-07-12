###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Window::Health
  class ClientsController < IndividualPatientController

    before_action :set_client, only: [:careplan]
    before_action :set_hpc_patient, only: [:careplan]
    
    include PjaxModalController
    include WindowClientPathGenerator
    def careplan

    end

  end
end