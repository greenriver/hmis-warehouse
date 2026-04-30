###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Determines a user's permissions for CE Referrals.
# Key rules:
# - A user can view a referral if they have broad `:can_view_referrals` permission on the target project.
# - A user can also view a referral if they have `:can_view_own_referrals` and are assigned to one of its steps.
# - A user can also view a referral if they have `:can_view_own_referrals` and are a participant in a swimlane
#   that has a completed step in the referral.
class Hmis::AuthPolicies::CeReferralPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_view?
      return false unless Hmis::Ce.configuration.enabled?

      # Referrals that the user can view because they have can_view_referrals in the target project
      return true if project_permissions.include?(:can_view_referrals) && project_permissions.include?(:can_view_project)

      # Referrals that the user can view because they have can_view_outgoing_referral_details in the source project.
      # Note that can_view_outgoing_referral_details grants full referral details,
      # whereas can_manage_outgoing_referrals only grants summary level permission.
      return true if source_project_permissions.include?(:can_view_outgoing_referral_details)

      # Referrals that have a step assigned to this user, in projects in which the user can_view_own_referrals.
      # Referral only becomes viewable once the assigned step becomes available.
      # Note that the user does *not* need can_view_project in this case
      project_permissions.include?(:can_view_own_referrals) && context.assigned_referral_instance_ids.include?(referral.workflow_instance_id)
    end

    def can_view_summary?
      return false unless Hmis::Ce.configuration.enabled?

      return true if can_view?

      # Users who can manage outgoing referrals from the source project
      return true if source_project_permissions.include?(:can_manage_outgoing_referrals)

      # Users who can view the target enrollment. Bakes in the assumption that the target enrollment is in the referral's project, which is validated on the referral
      # TODO(8549) - encapsulate this check requiring both can_view_enrollment_details and can_view_project in the Enrollment Policy
      return true if referral.target_enrollment_id.present? && project_permissions.include?(:can_view_enrollment_details) && project_permissions.include?(:can_view_project)

      false
    end

    def can_assign_referral_tasks?
      return false unless Hmis::Ce.configuration.enabled?

      project_permissions.include?(:can_assign_referral_tasks)
    end

    def can_perform?(step: nil)
      return false unless Hmis::Ce.configuration.enabled?

      return true if project_permissions.include?(:can_perform_any_referral_tasks)

      return context.assigned_referral_step_ids.include?(step.id) if step && project_permissions.include?(:can_perform_own_referral_tasks)

      false
    end

    def can_create_note?(step: nil)
      return can_perform?(step: step) if step

      # If step is not provided, this check is for creating a top-level referral note. Allowed if user can perform _any_ available steps.
      return false unless Hmis::Ce.configuration.enabled?
      return true if project_permissions.include?(:can_perform_any_referral_tasks)
      return true if project_permissions.include?(:can_perform_own_referral_tasks) && context.assigned_referral_instance_ids.include?(referral.workflow_instance_id)

      false
    end

    protected

    # convenience
    def referral = resource

    # Permissions for the *target* project
    def project_permissions
      project_id = context.referral_project_id(referral.id)
      context.project_permissions(project_id)
    end

    def source_project_permissions
      project_id = context.referral_source_project_id(referral.id)
      context.project_permissions(project_id)
    end

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Ce::Referral)
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    # Whether the user can resolve a list of CE referrals.
    # Returns true if the user has either broad or own view permission anywhere in the data source.
    # The actual list resolved by the consumer must still be filtered via Hmis::Ce::Referral.viewable_by.
    def can_index?
      return false unless Hmis::Ce.configuration.enabled?

      (global_permissions & [:can_view_referrals, :can_view_own_referrals]).any?
    end

    # Whether the user has any referral task perform permission (broad or own) somewhere in the data source.
    # Use in combination with `can_index?` when a screen requires the user to be able to view and act on some referrals.
    def can_perform_some_referral_tasks?
      return false unless Hmis::Ce.configuration.enabled?

      (global_permissions & [:can_perform_any_referral_tasks, :can_perform_own_referral_tasks]).any?
    end

    # Whether the user is eligible to be assigned as a *data-source-wide* CE default contact.
    # Restricted to users who have `can_perform_any_referral_tasks` globally. Users who only have
    # `can_perform_own_referral_tasks` are not "admin-like" and should not be global default contacts.
    def can_be_global_default_contact?
      global_permissions.include?(:can_perform_any_referral_tasks)
    end

    # Whether the user can manage CE default contacts in the data source.
    # If we end up with a lot of default-contact-related permission checks, it might make sense to create a separate DefaultContactPolicy.
    def can_manage_ce_default_contacts?
      global_permissions.include?(:can_administrate_coordinated_entry)
    end

    # TODO(#9004): can_view_referrals? and can_view_own_referrals? are currently resolved
    # on the Client.access schema object, but the frontend always checks them both together.
    # Instead, we should deprecate these and resolve and use `can_index?` instead.
    #
    # Whether the user has permission to view SOME Referrals in the current DataSource
    # WARNING: use Instance policy to authorize access to a specific referral, not this method.
    def can_view_referrals?
      global_permissions.include?(:can_view_referrals)
    end

    # Whether the user has permission to view SOME of their own referrals in the Data Source.
    # WARNING: use Instance policy to authorize access to a specific referral, not this method.
    def can_view_own_referrals?
      global_permissions.include?(:can_view_own_referrals)
    end

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::Ce::Referral)
  end
end
