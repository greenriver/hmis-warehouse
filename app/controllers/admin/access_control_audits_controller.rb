###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class AccessControlAuditsController < ::ApplicationController
    before_action :require_can_audit_users!
    before_action :set_access_control
    include AuditHistory

    def show
      @history = Audit::Versions.new(@access_control, access_control_component_config)
      @pagy, @versions = pagy_array(@history.version_scope)
    end

    def export
      @history = Audit::Versions.new(@access_control, access_control_component_config)
      @versions = @history.version_scope

      respond_to do |format|
        format.csv do
          send_data generate_audit_csv(@versions, @history), filename: "access-control-#{@access_control.id}-component-history-#{Date.current}.csv"
        end
      end
    end

    private

    def set_access_control
      @access_control = AccessControl.find(params[:access_control_id].to_i)
    end
  end
end
