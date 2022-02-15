###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients::Youth
  class FollowUpsController < ApplicationController
    include ClientPathGenerator
    include AjaxModalRails::Controller
    include ClientDependentControllers

    before_action :require_can_access_youth_intake_list!
    before_action :require_can_edit_some_youth_intakes!
    before_action :set_client
    before_action :set_follow_up, only: [:edit, :update, :destroy]

    def new
      @follow_up = follow_up_source.new(contacted_on: Date.current)
    end

    def create
      @follow_up = follow_up_source.new(user_id: current_user.id, client: @client)
      @follow_up.update(follow_up_params)
      respond_with(@follow_up, location: polymorphic_path(youth_intakes_path_generator))
    end

    def edit
    end

    def update
      @follow_up.update(follow_up_params)
      respond_with(@follow_up, location: polymorphic_path(youth_intakes_path_generator))
    end

    def destroy
      @follow_up.destroy
      respond_with(@follow_up, location: polymorphic_path(youth_intakes_path_generator))
    end

    def follow_up_params
      params.require(:follow_up).permit(
        :contacted_on,
        :housing_status,
        :zip_code,
      )
    end

    def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    def set_follow_up
      @follow_up = follow_up_scope.find(params[:id].to_i)
    end

    def follow_up_source
      GrdaWarehouse::Youth::YouthFollowUp
    end

    def follow_up_scope
      follow_up_source.visible_by?(current_user)
    end

    def flash_interpolation_options
      { resource_name: '3-month follow up' }
    end
  end
end
