###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class CpRosterController < ApplicationController
    before_action :require_can_administer_health!

    def index
      @pagy, @files = pagy(file_scope)
    end

    def show
      @file = file_scope.find(params[:id].to_i)
      @pagy, @rows = pagy(@file.rosters)
    end

    def roster
      @file = Health::CpMembers::RosterFile.create(
        content: roster_params[:content].read,
        user: current_user,
        file: roster_params[:content].original_filename,
      )
      @file.parse
      @pagy, @rows = pagy(@file.rosters)
      render :show
    rescue Exception => e
      flash[:error] = "Error processing uploaded file #{e}"
      redirect_to action: :index
    end

    def enrollment
      @file = Health::CpMembers::EnrollmentRosterFile.create(
        content: enrollment_params[:content].read,
        user: current_user,
        file: enrollment_params[:content].original_filename,
      )
      @file.parse
      @pagy, @rows = pagy(@file.rosters)
      render :show
    rescue Exception => e
      flash[:error] = "Error processing uploaded file #{e}"
      redirect_to action: :index
    end

    def destroy
      file = file_scope.find(params[:id].to_i)
      file.destroy
      redirect_to action: :index
    end

    def roster_params
      params.require(:roster).permit(:content)
    end

    def enrollment_params
      params.require(:enrollment).permit(:content)
    end

    private def file_scope
      Health::CpMembers::FileBase.order(created_at: :desc)
    end
  end
end
