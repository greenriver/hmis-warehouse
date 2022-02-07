###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::He
  class LocationsController < HealthController
    include IndividualContactTracingController
    include AjaxModalRails::Controller

    before_action :set_case
    before_action :set_location, only: [:edit, :update, :destroy]

    def new
      @location = @case.locations.build
    end

    def create
      @location = @case.locations.create(location_params)
      redirect_to edit_health_he_case_path(@case) unless request.xhr?
    end

    def edit
    end

    def update
      @location.update(location_params)
      redirect_to edit_health_he_case_path(@case) unless request.xhr?
    end

    def destroy
      @location.destroy
      # respond_to do |format|
      #   format.html do
      redirect_to edit_health_he_case_path(@case) unless request.xhr?
      #   end
      # end
    end

    def location_params
      params.require(:health_tracing_location).permit(
        :location,
      )
    end

    def set_location
      @location = @case.locations.find(params[:id].to_i)
    end
  end
end
