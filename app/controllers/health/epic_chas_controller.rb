###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class EpicChasController < HealthController
    include PjaxModalController
    include ClientPathGenerator
    include HealthFileController

    before_action :require_pilot_or_some_client_access!
    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show]

    def show
      set_hpc_patient
      set_patient if @patient.blank?
    end

    def set_form
      @form = form_scope.find(params[:id].to_i)
    end

    def form_scope
      Health::EpicCha.all
    end

    protected def title_for_show
      "#{@client.name} - Health - Epic CHA"
    end
  end
end
