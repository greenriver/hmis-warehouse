###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class RoleAuditsController < ::ApplicationController
    before_action :require_can_audit_users!
    before_action :set_role
    include AuditHistory

    def show
      @history = Audit::Versions.new(@role, role_audit_config)
      @pagy, @versions = pagy_array(@history.version_scope)
    end

    def export
      @history = Audit::Versions.new(@role, role_audit_config)
      @versions = @history.version_scope

      respond_to do |format|
        format.csv do
          send_data generate_csv, filename: "#{@role.name.parameterize}-audit-history-#{Date.current}.csv"
        end
      end
    end

    private

    def set_role
      @role = Role.find(params[:role_id].to_i)
    end
  end
end
