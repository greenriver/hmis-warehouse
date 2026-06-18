###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
