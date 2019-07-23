###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module AuditReports
  class AgencyUserController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_user_audit_report!

    def index
      if current_user.can_manage_all_agencies
        @agencies = Agency.all.order(:name)
      end
      @users = user_scope
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename="#{@agency.downcase.gsub(/ /, '-')}-audit-#{Date.today.strftime('%Y-%m-%d')}"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def clients_viewed(user, months_in_past)
      return 0 unless view_history[user.id].present?

      return view_history[user.id][months_in_past]
    end
    helper_method :clients_viewed

    def view_history
      @view_history ||= ActivityLog.where(
        user_id: user_scope.pluck(:id),
        item_model: GrdaWarehouse::Hud::Client.name,
        created_at: 2.months.ago.beginning_of_month .. Date.today,
      ).
      select(:user_id, :item_id, :created_at).
      group_by(&:user_id).
        map do |user_id, dates|
          current = dates.select { |date| date.created_at >= Date.today.beginning_of_month }.map(&:item_id).uniq.count
          last = dates.select { |date| date.created_at < Date.today.beginning_of_month && date.created_at >= 1.month.ago.beginning_of_month }.map(&:item_id).uniq.count
          previous = dates.select { |date| date.created_at < 1.month.ago.beginning_of_month  }.map(&:item_id).uniq.count

          [user_id, [current, last, previous]]
        end.to_h
    end

    def user_scope
      scope = User.
        active.
        joins(:agency)
      if current_user.can_manage_all_agencies
        @agency = "All Agencies"
        if params[:report].present?
          if params[:report][:agency].present?
            agency = Agency.find(params[:report][:agency].to_i)
            scope = scope.where(agency_id: agency.id)
            @agency_id = agency.id
            @agency = agency.name
          end
        end
      else
        @agency = current_user.agency.name
        scope = scope.where(agency: current_user.agency)
      end
      scope.order(:last_name, :first_name).page(params[:page])
    end

  end
end