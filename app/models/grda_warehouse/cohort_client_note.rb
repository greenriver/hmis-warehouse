###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class CohortClientNote < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :cohort_client
    has_one :client, through: :cohort_client
    belongs_to :user

    validates_presence_of :cohort_client, :note

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    # only destroyable by admins for now
    def destroyable_by user
      user.can_edit_cohort_clients? || user.can_manage_cohorts? # || user_id == user.id
    end

  end
end