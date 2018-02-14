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

    def require_can_edit_cohort!
      current_user.can_manage_cohorts? || current_user.can_edit_cohort_clients?
    end

    def cohort_scope
      cohort_source.viewable_by(current_user)
    end

    def set_cohort
      @cohort = cohort_scope.find(cohort_id)
    end

    def cohort_source
      GrdaWarehouse::Cohort
    end
    

  end
end