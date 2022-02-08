###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class AgenciesController < HealthController
    before_action :require_has_administrative_access_to_health!
    before_action :require_can_manage_health_agencies!
    before_action :set_health_agency, only: [:edit, :update, :destroy]

    respond_to :html

    def index
      @health_agencies = agency_scope.order(name: :asc)
      respond_with(@health_agencies)
    end

    def new
      @form_url = admin_health_agencies_path
      @health_agency = agency_source.new
      respond_with(@health_agency)
    end

    def edit
      @form_url = admin_health_agency_path(@health_agency)
    end

    def create
      @health_agency = agency_source.new(health_agency_params)
      @health_agency.save
      respond_with(@health_agency, location: admin_health_agencies_path)
    end

    def update
      @health_agency.update(health_agency_params)
      respond_with(@health_agency, location: admin_health_agencies_path)
    end

    def destroy
      @health_agency.destroy
      respond_with(@health_agency, location: admin_health_agencies_path)
    end

    private

    def flash_interpolation_options
      { resource_name: 'Agency' }
    end

    def agency_source
      Health::Agency
    end

    def agency_scope
      agency_source.all
    end

    def set_health_agency
      @health_agency = agency_scope.find(params[:id].to_i)
    end

    def health_agency_params
      params.require(:health_agency).permit(:name, :short_name)
    end
  end
end
