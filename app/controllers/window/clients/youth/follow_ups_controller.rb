###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Window::Clients::Youth
  class FollowUpsController < ApplicationController
    include WindowClientPathGenerator
    include PjaxModalController

    before_action :require_can_access_youth_intake_list!
    before_action :require_can_edit_some_youth_intakes!, only: [:new, :create, :edit, :update, :destroy]
    before_action :set_client
    before_action :set_follow_up, only: [:edit, :update, :destroy]

    def new
      @follow_up =  GrdaWarehouse::Youth::YouthFollowUp.new(contacted_on: Date.today)
    end

    def create
      @follow_up = GrdaWarehouse::Youth::YouthFollowUp.new(user_id: current_user.id, client: @client)
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
      @client = GrdaWarehouse::Hud::Client.destination.find(params[:client_id].to_i)
    end

    def set_follow_up
      @follow_up =  GrdaWarehouse::Youth::YouthFollowUp.find(params[:id].to_i)
    end
  end
end