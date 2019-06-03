###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Window::Health::Pilot
  class PatientController < HealthController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]
    include PjaxModalController
    include WindowClientPathGenerator
    include ActionView::Helpers::NumberHelper
    
    helper HealthOverviewHelper

    def index
      load_patient_metrics
      
      render layout: !request.xhr?      
    end
    
  end
end