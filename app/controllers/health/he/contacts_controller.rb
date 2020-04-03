###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::He
  class ContactsController < HealthController
    include ContactTracingController
    before_action :set_case
    before_action :set_client
    before_action :set_contact, only: [:edit, :update, :destroy]

    def new
      @contact = @case.contacts.build(investigator: @case.investigator)
    end

    def index
      @contacts = @case.contacts
    end

    def create
      @case.contacts.create(contact_params)
      redirect_to action: :index
    end

    def destroy
      @contact.destroy
      redirect_to action: :index
    end

    def update
      @contact.update(contact_params)
      redirect_to action: :index
    end

    private def set_contact
      @contact = @case.contacts.find(params[:id].to_i)
    end

    def contact_params
      params.require(:health_tracing_contact).permit(
        :investigator,
        :date_interviewed,
        :alert_in_epic,
        :first_name,
        :last_name,
        :aliases,
        :phone_number,
        :address,
        :dob,
        :estimated_age,
        :gender,
        :ethnicity,
        :preferred_language,
        :relationship_to_index_case,
        :location_of_exposure,
        :nature_of_exposure,
        :location_of_contact,
        :sleeping_location,
        :symptomatic,
        :symptom_onset_date,
        :referred_for_testing,
        :test_result,
        :isolated,
        :isolation_location,
        :quarantine,
        :quarantine_location,
        :notes,
        race: [],
      )
    end
  end
end
