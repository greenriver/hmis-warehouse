###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortAuthorization
  extend ActiveSupport::Concern

  included do
    helper_method :cohort_policy, :cohort_policy_for

    def some_cohort_access!
      return true if cohort_source.has_some_cohort_access current_user

      not_authorized!
    end

    def require_can_access_cohort!
      return true if cohort_scope.where(id: cohort_id).any?

      not_authorized!
    end

    def require_more_than_read_only_access_to_cohort!
      return true if cohort_source.has_some_cohort_access(current_user) && current_user.can_edit_some_cohorts

      not_authorized!
    end

    # Loads unscoped so authorize_with decides; a nonexistent id raises RecordNotFound
    def load_cohort
      @cohort = cohort_source.find(cohort_id)
    end

    def cohort_policy
      cohort_policy_for(@cohort)
    end

    def cohort_policy_for(cohort)
      current_user.policy_for(cohort)
    end

    def cohort_scope
      cohort_source.viewable_by(current_user)
    end

    def active_cohort_scope
      cohort_scope.active
    end

    def inactive_cohort_scope
      cohort_scope.inactive
    end

    def set_cohort
      @cohort = cohort_scope.find(cohort_id)
    end

    # TODO: START_ACL remove when ACL transition complete
    def set_groups
      @groups = @cohort.access_groups
      @group_ids = @cohort.access_group_ids
    end
    # END_ACL

    def set_users
      @users = User.active.not_system
      @participant_ids = @cohort.editable_access_control.user_ids
      @viewer_ids = @cohort.viewable_access_control.user_ids
      @manager_ids = @cohort.manager_user_ids
    end

    def cohort_source
      GrdaWarehouse::Cohort
    end
  end
end
