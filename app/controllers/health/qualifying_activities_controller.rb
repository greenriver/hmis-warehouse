###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class QualifyingActivitiesController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    before_action :require_some_patient_access!
    before_action :set_hpc_patient
    before_action :set_qualifying_activities, only: [:index]
    before_action :require_can_unsubmit_submitted_claims!, only: [:destroy]
    before_action :set_qualifying_activity, only: [:destroy]
    before_action :set_client

    def index
      @start_date = params[:start_date]
      @end_date = params[:end_date]
    end

    def destroy
      # Destroy has 2 levels:
      # If the claim was submitted destroy the record of that
      # Otherwise, remove the QA
      if @qa.claim_submitted_on.blank?
        @qa.destroy
        flash[:notice] = 'QA deleted'
      else
        @qa.claim_submitted_on = nil
        @qa.save(validate: false)
        flash[:notice] = 'QA unsubmitted'
      end
      redirect_to(polymorphic_path(health_path_generator + [:qualifying_activities]))
    end

    def set_qualifying_activities
      # search / paginate
      @qualifying_activities = @patient.qualifying_activities.
        date_search(params[:start_date], params[:end_date]).
        order(date_of_activity: :desc)
      @pagy, @qualifying_activities = pagy(@qualifying_activities)
    end

    protected def title_for_show
      "#{@client.name} - Health - Qualifying Activities"
    end

    protected def set_qualifying_activity
      @qa = @patient.qualifying_activities.find(params[:id].to_i)
    end

    def flash_interpolation_options
      { resource_name: 'Qualifying Activity' }
    end
  end
end
