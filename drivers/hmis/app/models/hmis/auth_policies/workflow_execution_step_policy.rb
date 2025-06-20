# frozen_string_literal: true

class Hmis::AuthPolicies::WorkflowExecutionStepPolicy < Hmis::AuthPolicies::BasePolicy
  def can_perform?
    return false unless Hmis::Ce.configuration.enabled?

    project_permissions = context.referral_project_permissions(referral)
    return true if project_permissions.include?(:can_perform_any_referral_tasks)

    project_permissions.include?(:can_perform_own_referral_tasks) && context.assigned_referral_step_ids.include?(step.id)
  end

  protected

  # convenience
  def step = resource
  def referral = context.referral_for_step(step.id)

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::WorkflowExecution::Step)
end
