###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class IndividualPatientController < HealthController
  before_action :require_some_patient_access!
  after_action :log_client
end
