module AuditReports
  class UserLoginController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @users = User.active.order(current_sign_in_at: :desc)
    end

  end
end