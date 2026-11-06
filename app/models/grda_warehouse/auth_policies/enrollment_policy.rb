###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Per-record equivalent of GrdaWarehouse::Hud::Enrollment.visible_to
# (ClientAccessControl::EnrollmentArbiter#enrollments_visible_to)
class GrdaWarehouse::AuthPolicies::EnrollmentPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  memoize def can_view?
    return false unless enrollment.client && project

    user.using_acls? ? acl_can_view? : legacy_can_view?
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, GrdaWarehouse::Hud::Enrollment)
  end

  def enrollment
    resource
  end

  memoize def project
    enrollment.project
  end

  def acl_can_view?
    permissions = context.project_role_permissions(project.id)
    return true if permissions.include?(:can_view_clients)

    permissions.include?(:can_view_client_enrollments_with_roi) && roi_authorized?
  end

  def legacy_can_view?
    return true if context.project_role_permissions(project.id).present?
    return true if window_visible?

    roi_authorized?
  end

  def window_visible?
    context.legacy_window_data_source_ids.include?(project.data_source_id) &&
      !context.legacy_window_access_requires_release?
  end

  def roi_authorized?
    context.source_client_roi_authorized?(enrollment.client)
  end
end
