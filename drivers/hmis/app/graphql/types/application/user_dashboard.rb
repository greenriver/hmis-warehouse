###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Application::UserDashboard < Types::BaseObject
    # Type for resolving data needed on the HMIS user dashboard.
    # Underlying object is Hmis::User, who should always be the currently logged-in user.
    description 'Resolves everything that is needed on the user dashboard'

    def self.authorized?(object, ctx)
      raise 'user dashboard can only be resolved for current user' unless object == ctx[:current_user]

      super
    end

    field :id, ID, null: false
    field :user_dashboard_config, Types::Application::UserDashboardConfig, null: false
    field :staff_assignments, HmisSchema::StaffAssignment.page_type, null: true
    field :ce_referral_steps, HmisSchema::CeReferralStep.page_type, null: true

    def user_dashboard_config
      {
        id: object.id,
        show_staff_assignment: show_staff_assignment,
        show_referrals: show_referrals,
      }
    end

    def staff_assignments
      return unless show_staff_assignment

      object.staff_assignments.
        viewable_by(current_user). # Only resolve assignments where the user has access to view the household
        open_on_date. # This will include households that exited today
        merge(Hmis::Hud::Household.sort_by_option(:most_recent))
    end

    def ce_referral_steps
      return unless show_referrals

      step_scope = Hmis::WorkflowExecution::Step.
        joins(:assignments).
        merge(object.workflow_step_assignments).
        open.
        order(available_at: :desc, id: :desc)

      # Join to referrals for
      # - permission checking
      # - ensuring we only resolve CE steps and not other workflow types
      # For performance, rely on assumption that only active referrals have active steps.
      referral_scope = Hmis::Ce::Referral.active.viewable_by(current_user)
      instance_ids = referral_scope.pluck(:workflow_instance_id).uniq

      step_scope.where(instance_id: instance_ids)
    end

    private

    def show_referrals
      @show_referrals ||= begin
        return false unless Hmis::Ce.configuration.enabled?

        can_view_referrals = object.permissions?(:can_view_referrals, :can_view_own_referrals)
        can_perform_referral_steps = object.permissions?(:can_perform_any_referral_tasks, :can_perform_own_referral_tasks)

        can_view_referrals && can_perform_referral_steps
      end
    end

    def show_staff_assignment
      @show_staff_assignment ||= begin
        return false unless Hmis::ProjectStaffAssignmentConfig.exists?

        project_scope = Hmis::Hud::Project.with_access(object, :can_edit_enrollments).preload(:organization)
        Hmis::ProjectStaffAssignmentConfig.for_projects(project_scope).exists?
      end
    end
  end
end
