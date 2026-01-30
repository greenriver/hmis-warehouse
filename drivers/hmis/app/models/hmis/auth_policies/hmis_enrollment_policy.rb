###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisEnrollmentPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
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

    protected

    # convenience
    def enrollment = resource

    def project_permissions
      raise "Enrollment #{enrollment.id} is missing project_pk" unless enrollment.project_pk.present?

      context.project_permissions(enrollment.project_pk)
    end

    def validate_resource!(arg)
      ensure_arg_type!(arg, Hmis::Hud::Enrollment)
    end
  end
end
