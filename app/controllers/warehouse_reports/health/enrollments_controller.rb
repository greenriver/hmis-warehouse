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
      begin
        @file = Health::Enrollment.create(
          user_id: current_user.id,
          content: enrollment_params[:content].read,
          original_filename: enrollment_params[:content].original_filename,
          status: 'processing',
        )
        Health::ProcessEnrollmentChangesJob.perform_later(@file.id)
      rescue Exception => e
        flash[:error] = "Error processing uploaded file #{e}"
      end
      redirect_to action: :index
    end

    def show
      @file = Health::Enrollment.find(params[:id].to_i)
      @transactions = Kaminari.paginate_array(@file.transactions).page(params[:page])
    end

    def enrollment_params
      params.require(:health_enrollment).permit(:content)
    end

  end
end