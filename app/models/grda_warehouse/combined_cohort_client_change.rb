###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class CombinedCohortClientChange < GrdaWarehouseBase
    belongs_to :cohort
    belongs_to :cohort_client, -> { with_deleted }
    has_one :client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :client_id, foreign_key: :id
    belongs_to :user, optional: true

    scope :on_cohort_between, -> (start_date:, end_date:) do
      at = arel_table
      # Excellent discussion of why this works:
      # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
      d_1_start = start_date
      d_1_end = end_date
      d_2_start = at[:entry_date]
      d_2_end = at[:exit_date]
      # Currently does not count as an overlap if one starts on the end of the other
      where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
    end

    scope :on_cohort, -> (cohort_id) do
      where(cohort_id: cohort_id)
    end

    scope :removal, -> do
      where(exit_action: ['destroy', 'deactivate'])
    end

    def change_reason
      return reason if reason.present?
      if exit_action == 'deactivate'
        return 'Deactivated'
      end
    end
  end
end
