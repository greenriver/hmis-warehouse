###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisAdmin::RoleAuditsController < ApplicationController
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
                  filename: "#{@role.name.parameterize}-audit-history-#{Date.current.to_fs(:db)}.csv"
      end
    end
  end

  private

  def set_variables
    @role = Hmis::Role.with_deleted.find(params[:role_id].to_i)
    @history = Audit::Versions.new(@role, hmis_role_audit_config)
    @versions = @history.version_array.sort_by(&:created_at).reverse
  end
end
