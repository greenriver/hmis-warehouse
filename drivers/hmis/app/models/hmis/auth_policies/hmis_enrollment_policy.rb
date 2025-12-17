###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisEnrollmentPolicy < Hmis::AuthPolicies::BasePolicy
  # TODO: Add policy methods for can_view and can_view_limited and use them in GraphQL queries

  def can_edit?
    project_permissions.include?(:can_edit_enrollments)
  end

  def can_delete?
    # WIP Enrollments can be deleted if user has "can_edit_enrollments" access for this project
    return can_edit? if enrollment.in_progress?

    # Otherwise, to delete an active enrollment the user needs "can_delete_enrollments" permission
    project_permissions.include?(:can_delete_enrollments)
  end

  def can_delete_assessment?(assessment)
    # WIP assessments, including WIP Intakes, can be deleted by users that can edit the enrollment
    return can_edit? if assessment.in_progress?

    # Deleting a completed intake deletes the enrollment, so only users that can delete the enrollment can do this
    return project_permissions.include?(:can_delete_enrollments) if assessment.intake?

    # Otherwise, require can_delete_assessments
    project_permissions.include?(:can_delete_assessments)
  end

  protected

  # convenience
  def enrollment = resource

  def project_permissions
    raise 'Tried to call enrollment policy on non-hmis enrollment' unless enrollment.project_pk.present?

    context.project_permissions(enrollment.project_pk)
  end

  def validate_resource!(arg)
    ensure_arg_type!(arg, Hmis::Hud::Enrollment)
  end
end
