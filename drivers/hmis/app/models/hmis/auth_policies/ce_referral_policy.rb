# frozen_string_literal: true

class Hmis::AuthPolicies::CeReferralPolicy < Hmis::AuthPolicies::BasePolicy
  CAN_VIEW_CE_REFERRAL_PERMS = [:can_view_referrals, :can_view_own_referrals].freeze
  CAN_PERFORM_CE_REFERRAL_TASK_PERMS = [:can_perform_any_referral_tasks, :can_perform_own_referral_tasks].freeze
  def can_index?
    return false unless Hmis::Ce.configuration.enabled?

    # require that a user could both view referrals and act on them
    return false unless (context.potential_permissions & CAN_VIEW_CE_REFERRAL_PERMS).any?
    return false unless (context.potential_permissions & CAN_PERFORM_CE_REFERRAL_TASK_PERMS).any?

    true
  end

  # What makes a referral viewable by a user?
  # - If they have can_view_referrals at the target project, OR
  # - If they have can_view_own_referrals, AND are assigned a step in the referral.
  def can_view?
    return false unless Hmis::Ce.configuration.enabled?

    project_permissions = context.referral_project_permissions(referral)

    # Referrals that the user can view because they have can_view_referrals in the target project
    return true if project_permissions.include?(:can_view_referrals) && project_permissions.include?(:can_view_project)

    # Referrals that have a step assigned to this user, in projects in which the user can_view_own_referrals.
    # Referral only becomes viewable once the assigned step becomes available.
    # Note that the user does *not* need can_view_project in this case
    project_permissions.include?(:can_view_own_referrals) && context.assigned_referral_instance_ids.include?(referral.workflow_instance_id)
  end

  protected

  # convenience
  def referral = resource

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Ce::Referral)
end
