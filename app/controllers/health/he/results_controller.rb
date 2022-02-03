###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::He
  class ResultsController < HealthController
    include IndividualContactTracingController
    include AjaxModalRails::Controller

    before_action :set_case
    before_action :set_contact
    before_action :set_result, only: [:edit, :update, :destroy]

    def new
      @result = @contact.results.build
    end

    def create
      @result = @contact.results.create(result_params)
      redirect_to edit_health_he_contact_path(@contact) unless request.xhr?
    end

    def edit
    end

    def update
      @result.update(result_params)
      redirect_to edit_health_he_contact_path(@contact) unless request.xhr?
    end

    def destroy
      @result.destroy
      # respond_to do |format|
      #   format.html do
      redirect_to edit_health_he_contact_path(@contact) unless request.xhr?
      #   end
      # end
    end

    def result_params
      params.require(:health_tracing_result).permit(
        :test_result,
        :isolated,
        :isolation_location,
        :quarantine,
        :quarantine_location,
      )
    end

    def set_contact
      @contact = @case.contacts.find(params[:contact_id].to_i)
    end

    def set_result
      @result = @contact.results.find(params[:id].to_i)
    end
  end
end
