###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ContactsController < IndividualPatientController
    before_action :set_hpc_patient

    def index
      @contacts = @patient.
        client_contacts.
        order(collected_on: :desc)
    end
  end
end
