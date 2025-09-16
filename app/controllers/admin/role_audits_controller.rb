###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class RoleAuditsController < ::ApplicationController
    before_action :require_can_audit_users!
    before_action :set_variables
    include AuditHistory

    def show
    end

    def export
      respond_to do |format|
        format.csv do
          send_data generate_audit_csv(@versions, @history), filename: "#{@role.name.parameterize}-audit-history-#{Date.current.to_fs(:db)}.csv"
        end
      end
    end

    private

    def set_variables
      @role = Role.find(params[:role_id].to_i)
      @history = Audit::Versions.new(@role, role_audit_config)
      @versions = @history.version_array.sort_by(&:created_at).reverse
    end
  end
end
