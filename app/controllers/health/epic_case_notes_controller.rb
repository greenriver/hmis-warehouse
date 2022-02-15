###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class EpicCaseNotesController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    before_action :set_client
    before_action :set_hpc_patient

    def show
      @note = @patient.epic_case_notes.find(params[:id].to_i)
    end

    protected def title_for_show
      "#{@client.name} - Health - Epic Case Note"
    end
  end
end
