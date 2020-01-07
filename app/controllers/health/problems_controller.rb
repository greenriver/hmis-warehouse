###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class ProblemsController < HealthController
    # This controller serves both BH CP data and pilot data, so it can't use the BH CP permissions
    include PjaxModalController
    include ClientPathGenerator

    before_action :require_pilot_or_some_client_access!
    before_action :set_client, only: [:index]

    def index
      set_hpc_patient
      set_patient if @patient.blank?
      @problems = @patient.problems.order(onset_date: :desc)

      render layout: !request.xhr?
    end

    protected def title_for_show
      "#{@client.name} - Health - Problems"
    end
  end
end
