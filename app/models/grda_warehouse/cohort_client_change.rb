###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class CohortClientChange < GrdaWarehouseBase
    belongs_to :cohort
    belongs_to :cohort_client, -> { with_deleted }
    has_one :client, through: :cohort_client
    belongs_to :user

    validates_presence_of :cohort_client, :cohort, :user, :change

    scope :on_cohort, -> (cohort_id) do
      where(cohort_id: cohort_id)
    end

    scope :removal, -> do
      where(change: ['destroy', 'deactivate'])
    end

    # has_one :cohort_exit, -> { where("id > " ).order(id: :asc) }, class_name: 'GrdaWarehouse::CohortClientChange', primary_key: [:cohort_id, :cohort_client_id], foreign_key: [:cohort_id, :cohort_client_id]

    def associated_exit
      a_t = self.class.arel_table
      self.class.removal.
        where(
          cohort_id: cohort_id,
          cohort_client_id: cohort_client_id
        ).
        where(a_t[:id].gt(id)).
        order(id: :asc).
        limit(1).first
    end

    def change_reason
      return reason if reason.present?
      if change == 'deactivate'
        return 'Deactivated'
      end
    end
  end
end
