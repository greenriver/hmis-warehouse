###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::ProjectPolicy < Hmis::AuthPolicies::BasePolicy
  # not yet used, example
  def can_view? = project_role_permissions(resource).include?(:can_view_project)

  protected

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::Project)
end
