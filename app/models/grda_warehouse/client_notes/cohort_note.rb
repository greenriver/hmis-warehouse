module GrdaWarehouse::ClientNotes
  class CohortNote < Base
    def self.type_name
      "Cohort Note"
    end

    # only destroyable by admins for now
    def destroyable_by user
      user.can_edit_cohort_clients? || user.can_manage_cohorts? # || user_id == user.id
    end
  end
end