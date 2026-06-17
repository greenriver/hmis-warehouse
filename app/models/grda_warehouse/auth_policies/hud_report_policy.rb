###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::AuthPolicies::HudReportPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # For future use
  # def can_view?
  #   ?
  # end

  # No appropriate collection or access group relationship exists; wrap the permission methods on
  # user for backwards compatibility
  def can_view_checkpoints?
    user.can_view_all_hud_reports? && user.can_manage_config?
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, HudReports::ReportInstance)
  end
end
