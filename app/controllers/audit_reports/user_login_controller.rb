###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AuditReports
  class UserLoginController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @users = users_scope
      respond_to do |format|
        format.html do
          @users = @users.page(params[:page]).per(25)
        end
        format.xlsx do
          date = Date.current.strftime('%Y-%m-%d')
          filename = "user-logins-#{date}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def users_scope
      User.
        joins(:agency).
        preload(:agency).
        active.
        where.not(current_sign_in_at: nil).
        order(current_sign_in_at: :desc)
    end
  end
end
