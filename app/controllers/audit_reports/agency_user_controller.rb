###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AuditReports
  class AgencyUserController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :require_can_view_user_audit_report!

    # To see this report, a user needs:
    # 1. Can manage agency
    # 2. Can audit users
    # 3. Can view assigned reports
    # 4. Assign the report
    # 5. User needs an agency assigned

    def index
      @column = user_sort_options.map { |i| i[:column] }.detect { |c| c == params[:column] } || 'last_name'
      @direction = ['asc', 'desc'].detect { |c| c == params[:direction] } || 'asc'

      @agencies = Agency.all.order(:name) if current_user.can_manage_all_agencies
      @users = user_scope

      respond_to do |format|
        format.html do
          @users = sort_users(@users)
          @users = @users.page(params[:page]).per(25)
        end
        format.xlsx do
          @users = @users.order(:last_name, :first_name)
          filename = "#{@agency.downcase.tr(' ', '-')}-audit-#{Date.current.strftime('%Y-%m-%d')}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def clients_viewed(user, months_in_past)
      return 0 unless view_history[user.id].present?
      return 0 unless view_history[user.id][months_in_past].present?

      view_history[user.id][months_in_past]
    end
    helper_method :clients_viewed

    def user_sort_options
      [
        {
          column: 'last_name',
          direction: :asc,
          title: 'Last name A-Z',
        },
        {
          column: 'last_name',
          direction: :desc,
          title: 'Last name Z-A',
        },
        {
          column: 'current_sign_in_at',
          direction: :desc,
          title: 'Most Recent Login',
        },
        {
          column: 'current_sign_in_at',
          direction: :asc,
          title: 'Least Recent Login',
        },
        {
          column: 'this_month',
          direction: :desc,
          title: 'Most Clients This Month',
        },
        {
          column: 'this_month',
          direction: :asc,
          title: 'Least Clients This Month',
        },
        {
          column: 'last_month',
          direction: :desc,
          title: 'Most Clients Last Month',
        },
        {
          column: 'last_month',
          direction: :asc,
          title: 'Least Clients Last Month',
        },
        {
          column: 'prev_month',
          direction: :desc,
          title: 'Most Clients Previous Month',
        },
        {
          column: 'prev_month',
          direction: :asc,
          title: 'Least Clients Previous Month',
        },
      ]
    end
    helper_method :user_sort_options

    def sort_users(users)
      return users.order(@column => @direction) unless @column.include? 'month'

      # FIXME: this needs to be pushed off to the database
      case @column
      when 'this_month'
        sorted = users.sort_by { |user| clients_viewed(user, 0) }
      when 'last_month'
        sorted = users.sort_by { |user| clients_viewed(user, 1) }
      when 'prev_month'
        sorted = users.sort_by { |user| clients_viewed(user, 2) }
      end

      sorted.reverse! if @direction == 'desc'
      Kaminari.paginate_array(sorted)
    end

    def view_history
      al_t = ActivityLog.arel_table
      @view_history ||= begin
        history = {}
        months = {
          Date.current.month => 0,
          (Date.current - 1.months).month => 1,
          (Date.current - 2.months).month => 2,
        }
        User.active.pluck_in_batches(:id, batch_size: 100) do |batch|
          ActivityLog.created_in_range(
            range: 2.months.ago.beginning_of_month.to_date .. Date.tomorrow,
          ).
            where(
              user_id: batch,
              item_model: 'GrdaWarehouse::Hud::Client',
            ).
            group(:user_id, datepart(ActivityLog, 'month', al_t[:created_at]).to_sql).
            distinct.
            count(:item_id).each do |(user_id, month), count|
            history[user_id] ||= []
            history[user_id][months[month.to_i]] = count
          end
        end
        history
      end
    end

    def user_scope
      return User.none if current_user.agency.blank?

      scope = User.
        active.
        joins(:agency)
      if current_user.can_manage_all_agencies
        @agency = 'All Agencies'
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
      scope.
        preload(:agency)
    end

    private def report_params
      params.permit(report: [:agency])
    end
    helper_method :report_params
  end
end
