###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class UserGroupAuditsController < ::ApplicationController
    before_action :require_can_audit_users!
    before_action :set_user_group
    include AuditHistory

    def show
      @history = Audit::Versions.new(@user_group, user_group_audit_config)
      @pagy, @versions = pagy_array(@history.version_scope)
    end

    def export
      @history = Audit::Versions.new(@user_group, user_group_audit_config)
      @versions = @history.version_scope

      respond_to do |format|
        format.csv do
          send_data generate_csv, filename: "#{@user_group.name.parameterize}-audit-history-#{Date.current}.csv"
        end
      end
    end

    private

    def set_user_group
      @user_group = UserGroup.find(params[:user_group_id].to_i)
    end
  end
end
