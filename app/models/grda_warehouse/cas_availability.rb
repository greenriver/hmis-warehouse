###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class CasAvailability < GrdaWarehouseBase

    scope :available_between, -> (start_date:, end_date:) do
      where(
        arel_table[:available_at].lt(end_date).
        and(
          arel_table[:unavailable_at].gt(start_date).
          or(arel_table[:unavailable_at].eq(nil))
        )
      )
    end

    scope :already_available, -> do
      where(unavailable_at: nil)
    end

    scope :family, -> do
      where(part_of_a_family: true)
    end

    scope :individuals, -> do
      where(part_of_a_family: false)
    end

    scope :youth, -> do
      where(age_at_available_at: (18..24))
    end

  end
end
