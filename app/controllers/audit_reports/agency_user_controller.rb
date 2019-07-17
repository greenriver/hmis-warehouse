module AuditReports
  class AgencyUserController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_user_audit_report!

    def index
      if current_user.can_manage_all_agencies
        @agency = "All Agencies"
      else
        @agency = current_user.agency.name
      end
      @users = user_scope
    end

    def clients_viewed(user, months_in_past)
      month = months_in_past.months.ago
      ActivityLog.where(
        user: user, item_model:
        GrdaWarehouse::Hud::Client.name,
        created_at: month.beginning_of_month .. month.end_of_month).
        distinct.
        select(:item_id).
        count
    end
    helper_method :clients_viewed

    def user_scope
      if current_user.can_manage_all_agencies
        scope = User.all
      else
        scope = User.where(agency: current_user.agency)
      end
      scope.order(:last_name, :first_name)
    end

  end
end