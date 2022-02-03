###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class MedicationsController < HealthController
    # This controller serves both BH CP data and pilot data, so it can't use the BH CP permissions
    include AjaxModalRails::Controller
    include ClientPathGenerator

    before_action :require_pilot_or_some_client_access!
    before_action :set_client, only: [:index]

    def index
      set_hpc_patient
      set_patient if @patient.blank?
      @medications = @patient.medications.order(start_date: :desc, ordered_date: :desc)

      render layout: !request.xhr?
    end

    protected def title_for_show
      "#{@client.name} - Health - Medications"
    end
  end
end
