###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortAuthorization
  extend ActiveSupport::Concern

  included do
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

    def set_users
      @users = User.active.not_system
      @participator_ids = @cohort.editable_acl.user_ids
      @viewer_ids = @cohort.viewable_acl.user_ids
    end

    def cohort_source
      GrdaWarehouse::Cohort
    end
  end
end
