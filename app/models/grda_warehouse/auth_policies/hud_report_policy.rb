# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::HudReportPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # For future use
  # def can_view?
  #   return true if resource_permissions.include?(:can_view_all_hud_reports)

  #   resource.user_id == user.id && resource_permissions.include?(:can_view_own_hud_reports)
  # end

  def can_view_checkpoints?
    resource_permissions.include?(:can_view_all_hud_reports) && resource_permissions.include?(:can_manage_config)
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, HudReports::ReportInstance)
  end

  memoize def resource_permissions
    results = Set.new
    resource.project_ids.each do |project_id|
      results.merge(context.project_role_permissions(project_id))
    end
    results
  end
end
