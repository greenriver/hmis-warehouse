###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PatientReferralsController < IndividualPatientController
    include PjaxModalController
    include ClientPathGenerator

    before_action :require_some_patient_access!
    before_action :set_hpc_patient
    before_action :set_client

    def index
      @patient_referrals = @patient.patient_referrals.
        order(enrollment_start_date: :asc)
    end

    protected def title_for_show
      "#{@client.name} - Health - Enrollment History"
    end
  end
end
