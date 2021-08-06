###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::He
  class StaffController < HealthController
    include IndividualContactTracingController
    before_action :set_case
    before_action :set_client
    before_action :set_staff, only: [:edit, :update, :destroy]

    def index
      @staffs = @case.staffs
    end

    def new
      @staff = @case.staffs.build(investigator: @case.investigator)
    end

    def create
      @case.staffs.create(staff_params)
      redirect_to action: :index
    end

    def edit
    end

    def update
      @staff.update(staff_params)
      redirect_to action: :index
    end

    def destroy
      @staff.destroy
      redirect_to action: :index
    end

    def staff_params
      params.require(:health_tracing_staff).permit(
        :investigator,
        :date_interviewed,
        :first_name,
        :last_name,
        :site_name,
        :notified,
        :nature_of_exposure,
        :symptomatic,
        :other_symptoms,
        :referred_for_testing,
        :test_result,
        :notes,
        :phone_number,
        :address,
        :dob,
        :estimated_age,
        :gender,
        :vaccinated,
        :vaccination_complete,
        vaccine: [],
        vaccination_dates: [],
        symptoms: [],
      )
    end

    private def set_staff
      @staff = @case.staffs.find(params[:id])
    end
  end
end
