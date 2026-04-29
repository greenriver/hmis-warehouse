###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisCustomAssessmentPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_delete?
      if resource.in_progress?
        # WIP Assessments, including WIP Intakes, can be deleted by users that have "can_edit_enrollments"
        project_permissions.include?(:can_edit_enrollments)
      elsif resource.intake?
        # Deleting a completed Intake deletes the enrollment, so the user needs "can_delete_enrollments"
        project_permissions.include?(:can_delete_enrollments)
      else
        # Otherwise, check "can_delete_assessments"
        project_permissions.include?(:can_delete_assessments)
      end
    end

    protected

    memoize def project_permissions
      raise "Enrollment #{resource.enrollment.id} is missing project_pk" unless resource.enrollment.project_pk.present?

      context.project_permissions(resource.enrollment.project_pk)
    end

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::CustomAssessment)
  end
end
