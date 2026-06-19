###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class IndividualPatientController < HealthController
  before_action :require_some_patient_access!
  after_action :log_client
end
