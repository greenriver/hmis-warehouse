###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::He
  class SiteManagersController < HealthController
    include ContactTracingController
    before_action :set_case
    before_action :set_manager, only: [:edit, :update, :destroy]

    def index
      @managers = @case.site_leaders
    end

    def new
      @manager = @case.site_leaders.build
    end

    def create
      @case.site_leaders.create(site_manager_params)
      redirect_to action: :index
    end

    def edit
    end

    def update
      @manager.update(site_manager_params)
      redirect_to action: :index
    end

    def destroy
      @manager.destroy
      redirect_to action: :index
    end

    def site_manager_params
      params.require(:health_tracing_site_leader).permit(
        :site_name,
        :site_leader_name,
        :contacted_on,
      )
    end

    def set_case
      @case = Health::Tracing::Case.find(params[:case_id])
    end

    def set_manager
      @manager = @case.site_leaders.find(params[:id])
    end
  end
end
