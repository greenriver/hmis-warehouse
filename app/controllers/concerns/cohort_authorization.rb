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

    # Finds a cohort client only if it is in a tab the user can see on this cohort
    def find_visible_cohort_client(id, with_deleted: false)
      id = id.to_i
      visible = @cohort.cohort_tabs.select { |tab| tab.show_for?(current_user) }.any? do |tab|
        @cohort.clients_for_tab(current_user, tab.name, tab).where(id: id).exists?
      end
      raise ActiveRecord::RecordNotFound unless visible

      scope = @cohort.cohort_clients
      scope = scope.with_deleted if with_deleted
      scope.find(id)
    end

    def cohort_source
      GrdaWarehouse::Cohort
    end
  end
end
