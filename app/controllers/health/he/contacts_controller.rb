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
      @contact = @case.contacts.build
    end

    def index
      @contacts = @case.contacts
    end

    def create
      @case.contacts.create(contact_params)
      redirect_to action: :index
    end

    def destroy
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
        :date_interviewed,
        :first_name,
        :last_name,
      )
    end
  end
end
