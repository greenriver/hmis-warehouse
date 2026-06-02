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

    def can_view_details?
      project_permissions.include?(:can_view_enrollment_details) # can_view_enrollment_details? requires can_view_project?
    end

    def can_create_file?
      # User can create a file for this enrollment if they:
      # - can manage client files in the project, OR
      # - have the global permission can_manage_own_client_files
      project_permissions.include?(:can_manage_any_client_files) || global_permissions.include?(:can_manage_own_client_files)
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

  class Global < Hmis::AuthPolicies::BasePolicy
    # Whether the user can view some enrollments with full details
    def can_view?
      global_permissions.include?(:can_view_enrollment_details) && global_permissions.include?(:can_view_project)
    end

    # Whether the user can view some enrollments with limited details
    def can_view_limited?
      global_permissions.include?(:can_view_limited_enrollment_details)
    end

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::Hud::Enrollment)
  end
end
