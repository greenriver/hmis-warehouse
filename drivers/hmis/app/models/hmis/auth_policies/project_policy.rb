###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# NOT in active use yet
class Hmis::AuthPolicies::ProjectPolicy < Hmis::AuthPolicies::BasePolicy
  def can_view?
    project_permissions.include?(:can_view_project)
  end

  def can_edit?
    project_permissions.include?(:can_edit_project_details)
  end

  def can_destroy?
    project_permissions.include?(:can_delete_project)
  end

  protected

  memoize def project_permissions
    context.project_role_permissions(resource.id)
  end

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::Project)
end
