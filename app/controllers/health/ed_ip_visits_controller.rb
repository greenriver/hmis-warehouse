###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class EdIpVisitsController < HealthController
    # This controller serves both BH CP data and pilot data, so it can't use the BH CP permissions
    include PjaxModalController
    include ClientPathGenerator

    before_action :require_pilot_or_some_client_access!

    def index
      set_hpc_patient
      set_patient if @patient.blank?

      respond_to do |format|
        format.json do
          render json: @patient.ed_ip_visits_for_chart
        end
      end
    end

    private def title_for_show
      "#{@client.name} - Health - ED & IP Visits"
    end
  end
end
