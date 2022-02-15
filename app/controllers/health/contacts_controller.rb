###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ContactsController < IndividualPatientController
    def index
      @patient = Health::Patient.accessible_by_user(current_user).find_by(client_id: params[:client_id].to_i)
    end
  end
end
