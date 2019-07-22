module AuditReports
  class UserLoginController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @users = User.active.where.not(current_sign_in_at: nil).order(current_sign_in_at: :desc).page(params[:page])
    end

  end
end