###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisProjectPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_view?
      project_permissions.include?(:can_view_project)
    end

    def can_edit?
      project_permissions.include?(:can_edit_project_details)
    end

    def can_destroy?
      project_permissions.include?(:can_delete_project)
    end

    def can_manage_units?
      project_permissions.include?(:can_manage_units)
    end

    def can_update_unit_availability?
      project_permissions.include?(:can_update_unit_availability)
    end

    def can_send_out_direct_referral?
      project_permissions.include?(:can_manage_outgoing_referrals)
    end

    def can_view_outgoing_referral_summaries?
      project_permissions.include?(:can_view_outgoing_referral_details) || project_permissions.include?(:can_manage_outgoing_referrals)
    end

    def can_manage_ce_default_contacts?
      # Currently CE contact management is authorized using the global permission
      # "can_administrate_coordinated_entry", which grants access to manage default contacts at all projects.
      # In the future if/when we allow project-level admins to manage their own contacts,
      # this may be replaced with a check for a new non-admin permission like `project_permissions.include?(:can_manage_ce_default_contacts)`
      global_permissions.include?(:can_administrate_coordinated_entry)
    end

    # Whether the user can, in general, perform referral tasks in the project.
    # For determining whether a user can perform a specific task, see CeReferralPolicy.can_perform?
    def can_perform_referral_tasks?
      project_permissions.include?(:can_perform_any_referral_tasks) || project_permissions.include?(:can_perform_own_referral_tasks)
    end

    def can_enroll_clients?
      # TODO(#7475) - The historical relationship between can_enroll_clients and can_edit_enrollments is complex.
      # Currently we are only checking can_edit_enrollments, but this should be rethought/updated using permission requirements.
      # See ticket for details.
      project_permissions.include?(:can_edit_enrollments)
    end

    protected

    memoize def project_permissions
      context.project_permissions(resource.id)
    end

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::Project)
  end
end
