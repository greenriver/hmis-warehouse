###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class EnrollmentsController < ApplicationController
    include ClientController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :set_enrollment

    def show
      @chronic_at_entry_matrix = GrdaWarehouse::ChEnrollment.ch_at_entry_matrix(@enrollment)
    end

    private

    def set_enrollment
      @enrollment = GrdaWarehouse::Hud::Enrollment.visible_to(current_user).find(params[:id].to_i)
      @service_history_enrollment = @enrollment.service_history_enrollment
      @client = @enrollment.destination_client
      raise ActiveRecord::RecordNotFound if @client.id != params[:client_id].to_i
    end
  end
end
