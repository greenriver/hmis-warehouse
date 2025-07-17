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
# - Indexing (e.g., for a dashboard) requires a combination of view and perform permissions.
class Hmis::AuthPolicies::CeReferralPolicy < Hmis::AuthPolicies::BasePolicy
  def can_index?
    return false unless Hmis::Ce.configuration.enabled?

    # require that a user could both view referrals and act on them
    return false unless (context.potential_permissions & [:can_view_referrals, :can_view_own_referrals]).any?
    return false unless (context.potential_permissions & [:can_perform_any_referral_tasks, :can_perform_own_referral_tasks]).any?

    true
  end

  def can_view?
    return false unless Hmis::Ce.configuration.enabled?

    # Referrals that the user can view because they have can_view_referrals in the target project
    return true if project_permissions.include?(:can_view_referrals) && project_permissions.include?(:can_view_project)

    # Referrals that have a step assigned to this user, in projects in which the user can_view_own_referrals.
    # Referral only becomes viewable once the assigned step becomes available.
    # Note that the user does *not* need can_view_project in this case
    project_permissions.include?(:can_view_own_referrals) && context.assigned_referral_instance_ids.include?(referral.workflow_instance_id)
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

  def can_create_note?(...) = can_perform?(...)

  protected

  # convenience
  def referral = resource

  def project_permissions
    project_id = context.referral_project_id(referral.id)
    context.project_permissions(project_id)
  end

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Ce::Referral)
end
