module Admin
  class AuditsController < ::ApplicationController
    before_action :require_can_audit_users!

    def show
      @user = User.find params[:user_id]
      @activity_log = ActivityLog.where(user_id: @user.id)
        .order(created_at: :desc)
        .page(params[:page]).per(50)
    end

  end
end
