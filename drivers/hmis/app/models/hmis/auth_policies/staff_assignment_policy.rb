###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::StaffAssignmentPolicy < Hmis::AuthPolicies::BasePolicy
  memoize def can_index?
    return false unless Hmis::ProjectStaffAssignmentConfig.exists?

    project_scope = Hmis::Hud::Project.with_access(user, :can_edit_enrollments).preload(:organization)
    Hmis::ProjectStaffAssignmentConfig.for_projects(project_scope).exists?
  end

  protected

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::StaffAssignment)
end
