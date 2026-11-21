###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::AuthPolicies::HudReportPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  memoize def can_view_definition?
    url = resource.report_definition_url
    return false if url.nil?

    GrdaWarehouse::WarehouseReports::ReportDefinition.url_viewable_by?(url, user)
  end

  memoize def run_visible?
    HudReports::ReportInstance.viewable_by(user).where(id: resource.id).exists?
  end

  # The definition check implies can_view_any_reports, so that flag isn't checked separately.
  memoize def can_view?
    can_view_definition? && run_visible?
  end

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
