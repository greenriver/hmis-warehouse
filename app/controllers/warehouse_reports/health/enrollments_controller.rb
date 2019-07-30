###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class EnrollmentsController < ApplicationController
    before_action :require_can_administer_health!

    def index
      @file = Health::Enrollment.new
      @files = Health::Enrollment.order(created_at: :desc)
    end

    def create
      @file = Health::Enrollment.create(
        user_id: current_user.id,
        content: enrollment_params[:content].read,
        original_filename: enrollment_params[:content].original_filename)
      redirect_to action: :index
    end

    def enrollment_params
      params.require(:health_enrollment).permit(:content)
    end

  end
end