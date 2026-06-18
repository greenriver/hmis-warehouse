###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisAdmin::AccessControlAuditsController < ApplicationController
  include EnforceHmisEnabled
  include HmisAuditHistory

  before_action :require_hmis_admin_access!
  before_action :set_variables

  def show
  end

  def export
    respond_to do |format|
      format.csv do
        send_data generate_audit_csv(@versions, @history),
                  filename: "hmis-access-control-#{@access_control.id}-audit-history-#{Date.current.to_fs(:db)}.csv"
      end
    end
  end

  private

  def set_variables
    @access_control = Hmis::AccessControl.with_deleted.find(params[:access_control_id].to_i)
    @access_control.define_singleton_method(:name) { "Access Control List #{id}" }
    @history = Audit::Versions.new(@access_control, hmis_access_control_component_config)
    @versions = @history.version_array.sort_by(&:created_at).reverse
  end
end
